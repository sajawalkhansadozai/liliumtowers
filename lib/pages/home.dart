// ignore_for_file: unused_element
part of lilium;

// NOTE: This file assumes the main library imports cloud_firestore:
// import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // For hero parallax (reads scroll via Notification in Shell; we simulate here with 0)
  double _scrollOffset = 0;

  // ------------------ Inquiry form state ------------------
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  // Contact section anchor for smooth scroll
  final GlobalKey _contactAnchor = GlobalKey();

  // Submitting state
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-cache hero images so they appear instantly and reliably.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheHeroImages(context);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _precacheHeroImages(BuildContext context) {
    const desktop = AssetImage('assets/hero/centaurus_islamabad.jpg');
    const mobile = AssetImage('assets/hero/centaurus_islamabad_mobile.jpg');
    precacheImage(desktop, context);
    precacheImage(mobile, context);
  }

  Future<void> _submitInquiry() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      // Store in Firestore (collection: inquiries)
      await FirebaseFirestore.instance.collection('inquiries').add({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _formKey.currentState?.reset();
      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _subjectCtrl.clear();
      _messageCtrl.clear();

      _showResultSnack(ok: true, text: 'Thanks! Your inquiry has been sent.');
    } catch (e) {
      _showResultSnack(ok: false, text: 'Submission failed. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showResultSnack({required bool ok, required String text}) {
    final icon = ok ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final color = ok ? AppColors.accentBlue : Colors.red;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withOpacity(0.25)),
          ),
          content: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = math.max(size.height * 0.92, 640.0);
    final parallax = ((_scrollOffset * 0.3).clamp(0, height * 0.6)).toDouble();

    // How far to push hero CONTENT down so it clears the fixed header/glass bar.
    // Tweak these numbers if you change the header height later.
    final isMobile = size.width < 700;
    final heroTopSpacer = isMobile ? 88.0 : 104.0; // <-- added spacer

    return Column(
      children: [
        // ============================== HERO ==============================
        Container(
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.secondaryDark],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Pakistani skyscraper — desktop/tablet vs mobile (assets only)
              Positioned.fill(
                child: _ResponsiveHeroBackdropImage(
                  desktopSrc: 'assets/hero/centaurus_islamabad.jpg',
                  mobileSrc: 'assets/hero/centaurus_islamabad_mobile.jpg',
                  parallaxOffset: parallax * 0.4,
                  mobileBreakpoint: 720,
                ),
              ),

              // Soft dark overlay for readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
              ),

              // Optional glow accents
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _HeroGlowPainter()),
                ),
              ),

              // Foreground content (parallax translate)
              Transform.translate(
                offset: Offset(0, parallax),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // >>> added spacer so hero copy clears the app bar <<<
                            SizedBox(height: heroTopSpacer),

                            // Location line (small, overflow-safe)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Gulshan-e-Sehat E-18 · Islamabad · Near CPEC Interchange',
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Headline + strap
                            ShaderMask(
                              shaderCallback: (r) => const LinearGradient(
                                colors: [Colors.white, Color(0xFFE5E7EB)],
                              ).createShader(r),
                              child: Text(
                                'LILIUM TOWERS',
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: _fluid(50, 100, context),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'LIVE ELEVATED',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _fluid(16, 24, context),
                                letterSpacing: 6,
                                color: Colors.white.withOpacity(0.92),
                                fontWeight: FontWeight.w300,
                              ),
                            ),

                            const SizedBox(height: 22),

                            // USPs (chips)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 860),
                              child: const Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  _USPChip(
                                    text: 'Studios, 1 & 2 Bedroom Residences',
                                  ),
                                  _USPChip(
                                    text: 'Amenities Deck, Fitness & Lounge',
                                  ),
                                  _USPChip(
                                    text: 'Retail & Mixed-Use Convenience',
                                  ),
                                  _USPChip(
                                    text: 'Near 1200 ft CPEC Interchange',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Sub-copy
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 820),
                              child: Text(
                                "Experience premium living in a landmark mixed-use development. Modern design, world-class amenities, and unmatched connectivity to Islamabad’s key corridors.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: _fluid(14, 18, context),
                                  color: Colors.white.withOpacity(0.88),
                                  height: 1.8,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),

                            const SizedBox(height: 26),

                            // CTAs (tiny-screen safe)
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                _CtaButtonPrimary(
                                  label: 'Explore Apartments',
                                  icon: Icons.home_work_outlined,
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/apartments'),
                                ),
                                _CtaButtonSecondary(
                                  label: 'Contact Us',
                                  icon: Icons.support_agent_outlined,
                                  onTap: () {
                                    final ctx = _contactAnchor.currentContext;
                                    if (ctx != null) {
                                      Scrollable.ensureVisible(
                                        ctx,
                                        duration: const Duration(
                                          milliseconds: 650,
                                        ),
                                        curve: Curves.easeInOutCubic,
                                        alignment: 0.06,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ========================== INTRO STRIP ===========================
        Container(
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.sizeOf(context).width < 700 ? 48 : 80,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.bgLight, Colors.white],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SectionHeader(
                      title: 'Live Elevated',
                      subtitle: 'Premium Mixed-Use Development',
                    ),
                    BodyText(
                      "A landmark address at Gulshan-e-Sehat E-18, Islamabad—offering world-class amenities, mixed-use convenience, and connectivity with the CPEC interchange.",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ========================== KEY METRICS ===========================
        _LightSection(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: const _KeyMetricsRow(
              metrics: [
                ('350+', 'Total Units'),
                ('10', 'Residential Floors'),
                ('2', 'Commercial Levels'),
                ('1200 ft', 'Near CPEC Interchange'),
              ],
            ),
          ),
        ),

        // ========================= SHOWCASE GALLERY =======================
        _LightSection(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              children: [
                const SectionHeader(
                  title: 'Showcase Gallery',
                  subtitle: 'Exteriors · Interiors · Amenities',
                ),
                _HomeGalleryGrid(
                  items: const [
                    (
                      'Iconic Facade — Tower A',
                      'assets/gallery/exterior_facade.jpg',
                    ),
                    (
                      'Skyline View — Islamabad',
                      'assets/gallery/skyline_isb.jpg',
                    ),
                    (
                      'Grand Lobby — Double Height',
                      'assets/gallery/lobby_double_height.jpg',
                    ),
                    ('Model Apartment — 2 BR', 'assets/gallery/model_2br.jpg'),
                    (
                      'Amenity Deck — Pool & Loungers',
                      'assets/gallery/amenity_pool.jpg',
                    ),
                    (
                      'Evening Elevation — Tower B',
                      'assets/gallery/evening_elevation.jpg',
                    ),
                    ('Fitness & Wellness', 'assets/gallery/fitness.jpg'),
                    ('Courtyard Garden', 'assets/gallery/courtyard.jpg'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ========================= OUR JOURNEY ============================
        _JourneySection(),

        // ========================= AMENITIES PREVIEW ======================
        _LightSection(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: const Column(
              children: [
                SectionHeader(
                  title: 'World-Class Amenities',
                  subtitle: 'A Lifestyle Beyond the Ordinary',
                ),
                _AmenityPreviewRow(
                  items: [
                    ('VIEW', 'Panoramic Tower Views'),
                    ('FIT', 'Modern Fitness Club'),
                    ('PARK', 'Secured Covered Parking'),
                    ('CLUB', 'Residents’ Lounge'),
                    ('PRAY', 'Dedicated Masjid'),
                    ('AIR', 'Climate-Controlled Atriums'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ========================= FLOORPLAN TEASERS ======================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              children: [
                const SectionHeader(
                  title: 'Apartment Collection',
                  subtitle: 'Studios · 1 Bedroom · 2 Bedroom',
                ),
                _FloorplanTeasers(
                  tiles: const [
                    (
                      'Studio — Compact Elegance',
                      'assets/gallery/floor_studio.jpg',
                      'Explore Studios',
                      '/apartments',
                    ),
                    (
                      '1 Bedroom — Premium Living',
                      'assets/gallery/floor_1br.jpg',
                      'View 1 BR',
                      '/apartments',
                    ),
                    (
                      '2 Bedroom — Luxury Residence',
                      'assets/gallery/floor_2br.jpg',
                      'See 2 BR',
                      '/apartments',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ========================= PRICING TEASER ========================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: _PricingTeaser(
              chips: const [
                '2 Years · Rs. 10,800 / sft',
                '3 Years · Rs. 13,000 / sft',
                '4 Years · Rs. 15,000 / sft',
              ],
              ctaLabel: 'View Investment Plans',
              route: '/pricing',
            ),
          ),
        ),

        // ========================= CONTACT (INFO + FORM) ==================
        _LightSection(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: LayoutBuilder(
              builder: (context, c) {
                final isWide = c.maxWidth >= 1024;

                // IMPORTANT: avoid Expanded in a vertical (unbounded) layout.
                final form = _InquiryFormCard(
                  formKey: _formKey,
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  phoneCtrl: _phoneCtrl,
                  subjectCtrl: _subjectCtrl,
                  messageCtrl: _messageCtrl,
                  onSubmit: _submitInquiry,
                  submitting: _submitting,
                );

                const info = Column(
                  children: [
                    _ContactInfoCardBlue(
                      icon: Icons.place_outlined,
                      title: 'Premium Location',
                      lines: [
                        'Gulshan-e-Sehat E-18, Islamabad',
                        'Near CPEC Motorway Interchange',
                        'Automotive Development Zone',
                      ],
                    ),
                    SizedBox(height: 16),
                    _ContactInfoCardBlue(
                      icon: Icons.access_time,
                      title: 'Business Hours',
                      lines: [
                        'Monday - Saturday: 9:00 AM – 6:00 PM',
                        'Sunday: 10:00 AM – 4:00 PM',
                        'Special appointments available',
                      ],
                    ),
                    SizedBox(height: 16),
                    _ContactInfoCardBlue(
                      icon: Icons.phone_in_talk_outlined,
                      title: 'Sales Consultation',
                      lines: [
                        'Guidance on units, pricing & plans',
                        'Investment opportunities with our team',
                      ],
                    ),
                    SizedBox(height: 16),
                    _ContactInfoCardBlue(
                      icon: Icons.info_outline,
                      title: 'Detailed Information',
                      lines: [
                        'Brochures, floor plans, investment guides',
                        'Complete project documentation available',
                      ],
                    ),
                  ],
                );

                return Column(
                  children: [
                    // anchor for smooth scroll
                    SizedBox(height: 0, key: _contactAnchor),

                    const SectionHeader(
                      title: 'Get In Touch',
                      subtitle:
                          'Ready to transform your lawn? Let’s discuss your project',
                    ),
                    const SizedBox(height: 8),

                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // left: form
                          Expanded(flex: 6, child: form),
                          const SizedBox(width: 24),
                          // right: info
                          Expanded(flex: 5, child: info),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [form, const SizedBox(height: 24), info],
                      ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 56),
      ],
    );
  }

  double _fluid(double min, double max, BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= 400) return min;
    if (w >= 1400) return max;
    return min + (max - min) * ((w - 400) / (1000));
  }
}

class _HeroGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final g1 = RadialGradient(
      colors: [AppColors.lightBlue.withOpacity(0.12), Colors.transparent],
      stops: const [0, 1],
    );
    final g2 = RadialGradient(
      colors: [AppColors.accentBlue.withOpacity(0.10), Colors.transparent],
    );
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    final r1 = Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.8),
      radius: size.shortestSide * 0.6,
    );
    canvas.drawRect(r1, Paint()..shader = g1.createShader(r1));
    final r2 = Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.2),
      radius: size.shortestSide * 0.5,
    );
    canvas.drawRect(r2, Paint()..shader = g2.createShader(r2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ====================================================================
//                          ADDED WIDGETS (HOME-ONLY)
// ====================================================================

class _LightSection extends StatelessWidget {
  final Widget child;
  const _LightSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width < 700 ? 42.0 : 72.0;
    return Container(
      padding: EdgeInsets.symmetric(vertical: pad),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgLight, Colors.white],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

class _USPChip extends StatelessWidget {
  final String text;
  const _USPChip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.10),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Text(
        text,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _KeyMetricsRow extends StatelessWidget {
  final List<(String value, String label)> metrics;
  const _KeyMetricsRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isCompact = c.maxWidth < 800;
        final w = isCompact ? c.maxWidth : (c.maxWidth - 60) / 4;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: metrics
              .map(
                (m) => SizedBox(
                  width: w,
                  child: WhiteCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 18,
                    ),
                    child: Column(
                      children: [
                        Text(
                          m.$1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: Theme.of(context).textTheme.headlineMedium!
                              .copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentBlue,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _HomeWideBannerImage extends StatelessWidget {
  final String src;
  final String caption;
  const _HomeWideBannerImage({required this.src, required this.caption});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          AspectRatio(aspectRatio: 16 / 6, child: _smartImage(src)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.05),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeGalleryGrid extends StatelessWidget {
  final List<(String title, String src)> items;
  const _HomeGalleryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 1200 ? 4 : (w >= 900 ? 3 : 2);
        final gap = 16.0;
        final tileW = (w - (gap * (cols - 1))) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (e) => SizedBox(
                  width: tileW,
                  child: _HomePhotoCard(title: e.$1, src: e.$2),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _HomePhotoCard extends StatefulWidget {
  final String title;
  final String src; // asset only in this build
  const _HomePhotoCard({required this.title, required this.src});

  @override
  State<_HomePhotoCard> createState() => _HomePhotoCardState();
}

class _HomePhotoCardState extends State<_HomePhotoCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final canLift = MediaQuery.sizeOf(context).width >= 700;
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12), // guard gap below each tile
        transform: Matrix4.identity()
          ..translate(0.0, (canLift && hover) ? -6.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(hover ? 0.35 : 0.25),
              blurRadius: hover ? 28 : 18,
              offset: Offset(0, hover ? 16 : 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AspectRatio(aspectRatio: 4 / 3, child: _smartImage(widget.src)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------- AMENITIES (mobile-friendly version) -----------------
class _AmenityPreviewRow extends StatelessWidget {
  final List<(String code, String text)> items;
  const _AmenityPreviewRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        const minTileWidth = 168.0; // target width per card
        final maxW = c.maxWidth;

        // How many columns can we fit if each card wants ~minTileWidth?
        int cols = (maxW / (minTileWidth + gap)).floor();
        cols = cols.clamp(2, 6); // never less than 2 columns

        final tileW = (maxW - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          children: items
              .map(
                (e) => SizedBox(
                  width: tileW,
                  child: _AmenityTile(
                    code: e.$1,
                    text: e.$2,
                    compact: tileW < 200, // switch to vertical layout if tight
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AmenityTile extends StatelessWidget {
  final String code;
  final String text;
  final bool compact; // if true -> vertical stacked layout

  const _AmenityTile({
    required this.code,
    required this.text,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: compact ? 36 : 40,
      height: compact ? 36 : 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [AppColors.lightBlue, AppColors.accentBlue],
        ),
      ),
      child: Text(
        code,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 11 : 12,
          letterSpacing: 0.2,
        ),
      ),
    );

    final textWidget = Text(
      text,
      maxLines: compact ? 3 : 2,
      textAlign: compact ? TextAlign.center : TextAlign.start,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        height: 1.25,
        fontSize: compact ? 12.5 : 13.5,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: compact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [badge, const SizedBox(height: 8), textWidget],
            )
          : Row(
              children: [
                badge,
                const SizedBox(width: 10),
                Expanded(child: textWidget),
              ],
            ),
    );
  }
}

class _FloorplanTeasers extends StatelessWidget {
  final List<(String title, String src, String cta, String route)> tiles;
  const _FloorplanTeasers({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 1000;
        final cols = isNarrow ? 1 : 3;
        final gap = 18.0;
        final w = (c.maxWidth - (gap * (cols - 1))) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: tiles
              .map(
                (t) => SizedBox(
                  width: w,
                  child: _FloorTile(
                    title: t.$1,
                    src: t.$2,
                    cta: t.$3,
                    route: t.$4,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FloorTile extends StatefulWidget {
  final String title, src, cta, route;
  const _FloorTile({
    required this.title,
    required this.src,
    required this.cta,
    required this.route,
  });

  @override
  State<_FloorTile> createState() => _FloorTileState();
}

class _FloorTileState extends State<_FloorTile> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final enableLift = MediaQuery.sizeOf(context).width >= 700;
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12), // guard space under tile
        transform: Matrix4.identity()
          ..translate(0.0, enableLift && hover ? -6.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(hover ? 0.2 : 0.12),
              blurRadius: hover ? 24 : 16,
              offset: Offset(0, hover ? 16 : 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AspectRatio(aspectRatio: 16 / 10, child: _smartImage(widget.src)),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: WhiteCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _CtaButtonSecondary(
                        label: widget.cta,
                        icon: Icons.arrow_forward,
                        onTap: () => Navigator.of(
                          context,
                        ).pushReplacementNamed(widget.route),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingTeaser extends StatelessWidget {
  final List<String> chips;
  final String ctaLabel;
  final String route;
  const _PricingTeaser({
    required this.chips,
    required this.ctaLabel,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: const LinearGradient(
        colors: [AppColors.primaryDark, AppColors.secondaryDark],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          const Text(
            'Flexible Payment Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: chips.map((c) => _PlanChip(text: c)).toList(),
          ),
          const SizedBox(height: 16),
          _CtaButtonPrimary(
            label: ctaLabel,
            icon: Icons.payments_outlined,
            onTap: () => Navigator.of(context).pushReplacementNamed(route),
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String text;
  const _PlanChip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [AppColors.lightBlue, AppColors.accentBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ------------------- HERO BACKDROP + CTA BUTTONS --------------------

class _ResponsiveHeroBackdropImage extends StatelessWidget {
  final String desktopSrc;
  final String mobileSrc;
  final double parallaxOffset;
  final double mobileBreakpoint; // width below which we show mobile image
  const _ResponsiveHeroBackdropImage({
    required this.desktopSrc,
    required this.mobileSrc,
    required this.parallaxOffset,
    this.mobileBreakpoint = 720,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final src = w < mobileBreakpoint ? mobileSrc : desktopSrc;
    return _HeroBackdropImage(src: src, parallaxOffset: parallaxOffset);
  }
}

class _HeroBackdropImage extends StatelessWidget {
  final String src;
  final double parallaxOffset;
  const _HeroBackdropImage({required this.src, required this.parallaxOffset});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -parallaxOffset),
      child: _smartImage(src),
    );
  }
}

class _CtaButtonPrimary extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;
  const _CtaButtonPrimary({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  @override
  State<_CtaButtonPrimary> createState() => _CtaButtonPrimaryState();
}

class _CtaButtonPrimaryState extends State<_CtaButtonPrimary> {
  bool hover = false;
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final isTiny = MediaQuery.sizeOf(context).width < 380;
    final height = isTiny ? 46.0 : 52.0;
    final minW = isTiny ? 160.0 : 220.0;

    final enabled = widget.enabled && !widget.loading;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => down = true) : null,
        onTapCancel: enabled ? () => setState(() => down = false) : null,
        onTapUp: enabled ? (_) => setState(() => down = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          transform: Matrix4.identity()..scale(down ? 0.98 : 1.0),
          padding: EdgeInsets.symmetric(horizontal: isTiny ? 18 : 22),
          height: height,
          constraints: BoxConstraints(minWidth: minW),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.lightBlue, AppColors.accentBlue],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightBlue.withOpacity(
                  (hover && enabled) ? 0.45 : 0.28,
                ),
                blurRadius: (hover && enabled) ? 34 : 22,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            // dim if disabled
            color: enabled ? null : Colors.white.withOpacity(0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.loading) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
              ] else ...[
                Icon(widget.icon, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaButtonSecondary extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _CtaButtonSecondary({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CtaButtonSecondary> createState() => _CtaButtonSecondaryState();
}

class _CtaButtonSecondaryState extends State<_CtaButtonSecondary> {
  bool hover = false;
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final isTiny = MediaQuery.sizeOf(context).width < 380;
    final height = isTiny ? 46.0 : 52.0;
    final minW = isTiny ? 160.0 : 220.0;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => down = true),
        onTapCancel: () => setState(() => down = false),
        onTapUp: (_) => setState(() => down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          transform: Matrix4.identity()..scale(down ? 0.98 : 1.0),
          padding: EdgeInsets.symmetric(horizontal: isTiny ? 18 : 22),
          height: height,
          constraints: BoxConstraints(minWidth: minW),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(hover ? 0.18 : 0.14),
            border: Border.all(
              color: Colors.white.withOpacity(hover ? 0.55 : 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(hover ? 0.28 : 0.18),
                blurRadius: hover ? 28 : 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------- Inquiry Form Card (Home) ----------------------

class _InquiryFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController subjectCtrl;
  final TextEditingController messageCtrl;
  final VoidCallback onSubmit;
  final bool submitting;

  const _InquiryFormCard({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.subjectCtrl,
    required this.messageCtrl,
    required this.onSubmit,
    required this.submitting,
  });

  InputDecoration _dec(String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Us a Message',
              softWrap: false,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameCtrl,
              enabled: !submitting,
              decoration: _dec('Full Name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailCtrl,
              enabled: !submitting,
              decoration: _dec('Email Address *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final s = v?.trim() ?? '';
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                return ok ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              enabled: !submitting,
              decoration: _dec('Phone Number *'),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().length < 7)
                  ? 'Enter a valid phone'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: subjectCtrl,
              enabled: !submitting,
              decoration: _dec(
                'Subject *',
                suffixIcon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.black45,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: messageCtrl,
              enabled: !submitting,
              minLines: 5,
              maxLines: 8,
              decoration: _dec('Message *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: _CtaButtonPrimary(
                label: submitting ? 'Sending…' : 'Send Message',
                icon: Icons.send_rounded,
                onTap: submitting ? null : onSubmit,
                enabled: !submitting,
                loading: submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- BLUE Contact Info Card ----------------------

class _ContactInfoCardBlue extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;

  const _ContactInfoCardBlue({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ribbon strip
            Container(
              width: 6,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.accentBlue, AppColors.lightBlue],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: AppColors.accentBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...lines.map(
                      (l) => Text(
                        l,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------- OUR JOURNEY (Timeline) -------------------

class _JourneySection extends StatelessWidget {
  _JourneySection();

  final List<_Milestone> _items = const [
    _Milestone(
      year: '2019',
      title: 'Concept & Land',
      text: 'Initial concept, site due diligence and land acquisition.',
    ),
    _Milestone(
      year: '2020',
      title: 'Master Planning',
      text: 'Urban design studies, massing and unit program.',
    ),
    _Milestone(
      year: '2021',
      title: 'Design Development',
      text: 'Architecture, MEP and structural coordination.',
    ),
    _Milestone(
      year: '2022',
      title: 'Approvals',
      text: 'Authorities NOCs, EIA and utilities coordination.',
    ),
    _Milestone(
      year: '2023',
      title: 'Enable Works',
      text: 'Site mobilization, grading and early works.',
    ),
    _Milestone(
      year: '2024',
      title: 'Launch & Sales',
      text: 'Marketing launch, model apartments and sales program.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _LightSection(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              const SectionHeader(
                title: 'Our Journey',
                subtitle: 'Six Years of Progress',
              ),
              _Timeline(items: _items),
            ],
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<_Milestone> items;
  const _Timeline({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 900;

        if (isNarrow) {
          // stacked timeline for mobile
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _TimelineTile(milestone: items[i], placeLeft: i.isEven),
                if (i != items.length - 1) const SizedBox(height: 18),
              ],
            ],
          );
        }

        // desktop: alternating left/right around a center line
        return Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              SizedBox(
                height: 120,
                child: Row(
                  children: [
                    Expanded(
                      child: i.isEven
                          ? _MilestoneCard(items[i], alignRight: true)
                          : const SizedBox(),
                    ),
                    SizedBox(
                      width: 70,
                      child: Stack(
                        children: [
                          // vertical center line
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                width: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0x11000000),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          // dot + year
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.accentBlue,
                                        AppColors.lightBlue,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  items[i].year,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: i.isOdd
                          ? _MilestoneCard(items[i], alignRight: false)
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
              if (i != items.length - 1)
                const SizedBox(
                  height: 26,
                  child: Center(
                    child: SizedBox(
                      width: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x11000000)),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final _Milestone milestone;
  final bool placeLeft; // used only for a slight visual offset on mobile
  const _TimelineTile({required this.milestone, required this.placeLeft});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MilestoneCard(milestone, alignRight: placeLeft)),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final _Milestone m;
  final bool alignRight;
  const _MilestoneCard(this.m, {required this.alignRight});

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alignRight) const SizedBox(width: 0) else const SizedBox(),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.lightBlue, AppColors.accentBlue],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightBlue.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              m.year.substring(2), // '2019' -> '19'
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  m.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestone {
  final String year;
  final String title;
  final String text;
  const _Milestone({
    required this.year,
    required this.title,
    required this.text,
  });
}

// --------------------------- shared image helper ---------------------
Widget _smartImage(
  String src, {
  String placeholder = 'assets/placeholders/placeholder.jpg',
}) {
  final isNetwork = src.startsWith('http'); // not used in this build
  if (isNetwork) {
    return Image.network(
      src,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Text(
            'Loading…',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Image.asset(placeholder, fit: BoxFit.cover),
    );
  } else {
    return Image.asset(
      src,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Image.asset(placeholder, fit: BoxFit.cover),
    );
  }
}
