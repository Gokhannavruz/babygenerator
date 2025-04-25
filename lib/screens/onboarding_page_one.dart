import 'dart:ui'; // `BackdropFilter` için gerekli
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:babyprediction/src/components/native_dialog.dart';
import 'package:babyprediction/src/model/singletons_data.dart';
import 'package:babyprediction/src/model/weather_data.dart';
import 'package:babyprediction/src/rvncat_constant.dart';
import 'package:babyprediction/src/views/firstlaunch_paywall.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:babyprediction/models/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animation
                        Expanded(
                          flex: 14,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Image.asset(
                              'assets/images/4.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Title - Daha yumuşak font
                        Text(
                          'Baby Prediction',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        // Daha sıcak bir açıklama
                        Text(
                          "Create magical moments with AI",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Daha sevimli kartlar
                        Row(
                          children: [
                            Expanded(
                              child: _buildSimpleFeatureCard(
                                icon: Icons.face_retouching_natural,
                                title: 'Age Prediction',
                                description: 'See your future self',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSimpleFeatureCard(
                                icon: Icons.family_restroom,
                                title: 'Baby Prediction',
                                description: 'Mix with your partner',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Daha sıcak özellikler
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              _buildSimpleFeatureItem(
                                icon: Icons.auto_awesome,
                                text: 'Advanced AI Technology',
                              ),
                              _buildSimpleFeatureItem(
                                icon: Icons.flash_on,
                                text: 'Instant Results',
                              ),
                              _buildSimpleFeatureItem(
                                icon: Icons.favorite,
                                text: 'High Quality Images',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => _isLoading = true);

                          try {
                            final offerings = await Purchases.getOfferings();

                            setState(() => _isLoading = false);

                            if (offerings.current != null) {
                              // Save first launch preference
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('isFirstLaunch', false);

                              // Navigate to paywall
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Paywall2(
                                    offering: offerings.current!,
                                  ),
                                ),
                              );
                            } else {
                              // Show error dialog if no offerings
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    ShowDialogToDismiss(
                                  title: "Error",
                                  content: "No offerings available",
                                  buttonText: 'OK',
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => _isLoading = false);

                            // Show error dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  ShowDialogToDismiss(
                                title: "Error",
                                content: e.toString(),
                                buttonText: 'OK',
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          minimumSize: Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              )
                            : Text(
                                'Start the Magic',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          // Save first launch preference when skipping
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isFirstLaunch', false);

                          // Navigate to paywall
                          final offerings = await Purchases.getOfferings();
                          if (offerings.current != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Paywall2(
                                  offering: offerings.current!,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Skip Introduction',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFeatureItem(
      {required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.primary, // Default to primary color
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          // ... existing container content ...
        ),
      ),
    );
  }
}

class _UserReview extends StatelessWidget {
  final String review;
  final String reviewer;
  final String imageAsset;

  const _UserReview(
      {required this.review, required this.reviewer, required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(imageAsset),
            radius: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review,
                  style: TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "- $reviewer",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(Icons.star, color: Colors.yellow, size: 15);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurredBackground extends StatelessWidget {
  final Widget child;

  const _BlurredBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: child,
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}
