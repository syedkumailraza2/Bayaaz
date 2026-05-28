import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/kalaam_model.dart';
import '../providers/kalaam_provider.dart';
import '../services/offline_sync_service.dart';
import '../services/reference_audio_service.dart';

// ─── Brand tokens (theme-invariant) ─────────────────────────────────────────
const _kTeal = Color(0xFF234547);
const _kOrangeGrad1 = Color(0xFFFDA43F);
const _kOrangeGrad2 = Color(0xFFFDBA55);
const _kInkMutedNeutral = Color(0xFFA0A0A0);

const int _kPoetMaxChars = 40;

// Theme-aware palette — mirrors the home_screen palette so the surfaces
// align across the app.
class _Palette {
  final bool isDark;
  const _Palette._(this.isDark);
  factory _Palette.of(BuildContext c) =>
      _Palette._(Theme.of(c).brightness == Brightness.dark);

  Color get pageBg => isDark ? const Color(0xFF0A0A0A) : Colors.white;
  Color get sheetBg => isDark ? const Color(0xFF161616) : Colors.white;
  Color get surfaceMuted =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get textBody =>
      isDark ? const Color(0xFFE8E8E8) : const Color(0xFF303030);
  Color get textSecondary =>
      isDark ? const Color(0xFFCFCFCF) : const Color(0xFF545454);
  Color get textMuted => _kInkMutedNeutral;
  Color get ctaBg => isDark ? const Color(0xFF2E5B5E) : _kTeal;
  Color get focusBorder => isDark ? const Color(0xFF3B7178) : _kTeal;
  Color get sheetHandle =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E2E2);
}

class AddKalaamScreen extends StatefulWidget {
  final KalaamModel? existing;
  const AddKalaamScreen({super.key, this.existing});

  @override
  State<AddKalaamScreen> createState() => _AddKalaamScreenState();
}

class _AddKalaamScreenState extends State<AddKalaamScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _poetController = TextEditingController();
  final _bodyController = TextEditingController();
  final _titleFocus = FocusNode();
  final _poetFocus = FocusNode();
  final _bodyFocus = FocusNode();

  String? _category;
  bool _isPublic = true;
  bool _submitting = false;

  // Final once `didChangeDependencies` has seen the route arguments. We
  // can't compute this in `initState` because the `/edit` route hands the
  // kalaam in via `ModalRoute.settings.arguments`, which isn't readable
  // until `didChangeDependencies` runs.
  String? _refTempId;
  bool _refReady = false;

  // Existing tag list is preserved verbatim on edit so we don't lose any
  // taxonomy the user (or a future feature) attached on the server side.
  List<String> _baseTags = const [];

  late final AnimationController _entryController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _formFade;
  late final List<Animation<double>> _fieldAnims;

  bool _prefilled = false;

  KalaamModel? get _existing =>
      widget.existing ??
      ModalRoute.of(context)?.settings.arguments as KalaamModel?;

  bool get _isEditing => _existing != null;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _formFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    _headerFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    // Four fields, each on a 60 ms (≈0.086 of 700 ms) staggered offset
    // starting at 200 ms (≈0.286): title → type → poet → body.
    _fieldAnims = List.generate(4, (i) {
      final start = 0.28 + i * 0.086;
      final end = (start + 0.22).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entryController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    // Repaint when the focus changes so the AnimatedContainer borders update.
    _titleFocus.addListener(() => setState(() {}));
    _poetFocus.addListener(() => setState(() {}));
    _bodyFocus.addListener(() => setState(() {}));

    _titleController.addListener(() => setState(() {}));
    _poetController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    final existing = _existing;

    // Resolve the reference-audio key NOW: on the /edit route the kalaam
    // arrives via ModalRoute arguments, which `initState` can't see. If we
    // initialise the tempId there we'd hand a fresh UUID to the reference
    // section and the picked file would be persisted under that UUID
    // forever — invisible to the practice screen which looks up the real
    // kalaam id.
    _refTempId = existing?.id ?? const Uuid().v4();

    if (existing == null) {
      _prefilled = true;
      return;
    }
    _titleController.text = existing.title;
    _poetController.text = existing.poet ?? '';
    _bodyController.text = existing.content
        .map((s) => s.lines.join('\n'))
        .join('\n\n');
    _category = existing.category;
    _isPublic = existing.isPublic;
    _baseTags = List<String>.from(existing.tags);
    _prefilled = true;
  }

  @override
  void dispose() {
    _entryController.dispose();
    _titleController.dispose();
    _poetController.dispose();
    _bodyController.dispose();
    _titleFocus.dispose();
    _poetFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  // Split the body on blank lines into Stanza-shaped payloads.
  List<Map<String, dynamic>> _buildContent() {
    final text = _bodyController.text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (text.isEmpty) return const [];

    final chunks = text
        .split(RegExp(r'\n[ \t]*\n+'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final stanzas = <Map<String, dynamic>>[];
    for (final chunk in chunks) {
      final lines = chunk
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;
      stanzas.add({'stanzaNumber': stanzas.length + 1, 'lines': lines});
    }
    return stanzas;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Please enter a title', isError: true);
      return;
    }
    final content = _buildContent();
    if (content.isEmpty) {
      _showSnack('Please write your kalaam', isError: true);
      return;
    }

    setState(() => _submitting = true);

    final poetRaw = _poetController.text.trim();
    final poet = poetRaw.isEmpty ? null : poetRaw;
    final category = _category ?? kKalaamCategories.first;

    final provider = context.read<KalaamProvider>();
    final existing = _existing;
    bool success;
    KalaamModel? created;

    if (existing != null) {
      success = await provider.updateKalaam(
        id: existing.id,
        title: title,
        content: content,
        category: category,
        isPublic: _isPublic,
        poet: poet,
        tags: _baseTags,
      );
    } else {
      created = await provider.addKalaam(
        title: title,
        content: content,
        category: category,
        isPublic: _isPublic,
        poet: poet,
        tags: _baseTags,
      );
      success = created != null;
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      // Link the reference audio temp record to the real kalaam id.
      // Create: `_refTempId` is a fresh UUID; the new server-assigned id is
      //   on `created`.
      // Edit:  `_refTempId` should already equal `existing.id` (resolved in
      //   `didChangeDependencies`), so this is a no-op fallback — but we
      //   still call it in case the section was mounted with a UUID before
      //   args resolved (route races, hot reload, etc.).
      final tempId = _refTempId;
      final realId = created?.id ?? existing?.id;
      if (_refReady && tempId != null && realId != null) {
        if (tempId != realId) {
          await ReferenceAudioService.instance.linkToKalaam(
            tempId: tempId,
            realId: realId,
          );
        }
        // Push the local file up to the server so anyone else opening this
        // kalaam on another device can fetch and follow-voice off it.
        // Fire-and-forget: failure (offline / 5xx) doesn't block the save —
        // OfflineSyncService will retry on the next reconnect.
        unawaited(_syncReferenceUp(realId, provider));
      }
      if (!mounted) return;
      _showSnack(_isEditing ? 'Kalaam updated' : 'Kalaam created');
      Navigator.pop(context);
    } else {
      _showSnack('Failed to save. Please try again.', isError: true);
    }
  }

  Future<void> _syncReferenceUp(
    String kalaamId,
    KalaamProvider provider,
  ) async {
    final updated =
        await ReferenceAudioService.instance.uploadToServer(kalaamId);
    if (updated == null) {
      // Couldn't push right now (likely offline). Queue it so the offline
      // sync drain retries when the app comes back online.
      await OfflineSyncService.instance.stashPendingReferenceUpload(kalaamId);
      return;
    }
    provider.applyServerKalaam(updated);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _Palette.of(context).ctaBg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Scaffold(
      backgroundColor: palette.pageBg,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: FadeTransition(
                opacity: _formFade,
                child: SlideTransition(
                  position: _formSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ───────────────────────────────────────────
                      FadeTransition(
                        opacity: _headerFade,
                        child: _Header(isEditing: _isEditing),
                      ),
                      const SizedBox(height: 28),

                      // ── Field 1: Title ───────────────────────────────────
                      _StaggeredField(
                        animation: _fieldAnims[0],
                        child: _TitleField(
                          controller: _titleController,
                          focusNode: _titleFocus,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Field 2: Kalaam Type ─────────────────────────────
                      _StaggeredField(
                        animation: _fieldAnims[1],
                        child: _DropdownField(
                          label: 'Kalaam Type',
                          placeholder: 'Select kalaam type',
                          value: _category == null
                              ? null
                              : _capitalise(_category!),
                          onTap: _openCategorySheet,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Field 3: Poet (text input) ───────────────────────
                      _StaggeredField(
                        animation: _fieldAnims[2],
                        child: _PoetField(
                          controller: _poetController,
                          focusNode: _poetFocus,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Field 4: Your Kalaam (multiline) ─────────────────
                      _StaggeredField(
                        animation: _fieldAnims[3],
                        child: _BodyField(
                          controller: _bodyController,
                          focusNode: _bodyFocus,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Visibility toggle (preserved behaviour) ──────────
                      _VisibilityRow(
                        isPublic: _isPublic,
                        onChanged: (v) => setState(() => _isPublic = v),
                      ),

                      const SizedBox(height: 20),

                      // ── Reference media (optional) ───────────────────────
                      // `_refTempId` is set in didChangeDependencies once
                      // ModalRoute args are visible; the section needs a
                      // stable id for the lifetime of the screen.
                      _ReferenceMediaSection(
                        tempId: _refTempId ?? '',
                        onStateChanged: (ready) =>
                            setState(() => _refReady = ready),
                      ),

                      const SizedBox(height: 20),

                      // ── Submit button ────────────────────────────────────
                      _SubmitButton(
                        label: _isEditing ? 'Save Changes' : 'Create Kalaam',
                        loading: _submitting,
                        onPressed: _submit,
                      ),

                      const SizedBox(height: 16),

                      // ── Back pill ────────────────────────────────────────
                      _BackPill(onTap: () => Navigator.pop(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom sheets ─────────────────────────────────────────────────────────

  Future<void> _openCategorySheet() async {
    FocusScope.of(context).unfocus();
    final picked = await _showOptionSheet(
      title: 'Kalaam Type',
      options: kKalaamCategories
          .map((c) => _SheetOption(value: c, label: _capitalise(c)))
          .toList(),
      selected: _category,
    );
    if (picked != null) setState(() => _category = picked);
  }

  Future<String?> _showOptionSheet({
    required String title,
    required List<_SheetOption> options,
    required String? selected,
  }) {
    final palette = _Palette.of(context);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: palette.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final p = _Palette.of(ctx);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.sheetHandle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: p.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ...options.map((opt) {
                  final isSelected = selected == opt.value;
                  return InkWell(
                    onTap: () => Navigator.pop(ctx, opt.value),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 15,
                                color: p.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_rounded,
                                color: p.focusBorder, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _SheetOption {
  final String value;
  final String label;
  const _SheetOption({required this.value, required this.label});
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isEditing;
  const _Header({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Column(
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kOrangeGrad1, _kOrangeGrad2],
          ).createShader(rect),
          child: const Text(
            'بیاض',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 36,
              height: 1.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isEditing ? 'Edit Kalaam' : 'Create New Kalaam',
          style: TextStyle(
            fontSize: 22,
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

// ─── Staggered wrapper used per field ───────────────────────────────────────

class _StaggeredField extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _StaggeredField({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
    );
  }
}

// ─── Field shell (label + body) ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

BoxDecoration _fieldDecoration(BuildContext context, {required bool focused}) {
  final palette = _Palette.of(context);
  return BoxDecoration(
    color: palette.surfaceMuted,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: focused ? palette.focusBorder : Colors.transparent,
      width: 1.4,
    ),
  );
}

// ─── Title field ────────────────────────────────────────────────────────────

class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const _TitleField({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Kalaam Title'),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 54,
          decoration: _fieldDecoration(context, focused: focusNode.hasFocus),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              fontSize: 15,
              color: palette.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              hintText: 'Enter kalaam title',
              hintStyle: TextStyle(
                fontSize: 15,
                color: palette.textMuted,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              counterText: '',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Title is required';
              return null;
            },
          ),
        ),
      ],
    );
  }
}

// ─── Dropdown field (kalaam type) ───────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final String placeholder;
  final String? value;
  final VoidCallback onTap;

  const _DropdownField({
    required this.label,
    required this.placeholder,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final hasValue = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 54,
            decoration: _fieldDecoration(context, focused: false),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    style: TextStyle(
                      fontSize: 15,
                      color: hasValue ? palette.textPrimary : palette.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: palette.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Poet field (replaces the Prophet dropdown) ─────────────────────────────

class _PoetField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const _PoetField({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Poet'),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 54,
          decoration: _fieldDecoration(context, focused: focusNode.hasFocus),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLength: _kPoetMaxChars,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_kPoetMaxChars),
            ],
            textInputAction: TextInputAction.next,
            style: TextStyle(
              fontSize: 15,
              color: palette.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              hintText: 'Enter poet name',
              hintStyle: TextStyle(
                fontSize: 15,
                color: palette.textMuted,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              counterText: '',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: palette.textSecondary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Body field (Your Kalaam) ───────────────────────────────────────────────

class _BodyField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const _BodyField({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Your Kalaam'),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 180),
          decoration: _fieldDecoration(context, focused: focusNode.hasFocus),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: null,
            minLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: TextStyle(
              fontSize: 14,
              color: palette.textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              hintText: 'Write your kalaam here',
              hintStyle: TextStyle(
                fontSize: 14,
                color: palette.textMuted,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Visibility row (preserved behaviour) ───────────────────────────────────

class _VisibilityRow extends StatelessWidget {
  final bool isPublic;
  final ValueChanged<bool> onChanged;
  const _VisibilityRow({required this.isPublic, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock_outline,
            size: 18,
            color: isPublic ? palette.focusBorder : palette.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            'Make public',
            style: TextStyle(
              fontSize: 14,
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Switch(
            value: isPublic,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: palette.ctaBg,
            inactiveTrackColor:
                palette.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E2E2),
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

// ─── Submit button ──────────────────────────────────────────────────────────

class _SubmitButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.ctaBg,
            borderRadius: BorderRadius.circular(40),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: widget.loading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    key: const ValueKey('label'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Back pill ──────────────────────────────────────────────────────────────

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded,
                  size: 18, color: palette.textPrimary),
              const SizedBox(width: 6),
              Text(
                'Back',
                style: TextStyle(
                  fontSize: 14,
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reference Media Section ─────────────────────────────────────────────────

enum _RefState { idle, processing, ready, error }

class _ReferenceMediaSection extends StatefulWidget {
  final String tempId;
  final void Function(bool ready) onStateChanged;

  const _ReferenceMediaSection({
    required this.tempId,
    required this.onStateChanged,
  });

  @override
  State<_ReferenceMediaSection> createState() => _ReferenceMediaSectionState();
}

class _ReferenceMediaSectionState extends State<_ReferenceMediaSection> {
  _RefState _state = _RefState.idle;
  bool _showYoutubeInput = false;
  final _urlController = TextEditingController();
  String _displayName = '';
  String _duration = '';
  String _error = '';
  double? _downloadProgress;
  bool _isConnecting = false;
  String _fetchStatus = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return '–';
    final total = ms ~/ 1000;
    final m = total ~/ 60;
    final s = total % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  Future<void> _process(
    File source,
    String sourceType, {
    String? sourceUrl,
    required String displayName,
    String? extension,
  }) async {
    setState(() {
      _state = _RefState.processing;
      _error = '';
    });
    try {
      final svc = ReferenceAudioService.instance;
      final filePath = await svc.extractAndNormalize(
        source,
        widget.tempId,
        extension: extension,
      );
      final durationMs = await svc.getFileDurationMs(filePath);
      await svc.saveReference(
        kalaamId: widget.tempId,
        wavPath: filePath,
        sourceType: sourceType,
        sourceUrl: sourceUrl,
        durationMs: durationMs,
      );
      setState(() {
        _state = _RefState.ready;
        _displayName = displayName;
        _duration = _formatDuration(durationMs);
      });
      widget.onStateChanged(true);
    } catch (_) {
      setState(() {
        _state = _RefState.error;
        _error = 'Processing failed. Try a different file.';
      });
      widget.onStateChanged(false);
    }
  }

  Future<void> _handleAudioFile() async {
    final picked = await ReferenceAudioService.instance.pickAudioFile();
    if (picked == null) return;
    await _process(
      picked.file,
      'audio_file',
      displayName: picked.file.path.split('/').last,
      extension: picked.extension,
    );
  }

  Future<void> _handleVideoFile() async {
    final picked = await ReferenceAudioService.instance.pickVideoFile();
    if (picked == null) return;
    await _process(
      picked.file,
      'video_file',
      displayName: picked.file.path.split('/').last,
      extension: picked.extension,
    );
  }

  Future<void> _handleYouTubeImport() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _state = _RefState.processing;
      _downloadProgress = null;
      _isConnecting = true;
      _fetchStatus = 'Resolving stream…';
      _error = '';
    });
    try {
      final result = await ReferenceAudioService.instance.fetchYouTubeAudio(
        url,
        onStatus: (s) {
          if (mounted) setState(() => _fetchStatus = s);
        },
        onProgress: (p) {
          if (mounted) setState(() { _downloadProgress = p; _isConnecting = false; });
        },
      );
      if (result == null) throw Exception('Invalid URL');
      setState(() { _downloadProgress = null; _isConnecting = false; });
      final svc = ReferenceAudioService.instance;
      final filePath = await svc.extractAndNormalize(result.file, widget.tempId);
      final durationMs = result.durationMs > 0
          ? result.durationMs
          : await svc.getFileDurationMs(filePath);
      await svc.saveReference(
        kalaamId: widget.tempId,
        wavPath: filePath,
        sourceType: 'youtube',
        sourceUrl: url,
        durationMs: durationMs,
      );
      setState(() {
        _state = _RefState.ready;
        _displayName = 'YouTube Audio';
        _duration = _formatDuration(durationMs);
      });
      widget.onStateChanged(true);
    } catch (_) {
      setState(() {
        _state = _RefState.error;
        _downloadProgress = null;
        _isConnecting = false;
        _error = 'Could not fetch YouTube audio. Check the URL.';
      });
      widget.onStateChanged(false);
    }
  }

  Future<void> _clear() async {
    await ReferenceAudioService.instance.deleteReference(widget.tempId);
    setState(() {
      _state = _RefState.idle;
      _displayName = '';
      _duration = '';
      _error = '';
      _showYoutubeInput = false;
      _urlController.clear();
    });
    widget.onStateChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _FieldLabel('Reference Audio'),
            const SizedBox(width: 6),
            Text(
              'optional',
              style: TextStyle(
                fontSize: 11,
                color: palette.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _state == _RefState.ready
                  ? _kTeal.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: switch (_state) {
            _RefState.processing => _buildProcessing(palette),
            _RefState.ready => _buildReady(palette),
            _ => _buildIdle(palette),
          },
        ),
      ],
    );
  }

  Widget _buildIdle(_Palette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MediaButton(
              icon: Icons.audio_file_outlined,
              label: 'Audio',
              onTap: _handleAudioFile,
              palette: palette,
            ),
            const SizedBox(width: 8),
            _MediaButton(
              icon: Icons.video_file_outlined,
              label: 'Video',
              onTap: _handleVideoFile,
              palette: palette,
            ),
            const SizedBox(width: 8),
            _MediaButton(
              icon: Icons.play_circle_outline_rounded,
              label: 'YouTube',
              onTap: () =>
                  setState(() => _showYoutubeInput = !_showYoutubeInput),
              palette: palette,
              active: _showYoutubeInput,
            ),
          ],
        ),
        if (_showYoutubeInput) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.pageBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _urlController,
                    style: TextStyle(
                        fontSize: 13, color: palette.textPrimary),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: 'Paste YouTube URL',
                      hintStyle: TextStyle(
                          fontSize: 13, color: palette.textMuted),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _handleYouTubeImport,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: palette.ctaBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Import',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _error,
            style:
                const TextStyle(fontSize: 12, color: Colors.redAccent),
          ),
        ],
      ],
    );
  }

  Widget _buildProcessing(_Palette palette) {
    final progress = _downloadProgress;
    if (progress != null) {
      // progress >= 0: determinate (show %). progress < 0: indeterminate (size unknown).
      final isDeterminate = progress >= 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kTeal),
              ),
              const SizedBox(width: 10),
              Text(
                isDeterminate
                    ? 'Downloading… ${(progress * 100).toStringAsFixed(0)}%'
                    : 'Downloading…',
                style: TextStyle(fontSize: 13, color: palette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isDeterminate ? progress : null,
              minHeight: 4,
              backgroundColor: palette.pageBg,
              valueColor: const AlwaysStoppedAnimation(_kTeal),
            ),
          ),
        ],
      );
    }
    final label = _isConnecting
        ? (_fetchStatus.isNotEmpty ? _fetchStatus : 'Fetching audio…')
        : 'Processing audio…';
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kTeal),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: palette.textSecondary),
        ),
      ],
    );
  }

  Widget _buildReady(_Palette palette) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: _kTeal, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _duration,
                style: TextStyle(
                    fontSize: 11, color: palette.textSecondary),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _clear,
          child: Icon(Icons.close_rounded,
              size: 18, color: palette.textMuted),
        ),
      ],
    );
  }
}

// ─── Media source button ─────────────────────────────────────────────────────

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _Palette palette;
  final bool active;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.palette,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: active
                ? _kTeal.withValues(alpha: 0.1)
                : palette.pageBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? _kTeal.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: active ? _kTeal : palette.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? _kTeal : palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
