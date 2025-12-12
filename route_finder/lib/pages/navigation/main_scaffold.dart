import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:route_finder/logic/providers.dart';
import 'package:route_finder/pages/dashboard/dashboard_page.dart';
import 'package:route_finder/pages/explorer/explorer_page.dart';
import 'package:route_finder/pages/navigation/bottom_navbar.dart';
import 'package:route_finder/pages/profile/profile_page.dart';
import 'package:route_finder/pages/routes/my_routes_page.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final List<Widget> _pages = [
    const DashboardPage(),
    const ExplorerPage(),
    const MyRoutesPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      ref.invalidate(communityRoutesProvider);
    }
    ref.read(navigationIndexProvider.notifier).setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
