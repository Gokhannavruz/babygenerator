import 'package:flutter/material.dart';

class OnboardingModel {
  final String title;
  final String description;
  final String animationPath;
  final Color backgroundColor;
  final List<OnboardingFeature>? features;

  OnboardingModel({
    required this.title,
    required this.description,
    required this.animationPath,
    required this.backgroundColor,
    this.features,
  });
}

class OnboardingFeature {
  final IconData icon;
  final String title;
  final String description;

  OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}
