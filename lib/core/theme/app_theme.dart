import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'tokens.dart';

/// Evernote-inspired theme: crisp white (or charcoal) canvas, a dark
/// navigation sidebar, one signature green accent, Inter typography,
/// hairline borders instead of shadows and small, consistent radii.
abstract final class AppTheme {
  static const fontFamily = 'Inter';

  static ThemeData get light => _build(_lightScheme, AppColors.light);
  static ThemeData get dark => _build(_darkScheme, AppColors.dark);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF00A82D),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDDF3E2),
    onPrimaryContainer: Color(0xFF0B4F1E),
    secondary: Color(0xFF525252),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEFEFEC),
    onSecondaryContainer: Color(0xFF333333),
    tertiary: Color(0xFF2F6FDB),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE3ECFB),
    onTertiaryContainer: Color(0xFF173A73),
    error: Color(0xFFD64545),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFBE5E5),
    onErrorContainer: Color(0xFF7A1F1F),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF262626),
    onSurfaceVariant: Color(0xFF737373),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F7F5),
    surfaceContainer: Color(0xFFF2F2EF),
    surfaceContainerHigh: Color(0xFFEBEBE8),
    surfaceContainerHighest: Color(0xFFE3E3E0),
    outline: Color(0xFFA3A3A3),
    outlineVariant: Color(0xFFE6E6E3),
    inverseSurface: Color(0xFF262626),
    onInverseSurface: Color(0xFFF2F2F2),
    inversePrimary: Color(0xFF2DBE60),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF2DBE60),
    onPrimary: Color(0xFF06210F),
    primaryContainer: Color(0xFF1E3326),
    onPrimaryContainer: Color(0xFFA6E8BC),
    secondary: Color(0xFFB3B3B3),
    onSecondary: Color(0xFF1E1E1E),
    secondaryContainer: Color(0xFF2E2E2E),
    onSecondaryContainer: Color(0xFFE0E0E0),
    tertiary: Color(0xFF7AA7F0),
    onTertiary: Color(0xFF0E2550),
    tertiaryContainer: Color(0xFF1C2B45),
    onTertiaryContainer: Color(0xFFCADBF8),
    error: Color(0xFFE5645F),
    onError: Color(0xFF2B0807),
    errorContainer: Color(0xFF4A1E1C),
    onErrorContainer: Color(0xFFF8C9C6),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE8E8E8),
    onSurfaceVariant: Color(0xFFA3A3A3),
    surfaceContainerLowest: Color(0xFF242424),
    surfaceContainerLow: Color(0xFF1A1A1A),
    surfaceContainer: Color(0xFF2A2A2A),
    surfaceContainerHigh: Color(0xFF313131),
    surfaceContainerHighest: Color(0xFF3A3A3A),
    outline: Color(0xFF6B6B6B),
    outlineVariant: Color(0xFF333333),
    inverseSurface: Color(0xFFE8E8E8),
    onInverseSurface: Color(0xFF1E1E1E),
    inversePrimary: Color(0xFF00A82D),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );

  static TextTheme _textTheme(Color ink) {
    TextStyle s(double size, FontWeight w, {double h = 1.3, double ls = 0}) =>
        TextStyle(fontFamily: fontFamily, fontSize: size, fontWeight: w, height: h, letterSpacing: ls, color: ink);
    return TextTheme(
      displaySmall: s(32, FontWeight.w700, h: 1.15, ls: -0.9),
      headlineLarge: s(28, FontWeight.w700, h: 1.2, ls: -0.7),
      headlineMedium: s(24, FontWeight.w700, h: 1.25, ls: -0.5),
      headlineSmall: s(20, FontWeight.w600, h: 1.3, ls: -0.3),
      titleLarge: s(18, FontWeight.w600, h: 1.35, ls: -0.2),
      titleMedium: s(15, FontWeight.w600, h: 1.4, ls: -0.1),
      titleSmall: s(13, FontWeight.w600, h: 1.4),
      bodyLarge: s(15, FontWeight.w400, h: 1.65),
      bodyMedium: s(14, FontWeight.w400, h: 1.5),
      bodySmall: s(12.5, FontWeight.w400, h: 1.45),
      labelLarge: s(13.5, FontWeight.w500, h: 1.3),
      labelMedium: s(12.5, FontWeight.w500, h: 1.3),
      labelSmall: s(11, FontWeight.w500, h: 1.3, ls: 0.2),
    );
  }

  static ThemeData _build(ColorScheme scheme, AppColors colors) {
    final text = _textTheme(scheme.onSurface);
    final isLight = scheme.brightness == Brightness.light;

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: Radii.mdAll,
      borderSide: BorderSide(color: c, width: w),
    );

    final roundedMd = RoundedRectangleBorder(borderRadius: Radii.mdAll);
    const buttonPadding = EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md - 2);
    final buttonText = text.labelLarge!.copyWith(fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      extensions: [colors],
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      hoverColor: scheme.onSurface.withValues(alpha: 0.04),
      focusColor: scheme.primary.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
        toolbarHeight: 56,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.md),
        hintStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(scheme.primary, 1.5),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium!.copyWith(color: scheme.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        showCheckmark: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: roundedMd,
          padding: buttonPadding,
          minimumSize: const Size(0, 40),
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: roundedMd,
          padding: buttonPadding,
          minimumSize: const Size(0, 40),
          textStyle: buttonText,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: roundedMd,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: roundedMd, foregroundColor: scheme.onSurfaceVariant),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          side: BorderSide(color: scheme.outlineVariant),
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          textStyle: text.labelMedium,
          visualDensity: VisualDensity.compact,
          shape: roundedMd,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall!.copyWith(
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 4,
        highlightElevation: 2,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: buttonText,
        shape: RoundedRectangleBorder(borderRadius: Radii.lgAll),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? scheme.surface : scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: isLight ? 0.18 : 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: Radii.mdAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: text.bodyMedium,
        labelTextStyle: WidgetStatePropertyAll(text.bodyMedium),
        menuPadding: const EdgeInsets.symmetric(vertical: Space.xs),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: Radii.mdAll))),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        textStyle: text.labelSmall!.copyWith(color: scheme.onInverseSurface),
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: Radii.smAll),
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs + 1),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? scheme.surface : scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: Radii.lgAll),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? scheme.surface : scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg + 4))),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: isLight ? scheme.surface : scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: Radii.lgAll),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(Radii.pill),
        thumbColor: WidgetStatePropertyAll(scheme.onSurface.withValues(alpha: 0.18)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
        titleTextStyle: text.bodyMedium,
        iconColor: scheme.onSurfaceVariant,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {for (final p in TargetPlatform.values) p: const FadeForwardsPageTransitionsBuilder()},
      ),
    );
  }
}
