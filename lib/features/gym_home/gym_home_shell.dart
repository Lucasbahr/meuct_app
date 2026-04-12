import 'package:flutter/material.dart';

import 'widgets/gym_dashboard_tab.dart';
import 'widgets/gym_more_tab.dart';
import 'widgets/gym_students_tab.dart';

class GymHomeShell extends StatefulWidget {
  const GymHomeShell({
    super.key,
    required this.isAdmin,
    required this.isStaff,
    required this.isSystemAdmin,
    required this.onMoreNavigate,
    this.student,
    this.academyName,
  });

  final bool isAdmin;
  final bool isStaff;
  final bool isSystemAdmin;
  final Future<void> Function(String route) onMoreNavigate;
  final Map<String, dynamic>? student;
  final String? academyName;

  @override
  State<GymHomeShell> createState() => _GymHomeShellState();
}

class _GymHomeShellState extends State<GymHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _index,
        children: [
          GymDashboardTab(
            isStaff: widget.isStaff,
            isAdmin: widget.isAdmin,
            student: widget.student,
            academyName: widget.academyName,
          ),
          GymStudentsTab(
            canLoadStudents: widget.isStaff,
            canCheckInForOthers: widget.isAdmin,
          ),
          GymMoreTab(
            isStaff: widget.isStaff,
            isAdmin: widget.isAdmin,
            isSystemAdmin: widget.isSystemAdmin,
            onGoHome: () => setState(() => _index = 0),
            onNavigateRoute: widget.onMoreNavigate,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        indicatorColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Alunos',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.apps_rounded),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}
