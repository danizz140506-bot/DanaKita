import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Centralized design tokens for DanaKita
// ---------------------------------------------------------------------------

/// Color palette.
class AppColors {
  AppColors._();

  // Primary green palette
  static const Color accent = Color(0xFF2E7D32);
  static const Color primary = accent;
  static const Color primaryLight = accent;
  static const Color light = Color(0xFFE8F5E9);
  static const Color soft = Color(0xFFA5D6A7);
  static const Color darkGreen = Color(0xFF1B5E20);

  // Tag colors
  static const Color tagGreenBg = Color(0xFFE8F5E9);
  static const Color tagGreenText = Color(0xFF1B5E20);
  static const Color tagOrangeBg = Color(0xFFFFF3E0);
  static const Color tagOrangeText = Color(0xFFE65100);
  static const Color tagBlueBg = Color(0xFFE3F2FD);
  static const Color tagBlueText = Color(0xFF1565C0);

  // Neutrals
  static const Color white = Colors.white;
  static const Color surface = Color(0xFFF5F5F5);
  static const Color scaffoldBg = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xDD000000); // black87
  static const Color textPrimary = textDark;
  static const Color textBody = Color(0xFF757575); // grey.shade600
  static const Color textSecondary = textBody;
  static const Color textMuted = Color(0xFF9E9E9E); // grey.shade500
  static const Color textTertiary = textMuted;
  static const Color textHint = Color(0xFFBDBDBD); // grey.shade400
  static const Color border = Color(0xFFE0E0E0); // grey.shade300
  static const Color divider = border;
  static const Color placeholder = Color(0xFFBDBDBD); // grey.shade400
  static const Color iconMuted = Color(0xFFBDBDBD); // grey.shade400
  static const Color shimmer = Color(0xFFE0E0E0);

  // Semantic colors
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFFF57C00);
  static const Color success = Color(0xFF2E7D32);

  // Gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black54],
  );

  // Verified badge — on-theme green instead of blue
  static const Color verifiedBadge = Color(0xFF2E7D32);

}

/// Standardized border radii.
class AppRadius {
  AppRadius._();

  static const double small = 8.0;
  static const double sm = small;
  static const double medium = 12.0;
  static const double md = medium;
  static const double large = 16.0;
  static const double lg = large;
  static const double xl = 24.0;
  static const double xxl = 28.0;
}

/// Standardized box shadows.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x332E7D32),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// Standardized card elevation.
class AppElevation {
  AppElevation._();

  static const double card = 1.0;
}

/// Standardized sizes for progress bars, thumbnails, icon containers.
class AppSizes {
  AppSizes._();

  static const double progressBarHeight = 6.0;
  static const double progressBarRadius = 3.0;
  static const double thumbnailSize = 80.0;
  static const double iconContainerSize = 44.0;
  static const double iconContainerRadius = 10.0;
}

/// Animation durations.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splash = Duration(milliseconds: 2500);
}

/// Build the complete Material 3 ThemeData for the app.
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.light,
    onPrimaryContainer: AppColors.darkGreen,
    secondary: AppColors.soft,
    onSecondary: AppColors.darkGreen,
    secondaryContainer: AppColors.light,
    onSecondaryContainer: AppColors.darkGreen,
    surface: AppColors.white,
    onSurface: AppColors.textPrimary,
    error: Color(0xFFB00020),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Bottom navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Color(0xFF9E9E9E),
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      elevation: 8,
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: AppElevation.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),

    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    ),

    // Text buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
      ),
    ),

    // Chips
    chipTheme: ChipThemeData(
      selectedColor: AppColors.light,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.divider),
      labelStyle: const TextStyle(fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Progress indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearMinHeight: 6.0,
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
    ),

    // Dividers
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),

    // Checkboxes
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return null;
      }),
    ),

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
