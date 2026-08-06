import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/settings/settings_service.dart';
import 'core/theme/app_colors.dart';
import 'features/splash/welcome_screen.dart';

/// Fallback font kalau 'Avenir' tidak tersedia di device (Avenir hanya
/// bawaan iOS/macOS). Di Android jatuh ke Roboto, di Windows/web ke
/// Segoe UI/Helvetica/Arial — mengikuti gaya font-stack CSS (tiket.com),
/// disesuaikan ke nama font asli yang dikenali Flutter (Flutter tidak
/// mendukung keyword generik CSS seperti -apple-system/sans-serif).
const List<String> kFontFallback = [
  'Segoe UI',
  'Roboto',
  'Helvetica Neue',
  'Helvetica',
  'Arial',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Setup service locator (get_it) — fondasi DI, dipakai bertahap oleh
  // fitur yang sudah dimigrasi (lihat lib/core/di/injection.dart).
  await initDependencies();
  // Muat preferensi (tema/bahasa/mata uang) sebelum UI tampil agar tidak
  // "berkedip" saat start. Inisialisasi Clerk tetap di background.
  await SettingsService.instance.init();
  // Langsung tampilkan UI — JANGAN blokir menunggu Clerk. WelcomeScreen tampil
  // seketika (animasi pesawat) sambil inisialisasi Clerk di background.
  runApp(const KlikTripApp());
}

class KlikTripApp extends StatelessWidget {
  const KlikTripApp({super.key});

  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.azureSky,
    primary: AppColors.azureSky,
    surface: AppColors.background,
    error: AppColors.error,
  );

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp otomatis saat pengguna mengganti tema di Pengaturan.
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final theme = SettingsService.instance.theme;
        return MaterialApp(
          title: 'GMM Global Explore - Travel & Umroh Terpercaya',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: theme.themeMode,
          scrollBehavior: const _AppScrollBehavior(),
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: child!,
          ),
          home: const WelcomeScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      fontFamily: 'Avenir',
      fontFamilyFallback: kFontFallback,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Transisi halaman ringan & smooth (bukan zoom berat).
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: const FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: const FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: const FadeForwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.azureSky),
        titleTextStyle: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.azureSky,
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.azureSky,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azureSky,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.azureSky,
        linearTrackColor: Color(0xFFE5E2E1),
        circularTrackColor: Color(0xFFE5E2E1),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E2E1),
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        floatingLabelStyle: const TextStyle(color: AppColors.azureSky),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.azureSky, width: 1.5),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Tema gelap — varian dari tema terang, konsisten dengan brand GMM.
  ThemeData _buildDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.azureSky,
      primary: AppColors.azureSky,
      brightness: Brightness.dark,
      surface: const Color(0xFF121417),
      onSurface: Colors.white,
      surfaceContainerLow: const Color(0xFF1B1E22),
      surfaceContainerHigh: const Color(0xFF24272B),
      onSurfaceVariant: const Color(0xFF9FB3C8),
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Avenir',
      fontFamilyFallback: kFontFallback,
      scaffoldBackgroundColor: const Color(0xFF121417),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: const FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: const FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: const FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121417),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.azureSky),
        titleTextStyle: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1B1E22),
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1B1E22),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFF1B1E22),
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF24272B),
        selectedColor: AppColors.azureSky,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.azureSky,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azureSky,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.azureSky,
        linearTrackColor: Color(0xFF2A2D31),
        circularTrackColor: Color(0xFF2A2D31),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2D31),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B1E22),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: const TextStyle(color: AppColors.azureSky),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A3E44)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.azureSky, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Scroll yang terasa responsif (bouncing di semua platform) + dukungan
/// drag mouse agar nyaman dipakai di tablet/desktop.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
