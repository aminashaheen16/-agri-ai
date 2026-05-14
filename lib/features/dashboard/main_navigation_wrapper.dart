import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_screen.dart';
import '../ai_chat/chat_screen.dart';
import '../store/store_screen.dart';
import '../plant_health/plant_health_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationWrapper extends ConsumerStatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  ConsumerState<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends ConsumerState<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ChatScreen(),
    const StoreScreen(),
    const PlantHealthScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}