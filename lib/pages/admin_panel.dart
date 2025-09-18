part of lilium;

/// ✅ Admin Panel (Email/Password only)
/// Any user who can sign in with Firebase Authentication gets access.
/// No allow-list.
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  User? get _user => FirebaseAuth.instance.currentUser;

  // ===== Email/Password Auth State =====
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _authLoading = false;

  // Spacer so content doesn't hide under the overlay header
  double _headerOffset(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final safeTop = MediaQuery.of(context).padding.top; // safer across SDKs
    final isMobile = Breakpoints.isMobile(w);
    final isTablet = Breakpoints.isTablet(w);
    final bar = isMobile ? 2.0 : 3.0; // progress bar in header
    final header = isMobile ? 66.0 : (isTablet ? 74.0 : 82.0);
    return safeTop + bar + header + 6; // small buffer
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailPassword() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    setState(() => _authLoading = true);
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signed in successfully')));
      }
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
      if (mounted) setState(() => _authLoading = false);
    }
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email to reset password')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      final msg = _friendlyAuthError(e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signed out')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign-out failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep UI in sync with auth changes.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: _user,
      builder: (context, snap) {
        final signedIn = snap.data != null;

        return Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            top: _headerOffset(context), // keeps it below the floating header
            bottom: 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.settings_outlined,
                            color: AppColors.accentBlue,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Admin Panel',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (signedIn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: AppColors.accentBlue.withOpacity(0.08),
                                border: Border.all(
                                  color: AppColors.accentBlue.withOpacity(0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    size: 16,
                                    color: AppColors.accentBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    snap.data!.email ?? '',
                                    style: const TextStyle(
                                      color: AppColors.accentBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 10),
                          if (signedIn)
                            OutlinedButton.icon(
                              onPressed: _signOut,
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('Sign out'),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Gate
                    if (!signedIn)
                      _LoginCard(
                        formKey: _loginFormKey,
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        obscure: _obscure,
                        loading: _authLoading,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onSubmit: _signInWithEmailPassword,
                        onForgot: _sendReset,
                      )
                    else
                      const _AdminTabs(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;

  const _LoginCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: WhiteCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sign in with Email',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Email is required';
                    if (!t.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passCtrl,
                  obscureText: obscure,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: loading ? null : onForgot,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: loading ? null : onSubmit,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Any account that can sign in will access this panel.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTabs extends StatelessWidget {
  const _AdminTabs();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Pill-style tabs
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.lightBlue, AppColors.accentBlue],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(icon: Icon(Icons.apartment_outlined), text: 'Apartments'),
                Tab(icon: Icon(Icons.event_note_outlined), text: 'Bookings'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            height: 720, // keep bounded to avoid layout exceptions
            child: TabBarView(
              children: [_AdminApartmentsTab(), _AdminBookingsTab()],
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================= Apartments TAB ========================== */

class _AdminApartmentsTab extends StatefulWidget {
  const _AdminApartmentsTab();

  @override
  State<_AdminApartmentsTab> createState() => _AdminApartmentsTabState();
}

class _AdminApartmentsTabState extends State<_AdminApartmentsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top actions row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search apartments by type, subtitle…',
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Apartment'),
              onPressed: () => _AdminAptEditor.open(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('apartments')
                .orderBy('type')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snap.data?.docs ?? [];
              final q = _searchCtrl.text.trim().toLowerCase();
              if (q.isNotEmpty) {
                docs = docs.where((d) {
                  final m = d.data();
                  final t = (m['type'] ?? '').toString().toLowerCase();
                  final s = (m['subtitle'] ?? '').toString().toLowerCase();
                  return t.contains(q) || s.contains(q);
                }).toList();
              }
              if (docs.isEmpty) {
                return const Center(child: Text('No apartments found.'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final apt = ApartmentData.fromDoc(docs[i]);
                  return _AdminAptTile(apt: apt);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminAptTile extends StatelessWidget {
  final ApartmentData apt;
  const _AdminAptTile({required this.apt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 132,
              height: 88,
              child: (apt.cardImageUrl?.isNotEmpty ?? false)
                  ? Image.network(
                      apt.cardImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.bgLight,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textLight,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.bgLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.photo_outlined,
                        color: AppColors.textLight,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              runSpacing: 4,
              children: [
                Text(
                  apt.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  apt.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(label: apt.bedLabel),
                    _Chip(label: '${apt.sqft} sft'),
                    if ((apt.priceText ?? '').isNotEmpty)
                      _Chip.highlight(label: apt.priceText!),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => _AdminAptEditor.open(context, existing: apt),
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final ok =
                      await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete apartment?'),
                          content: Text(
                            'This will permanently remove “${apt.type}”.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (!ok) return;

                  await FirebaseFirestore.instance
                      .collection('apartments')
                      .doc(apt.id)
                      .delete();
                  // (Optional) Storage cleanup should be done with a Cloud Function.
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed('/apartment', arguments: apt),
                child: const Text('Open'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ====================== Editor Dialog ======================= */

class _AdminAptEditor extends StatefulWidget {
  final ApartmentData? existing;
  const _AdminAptEditor({this.existing});

  static Future<void> open(BuildContext context, {ApartmentData? existing}) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: SizedBox(
          width: 640,
          child: _AdminAptEditor(existing: existing),
        ),
      ),
    );
  }

  @override
  State<_AdminAptEditor> createState() => _AdminAptEditorState();
}

class _AdminAptEditorState extends State<_AdminAptEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _type = TextEditingController(
    text: widget.existing?.type ?? '',
  );
  late final TextEditingController _subtitle = TextEditingController(
    text: widget.existing?.subtitle ?? '',
  );
  late final TextEditingController _sqft = TextEditingController(
    text: widget.existing?.sqft.toString() ?? '',
  );
  late final TextEditingController _bed = TextEditingController(
    text: widget.existing?.bedLabel ?? '',
  );
  late final TextEditingController _features = TextEditingController(
    text: widget.existing?.features ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.existing?.priceText ?? '',
  );
  late final TextEditingController _long = TextEditingController(
    text: widget.existing?.longDetail ?? '',
  );

  // URLs (prefilled if editing) – all null-safe
  late final TextEditingController _cardUrl = TextEditingController(
    text: widget.existing?.cardImageUrl ?? '',
  );
  late final TextEditingController _g1 = TextEditingController(
    text: (widget.existing?.galleryUrls.isNotEmpty ?? false)
        ? widget.existing!.galleryUrls[0]
        : '',
  );
  late final TextEditingController _g2 = TextEditingController(
    text: ((widget.existing?.galleryUrls.length ?? 0) > 1)
        ? widget.existing!.galleryUrls[1]
        : '',
  );
  late final TextEditingController _g3 = TextEditingController(
    text: ((widget.existing?.galleryUrls.length ?? 0) > 2)
        ? widget.existing!.galleryUrls[2]
        : '',
  );

  // Bytes when uploading from device
  Uint8List? _cardBytes;
  String? _cardName;
  Uint8List? _g1Bytes;
  String? _g1Name;
  Uint8List? _g2Bytes;
  String? _g2Name;
  Uint8List? _g3Bytes;
  String? _g3Name;

  bool _saving = false;

  @override
  void dispose() {
    _type.dispose();
    _subtitle.dispose();
    _sqft.dispose();
    _bed.dispose();
    _features.dispose();
    _price.dispose();
    _long.dispose();
    _cardUrl.dispose();
    _g1.dispose();
    _g2.dispose();
    _g3.dispose();
    super.dispose();
  }

  Future<void> _pick(void Function(Uint8List, String) assign) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final f = res?.files.single;
    if (f?.bytes != null) {
      assign(f!.bytes!, f.name);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _saving,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              widget.existing == null ? 'Add Apartment' : 'Edit Apartment',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _fText(
                    _type,
                    'Type / Code (e.g., ROYAL (X04))',
                    requiredField: true,
                  ),
                  _fText(
                    _subtitle,
                    'Subtitle (e.g., 2 Bedroom Luxury Residence)',
                    requiredField: true,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _fText(
                          _sqft,
                          'Square Feet',
                          requiredField: true,
                          inputType: TextInputType.number,
                          positiveNumber: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _fText(
                          _bed,
                          'Bedrooms Label (e.g., 2 BR)',
                          requiredField: true,
                        ),
                      ),
                    ],
                  ),
                  _fText(_features, 'Features (short list)', maxLines: 3),
                  _fText(_price, 'Price Text'),
                  const SizedBox(height: 8),

                  // Card image
                  _slot(
                    label: 'Card Image',
                    bytes: _cardBytes,
                    urlCtrl: _cardUrl,
                    onPick: () => _pick((b, n) {
                      _cardBytes = b;
                      _cardName = n;
                      _cardUrl.clear();
                    }),
                  ),
                  const SizedBox(height: 16),

                  _fText(
                    _long,
                    'Long Detail (shown on details page)',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // Gallery 3 slots
                  Row(
                    children: [
                      Expanded(
                        child: _slot(
                          label: 'Gallery 1',
                          bytes: _g1Bytes,
                          urlCtrl: _g1,
                          onPick: () => _pick((b, n) {
                            _g1Bytes = b;
                            _g1Name = n;
                            _g1.clear();
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _slot(
                          label: 'Gallery 2',
                          bytes: _g2Bytes,
                          urlCtrl: _g2,
                          onPick: () => _pick((b, n) {
                            _g2Bytes = b;
                            _g2Name = n;
                            _g2.clear();
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _slot(
                          label: 'Gallery 3',
                          bytes: _g3Bytes,
                          urlCtrl: _g3,
                          onPick: () => _pick((b, n) {
                            _g3Bytes = b;
                            _g3Name = n;
                            _g3.clear();
                          }),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slot({
    required String label,
    required Uint8List? bytes,
    required TextEditingController urlCtrl,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload),
              label: const Text('Upload from device'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: urlCtrl,
                onChanged: (_) => setState(() {}), // live preview
                decoration: const InputDecoration(
                  hintText: '…or paste image URL',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 160,
          height: 100,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.bgLight,
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.cover)
              : (urlCtrl.text.isNotEmpty)
              ? Image.network(
                  urlCtrl.text,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textLight,
                    ),
                  ),
                )
              : const Center(child: Text('No image')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final col = FirebaseFirestore.instance.collection('apartments');
      final docRef = (widget.existing == null)
          ? col.doc()
          : col.doc(widget.existing!.id);

      // base fields
      await docRef.set({
        'type': _type.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'sqft': int.tryParse(_sqft.text.trim()) ?? 0,
        'bedLabel': _bed.text.trim(),
        'features': _features.text.trim(),
        'priceText': _price.text.trim(),
        'longDetail': _long.text.trim().isEmpty ? null : _long.text.trim(),
      }, SetOptions(merge: true));

      // Upload helpers
      String? cardUrl = _cardUrl.text.trim().isNotEmpty
          ? _cardUrl.text.trim()
          : widget.existing?.cardImageUrl;
      if (_cardBytes != null) {
        cardUrl = await _uploadBytes(
          'apartments/${docRef.id}/card_${DateTime.now().millisecondsSinceEpoch}_${_cardName ?? 'image'}',
          _cardBytes!,
          _guessContentType(_cardName),
        );
      }

      Future<String?> up(
        Uint8List? b,
        String? name,
        String urlText,
        int idx,
      ) async {
        if (b != null) {
          return await _uploadBytes(
            'apartments/${docRef.id}/gallery/${idx}_${DateTime.now().millisecondsSinceEpoch}_${name ?? 'image'}',
            b,
            _guessContentType(name),
          );
        }
        if (urlText.trim().isNotEmpty) return urlText.trim();
        return null;
      }

      final g1 = await up(_g1Bytes, _g1Name, _g1.text, 1);
      final g2 = await up(_g2Bytes, _g2Name, _g2.text, 2);
      final g3 = await up(_g3Bytes, _g3Name, _g3.text, 3);
      final newGallery = <String>[
        if (g1 != null) g1,
        if (g2 != null) g2,
        if (g3 != null) g3,
      ];

      // Merge rule: keep existing gallery if no new data provided.
      final update = <String, dynamic>{
        if (cardUrl != null) 'cardImageUrl': cardUrl,
      };
      if (newGallery.isNotEmpty || widget.existing == null) {
        update['galleryUrls'] = newGallery;
      }

      await docRef.set(update, SetOptions(merge: true));

      if (!mounted) return;

      // ✅ green success tick overlay
      _showSuccessCheck(context, label: 'Saved');

      // Optional toast
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Apartment saved')));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String> _uploadBytes(
    String path,
    Uint8List data,
    String? contentType,
  ) async {
    final ref = FirebaseStorage.instance.ref(path);
    final task = await ref.putData(
      data,
      SettableMetadata(contentType: contentType),
    );
    return task.ref.getDownloadURL();
  }

  String? _guessContentType(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/*';
  }

  Widget _fText(
    TextEditingController ctrl,
    String label, {
    bool requiredField = false,
    int maxLines = 1,
    TextInputType? inputType,
    bool positiveNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        maxLines: maxLines,
        validator: (v) {
          if (requiredField && (v == null || v.trim().isEmpty)) {
            return 'Required';
          }
          if (positiveNumber) {
            final t = (v ?? '').trim();
            final n = int.tryParse(t);
            if (n == null || n <= 0) return 'Enter a valid number';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/* ========================= Bookings TAB ========================== */

class _AdminBookingsTab extends StatefulWidget {
  const _AdminBookingsTab();

  @override
  State<_AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<_AdminBookingsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search bookings by name, phone, type…',
            isDense: true,
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snap.data?.docs ?? [];
              final q = _searchCtrl.text.trim().toLowerCase();
              if (q.isNotEmpty) {
                docs = docs.where((d) {
                  final m = d.data();
                  final name = (m['name'] ?? '').toString().toLowerCase();
                  final phone = (m['phone'] ?? '').toString().toLowerCase();
                  final type = (m['type'] ?? '').toString().toLowerCase();
                  return name.contains(q) ||
                      phone.contains(q) ||
                      type.contains(q);
                }).toList();
              }
              if (docs.isEmpty) {
                return const Center(child: Text('No bookings found.'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final m = d.data();
                  final status = (m['status'] ?? 'new') as String;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Buyer
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: AppColors.accentBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${m['name'] ?? ''} • ${m['phone'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _StatusChip(status: status),
                          ],
                        ),
                        if ((m['email'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${m['email']}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        if ((m['note'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${m['note']}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),
                        // Apartment snapshot
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _Chip(label: '${m['type'] ?? ''}'),
                              _Chip(label: '${m['subtitle'] ?? ''}'),
                              _Chip(label: '${m['bedLabel'] ?? ''}'),
                              _Chip(label: '${m['sqft'] ?? 0} sft'),
                              if ((m['priceText'] ?? '').toString().isNotEmpty)
                                _Chip.highlight(label: '${m['priceText']}'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            DropdownButtonHideUnderline(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.08),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.bgLight,
                                ),
                                child: DropdownButton<String>(
                                  value: status,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'new',
                                      child: Text('New'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'in_progress',
                                      child: Text('In Progress'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'won',
                                      child: Text('Won / Booked'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'lost',
                                      child: Text('Lost'),
                                    ),
                                  ],
                                  onChanged: (v) async {
                                    if (v == null) return;
                                    await d.reference.set({
                                      'status': v,
                                    }, SetOptions(merge: true));
                                  },
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                final ok =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete booking?'),
                                        content: const Text(
                                          'This will permanently remove this booking record.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton.tonal(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (!ok) return;
                                await d.reference.delete();
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ========================= Small UI Helpers ========================== */

class _Chip extends StatelessWidget {
  final String label;
  final bool highlighted;
  const _Chip({required this.label}) : highlighted = false;
  const _Chip.highlight({required this.label}) : highlighted = true;

  @override
  Widget build(BuildContext context) {
    if (highlighted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.lightBlue, AppColors.accentBlue],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _bg() {
    switch (status) {
      case 'won':
        return AppColors.lightBlue.withOpacity(0.18);
      case 'in_progress':
        return AppColors.accentBlue.withOpacity(0.14);
      case 'lost':
        return AppColors.textLight.withOpacity(0.18);
      default:
        return AppColors.bgLight;
    }
  }

  Color _fg() {
    switch (status) {
      case 'won':
        return AppColors.lightBlue;
      case 'in_progress':
        return AppColors.accentBlue;
      case 'lost':
        return AppColors.textLight;
      default:
        return AppColors.textSecondary;
    }
  }

  String _label() {
    switch (status) {
      case 'won':
        return 'Won / Booked';
      case 'in_progress':
        return 'In Progress';
      case 'lost':
        return 'Lost';
      default:
        return 'New';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _fg().withOpacity(0.22)),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          color: _fg(),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/* ---------------------- Success Tick Overlay ---------------------- */
void _showSuccessCheck(BuildContext context, {String? label}) {
  // `label` kept for backwards compatibility, but not shown.
  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: const Center(child: _SuccessCheck()),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1200), () {
    if (entry.mounted) entry.remove();
  });
}

class _SuccessCheck extends StatefulWidget {
  const _SuccessCheck();

  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<_SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);

    return AnimatedBuilder(
      animation: curve,
      builder: (_, __) {
        final v = curve.value; // may overshoot > 1
        final opacity = (v.clamp(0.0, 1.0)); // keep in [0,1]
        final scale = 0.90 + 0.10 * v; // subtle pop

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40, // smaller tick
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
