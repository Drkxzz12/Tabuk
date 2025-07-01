// ===========================================
// lib/utils/navigation_helper.dart
// ===========================================
// Helper for routing users to the correct main screen based on their role.

import 'package:flutter/material.dart';
import 'package:capstone_app/screens/tourist_module/main_tourist_screen.dart';
import 'package:capstone_app/screens/admin_module/main_admin_screen.dart';
import 'package:capstone_app/screens/bussiness_module/business_main_screen.dart';
import 'package:capstone_app/screens/tourist_module/preferences/tourist_registration_flow.dart';

/// Navigation helper class to route users based on their role.
class NavigationHelper {
  /// Navigates to the appropriate main screen for the given user role.
  static void navigateBasedOnRole(BuildContext context, String role) {
    Widget targetScreen;
    switch (role.toLowerCase()) {
      case 'administrator':
      case 'admin':
        targetScreen = const MainAdminScreen();
        break;
      case 'business owner':
      case 'businessowner':
        targetScreen = const MainBusinessOwnerScreen();
        break;
      case 'tourist':
        // Show registration flow for new tourist accounts
        targetScreen = const TouristRegistrationFlow();
        break;
      case 'guest':
      default:
        targetScreen = const MainTouristScreen();
        break;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }
}
