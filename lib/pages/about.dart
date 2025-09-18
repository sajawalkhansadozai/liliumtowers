part of lilium;

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const double _desktopMaxWidth = 1440;
  static const double _tabletMaxWidth = 1200;
  static const double _minLeftColWidth = 520; // content min width
  static const double _minRightColWidth = 360; // highlight min width
  static const double _desktopGutter = 32;
  static const double _tabletGutter = 28;
  static const double _mobileGutter = 20;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    final isMobile = Breakpoints.isMobile(width);
    final isTablet = Breakpoints.isTablet(width);
    final isDesktop = width >= 1024;

    // clamp text scale
    final mq = MediaQuery.of(context);
    final clamped = mq.copyWith(
      textScaleFactor: mq.textScaleFactor.clamp(1.0, 1.2),
    );

    // container paddings
    final vPad = isMobile ? 48.0 : (isTablet ? 64.0 : 80.0);
    final hPad = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);

    // extra top offset so content starts a little lower than the app bar
    final extraTop = isMobile
        ? 16.0
        : (isTablet ? 20.0 : 24.0); // ← added spacer

    // max content width
    final maxWidth = isMobile
        ? double.infinity
        : (isTablet ? _tabletMaxWidth : _desktopMaxWidth);

    // should we render side-by-side?
    final gutter = isMobile
        ? _mobileGutter
        : (isTablet ? _tabletGutter : _desktopGutter);
    final sideBySide =
        isDesktop &&
        width - hPad * 2 >= (_minLeftColWidth + _minRightColWidth + gutter);

    return MediaQuery(
      data: clamped,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgLight, Colors.white],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: extraTop,
                ), // ← NEW: pushes content below header

                const SectionHeader(
                  title: 'About Lilium Towers',
                  subtitle: 'Premium Mixed-Use Development',
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // content layout
                if (sideBySide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // left/content
                      Flexible(
                        flex: 3,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: _minLeftColWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(right: gutter),
                            child: _AboutContent(
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                          ),
                        ),
                      ),
                      // right/highlight
                      Flexible(
                        flex: 2,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: _minRightColWidth,
                          ),
                          child: _HighlightCardAbout(
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // stacked for tablet / mobile / narrow desktop
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AboutContent(isMobile: isMobile, isTablet: isTablet),
                      SizedBox(height: isMobile ? 20 : 24),
                      _HighlightCardAbout(
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                    ],
                  ),

                SizedBox(height: isMobile ? 24 : 32),
                _FeatureGridAbout(isMobile: isMobile, isTablet: isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _AboutContent({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final titleGap = isMobile ? 8.0 : 12.0;
    final blockGap = isMobile ? 12.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        H3('Strategic Location & Modern Design'),
        SizedBox(height: titleGap),
        const BodyText(
          "Lilium Towers stands as a premium mixed-use development at Gulshan-e-Sehat E-18 Islamabad, strategically positioned near the 1200 ft wide CPEC motorway interchange. This landmark project features commercial ground and mezzanine levels complemented by 10 residential floors of exceptional quality.",
        ),
        SizedBox(height: titleGap),
        const BodyText(
          "Our thoughtfully designed development offers studio, 1-bedroom, and 2-bedroom apartments with a dedicated utilities service floor for communal amenities. Each residence is meticulously crafted for discerning investors and residents, delivering an unparalleled blend of business opportunities and sophisticated urban living.",
        ),
        SizedBox(height: blockGap),
        H3('Part of Automotive Excellence Hub'),
        SizedBox(height: titleGap),
        const BodyText(
          "Positioned within a comprehensive automotive development ecosystem featuring exclusive dealership zones, specialized auto parts facilities, premium car care services, and dynamic business districts. This creates a unique one-stop destination offering infinite possibilities for investment and lifestyle enhancement.",
        ),
      ],
    );
  }
}

class _HighlightCardAbout extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _HighlightCardAbout({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    const items = [
      'Direct CPEC Motorway Access',
      'Mixed-Use Architecture',
      '10 Premium Residential Floors',
      'World-Class Amenities',
      'Strategic Investment Location',
      'Automotive Hub Integration',
      'Premium Architectural Excellence',
      'Multiple Unit Configurations',
    ];

    final pad = isMobile ? 20.0 : (isTablet ? 24.0 : 28.0);

    return GlassCard(
      gradient: const LinearGradient(
        colors: [AppColors.primaryDark, AppColors.secondaryDark],
      ),
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Distinguished Features',
            softWrap: true,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          ...List.generate(items.length, (i) {
            final isLast = i == items.length - 1;
            return Container(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isLast
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isMobile ? 8 : 10,
                    height: isMobile ? 8 : 10,
                    margin: EdgeInsets.only(top: isMobile ? 6 : 7),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.lightBlue, AppColors.accentBlue],
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Text(
                      items[i],
                      softWrap: true,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : (isTablet ? 14 : 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FeatureGridAbout extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _FeatureGridAbout({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    const cards = [
      (
        'CPEC',
        'CPEC Connectivity',
        'Unparalleled access to the 1200 ft wide CPEC motorway interchange, ensuring seamless connectivity to major commercial centers and transportation networks across Pakistan.',
      ),
      (
        'MIXED',
        'Mixed-Use Excellence',
        'Sophisticated commercial spaces at ground level seamlessly integrated with premium residential apartments, creating a dynamic and vibrant community ecosystem.',
      ),
      (
        'AUTO',
        'Automotive Hub',
        'Integral component of an expansive automotive development featuring premium dealerships, specialized services, and business facilities creating unique investment opportunities.',
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _FeatureCardAbout(
                  badge: e.$1,
                  title: e.$2,
                  body: e.$3,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              ),
            )
            .toList(),
      );
    }

    return ResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: isTablet ? 2 : 3,
      desktopColumns: 3,
      spacing: isMobile ? 12 : (isTablet ? 16 : 20),
      children: cards
          .map(
            (e) => _FeatureCardAbout(
              badge: e.$1,
              title: e.$2,
              body: e.$3,
              isMobile: isMobile,
              isTablet: isTablet,
            ),
          )
          .toList(),
    );
  }
}

class _FeatureCardAbout extends StatefulWidget {
  final String badge, title, body;
  final bool isMobile;
  final bool isTablet;

  const _FeatureCardAbout({
    required this.badge,
    required this.title,
    required this.body,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_FeatureCardAbout> createState() => _FeatureCardAboutState();
}

class _FeatureCardAboutState extends State<_FeatureCardAbout> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.isMobile ? 16.0 : 20.0;
    final pad = widget.isMobile ? 16.0 : (widget.isTablet ? 20.0 : 24.0);

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, hover ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(hover ? 0.15 : 0.08),
              blurRadius: hover ? 30 : (widget.isMobile ? 15 : 20),
              offset: Offset(0, hover ? 18 : (widget.isMobile ? 6 : 10)),
            ),
          ],
        ),
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.isMobile ? 48 : (widget.isTablet ? 56 : 64),
              height: widget.isMobile ? 48 : (widget.isTablet ? 56 : 64),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
                gradient: const LinearGradient(
                  colors: [AppColors.lightBlue, AppColors.accentBlue],
                ),
              ),
              child: Text(
                widget.badge,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.isMobile ? 10 : (widget.isTablet ? 11 : 12),
                ),
              ),
            ),
            SizedBox(height: widget.isMobile ? 12 : 16),
            Text(
              widget.title,
              softWrap: true,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: widget.isMobile ? 16 : (widget.isTablet ? 17 : 18),
              ),
            ),
            SizedBox(height: widget.isMobile ? 6 : 8),
            Text(
              widget.body,
              softWrap: true,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: widget.isMobile ? 13 : (widget.isTablet ? 14 : 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
