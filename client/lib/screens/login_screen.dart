import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../services/deep_link_service.dart';
import '../widgets/server_url_dialog.dart';

// ─── Brand tokens (theme-invariant) ─────────────────────────────────────────
const _kTeal = Color(0xFF234547);
const _kOrangeGrad1 = Color(0xFFFDA43F);
const _kOrangeGrad2 = Color(0xFFFDBA55);
const _kInkMutedNeutral = Color(0xFFA0A0A0);

// Theme-aware palette — mirrors home_screen / add_kalaam so the surfaces
// align across the app.
class _Palette {
  final bool isDark;
  const _Palette._(this.isDark);
  factory _Palette.of(BuildContext c) =>
      _Palette._(Theme.of(c).brightness == Brightness.dark);

  Color get pageBg => isDark ? const Color(0xFF0A0A0A) : Colors.white;
  Color get surfaceMuted =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);
  Color get tabTrackBg =>
      isDark ? const Color(0xFF161616) : const Color(0xFFF4F4F4);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get textBody =>
      isDark ? const Color(0xFFE8E8E8) : const Color(0xFF303030);
  Color get textSecondary =>
      isDark ? const Color(0xFFCFCFCF) : const Color(0xFF545454);
  Color get textMuted => _kInkMutedNeutral;
  Color get ctaBg => isDark ? const Color(0xFF2E5B5E) : _kTeal;
  Color get focusBorder => isDark ? const Color(0xFF3B7178) : _kTeal;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _nameFocus = FocusNode();
  bool _isRegister = false;
  bool _obscurePassword = true;

  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOut));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _nameFocus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().clearError();

    final auth = context.read<AuthProvider>();
    final bool success;

    if (_isRegister) {
      success = await auth.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
      // Redeem any invite link the user opened while logged out.
      unawaited(DeepLinkService.instance.consumePendingToken());
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final success = await auth.googleSignIn();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
      unawaited(DeepLinkService.instance.consumePendingToken());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final palette = _Palette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Hidden server-URL override (top-right corner). Highlighted
            // when the override is active so it's easy to confirm.
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Server URL',
                icon: Icon(
                  Icons.cloud_outlined,
                  color: AppConfig.isOverridden
                      ? _kOrangeGrad1
                      : palette.textMuted,
                ),
                onPressed: () async {
                  final changed = await showServerUrlDialog(context);
                  if (!context.mounted) return;
                  if (!changed) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Server URL updated. Restart the app to fully apply.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Center(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Brand wordmark (orange gradient, same as splash/home).
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
                                fontSize: 64,
                                height: 1.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -1.28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isRegister
                                ? 'Create your account'
                                : 'Welcome back',
                            style: TextStyle(
                              fontSize: 15,
                              color: palette.textBody,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Login / Register tab toggle.
                          _AuthTabToggle(
                            isRegister: _isRegister,
                            onSelect: (register) => setState(() {
                              _isRegister = register;
                              context.read<AuthProvider>().clearError();
                            }),
                          ),
                          const SizedBox(height: 20),

                          if (auth.error != null) ...[
                            _ErrorBanner(message: auth.error!),
                            const SizedBox(height: 14),
                          ],

                          if (_isRegister) ...[
                            _InputField(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              hint: 'Full name',
                              icon: Icons.person_outline,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Name is required'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                          ],

                          _InputField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            hint: 'Email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          _InputField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            obscure: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: palette.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (_isRegister && v.length < 6) {
                                return 'Minimum 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          _SubmitButton(
                            label: _isRegister ? 'Create Account' : 'Sign In',
                            loading: auth.loading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 16),
                          _GoogleSignInButton(
                            loading: auth.loading,
                            onPressed: _googleSignIn,
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
    );
  }
}

// ─── Auth tab toggle (Login / Register) ─────────────────────────────────────

class _AuthTabToggle extends StatelessWidget {
  final bool isRegister;
  final ValueChanged<bool> onSelect;

  const _AuthTabToggle({required this.isRegister, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.tabTrackBg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Login',
            selected: !isRegister,
            onTap: () => onSelect(false),
          ),
          _TabButton(
            label: 'Register',
            selected: isRegister,
            onTap: () => onSelect(true),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? palette.ctaBg : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: selected ? Colors.white : palette.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input field ────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? palette.focusBorder : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: palette.textMuted, fontSize: 15),
          prefixIcon:
              Icon(icon, color: palette.textSecondary, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
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

// ─── Google sign-in button ──────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: _kInkMutedNeutral.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.isDark ? Colors.white : _kTeal,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: palette.isDark ? Colors.white : _kTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
