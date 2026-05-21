import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/kalaam_model.dart';
import '../providers/kalaam_provider.dart';

// ─── Brand tokens (theme-invariant) ─────────────────────────────────────────
const _kTeal = Color(0xFF234547);
const _kOrange = Color(0xFFFDA944);
const _kOrangeGrad1 = Color(0xFFFDA43F);
const _kOrangeGrad2 = Color(0xFFFDBA55);
const _kInkMutedNeutral = Color(0xFFA0A0A0);

// Field & body constraints from the Figma frame.
const int _kTitleMaxChars = 30;
const int _kPoetMaxChars = 40;
const int _kBodyMaxChars = 300;

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
    final bool success;
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
      success = await provider.addKalaam(
        title: title,
        content: content,
        category: category,
        isPublic: _isPublic,
        poet: poet,
        tags: _baseTags,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      _showSnack(_isEditing ? 'Kalaam updated' : 'Kalaam created');
      Navigator.pop(context);
    } else {
      _showSnack('Failed to save. Please try again.', isError: true);
    }
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
    final length = controller.text.characters.length;
    final remaining = _kTitleMaxChars - length;
    final counterColor = remaining <= 0
        ? Colors.redAccent
        : (remaining <= 5 ? _kOrange : palette.textMuted);

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
            maxLength: _kTitleMaxChars,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_kTitleMaxChars),
            ],
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
              suffix: Text(
                '$length/$_kTitleMaxChars',
                style: TextStyle(
                  fontSize: 12,
                  color: counterColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
    final length = controller.text.characters.length;
    final remaining = _kBodyMaxChars - length;
    final counterColor = remaining <= 0
        ? Colors.redAccent
        : (remaining <= 5 ? _kOrange : palette.textMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Your Kalaam'),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 180,
          decoration: _fieldDecoration(context, focused: focusNode.hasFocus),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLength: _kBodyMaxChars,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_kBodyMaxChars),
                  ],
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
              Positioned(
                right: 14,
                bottom: 10,
                child: Text(
                  '$length/$_kBodyMaxChars',
                  style: TextStyle(
                    fontSize: 12,
                    color: counterColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
