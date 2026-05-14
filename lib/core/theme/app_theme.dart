import 'package:flutter/material.dart';

class EcoColors {
  // ── Core greens ──────────────────────────────
  static const Color primaryGreen   = Color(0xFF1B5E20); // deep forest
  static const Color midGreen       = Color(0xFF2E7D32);
  static const Color lightGreen     = Color(0xFF43A047);
  static const Color freshGreen     = Color(0xFF66BB6A);
  static const Color mintGreen      = Color(0xFFA5D6A7);
  static const Color paleGreen      = Color(0xFFE8F5E9);
  static const Color darkGreen      = Color(0xFF0A3D0A);

  // ── Gold accent ───────────────────────────────
  static const Color gold           = Color(0xFFD4A017);
  static const Color goldLight      = Color(0xFFF5C842);
  static const Color goldPale       = Color(0xFFFFF8E1);

  // ── Neutrals ──────────────────────────────────
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color backgroundGreen = Color(0xFFF1F8F1);
  static const Color cardSurface    = Color(0xFFFAFDFA);
  static const Color textDark       = Color(0xFF1A2E1A);
  static const Color textMid        = Color(0xFF3D5C3D);
  static const Color textLight      = Color(0xFF6B8F6B);
  static const Color divider        = Color(0xFFDCEDDC);

  // ── Shell washes ──────────────────────────────
  static const Color shellWashTop   = Color(0xFFE8F5E9);
  static const Color shellWashMid   = Color(0xFFF4FAF4);
  static const Color accentGreen    = Color(0xFF81C784);
  static const Color leafTeal       = Color(0xFF00897B);
}

class EcoGradients {
  // Rich forest-to-canopy app bar
  static const LinearGradient appBar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A3D0A),
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
      Color(0xFF388E3C),
    ],
    stops: [0.0, 0.3, 0.65, 1.0],
  );

  // Hero banner gradient
  static const LinearGradient heroBanner = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A3D0A),
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
      Color(0xFF43A047),
    ],
    stops: [0.0, 0.35, 0.70, 1.0],
  );

  // Gold shimmer accent
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A017), Color(0xFFF5C842), Color(0xFFD4A017)],
  );

  // Shell body gradients
  static const LinearGradient shellBody = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F5E9), Color(0xFFF4FAF4), Color(0xFFFFFFFF)],
  );

  static const LinearGradient driverShellBody = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0F2F1), Color(0xFFF5FAF9), Colors.white],
  );

  static const LinearGradient adminShellBody = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8EAF6), Color(0xFFF7F8FC), Colors.white],
  );

  // Card glass shimmer
  static const LinearGradient glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x20FFFFFF), Color(0x08FFFFFF)],
  );
}

class EcoTypography {
  EcoTypography._();

  static TextStyle screenTitle(BuildContext context) {
    return const TextStyle(
      color: Colors.white,
      fontSize: 21,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      height: 1.05,
      shadows: [
        Shadow(color: Color(0x60000000), offset: Offset(0, 2), blurRadius: 8),
      ],
    );
  }
}

class EcoThemeData {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: EcoColors.midGreen,
          primary: EcoColors.midGreen,
          secondary: EcoColors.freshGreen,
          tertiary: EcoColors.gold,
          surface: EcoColors.surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: EcoColors.shellWashMid,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 16,
          height: 74,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: const Color(0x30000000),
          indicatorColor: EcoColors.paleGreen,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: EcoColors.midGreen, size: 24);
            }
            return IconThemeData(color: Colors.grey.shade500, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: EcoColors.midGreen,
                letterSpacing: 0.3,
              );
            }
            return TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Colors.grey.shade500,
            );
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            shadowColor: EcoColors.midGreen.withValues(alpha: 0.4),
            backgroundColor: EcoColors.midGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: EcoColors.midGreen, width: 1.5),
            foregroundColor: EcoColors.midGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: EcoColors.midGreen,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: EcoColors.cardSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: EcoColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: EcoColors.divider, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: EcoColors.midGreen, width: 2),
          ),
          labelStyle: const TextStyle(color: EcoColors.textLight),
          hintStyle: TextStyle(color: EcoColors.textLight.withValues(alpha: 0.7)),
          prefixIconColor: EcoColors.midGreen,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: EcoColors.cardSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: EcoColors.divider, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: EcoColors.paleGreen,
          selectedColor: EcoColors.midGreen,
          labelStyle: const TextStyle(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
        dividerTheme: const DividerThemeData(
          color: EcoColors.divider,
          thickness: 1,
          space: 1,
        ),
      );
}