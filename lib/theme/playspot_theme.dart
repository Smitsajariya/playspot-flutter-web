import 'package:flutter/material.dart';

/// PlaySpot design tokens — ported 1:1 from the original HTML's CSS :root variables.
/// Keep these in sync if the web version's palette ever changes.
class PSColors {
  // base
  static const bg = Color(0xFF0E0700);
  static const surface = Color(0xFF1A0C00);
  static const surface2 = Color(0xFF241200);
  static const surface3 = Color(0xFF2E1800);
  static const border = Color(0x1AFFB93C); // rgba(255,185,60,0.10)
  static const borderHi = Color(0x33FFC850); // rgba(255,200,80,0.20)

  // ink (text)
  static const ink = Color(0xFFFFF8F0);
  static const inkDim = Color(0x8CFFF8F0); // 0.55
  static const inkMuted = Color(0x47FFF8F0); // 0.28

  // accents
  static const gold = Color(0xFFF5A623);
  static const goldBright = Color(0xFFFFD060);
  static const amber = Color(0xFFE8820C);
  static const copper = Color(0xFFC4591A);
  static const honey = Color(0xFFFFB830);
  static const volt = Color(0xFFC8FF00);
  static const voltGlow = Color(0x26C8FF00); // 0.15
  static const fire = Color(0xFFFF4D1C);
  static const lilac = Color(0xFFC4A45A);
  static const cyan = Color(0xFFF0C060);

  // desktop wide-screen backdrop
  static const desktopBg = Color(0xFF050300);
}

/// 8px grid spacing system — s1..s8 mirror the CSS --s1..--s8 vars.
class PSSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
}

/// Corner radius system — matches --r-sm..--r-full.
class PSRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const full = 999.0;
}

/// Shadows & glows — approximations of the CSS box-shadow tokens.
class PSShadows {
  static List<BoxShadow> sm = [
    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> md = [
    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> lg = [
    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 40, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> glowGold = [
    BoxShadow(color: const Color(0x59F5A623), blurRadius: 32), // 0.35
  ];
  static List<BoxShadow> glowGoldSm = [
    BoxShadow(color: const Color(0x38F5A623), blurRadius: 16), // 0.22
  ];
}

/// Easing curves — equivalents of the CSS cubic-bezier tokens.
class PSCurves {
  static const spring = Cubic(0.22, 1, 0.36, 1);
  static const easeOut = Cubic(0.16, 1, 0.3, 1);
}

/// Common linear/radial gradients reused across cards & headers.
class PSGradients {
  static const sportCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D2810), Color(0xFF2A1A08), Color(0xFF1F1205)],
    stops: [0.0, 0.5, 1.0],
  );

  static const sportCardSelected = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4D3020), Color(0xFF3A2200), Color(0xFF2F1800)],
    stops: [0.0, 0.5, 1.0],
  );

  static const categoryCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1A10), Color(0xFF1F1208), Color(0xFF150A05)],
  );

  static const goldAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD060), Color(0xFFF5A623), Color(0xFFE8820C)],
  );

  static const storyRing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD060), Color(0xFFF5A623), Color(0xFFE8820C)],
  );

  static const quickAction = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3A2515), Color(0xFF2A1A0A), Color(0xFF1A1005)],
  );

  static const screenSport = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF221000), Color(0xFF180900), Color(0xFF100600)],
    stops: [0.0, 0.5, 1.0],
  );

  static const screenProfileView = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF241200), Color(0xFF170B00), Color(0xFF100600)],
    stops: [0.0, 0.55, 1.0],
  );

  static const screenLeaderboard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A0E00), Color(0xFF0E0600)],
  );

  static const primaryButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5A623), Color(0xFFE8820C), Color(0xFFC4591A)],
  );

  static const secondaryButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3A2818), Color(0xFF2A1A10), Color(0xFF1A1008)],
  );

  static const glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33FFFFFF), Color(0x1AFFFFFF)],
  );

  static const navPillBg = Color(0xEB140A00); // rgba(20,10,0,0.92)
}

/// Text styles — Syne for display/brand, Space Grotesk for body, Space Mono for labels.
/// NOTE: add the fonts via google_fonts package or bundle them under assets/fonts/
/// and register in pubspec.yaml — see pubspec.yaml comments.
class PSText {
  static const _syne = 'Syne';
  static const _grotesk = 'SpaceGrotesk';
  static const _mono = 'SpaceMono';

  static const brand = TextStyle(
    fontFamily: _syne,
    fontWeight: FontWeight.w900,
    fontSize: 26,
    letterSpacing: -1.04, // -0.04em of 26px
    color: PSColors.ink,
  );

  static const screenTitle = TextStyle(
    fontFamily: _grotesk,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    color: PSColors.ink,
  );

  static const body = TextStyle(
    fontFamily: _grotesk,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: PSColors.ink,
  );

  static const bodyDim = TextStyle(
    fontFamily: _grotesk,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: PSColors.inkDim,
  );

  static const label = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 1.1, // ~0.10em
    color: PSColors.gold,
  );

  static const navLabel = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w400,
    fontSize: 9,
    letterSpacing: 0.36,
    color: PSColors.inkMuted,
  );

  static const eyebrow = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    letterSpacing: 0.84,
    color: PSColors.gold,
  );
}

/// The single ThemeData object the whole app is wrapped in.
ThemeData buildPlaySpotTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: PSColors.bg,
    fontFamily: 'SpaceGrotesk',
    colorScheme: const ColorScheme.dark(
      surface: PSColors.surface,
      primary: PSColors.gold,
      secondary: PSColors.goldBright,
      error: PSColors.fire,
    ),
    splashColor: PSColors.gold.withOpacity(0.12),
    highlightColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: PSColors.bg,
      foregroundColor: PSColors.ink,
      iconTheme: IconThemeData(color: PSColors.ink),
      actionsIconTheme: IconThemeData(color: PSColors.ink),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: PSText.body,
      titleLarge: PSText.screenTitle,
    ),
  );
}
