import 'package:flutter/material.dart';
import 'preferences/tourist_registration_flow.dart';
import 'main_tourist_screen.dart';

/// A widget that decides whether to show the registration flow or the main tourist screen
/// based on the user's registration status.
class RegistrationGate extends StatelessWidget {
  /// Creates an instance of [RegistrationGate].
  const RegistrationGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FutureBuilder<bool>(
              future: isTouristUserRegistered(),
              builder: (context, snapshot) {
                // While the registration status is being determined, show a loading indicator.
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // If the user is registered, show the main tourist screen.
                if (snapshot.data == true) {
                  return const MainTouristScreen();
                } 
                // If the user is not registered, show the registration flow.
                else {
                  return const TouristRegistrationFlow();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
