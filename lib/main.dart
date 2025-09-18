// ignore_for_file: deprecated_member_use

library lilium;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:async'; // ← for Timer
import 'package:flutter/material.dart';

// ---------------- Firebase ----------------
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// -----------------------------------------

// -------------- Admin/Uploads (used in part files) --------------
import 'package:file_picker/file_picker.dart';

// ---------------------------------------------------------------

import 'firebase_options.dart';

// === Parts: app sections + admin + detail ===
part 'pages/home.dart';
part 'pages/about.dart';
part 'pages/apartments.dart';
part 'pages/amenities.dart';

part 'pages/apartment_detail.dart';
part 'pages/admin_panel.dart';

// Logo asset path (update if you use a different file)
const String kLiliumLogoAsset = 'assets/lilium_logo.png';

// Initialize Firebase, then run the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LiliumApp());
}

class LiliumApp extends StatelessWidget {
  const LiliumApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF1E40AF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lilium Towers Islamabad - Live Elevated',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
          displayMedium: TextStyle(fontWeight: FontWeight.w900),
          headlineLarge: TextStyle(fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(fontWeight: FontWeight.w800),
          bodyLarge: TextStyle(height: 1.7),
          bodyMedium: TextStyle(height: 1.7),
        ),
      ),
      // Simple route-per-section
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        late Widget page;
        switch (name) {
          case '/':
            page = const HomePage();
            break;
          case '/about':
            page = const AboutPage();
            break;
          case '/apartments':
            page = const ApartmentsPage();
            break;
          case '/amenities':
            page = const AmenitiesPage();
            break;

          // NEW: detail + admin routes
          case '/apartment':
            // Accepts either ApartmentData or a String id
            page = ApartmentDetailPage.fromArgs(settings.arguments);
            break;
          case '/admin':
            page = const AdminPanelPage();
            break;

          default:
            page = const HomePage();
        }
        return MaterialPageRoute(
          settings: RouteSettings(name: name),
          builder: (_) => LiliumShell(currentRoute: name, child: page),
        );
      },
      initialRoute: '/',
    );
  }
}

// ========================= Responsive Breakpoints =========================
class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
  static bool isCompact(double width) => width < tablet;
}

// =================== Shell: fixed header + footer ===================
class LiliumShell extends StatefulWidget {
  final String currentRoute;
  final Widget child;
  const LiliumShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  @override
  State<LiliumShell> createState() => _LiliumShellState();
}

class _LiliumShellState extends State<LiliumShell> {
  final ScrollController _scroll = ScrollController();
  double _offset = 0;

  void _go(String route) {
    if (widget.currentRoute == route) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() => _offset = _scroll.offset));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _progress {
    if (!_scroll.hasClients) return 0;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return 0;
    return (_scroll.offset / max).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(children: [widget.child, const _Footer()]),
          ),
          _GlassHeader(
            scrolled: _offset > 50,
            scrollProgress: _progress,
            currentRoute: widget.currentRoute,
            onNavigate: _go,
          ),
        ],
      ),
    );
  }
}

// ========================= Colors (constants) =========================
class AppColors {
  static const primaryDark = Color(0xFF0A0F1C);
  static const secondaryDark = Color(0xFF162447);
  static const accentBlue = Color(0xFF1E40AF);
  static const lightBlue = Color(0xFF3B82F6);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
  static const bgLight = Color(0xFFF8FAFC);
}

/* ====================================================================
   Header (fixed) - Fully Responsive
   - Logo image + shimmering wordmark (tablet/desktop)
   - Hidden admin dialog: tap logo 5x in 2s
   - Top scroll progress
   - Mobile dropdown menu (no Admin entry)
==================================================================== */
class _GlassHeader extends StatefulWidget {
  final bool scrolled;
  final double scrollProgress;
  final String currentRoute;
  final void Function(String route) onNavigate;

  const _GlassHeader({
    required this.scrolled,
    required this.scrollProgress,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  State<_GlassHeader> createState() => _GlassHeaderState();
}

class _GlassHeaderState extends State<_GlassHeader>
    with SingleTickerProviderStateMixin {
  final GlobalKey _navAreaKey = GlobalKey();

  // Floating pill state (desktop/tablet)
  double? _inkLeft;
  double? _inkWidth;
  Rect? _activeRect;
  String? _hoverRoute;

  // Shimmer logo animation
  late final AnimationController _logoCtrl;

  // Easter egg state
  int _logoTapCount = 0;
  Timer? _logoTapResetTimer;

  void _handleLogoTap() {
    _logoTapResetTimer?.cancel();
    _logoTapCount++;
    _logoTapResetTimer = Timer(const Duration(seconds: 2), () {
      _logoTapCount = 0;
    });

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _logoTapResetTimer?.cancel();
      showDialog<void>(
        context: context,
        builder: (_) => const _AdminSigninDialog(),
      );
    } else {
      // Normal behavior: go Home on single tap
      widget.onNavigate('/');
    }
  }

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _logoTapResetTimer?.cancel();
    super.dispose();
  }

  void _snapToActive() {
    if (_activeRect == null) {
      setState(() => _inkWidth = 0);
      return;
    }
    final navBox = _navAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (navBox == null) return;
    final navOrigin = navBox.localToGlobal(Offset.zero);
    final left = _activeRect!.left - navOrigin.dx + 8;
    final width = _activeRect!.width - 16;
    setState(() {
      _inkLeft = left;
      _inkWidth = width.clamp(0, 400.0);
      _hoverRoute = null;
    });
  }

  void _onHoverRect(String route, Rect globalRect) {
    final navBox = _navAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (navBox == null) return;
    final navOrigin = navBox.localToGlobal(Offset.zero);
    final left = globalRect.left - navOrigin.dx + 8;
    final width = globalRect.width - 16;
    setState(() {
      _inkLeft = left;
      _inkWidth = width.clamp(0, 400.0);
      _hoverRoute = route;
    });
  }

  void _onActiveRect(String route, Rect globalRect) {
    if (route != widget.currentRoute) return;
    _activeRect = globalRect;
    if (_hoverRoute == null) _snapToActive();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);
    final isCompact = Breakpoints.isCompact(width);

    // Responsive dimensions (logo doubled)
    final logoDim = isMobile ? 56.0 : (isTablet ? 64.0 : 72.0); // ← doubled
    final logoTextSize = isMobile ? 0.0 : (isTablet ? 20.0 : 24.0);
    final logoTextLetter = isMobile ? 0.0 : (isTablet ? 2.0 : 3.0);
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    final verticalPadding = isMobile ? 8.0 : 10.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scroll progress bar (responsive height)
          SizedBox(
            height: isMobile ? 2 : 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: widget.scrollProgress,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.lightBlue, AppColors.accentBlue],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Responsive header
          Material(
            color: Colors.transparent,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.secondaryDark],
                ),
                border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile
                          ? double.infinity
                          : (isTablet ? 1200 : 1440),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: Row(
                        children: [
                          // MOBILE/TABLET: Dropdown Menu
                          if (isCompact)
                            _MobileDropdownMenu(
                              currentRoute: widget.currentRoute,
                              onNavigate: widget.onNavigate,
                              isMobile: isMobile,
                            ),

                          if (isMobile) const SizedBox(width: 12),

                          // Logo + (wordmark on tablet/desktop)
                          Expanded(
                            flex: isCompact ? 1 : 0,
                            child: GestureDetector(
                              onTap:
                                  _handleLogoTap, // ← handles both nav + secret
                              child: Row(
                                mainAxisSize: isCompact
                                    ? MainAxisSize.max
                                    : MainAxisSize.min,
                                mainAxisAlignment: isCompact
                                    ? MainAxisAlignment.center
                                    : MainAxisAlignment.start,
                                children: [
                                  // Logo image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      kLiliumLogoAsset,
                                      width: logoDim,
                                      height: logoDim,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: logoDim,
                                        height: logoDim,
                                        color: Colors.white.withOpacity(0.15),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.domain_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!isCompact) const SizedBox(width: 10),

                                  // Shimmer wordmark (hidden on mobile)
                                  if (!isCompact)
                                    AnimatedBuilder(
                                      animation: _logoCtrl,
                                      builder: (context, _) {
                                        final t = _logoCtrl.value;
                                        return ShaderMask(
                                          shaderCallback: (r) => LinearGradient(
                                            colors: const [
                                              Colors.white,
                                              Color(0xFFE5E7EB),
                                              Colors.white,
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                            transform: GradientRotation(
                                              6.28318 * (t),
                                            ),
                                          ).createShader(r),
                                          child: Text(
                                            'LILIUM TOWERS',
                                            style: TextStyle(
                                              fontSize: logoTextSize,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: logoTextLetter,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),

                          if (!isCompact) const Spacer(),

                          // DESKTOP/LARGE TABLET: full nav with glass pill indicator
                          if (!isCompact)
                            MouseRegion(
                              onExit: (_) => _snapToActive(),
                              child: Stack(
                                key: _navAreaKey,
                                children: [
                                  // Floating glass pill indicator
                                  if (_inkLeft != null && (_inkWidth ?? 0) > 0)
                                    AnimatedPositioned(
                                      duration: const Duration(
                                        milliseconds: 280,
                                      ),
                                      curve: Curves.easeInOutCubic,
                                      bottom: 2,
                                      left: _inkLeft!,
                                      width: _inkWidth!,
                                      height: 30,
                                      child: _GlassPill(),
                                    ),
                                  // Responsive nav links (Admin REMOVED)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _NavLink(
                                        label: 'Home',
                                        route: '/',
                                        current: widget.currentRoute,
                                        onTap: widget.onNavigate,
                                        onHoverRect: _onHoverRect,
                                        onActiveRect: _onActiveRect,
                                        isTablet: isTablet,
                                      ),
                                      _NavLink(
                                        label: 'About',
                                        route: '/about',
                                        current: widget.currentRoute,
                                        onTap: widget.onNavigate,
                                        onHoverRect: _onHoverRect,
                                        onActiveRect: _onActiveRect,
                                        isTablet: isTablet,
                                      ),
                                      _NavLink(
                                        label: 'Apartments',
                                        route: '/apartments',
                                        current: widget.currentRoute,
                                        onTap: widget.onNavigate,
                                        onHoverRect: _onHoverRect,
                                        onActiveRect: _onActiveRect,
                                        isTablet: isTablet,
                                      ),
                                      _NavLink(
                                        label: 'Amenities',
                                        route: '/amenities',
                                        current: widget.currentRoute,
                                        onTap: widget.onNavigate,
                                        onHoverRect: _onHoverRect,
                                        onActiveRect: _onActiveRect,
                                        isTablet: isTablet,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.lightBlue.withOpacity(0.28),
                  AppColors.accentBlue.withOpacity(0.28),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.22), Colors.transparent],
                  radius: 1.2,
                  center: const Alignment(0.0, -0.6),
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: const SizedBox.expand(),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.28)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label, route, current;
  final void Function(String) onTap;
  final void Function(String, Rect) onHoverRect;
  final void Function(String, Rect) onActiveRect;
  final bool isTablet;

  const _NavLink({
    required this.label,
    required this.route,
    required this.current,
    required this.onTap,
    required this.onHoverRect,
    required this.onActiveRect,
    this.isTablet = false,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool hover = false;
  final GlobalKey _key = GlobalKey();

  void _reportRect(void Function(String, Rect) cb) {
    final ctx = _key.currentContext;
    if (ctx == null) return;

    final ro = ctx.findRenderObject();
    // Guard: only read size after layout is complete
    if (ro is! RenderBox || !ro.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reportRect(cb);
      });
      return;
    }

    final size = ro.size;
    final offset = ro.localToGlobal(Offset.zero);
    cb(
      widget.route,
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.current == widget.route) _reportRect(widget.onActiveRect);
    });
  }

  @override
  void didUpdateWidget(covariant _NavLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.current == widget.route) _reportRect(widget.onActiveRect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.current == widget.route;

    // Responsive dimensions
    final fontSize = widget.isTablet ? 13.0 : 14.0;
    final horizontalPadding = widget.isTablet ? 12.0 : 16.0;
    final verticalPadding = widget.isTablet ? 8.0 : 10.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => hover = true);
        _reportRect(widget.onHoverRect);
      },
      onHover: (_) => _reportRect(widget.onHoverRect),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.route),
        child: Container(
          key: _key,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              color: Colors.white.withOpacity((active || hover) ? 1 : 0.9),
              fontWeight: FontWeight.w700,
              letterSpacing: (active || hover) ? 0.6 : 0.3,
              fontSize: fontSize,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

// =============================== Mobile Dropdown Menu - Responsive ===============================
class _MobileDropdownMenu extends StatelessWidget {
  final String currentRoute;
  final void Function(String route) onNavigate;
  final bool isMobile;

  const _MobileDropdownMenu({
    required this.currentRoute,
    required this.onNavigate,
    required this.isMobile,
  });

  String _getRouteLabel(String route) {
    switch (route) {
      case '/':
        return 'Home';
      case '/about':
        return 'About';
      case '/apartments':
        return 'Apartments';
      case '/amenities':
        return 'Amenities';
      default:
        return 'Home';
    }
  }

  IconData _getRouteIcon(String route) {
    switch (route) {
      case '/':
        return Icons.home_outlined;
      case '/about':
        return Icons.info_outline;
      case '/apartments':
        return Icons.apartment_outlined;
      case '/amenities':
        return Icons.pool_outlined;
      default:
        return Icons.home_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Admin route removed from menu
    final allRoutes = ['/', '/about', '/apartments', '/amenities'];
    final availableRoutes = allRoutes
        .where((route) => route != currentRoute)
        .toList();

    // Responsive dimensions
    final iconSize = isMobile ? 20.0 : 24.0;
    final fontSize = isMobile ? 12.0 : 14.0;
    final spacing = isMobile ? 6.0 : 8.0;

    return Theme(
      data: Theme.of(context).copyWith(canvasColor: AppColors.primaryDark),
      child: DropdownButton<String>(
        value: null,
        hint: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu, color: Colors.white, size: iconSize),
            SizedBox(width: spacing),
            if (!isMobile)
              Flexible(
                child: Text(
                  _getRouteLabel(currentRoute),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        icon: const SizedBox(),
        iconSize: 0,
        underline: const SizedBox(),
        dropdownColor: AppColors.primaryDark,
        menuMaxHeight: MediaQuery.sizeOf(context).height * 0.5,
        onChanged: (String? newValue) {
          if (newValue != null) onNavigate(newValue);
        },
        items: availableRoutes.map<DropdownMenuItem<String>>((String route) {
          return DropdownMenuItem<String>(
            value: route,
            child: Container(
              width: isMobile ? 160 : 200,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 6 : 8,
                horizontal: 4,
              ),
              child: Row(
                children: [
                  Icon(
                    _getRouteIcon(route),
                    color: Colors.white,
                    size: isMobile ? 18 : 20,
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Text(
                      _getRouteLabel(route),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontSize: isMobile ? 12.0 : 14.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================== Footer - Responsive ==============================
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 24 : (isTablet ? 30 : 36),
        horizontal: isMobile ? 16 : (isTablet ? 20 : 24),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.secondaryDark],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : (isTablet ? 1200 : 1440),
          ),
          child: Column(
            children: [
              Text(
                '© 2025 Lilium Towers. All rights reserved. Live Elevated.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isMobile ? 12 : (isTablet ? 13 : 14),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Text(
                'Premium Mixed-Use Development | Gulshan-e-Sehat E-18, Islamabad',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isMobile ? 11 : (isTablet ? 12 : 14),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================ Shared UI - Responsive Components ==============================
class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool dark;
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    final titleStyle = Theme.of(context).textTheme.headlineLarge!.copyWith(
      color: dark ? Colors.white : AppColors.textPrimary,
      letterSpacing: -0.5,
      fontSize: isMobile ? 24 : (isTablet ? 28 : 32),
    );

    final subStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
      color: dark ? Colors.white70 : AppColors.textLight,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      fontSize: isMobile ? 11 : (isTablet ? 12 : 14),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 24 : (isTablet ? 32 : 40)),
      child: Column(
        children: [
          Text(subtitle.toUpperCase(), style: subStyle),
          SizedBox(height: isMobile ? 4 : 8),
          Text(title, style: titleStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class H3 extends StatelessWidget {
  final String text;
  const H3(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: isMobile ? 18 : (isTablet ? 20 : 22),
      ),
    );
  }
}

class BodyText extends StatelessWidget {
  final String text;
  const BodyText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
        color: AppColors.textSecondary,
        height: 1.8,
        fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const GradientButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.lightBlue, AppColors.accentBlue],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightBlue.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : (isTablet ? 24 : 28),
              vertical: isMobile ? 10 : (isTablet ? 12 : 14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: isMobile ? 12 : (isTablet ? 13 : 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Badge extends StatelessWidget {
  final String label;
  const Badge(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    final size = isMobile ? 40.0 : (isTablet ? 44.0 : 48.0);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          isMobile ? 8 : (isTablet ? 10 : 12),
        ),
        gradient: const LinearGradient(
          colors: [AppColors.lightBlue, AppColors.accentBlue],
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: isMobile ? 12 : (isTablet ? 14 : 16),
        ),
      ),
    );
  }
}

class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const WhiteCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    final defaultPadding = EdgeInsets.all(
      isMobile ? 16.0 : (isTablet ? 20.0 : 24.0),
    );

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isMobile ? 4 : 6,
        horizontal: isMobile ? 8 : 0,
      ),
      padding: padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isMobile ? 16 : (isTablet ? 20 : 24),
        ),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isMobile ? 15 : (isTablet ? 20 : 25),
            offset: Offset(0, isMobile ? 6 : (isTablet ? 9 : 12)),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    final defaultPadding = EdgeInsets.all(
      isMobile ? 16.0 : (isTablet ? 20.0 : 24.0),
    );
    final borderRadius = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    radius: 0.9,
                    center: const Alignment(0.4, -0.3),
                  ),
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                padding: padding ?? defaultPadding,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================= Responsive Helper Widget =========================
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);
    final isDesktop = Breakpoints.isDesktop(width);

    return builder(context, isMobile, isTablet, isDesktop);
  }
}

// ========================= Responsive Container =========================
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    final defaultPadding = EdgeInsets.symmetric(
      horizontal: isMobile ? 16.0 : (isTablet ? 32.0 : 48.0),
      vertical: isMobile ? 16.0 : (isTablet ? 24.0 : 32.0),
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : (isTablet ? 1200 : 1440),
      ),
      padding: padding ?? defaultPadding,
      margin: margin,
      child: child,
    );
  }
}

// ========================= Responsive Grid =========================
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);

    final columns = isMobile
        ? (mobileColumns ?? 1)
        : isTablet
        ? (tabletColumns ?? 2)
        : (desktopColumns ?? 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: isMobile ? 1.2 : (isTablet ? 1.1 : 1.0),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/* ========================= Admin Sign-in Dialog (hidden) =========================
   - Pops up after 5 taps on the logo within 2 seconds.
   - On success: closes dialog and navigates to /admin.
=============================================================================== */
/* ========================= Admin Sign-in Dialog (hidden) =========================
   - Pops up after 5 taps on the logo within 2 seconds.
   - On success: closes dialog and navigates to /admin.
   - ✨ Polished UI: gradient header, iconography, nicer fields & layout
=============================================================================== */
class _AdminSigninDialog extends StatefulWidget {
  const _AdminSigninDialog();

  @override
  State<_AdminSigninDialog> createState() => _AdminSigninDialogState();
}

class _AdminSigninDialogState extends State<_AdminSigninDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl
      ..removeListener(_noop)
      ..dispose();
    _passCtrl
      ..removeListener(_noop)
      ..dispose();
    super.dispose();
  }

  void _noop() {}

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user is disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.pop(context); // close dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed in')));
      Navigator.of(context).pushNamed('/admin');
    } on FirebaseAuthException catch (e) {
      final msg = _friendlyAuthError(e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.accentBlue),
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: AppColors.bgLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use a fully custom Dialog for nicer styling
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Card background
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gradient header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accentBlue, AppColors.accentBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Access',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sign in to manage content',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),

                    // Form body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofocus: true,
                              validator: (v) {
                                final t = (v ?? '').trim();
                                if (t.isEmpty) return 'Email is required';
                                if (!t.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                              decoration: _fieldDecoration(
                                label: 'Email',
                                icon: Icons.alternate_email_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signIn(),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 6) {
                                  return 'Min 6 characters';
                                }
                                return null;
                              },
                              decoration: _fieldDecoration(
                                label: 'Password',
                                icon: Icons.lock_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                  tooltip: _obscure
                                      ? 'Show password'
                                      : 'Hide password',
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.accentBlue,
                                  ),
                                  onPressed: _loading
                                      ? null
                                      : () async {
                                          final email = _emailCtrl.text.trim();
                                          if (email.isEmpty ||
                                              !email.contains('@')) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Enter a valid email to reset password',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          try {
                                            await FirebaseAuth.instance
                                                .sendPasswordResetEmail(
                                                  email: email,
                                                );
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Password reset link sent to $email',
                                                ),
                                              ),
                                            );
                                          } on FirebaseAuthException catch (e) {
                                            final msg = _friendlyAuthError(e);
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(content: Text(msg)),
                                              );
                                            }
                                          }
                                        },
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Forgot password?'),
                                ),
                                const Spacer(),
                                OutlinedButton(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: _loading ? null : _signIn,
                                  icon: _loading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(Icons.login_rounded),
                                  label: Text(
                                    _loading ? 'Signing in…' : 'Sign in',
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Subtle top progress when loading
              if (_loading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
