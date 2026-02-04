import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../widgets/responsive_layout.dart';
import 'playlist_screen.dart';
import 'player_screen.dart';
import 'glossary_screen.dart';
import 'practice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PlaylistScreen(onNavigateToPlayer: _navigateToPlayer),
      const PlayerScreen(),
      const GlossaryScreen(),
      const PracticeScreen(),
    ];
  }

  void _navigateToPlayer() {
    setState(() {
      _currentIndex = 1;
    });
  }

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.queue_music_outlined),
      selectedIcon: Icon(Icons.queue_music),
      label: 'Playlist',
    ),
    NavigationDestination(
      icon: Icon(Icons.play_circle_outline),
      selectedIcon: Icon(Icons.play_circle),
      label: 'Reproductor',
    ),
    NavigationDestination(
      icon: Icon(Icons.book_outlined),
      selectedIcon: Icon(Icons.book),
      label: 'Glosario',
    ),
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: 'Repaso',
    ),
  ];

  List<NavigationRailDestination> get _railDestinations => [
        NavigationRailDestination(
          icon: _destinations[0].icon,
          selectedIcon: _destinations[0].selectedIcon,
          label: Text(_destinations[0].label),
        ),
        NavigationRailDestination(
          icon: _destinations[1].icon,
          selectedIcon: _destinations[1].selectedIcon,
          label: Text(_destinations[1].label),
        ),
        NavigationRailDestination(
          icon: _destinations[2].icon,
          selectedIcon: _destinations[2].selectedIcon,
          label: Text(_destinations[2].label),
        ),
        NavigationRailDestination(
          icon: _destinations[3].icon,
          selectedIcon: _destinations[3].selectedIcon,
          label: Text(_destinations[3].label),
        ),
      ];

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    if (isDesktop || isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: isDesktop
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.selected,
              extended: false,
              minWidth: 72,
              backgroundColor: AppTheme.surfaceColor,
              indicatorColor: AppTheme.primaryColor.withAlpha(50),
              selectedIconTheme: const IconThemeData(
                color: AppTheme.primaryColor,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppTheme.textSecondary,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppTheme.textSecondary,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              destinations: _railDestinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppTheme.surfaceColor,
        indicatorColor: AppTheme.primaryColor.withAlpha(50),
        destinations: _destinations,
      ),
    );
  }

  void navigateToPlayer() {
    _navigateToPlayer();
  }

  void navigateToGlossary() {
    setState(() {
      _currentIndex = 2;
    });
  }
}
