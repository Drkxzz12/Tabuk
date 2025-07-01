// ===========================================
// lib/screens/bussiness_module/business_main_screen.dart
// ===========================================
// Main screen for business owner users with bottom navigation.

import 'package:flutter/material.dart';
import 'package:capstone_app/utils/colors.dart';

/// Main screen for business owner users with bottom navigation.
class MainBusinessOwnerScreen extends StatefulWidget {
  const MainBusinessOwnerScreen({super.key});

  @override
  State<MainBusinessOwnerScreen> createState() =>
      _MainBusinessOwnerScreenState();
}

class _MainBusinessOwnerScreenState extends State<MainBusinessOwnerScreen> {
  int _selectedIndex = 0;

  // List of screens for navigation - matching the bottom nav items
  final List<Widget> _screens = [
    const _PlaceholderScreen(title: 'My Business'),
    const _PlaceholderScreen(title: 'Listings'),
    const _PlaceholderScreen(title: 'Analytics'),
    const _PlaceholderScreen(title: 'Reviews'),
    const _PlaceholderScreen(title: 'Profile'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: 'My Business',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Listings'),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.reviews), label: 'Reviews'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: AppColors.primaryOrange,
      onTap: _onItemTapped,
    );
  }
}

/// Placeholder widget for business owner screens.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Add/fix doc comments for all classes and key methods, centralize constants, use const where possible, and ensure code quality and maintainability throughout the file.
