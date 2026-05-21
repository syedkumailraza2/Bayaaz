import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kalaam_model.dart';
import '../providers/auth_provider.dart';
import '../providers/kalaam_provider.dart';

// ─── Design tokens shared with home_screen.dart ─────────────────────────────
// Kept colocated here so this screen renders standalone without importing the
// home module just for tokens.
const _kTeal = Color(0xFF234547);
const _kTealDarkGradTop = Color(0xFF1B3739);
const _kTealOnDark = Color(0xFF2E5B5E);
const _kInkPrimary = Color(0xFF303030);
const _kInkMuted = Color(0xFFA0A0A0);
const _kSurfaceLight = Color(0xFFF2F2F2);
const _kChipLightBg = Color(0xFFECECEC);
const _kChipLightFg = Color(0xFF2D2D2D);
const _kChipDarkBg = Color(0xFF1F1F1F);
const _kChipDarkFg = Color(0xFFCFCFCF);
const _kPageDark = Color(0xFF0A0A0A);
const _kSurfaceDark = Color(0xFF1A1A1A);

/// Read-only detail view of a kalaam, redesigned to match the new Figma
/// tombstone hero + stats + CTA layout. Accepts the kalaam via
/// `ModalRoute` arguments and adapts to the current [Theme.brightness].
class KalaamDetailScreen extends StatefulWidget {
  const KalaamDetailScreen({super.key});

  @override
  State<KalaamDetailScreen> createState() => _KalaamDetailScreenState();
}

class _KalaamDetailScreenState extends State<KalaamDetailScreen>
    with SingleTickerProviderStateMixin {
  KalaamModel? _kalaam;
  bool _initialized = false;
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    // Kick off the entry animation on the first frame so the screen fades in
    // even before the route transition fully resolves.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _kalaam = ModalRoute.of(context)!.settings.arguments as KalaamModel;
    // Fire-and-forget read counter bump. The provider reconciles the in-memory
    // lists optimistically so the count animates up immediately.
    final id = _kalaam?.id;
    if (id != null && id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<KalaamProvider>().recordView(id);
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _openPractice({required String mode}) {
    final kalaam = _kalaam;
    if (kalaam == null) return;
    Navigator.pushNamed(
      context,
      '/practice',
      arguments: <String, dynamic>{
        'kalaam': kalaam,
        'mode': mode,
        'startStanza': 0,
      },
    );
  }

  void _openReadSheet() {
    final kalaam = _kalaam;
    if (kalaam == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetCtx) => _ReadSheet(kalaam: kalaam, isDark: isDark),
    );
  }

  Future<void> _toggleVisibility() async {
    final kalaam = _kalaam;
    if (kalaam == null) return;
    final ok = await context.read<KalaamProvider>().toggleVisibility(kalaam.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t update visibility. Try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kalaam = _kalaam;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _kPageDark : Colors.white;

    if (kalaam == null) {
      return Scaffold(backgroundColor: bg);
    }

    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isOwner = kalaam.author.id == currentUserId;
    // Watch so the toggle re-renders in place after toggleVisibility resolves.
    final liveKalaam = context.select<KalaamProvider, KalaamModel>((p) {
      for (final list in [p.feed, p.myKalaams, p.savedKalaams, p.searchResults]) {
        for (final k in list) {
          if (k.id == kalaam.id) return k;
        }
      }
      return kalaam;
    });

    final cat = _CategoryGlyph.from(liveKalaam.category);
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    // Tombstone target ~360px tall but never more than 46% of the viewport so
    // the layout still breathes on shorter devices.
    final heroHeight = (size.height * 0.46).clamp(320.0, 400.0);

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedBuilder(
        animation: _entryController,
        builder: (context, _) {
          final t = _entryController.value;
          // Whole-screen fade + slide-up to introduce the layout.
          final overall = Curves.easeOut.transform(t.clamp(0.0, 1.0));
          return Opacity(
            opacity: overall,
            child: Transform.translate(
              offset: Offset(0, (1 - overall) * 12),
              child: Stack(
                children: [
                  _Hero(
                    height: heroHeight,
                    topInset: topInset,
                    glyph: cat.glyph,
                    progress: _stagger(t, 0.0, 0.40),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: heroHeight - topInset + 16),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                _StaggeredFade(
                                  progress: _stagger(t, 0.15, 0.55),
                                  child: _TitleBlock(
                                    kalaam: liveKalaam,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _StaggeredFade(
                                  progress: _stagger(t, 0.30, 0.70),
                                  child: _StatsRow(
                                    isDark: isDark,
                                    likes: liveKalaam.likesCount,
                                    // Per-kalaam save aggregation is not yet
                                    // computed server-side; placeholder until
                                    // the next backend pass.
                                    saves: 0,
                                    reads: liveKalaam.reads,
                                    liked: liveKalaam.likedByMe,
                                    onLikeTap: () => context
                                        .read<KalaamProvider>()
                                        .toggleLike(liveKalaam.id),
                                    animateIn: t > 0.30,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _StaggeredFade(
                                  progress: _stagger(t, 0.45, 0.85),
                                  child: _CtaRow(
                                    isDark: isDark,
                                    onRead: _openReadSheet,
                                    onFollowVoice: () =>
                                        _openPractice(mode: 'follow'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _StaggeredFade(
                                  progress: _stagger(t, 0.50, 0.90),
                                  child: Text(
                                    'You started reading this one',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : _kInkMuted,
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
                  // Bottom action pills (Back + Visibility).
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                    child: _StaggeredFade(
                      progress: _stagger(t, 0.60, 1.00),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BottomPill(
                            icon: Icons.arrow_back_rounded,
                            label: 'Back',
                            isDark: isDark,
                            onTap: () => Navigator.pop(context),
                          ),
                          _BottomPill(
                            icon: liveKalaam.isPublic
                                ? Icons.public
                                : Icons.lock_outline,
                            label: liveKalaam.isPublic ? 'Public' : 'Private',
                            isDark: isDark,
                            onTap: isOwner ? _toggleVisibility : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Maps a global progress [t] (0..1) onto a sub-interval [start..end] with
  /// easeOut. Used to stagger child entry animations within a single
  /// controller so we don't pay for N controllers.
  double _stagger(double t, double start, double end) {
    if (t <= start) return 0.0;
    if (t >= end) return 1.0;
    return Curves.easeOut.transform((t - start) / (end - start));
  }
}

// ─── Hero tombstone ─────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final double height;
  final double topInset;
  final String glyph;
  final double progress; // 0..1 for glyph scale-in

  const _Hero({
    required this.height,
    required this.topInset,
    required this.glyph,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // The hero is a vertical column ~70% of the viewport width, centered, with
    // big bottom-rounded corners — the inverted-U "tombstone" shape from Figma.
    final heroWidth = size.width * 0.72;
    final scale = 0.92 + 0.08 * progress;

    return Positioned(
      top: 0,
      left: (size.width - heroWidth) / 2,
      width: heroWidth,
      height: height,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kTealDarkGradTop, _kTeal],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(80),
            bottomRight: Radius.circular(80),
          ),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(top: topInset * 0.4),
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: scale,
              child: Text(
                glyph,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 120,
                  height: 1.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -2.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Title + author block ───────────────────────────────────────────────────

class _TitleBlock extends StatelessWidget {
  final KalaamModel kalaam;
  final bool isDark;

  const _TitleBlock({required this.kalaam, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasTag = kalaam.tags.isNotEmpty;
    final titleColor = isDark ? Colors.white : Colors.black;
    final dateText = _formatDate(kalaam.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasTag)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? _kChipDarkBg : _kChipLightBg,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(
              kalaam.tags.first,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? _kChipDarkFg : _kChipLightFg,
              ),
            ),
          ),
        if (hasTag) const SizedBox(height: 14),
        Text(
          kalaam.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: titleColor,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor:
                  isDark ? Colors.white12 : _kTeal.withValues(alpha: 0.15),
              backgroundImage: kalaam.author.avatar != null
                  ? NetworkImage(kalaam.author.avatar!)
                  : null,
              child: kalaam.author.avatar == null
                  ? Text(
                      kalaam.author.name.isNotEmpty
                          ? kalaam.author.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white : _kTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              kalaam.author.name.isEmpty ? 'Unknown' : kalaam.author.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : _kInkPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 12,
              color: isDark ? Colors.white24 : _kInkMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : _kInkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

// ─── Stats row (likes / saves / reads) ──────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final bool isDark;
  final int likes;
  final int saves;
  final int reads;
  final bool liked;
  final bool animateIn;
  final VoidCallback onLikeTap;

  const _StatsRow({
    required this.isDark,
    required this.likes,
    required this.saves,
    required this.reads,
    required this.liked,
    required this.animateIn,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? _kSurfaceDark : _kSurfaceLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              icon: liked ? Icons.favorite : Icons.favorite_border,
              iconColor: liked ? Colors.redAccent : null,
              value: likes,
              label: 'Likes',
              isDark: isDark,
              animateIn: animateIn,
              onTap: onLikeTap,
            ),
          ),
          Expanded(
            child: _StatCell(
              icon: Icons.bookmark_outline,
              value: saves,
              label: 'Saves',
              isDark: isDark,
              animateIn: animateIn,
            ),
          ),
          Expanded(
            child: _StatCell(
              icon: Icons.menu_book_rounded,
              value: reads,
              label: 'Read',
              isDark: isDark,
              animateIn: animateIn,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final bool isDark;
  final bool animateIn;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
    required this.animateIn,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black;
    final muted = isDark ? Colors.white70 : _kInkPrimary;
    final cell = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Swap the icon with a scale+fade so a like tap feels punchy.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            icon,
            key: ValueKey(icon),
            size: 22,
            color: iconColor ?? fg,
          ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          // animateIn flips false→true after the staggered entry hits this
          // row, which restarts the tween from 0 to the target count.
          tween: Tween<double>(begin: 0, end: animateIn ? value.toDouble() : 0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (_, v, _) {
            final shown = v.round();
            return Text(
              '$shown $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            );
          },
        ),
      ],
    );
    if (onTap == null) return cell;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: cell,
      ),
    );
  }
}

// ─── CTA row (Read / Follow Voice) ──────────────────────────────────────────

class _CtaRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRead;
  final VoidCallback onFollowVoice;

  const _CtaRow({
    required this.isDark,
    required this.onRead,
    required this.onFollowVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PressablePill(
            background: isDark ? _kTealOnDark : _kTeal,
            foreground: Colors.white,
            icon: Icons.menu_book_rounded,
            label: 'Read This Kalaam',
            onTap: onRead,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PressablePill(
            background: isDark ? const Color(0xFF1F1F1F) : Colors.black,
            foreground: Colors.white,
            icon: Icons.graphic_eq_rounded,
            label: 'Follow My Voice',
            onTap: onFollowVoice,
          ),
        ),
      ],
    );
  }
}

/// Pill that scales down on press for tactile feedback. Wraps a [GestureDetector]
/// + [AnimatedScale] instead of an InkWell so the visual stays flat (no
/// Material ripple on top of the brand colours).
class _PressablePill extends StatefulWidget {
  final Color background;
  final Color foreground;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PressablePill({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PressablePill> createState() => _PressablePillState();
}

class _PressablePillState extends State<_PressablePill> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: widget.foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.foreground,
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

// ─── Bottom action pills (back + visibility) ────────────────────────────────

class _BottomPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _BottomPill({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _kSurfaceDark : _kSurfaceLight;
    final fg = isDark ? Colors.white : _kInkPrimary;

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }
}

// ─── Stagger fade helper ────────────────────────────────────────────────────

/// Applies a [progress] (0..1) as combined fade + slight upward slide so each
/// section can ride a slice of the global entry controller.
class _StaggeredFade extends StatelessWidget {
  final double progress;
  final Widget child;

  const _StaggeredFade({required this.progress, required this.child});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * 10),
        child: child,
      ),
    );
  }
}

// ─── Category glyph helper (mirrors home_screen.dart) ───────────────────────

class _CategoryGlyph {
  final String glyph;
  const _CategoryGlyph(this.glyph);

  static _CategoryGlyph from(String category) {
    switch (category) {
      case 'nauha':
        return const _CategoryGlyph('نوحہ');
      case 'marsiya':
        return const _CategoryGlyph('مرثیہ');
      case 'qasida':
        return const _CategoryGlyph('قصیدہ');
      case 'qata':
        return const _CategoryGlyph('قطع');
      default:
        return const _CategoryGlyph('بیاض');
    }
  }
}

// ─── Read sheet (inline reader) ─────────────────────────────────────────────
// Replaces the previous navigation to PracticeModeScreen for the Read CTA.
// Opens as a draggable modal sheet over the detail screen, with the kalaam's
// stanzas separated by the brand's orange-diamond divider.

class _ReadSheet extends StatelessWidget {
  final KalaamModel kalaam;
  final bool isDark;
  const _ReadSheet({required this.kalaam, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sheetBg = isDark ? const Color(0xFF111111) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;
    final stanzaColor = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1F1F1F);
    final dividerLine = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final handleColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E2E2);
    final tagBg = isDark ? const Color(0xFF2A1A0C) : const Color(0xFFFDA944);
    final tagFg = isDark ? const Color(0xFFFDA944) : Colors.white;
    final firstTag = kalaam.tags.isNotEmpty ? kalaam.tags.first : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Swipe down to close',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : _kInkMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              if (firstTag != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    firstTag,
                    style: TextStyle(
                      fontSize: 12,
                      color: tagFg,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  kalaam.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: kalaam.content.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'This kalaam has no content yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white54
                                  : _kInkMuted,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                        itemCount: kalaam.content.length,
                        separatorBuilder: (_, _) => _DiamondDivider(
                          lineColor: dividerLine,
                        ),
                        itemBuilder: (ctx, i) {
                          final stanza = kalaam.content[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              stanza.lines.join('\n'),
                              textAlign: TextAlign.center,
                              textDirection: _detectDirection(stanza.lines),
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.55,
                                color: stanzaColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick RTL when the first non-whitespace character is in the Arabic block,
  // so Urdu/Arabic stanzas render correctly while Roman-Urdu stays LTR.
  static TextDirection _detectDirection(List<String> lines) {
    for (final line in lines) {
      for (final code in line.runes) {
        if (code == 0x20 || code == 0x09) continue;
        // Arabic + Arabic Supplement + Arabic Extended-A blocks.
        if ((code >= 0x0600 && code <= 0x06FF) ||
            (code >= 0x0750 && code <= 0x077F) ||
            (code >= 0x08A0 && code <= 0x08FF) ||
            (code >= 0xFB50 && code <= 0xFDFF) ||
            (code >= 0xFE70 && code <= 0xFEFF)) {
          return TextDirection.rtl;
        }
        return TextDirection.ltr;
      }
    }
    return TextDirection.ltr;
  }
}

class _DiamondDivider extends StatelessWidget {
  final Color lineColor;
  const _DiamondDivider({required this.lineColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          const SizedBox(width: 10),
          Transform.rotate(
            angle: 0.7853981633974483, // pi / 4
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFFFDA944)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}
