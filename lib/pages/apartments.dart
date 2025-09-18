part of lilium;

class ApartmentsPage extends StatelessWidget {
  const ApartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 700;
    final isTablet = size.width >= 700 && size.width < 1200;

    // extra top offset so content starts a little lower than the fixed header
    final extraTop = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: EdgeInsets.only(
        top: extraTop, // ↓ pushed below app bar
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
        bottom: isMobile ? 40 : 80,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F23), Color(0xFF1A1A3A), Color(0xFF2A2A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(narrow: isMobile),
              SizedBox(height: isMobile ? 32 : 48),

              // Live data only (no seed/dummy)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('apartments')
                    .orderBy('type')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _LoadingState();
                  }

                  if (snap.hasError) {
                    return _ErrorState(message: '${snap.error}');
                  }

                  final docs = snap.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const _EmptyState();
                  }

                  final items = docs
                      .map((d) => ApartmentData.fromDoc(d))
                      .toList();

                  return _ApartmentGrid(items: items, screenWidth: size.width);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------- Header ---------------------------- */

class _Header extends StatelessWidget {
  final bool narrow;
  const _Header({required this.narrow});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, t, _) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: Opacity(
            opacity: t,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'PREMIUM COLLECTION',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: narrow ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: narrow ? 14 : 18),
                Text(
                  'Luxury Apartments',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: narrow ? 26 : 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: narrow ? 8 : 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(
                    'Discover our collection of meticulously designed residences, each crafted to blend luxury, comfort, and modern living.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: narrow ? 13.5 : 15.5,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* --------------------------- States ---------------------------- */

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withOpacity(0.1),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading apartments…',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          children: const [
            Icon(Icons.apartment_outlined, color: Colors.white70, size: 36),
            SizedBox(height: 12),
            Text(
              'No apartments available yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Please check back soon or contact our sales team for upcoming releases.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
      child: Text(
        'Error loading apartments: $message',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

/* --------------------------- Grid ----------------------------- */

class _ApartmentGrid extends StatelessWidget {
  final List<ApartmentData> items;
  final double screenWidth;
  const _ApartmentGrid({required this.items, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1200;

    // Responsive columns & ratios tuned to avoid overflow
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    final childAspectRatio = isMobile ? 0.78 : (isTablet ? 0.82 : 0.86);

    final crossSpacing = isMobile ? 0.0 : 24.0;
    const mainSpacing = 24.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 500 + (i * 80)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, t, _) {
            return Transform.translate(
              offset: Offset(0, 36 * (1 - t)),
              child: Opacity(
                opacity: t,
                child: _EnhancedApartmentCard(
                  data: item,
                  onViewDetails: () {
                    Navigator.of(
                      context,
                    ).pushNamed('/apartment', arguments: item);
                  },
                  onBook: () => _openBooking(context, item),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Booking dialog
  Future<void> _openBooking(BuildContext context, ApartmentData apt) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final note = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.event_available,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Book Apartment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Snapshot
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apt.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${apt.subtitle} • ${apt.bedLabel} • ${apt.sqft} sft',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if ((apt.priceText ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                apt.priceText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Field(
                            controller: name,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: phone,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            required: true,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: email,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: note,
                            label: 'Message or Special Requirements',
                            icon: Icons.message_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 22),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.3),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: () async {
                                    if (!(formKey.currentState?.validate() ??
                                        false))
                                      return;

                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .add({
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                            'name': name.text.trim(),
                                            'phone': phone.text.trim(),
                                            'email': email.text.trim(),
                                            'note': note.text.trim(),
                                            'apartmentId': apt.id,
                                            'type': apt.type,
                                            'subtitle': apt.subtitle,
                                            'sqft': apt.sqft,
                                            'bedLabel': apt.bedLabel,
                                            'features': apt.features,
                                            'priceText': apt.priceText,
                                            'status': 'new',
                                          });

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Booking submitted successfully!',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    backgroundColor: AppColors.accentBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Submit Booking',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

/* ------------------------- Text Field -------------------------- */

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (v) => (required && (v == null || v.trim().isEmpty))
          ? '$label is required'
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.accentBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}

/* ======================= Data Model ========================== */
class ApartmentData {
  final String id;
  final String type;
  final String subtitle;
  final int sqft;
  final String bedLabel;
  final String features;
  final String? priceText;
  final String? cardImageUrl;
  final String? longDetail;
  final List<String> galleryUrls;
  final bool isLocalSeed;

  ApartmentData({
    required this.id,
    required this.type,
    required this.subtitle,
    required this.sqft,
    required this.bedLabel,
    required this.features,
    required this.priceText,
    required this.cardImageUrl,
    required this.longDetail,
    required this.galleryUrls,
    required this.isLocalSeed,
  });

  factory ApartmentData.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return ApartmentData(
      id: d.id,
      type: m['type'] ?? '',
      subtitle: m['subtitle'] ?? '',
      sqft: (m['sqft'] ?? 0) is int
          ? (m['sqft'] ?? 0)
          : int.tryParse('${m['sqft']}') ?? 0,
      bedLabel: m['bedLabel'] ?? '',
      features: m['features'] ?? '',
      priceText: m['priceText'],
      cardImageUrl: m['cardImageUrl'],
      longDetail: m['longDetail'],
      galleryUrls:
          (m['galleryUrls'] as List?)?.map((e) => '$e').toList() ?? const [],
      isLocalSeed: false,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'subtitle': subtitle,
    'sqft': sqft,
    'bedLabel': bedLabel,
    'features': features,
    'priceText': priceText,
    'cardImageUrl': cardImageUrl,
    'longDetail': longDetail,
    'galleryUrls': galleryUrls,
  };
}

/* ======================= Card UI ============================= */
class _EnhancedApartmentCard extends StatefulWidget {
  final ApartmentData data;
  final VoidCallback onViewDetails;
  final VoidCallback onBook;

  const _EnhancedApartmentCard({
    required this.data,
    required this.onViewDetails,
    required this.onBook,
  });

  @override
  State<_EnhancedApartmentCard> createState() => _EnhancedApartmentCardState();
}

class _EnhancedApartmentCardState extends State<_EnhancedApartmentCard>
    with TickerProviderStateMixin {
  bool hover = false;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 1.02,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  late final Animation<double> _lift = Tween(
    begin: 0.0,
    end: -12.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool v) {
    setState(() => hover = v);
    v ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Transform.scale(
          scale: _scale.value,
          child: Transform.translate(
            offset: Offset(0, _lift.value),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(hover ? 0.15 : 0.08),
                    blurRadius: hover ? 40 : 20,
                    offset: Offset(0, hover ? 20 : 10),
                  ),
                ],
              ),
              child: MouseRegion(
                onEnter: (_) => _onHover(true),
                onExit: (_) => _onHover(false),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CardHeader(d: d, hover: hover),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _Spec(
                                      value: d.sqft.toString(),
                                      label: 'Sq Ft',
                                      icon: Icons.square_foot_outlined,
                                      color: const Color(0xFF4F46E5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _Spec(
                                      value: d.bedLabel,
                                      label: 'Bedrooms',
                                      icon: Icons.bed_outlined,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Text(
                                  d.features,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.6,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if ((d.priceText ?? '').isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.accentBlue.withOpacity(0.1),
                                        AppColors.lightBlue.withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.accentBlue.withOpacity(
                                        0.3,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    d.priceText!,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.accentBlue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: widget.onViewDetails,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        side: const BorderSide(
                                          color: AppColors.accentBlue,
                                          width: 1.4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'VIEW DETAILS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: widget.onBook,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        backgroundColor: AppColors.accentBlue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'BOOK NOW',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardHeader extends StatelessWidget {
  final ApartmentData d;
  final bool hover;
  const _CardHeader({required this.d, required this.hover});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentBlue, AppColors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((d.cardImageUrl ?? '').isNotEmpty)
            Image.network(
              d.cardImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.accentBlue.withOpacity(0.3)),
            ),
          // overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.30),
                  Colors.transparent,
                  Colors.black.withOpacity(0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // bottom texts
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // hover hint
          AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: hover ? 1 : 0,
            child: Container(
              color: AppColors.accentBlue.withOpacity(0.18),
              child: const Center(
                child: Icon(
                  Icons.visibility_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------- Spec Tile -------------------------- */

class _Spec extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _Spec({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
