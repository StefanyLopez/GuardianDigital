import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../router/app_router.dart';
import '../widgets/intervention_banner.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  final String? profileId;
  const MainShell({super.key, required this.child, this.profileId});

  int _locationToIndex(String location) {
    if (location.contains('/chat')) return 1;
    if (location.contains('/achievements')) return 2;
    if (location.contains('/stats')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    final pid = profileId ?? '';
    switch (index) {
      case 0: context.go(AppRoutes.kidHome(pid)); break;
      case 1: context.go(AppRoutes.chat(pid)); break;
      case 2: context.go(AppRoutes.achievements(pid)); break;
      case 3: context.go(AppRoutes.stats(pid)); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Banner de intervención flotante sobre todo el contenido
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: const InterventionBanner(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GDColors.surface,
          border: Border(
            top: BorderSide(
              color: GDColors.primary.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => _onTap(context, i),
          backgroundColor: GDColors.surface,
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
