import 'package:flutter/material.dart';

class EcoColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color backgroundGreen = Color(0xFFF1F8E9);
  /// Soft wash behind main shell content
  static const Color shellWashTop = Color(0xFFE8F5E9);
  static const Color shellWashMid = Color(0xFFF5FBF4);
  static const Color leafTeal = Color(0xFF00897B);
}

class EcoGradients {
  static const LinearGradient appBar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF14532D),
      Color(0xFF2E7D32),
      Color(0xFF43A047),
      Color(0xFF66BB6A),
    ],
    stops: [0.0, 0.35, 0.72, 1.0],
  );

  static const LinearGradient shellBody = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      EcoColors.shellWashTop,
      EcoColors.shellWashMid,
      Colors.white,
    ],
  );

  static const LinearGradient driverShellBody = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE0F2F1),
      Color(0xFFF5FAF9),
      Colors.white,
    ],
  );

  static const LinearGradient adminShellBody = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE8EAF6),
      Color(0xFFF7F8FC),
      Colors.white,
    ],
  );
}

class EcoTypography {
  EcoTypography._();

  /// Bold, slightly playful screen titles (used in [EcoAppBar]).
  static TextStyle screenTitle(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.titleLarge ??
        const TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
    return base.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      height: 1.05,
      shadows: const [
        Shadow(
          color: Color(0x59000000),
          offset: Offset(0, 1.5),
          blurRadius: 4,
        ),
      ],
    );
  }
}

class EcoThemeData {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: EcoColors.primaryGreen,
          primary: EcoColors.primaryGreen,
          secondary: EcoColors.lightGreen,
          surface: Colors.white,
          tertiary: EcoColors.leafTeal,
        ),
        scaffoldBackgroundColor: EcoColors.shellWashMid,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Colors.white,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 12,
          height: 72,
          indicatorColor: EcoColors.accentGreen.withValues(alpha: 0.45),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.2,
              );
            }
            return const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            );
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            backgroundColor: EcoColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: EcoColors.primaryGreen, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: EcoColors.primaryGreen.withValues(alpha: 0.18),
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}
