import 'package:flutter/material.dart';
import 'package:babyprediction/screens/onboarding_page_one.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PageView(
      children: <Widget>[
        OnboardingPage(),

        // Add more onboarding pages here
      ],
      onPageChanged: (index) {
        if (index == 1) {
          // Adjust according to the number of pages
          // Save preference
          SharedPreferences.getInstance().then((prefs) {
            prefs.setBool('isFirstLaunch', false);
          });
        }
      },
    );
  }
}
