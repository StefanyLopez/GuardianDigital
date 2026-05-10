import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../widgets/intervention_banner.dart';
import '../theme/theme_extension.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  final String? profileId;
  const MainShell({super.key, required this.child, this.profileId});

  int _locationToIndex(String location) {
    if (location.contains('/chat'))         return 1;
    if (location.contains('/achievements')) return 2;
    if (location.contains('/stats'))        return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    final pid = profileId ?? '';
    if (pid.isEmpty) return;
    switch (index) {
      case 0: context.go(AppRoutes.kidHome(pid)); break;
      case 1: context.go(AppRoutes.chat(pid));    break;
      case 2: context.go(AppRoutes.achievements(pid)); break;
      case 3: context.go(AppRoutes.stats(pid));   break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final c = context.gd;

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          child,
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0, right: 0,
            child: const InterventionBanner(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.bottomNavBackground,
          border: Border(
            top: BorderSide(color: c.border, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => _onTap(context, i),
          backgroundColor: c.bottomNavBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Luma',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events_rounded),
              label: 'Logros',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Mi semana',
            ),
          ],
        ),
      ),
    );
  }
}
