import 'package:flutter/material.dart';
import 'package:capstone_app/services/auth_service.dart';
import 'package:capstone_app/utils/constants.dart';
import 'package:capstone_app/utils/colors.dart';
import '../../login_screen.dart';

/// A screen that displays the user's profile and allows them to sign out.
class ProfileScreen extends StatelessWidget {
  /// Creates a [ProfileScreen].
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.profile,
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.gradientEnd),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppConstants.profileScreenPlaceholder,
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.logout, color: AppColors.white),
                label: Text(
                  AppConstants.signOut,
                  style: TextStyle(color: AppColors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  await AuthService.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
