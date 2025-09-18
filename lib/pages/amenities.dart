part of lilium;

class AmenitiesPage extends StatelessWidget {
  const AmenitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // === Badge-style quick highlights ===
    const List<(String, String)> amenities = [
      ('VIEW', 'Spacious apartments with panoramic city views'),
      ('24/7', 'Uninterrupted water and electricity with backup systems'),
      ('PARK', 'Premium secured parking with ample spaces'),
      ('PRAY', 'Beautiful dedicated Masjid facility'),
      ('FIT', 'State-of-the-art fitness center'),
      ('PLAY', 'Professional indoor sports facilities'),
      ('CARE', 'Professional child care services'),
      ('REST', 'Comfortable dormitory accommodations'),
      ('CLUB', 'Elegant community lounge spaces'),
      ('TECH', 'Modern garbage disposal systems'),
      ('LIFT', 'Premium smart elevator systems'),
      ('AIR', 'Climate-controlled common areas'),
      // new quick highlights
      ('SAFE', '24/7 monitored security & CCTV'),
      ('FIBER', 'High-speed fiber internet ready'),
      ('GREEN', 'Landscaped courtyards & terraces'),
    ];

    // === Gallery items (images from assets) ===
    const List<_AmenityMedia> gallery = [
      _AmenityMedia(
        title: 'Sky Gym',
        subtitle: 'Panoramic fitness with top-tier equipment',
        asset: 'assets/amenities/gym.jpg',
      ),
      _AmenityMedia(
        title: 'Infinity Pool',
        subtitle: 'Serene laps with skyline views',
        asset: 'assets/amenities/pool.jpg',
      ),
      _AmenityMedia(
        title: 'Community Lounge',
        subtitle: 'Cozy shared spaces for residents & guests',
        asset: 'assets/amenities/lounge.jpg',
      ),
      _AmenityMedia(
        title: 'Prayer Hall',
        subtitle: 'Dedicated, peaceful, and thoughtfully designed',
        asset: 'assets/amenities/masjid.jpg',
      ),
      _AmenityMedia(
        title: 'Indoor Sports',
        subtitle: 'Courts & studios for year-round play',
        asset: 'assets/amenities/indoor_sports.jpg',
      ),
      _AmenityMedia(
        title: 'Kids’ Zone',
        subtitle: 'Safe, cheerful, and supervised activity area',
        asset: 'assets/amenities/kids.jpg',
      ),
      _AmenityMedia(
        title: 'Smart Lobby',
        subtitle: 'Concierge, access control & parcel room',
        asset: 'assets/amenities/lobby.jpg',
      ),
      _AmenityMedia(
        title: 'Rooftop Garden',
        subtitle: 'Green escapes with fresh air & seating',
        asset: 'assets/amenities/rooftop.jpg',
      ),
    ];

    // === Services & Facilities (icon + copy) ===
    const List<_AmenitySpec> specs = [
      _AmenitySpec(
        Icons.shield_moon_rounded,
        '24/7 Security',
        'Access-controlled entry, CCTV coverage, and onsite response.',
      ),
      _AmenitySpec(
        Icons.wifi_rounded,
        'Fiber Internet',
        'Gigabit-ready conduits to every residence.',
      ),
      _AmenitySpec(
        Icons.local_parking_rounded,
        'Secure Parking',
        'Covered, monitored, and EV-charging enabled bays.',
      ),
      _AmenitySpec(
        Icons.elevator_rounded,
        'Smart Elevators',
        'Fast, quiet, and energy-efficient with smart dispatch.',
      ),
      _AmenitySpec(
        Icons.recycling_rounded,
        'Waste Management',
        'Hygienic, modern garbage & recycling chutes.',
      ),
      _AmenitySpec(
        Icons.generating_tokens_rounded,
        'Backup Power',
        'Generators & UPS to keep essentials always on.',
      ),
    ];

    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 700;
    final pad = isMobile ? 48.0 : 80.0;

    // Spacer to keep content comfortably below the fixed header
    final topSpacer = isMobile ? 72.0 : 84.0;

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: topSpacer),

                const SectionHeader(
                  title: 'World-Class Amenities',
                  subtitle: 'Premium Lifestyle Features',
                ),

                // ====== Quick Highlights (badges) ======
                LayoutBuilder(
                  builder: (context, c) {
                    const min = 320.0;
                    final perRow = (c.maxWidth / (min + 20)).floor().clamp(
                      1,
                      4,
                    );
                    final cardWidth = (c.maxWidth - (perRow - 1) * 16) / perRow;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: amenities
                          .map<Widget>(
                            (a) => SizedBox(
                              width: cardWidth,
                              child: _AmenityItem(badge: a.$1, text: a.$2),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // ====== Amenity Gallery ======
                const SectionHeader(
                  title: 'Amenity Gallery',
                  subtitle: 'See What Awaits',
                ),
                LayoutBuilder(
                  builder: (context, c) {
                    final width = c.maxWidth;
                    final cols = width < 560
                        ? 1
                        : (width < 900 ? 2 : (width < 1200 ? 3 : 4));
                    const spacing = 16.0;
                    final itemW = (width - (cols - 1) * spacing) / cols;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: gallery
                          .map<Widget>(
                            (g) => SizedBox(
                              width: itemW,
                              child: _AmenityCard(media: g),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // ====== Services & Facilities ======
                const SectionHeader(
                  title: 'Services & Facilities',
                  subtitle: 'Everything You Need — Seamlessly',
                ),
                LayoutBuilder(
                  builder: (context, c) {
                    final width = c.maxWidth;
                    final cols = width < 560 ? 1 : (width < 900 ? 2 : 3);
                    const spacing = 16.0;
                    final itemW = (width - (cols - 1) * spacing) / cols;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: specs
                          .map<Widget>(
                            (s) => SizedBox(
                              width: itemW,
                              child: _SpecTile(spec: s),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- Data models ----------------------------- */
class _AmenityMedia {
  final String title;
  final String subtitle;
  final String asset;
  const _AmenityMedia({
    required this.title,
    required this.subtitle,
    required this.asset,
  });
}

// Renamed to avoid hot-reload const-class conflict
class _AmenitySpec {
  final IconData icon;
  final String title;
  final String body;
  const _AmenitySpec(this.icon, this.title, this.body);
}

/* ----------------------------- Widgets ----------------------------- */

class _AmenityItem extends StatefulWidget {
  final String badge, text;
  const _AmenityItem({required this.badge, required this.text});

  @override
  State<_AmenityItem> createState() => _AmenityItemState();
}

class _AmenityItemState extends State<_AmenityItem> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(0, hover ? -4 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(hover ? 0.12 : 0.08),
              blurRadius: hover ? 35 : 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [AppColors.lightBlue, AppColors.accentBlue],
                ),
              ),
              child: Text(
                widget.badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmenityCard extends StatefulWidget {
  final _AmenityMedia media;
  const _AmenityCard({required this.media});

  @override
  State<_AmenityCard> createState() => _AmenityCardState();
}

class _AmenityCardState extends State<_AmenityCard> {
  bool hover = false;

  void _openViewer() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.7,
                maxScale: 3,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    widget.media.asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.bgLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 42,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.45),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: _openViewer,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          transform: Matrix4.identity()
            ..translate(0.0, hover ? -6.0 : 0.0)
            ..scale(hover ? 1.01 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (hover)
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Image
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset(
                  widget.media.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.bgLight,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
              // Gradient overlay + text
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.media.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.media.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Subtle tap hint
              Positioned(
                right: 10,
                top: 10,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: hover ? 1 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.open_in_full_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'View',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
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

class _SpecTile extends StatelessWidget {
  final _AmenitySpec spec;
  const _SpecTile({required this.spec});

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Icon(spec.icon, color: AppColors.accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spec.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
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
