import 'package:flutter/material.dart';

class Responsive {
  // Common Screen sizes
  static const double mobileSmall = 320;
  static const double mobileMedium = 375;
  static const double mobileLarge = 414;
  static const double tablet = 600;

  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMedium;

  static bool isMediumMobile(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMedium &&
      MediaQuery.of(context).size.width < mobileLarge;

  static bool isLargeMobile(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileLarge;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  // Adaptive value builder
  static double value(BuildContext context, {
    required double small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Responsive.tablet && tablet != null) return tablet;
    if (width >= Responsive.mobileLarge && large != null) return large;
    if (width >= Responsive.mobileMedium && medium != null) return medium;
    return small;
  }
}

// Extension for easier usage
extension ResponsiveExt on BuildContext {
  bool get isSmallMobile => Responsive.isSmallMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  
  // Adaptive padding helper
  EdgeInsets get adaptivePadding {
    if (isSmallMobile) return const EdgeInsets.all(12);
    if (isTablet) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16); // Default standard
  }

  // Adaptive Font Size Helper
  double adaptiveSp(double size) {
    // scale text based on width, but clamp to avoid too small/large
    final width = MediaQuery.of(this).size.width;
    // Standard width 375.0 (iPhone 11 Pro / X)
    var scaleFactor = width / 375.0;
    // Limit scale factor for tablets so text doesn't look cartoonish
    if (scaleFactor > 1.2) scaleFactor = 1.2; 
    if (scaleFactor < 0.9) scaleFactor = 0.9;
    
    return size * scaleFactor;
  }
}
