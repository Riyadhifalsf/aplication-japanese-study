import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../state/app_controller.dart';
import '../widgets/admob_banner_slot.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common_widgets.dart';
import 'donation/donation_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'quiz/quiz_center_screen.dart';
import 'study/learning_experience_screen.dart';
import 'review/review_experience_screen.dart';
import 'notifications/notification_center_screen.dart';

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.app,
    required this.title,
    required this.onProfile,
  });

  final AppController app;
  final String title;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: .42)),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: .62),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Japanese Study',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: app.darkMode ? 'Gunakan mode terang' : 'Gunakan mode gelap',
              onPressed: app.toggleTheme,
              icon: Icon(
                app.darkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onProfile,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(
                        Icons.person_rounded,
                        size: 19,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      app.isAuthenticated ? app.homeDisplayName : 'Profil',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  AppController? _app;
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = PageController(initialPage: 0);
  }
  @override
  void dispose() {
    _app?.endSession();
    _pages.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
  }

  Future<void> _openProfile() async {
    final app = _app ?? AppScope.of(context);
    if (!app.isAuthenticated) {
      await requireLogin(context, feature: 'Profil');
      return;
    }
    if (!mounted) return;
    unawaited(Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())));
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    );
  }

  Future<void> _select(int value) async {
    final target = value.clamp(0, 4);
    setState(() => _index = target);
    if (_pages.hasClients) {
      _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
    unawaited(AdsService.instance.onTabChange());
  }

  void _onPageChanged(int value) {
    if (value == _index) return;
    setState(() => _index = value);
    unawaited(AdsService.instance.onTabChange());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _app?.startSession();
      if (mounted) setState(() {});
    }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _app?.endSession();
    }
  }

  /// Urutan tab: 0 Beranda, 1 Learning, 2 Donasi (tengah),
  /// 3 Practice, 4 Library. Daftar dipakai PageView agar bisa digeser.
  List<Widget> _tabPages(AppController app) => [
        HomeScreen(
            key: const PageStorageKey('tab-beranda'),
            onOpenStudy: () => _select(1),
            onOpenQuiz: () => _select(3),
            onOpenProfile: _openProfile),
        CurriculumPathScreen(
            key: const PageStorageKey('tab-learning'),
            initialLevel: app.curriculumActiveLevelId),
        const DonationScreen(key: PageStorageKey('tab-donasi')),
        const QuizCenterScreen(key: PageStorageKey('tab-practice')),
        const StudyHubScreen(key: PageStorageKey('tab-library')),
      ];

  @override
  Widget build(BuildContext context) {
    final app = _app ?? AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final pages = [
      const NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: Text('Beranda')),
      const NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: Text('Learning')),
      const NavigationRailDestination(icon: Icon(Icons.volunteer_activism_outlined, size: 30), selectedIcon: Icon(Icons.volunteer_activism_rounded, size: 30), label: Text('Donasi')),
      const NavigationRailDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz_rounded), label: Text('Practice')),
      const NavigationRailDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books_rounded), label: Text('Library')),
    ];
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final pageBody = SafeArea(
      bottom: false,
      child: AdaptiveContent(
        child: disableAnimations
            ? _tabPages(app)[_index]
            : PageView(
                controller: _pages,
                onPageChanged: _onPageChanged,
                children: _tabPages(app),
              ),
      ),
    );

    // Home sudah memiliki header khasnya sendiri. Semua tab lain memakai
    // header global yang identik agar posisi notifikasi dan profil selalu simetris.
    final body = _index == 0
        ? pageBody
        : Column(
            children: [
              _GlobalNavigationHeader(
                app: app,
                onNotifications: _openNotifications,
                onProfile: _openProfile,
              ),
              Expanded(child: pageBody),
            ],
          );

    if (wide) {
      final extended = MediaQuery.sizeOf(context).width >= 1120;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              extended: extended,
              minWidth: 76,
              minExtendedWidth: 214,
              groupAlignment: -.86,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 22),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/branding/japanese_study_logo.png',
                    width: 42,
                    height: 42,
                  ),
                ),
              ),
              destinations: pages,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _DesktopTopBar(
                    app: app,
                    title: const [
                      'Beranda',
                      'Learning',
                      'Donasi',
                      'Practice',
                      'Library',
                    ][_index],
                    onProfile: _openProfile,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AdmobBannerSlot(hidden: false),
      );
    }

    return Scaffold(
      body: body,
      appBar: null,
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        AdmobBannerSlot(hidden: false),
        NavigationBar(selectedIndex: _index, onDestinationSelected: _select, destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Learning'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined, size: 30), selectedIcon: Icon(Icons.volunteer_activism_rounded, size: 30), label: 'Donasi'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz_rounded), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books_rounded), label: 'Library'),
        ]),
      ]),
    );
  }
}
