import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'history_screen.dart';
import 'log_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    if (!app.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kSteps)),
      );
    }

    final Widget page;
    switch (app.tabIndex) {
      case 0:
        page = const DashboardScreen();
      case 1:
        // The key makes the form rebuild from scratch when you switch between
        // adding a new entry and editing an existing one.
        page = LogScreen(
          key: ValueKey(app.editing?.id ?? 'new'),
          entry: app.editing,
        );
      case 2:
        page = const HistoryScreen();
      default:
        page = const GoalsScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: page,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: app.tabIndex,
        onDestinationSelected: app.goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted),
            selectedIcon: Icon(Icons.format_list_bulleted_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Goals',
          ),
        ],
      ),
    );
  }
}
