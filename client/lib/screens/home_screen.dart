import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/kalaam_provider.dart';
import '../providers/group_provider.dart';
import '../providers/theme_provider.dart';
import '../models/kalaam_model.dart';
import '../widgets/beta_pill.dart';
import '../widgets/server_url_dialog.dart';
import 'groups_screen.dart';

// ─── Brand tokens ─────────────────────────────────────────────────────────────
const _kTeal = Color(0xFF234547);
const _kOrange = Color(0xFFFDA944);
const _kOrangeGrad1 = Color(0xFFFDA43F);
const _kOrangeGrad2 = Color(0xFFFDBA55);
const _kInkMutedNeutral = Color(0xFFA0A0A0);

// Theme-aware tokens. Keeping these collected in one place keeps the home
// surface coherent when the user toggles between light and dark modes.
class _Palette {
  final bool isDark;
  const _Palette._(this.isDark);
  factory _Palette.of(BuildContext c) =>
      _Palette._(Theme.of(c).brightness == Brightness.dark);

  Color get pageBg => isDark ? const Color(0xFF0A0A0A) : Colors.white;
  Color get cardBg => isDark ? const Color(0xFF161616) : Colors.white;
  Color get surfaceMuted =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);
  Color get tagChipBg =>
      isDark ? const Color(0xFF262626) : const Color(0xFFF4F4F4);
  Color get navBg => isDark ? const Color(0xFF161616) : Colors.white;
  Color get textPrimary => isDark ? Colors.white : Colors.black;
  Color get textBody => isDark ? const Color(0xFFE8E8E8) : const Color(0xFF303030);
  Color get textSecondary =>
      isDark ? const Color(0xFFCFCFCF) : const Color(0xFF545454);
  Color get textMuted => _kInkMutedNeutral;
  Color get textSnippet =>
      isDark ? const Color(0xFFB8B8B8) : const Color(0xFF858585);
  Color get chipSelectedBg =>
      isDark ? const Color(0xFF2E5B5E) : _kTeal;
  Color get chipSelectedText => Colors.white;
  Color get chipBg => surfaceMuted;
  Color get chipText => textMuted;
  Color get createCtaBg => isDark ? const Color(0xFF2E5B5E) : _kTeal;
  Color get navSelectedBg =>
      isDark ? _kTeal.withValues(alpha: 0.32) : _kTeal.withValues(alpha: 0.18);
  Color get navIcon => isDark ? Colors.white : const Color(0xFF545454);
  Color get fadeOverlayEnd => pageBg;
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 9.5,
            offset: const Offset(0, 4),
          ),
        ];
  List<BoxShadow> get pillShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 9.2,
            offset: const Offset(0, 2),
          ),
        ];
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KalaamProvider>().loadFeed();
      context.read<KalaamProvider>().loadSavedKalaams();
    });
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    // Defer provider calls to the next frame so they don't call notifyListeners
    // synchronously inside the same call stack as setState. Mixing setState +
    // notifyListeners in the same frame causes "wrong build scope" assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (index == 1) {
        context.read<KalaamProvider>().loadMyKalaams();
        context.read<KalaamProvider>().loadSavedKalaams();
      }
      if (index == 2) {
        context.read<GroupProvider>().loadGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final tabs = <Widget>[
      _FeedTab(onAvatarTap: _showProfileSheet),
      _MyBayaazTab(onAvatarTap: _showProfileSheet),
      const GroupsScreen(),
    ];

    return Scaffold(
      backgroundColor: palette.pageBg,
      body: Stack(
        children: [
          // Cross-fading the active tab keeps theme switches feeling smooth.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: tabs[_currentIndex],
            ),
          ),
          // Soft fade so the floating nav has a calm seat over the list.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.pageBg.withValues(alpha: 0),
                      palette.pageBg,
                    ],
                    stops: const [0.0, 0.58],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _HomeNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              onCreate: () => Navigator.pushNamed(context, '/add'),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _ProfileSheet(
        onSignOut: () async {
          final nav = Navigator.of(context);
          Navigator.of(sheetCtx).pop();
          await context.read<AuthProvider>().signOut();
          if (!mounted) return;
          nav.pushReplacementNamed('/login');
        },
      ),
    );
  }
}

// ─── Feed Tab (Figma 13:5 light + Figma "Pro - 2" dark) ─────────────────────

class _FeedTab extends StatefulWidget {
  final VoidCallback onAvatarTap;
  const _FeedTab({required this.onAvatarTap});

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollController.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    // Repaint so the clear/refresh icon swap reflects the current text.
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      final provider = context.read<KalaamProvider>();
      final q = value.trim();
      if (q.isEmpty) {
        provider.clearSearch();
      } else {
        provider.runSearch(q: q, category: provider.selectedCategory);
      }
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    context.read<KalaamProvider>().clearSearch();
    setState(() {});
  }

  void _onCategorySelected(String? cat) {
    final provider = context.read<KalaamProvider>();
    final q = _searchCtrl.text.trim();
    if (q.isNotEmpty) {
      provider.runSearch(q: q, category: cat);
    } else {
      provider.loadFeed(category: cat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KalaamProvider>();
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final user = context.watch<AuthProvider>().user;
    final palette = _Palette.of(context);

    // When a query is active, render the search-results pipeline; otherwise
    // fall back to the regular feed. Pagination follows the active pipeline.
    final isSearching = provider.searchQuery.trim().isNotEmpty;
    final list = isSearching ? provider.searchResults : provider.feed;
    final loading = isSearching ? provider.searchLoading : provider.feedLoading;
    final error = isSearching ? provider.searchError : provider.feedError;
    final hasMore = isSearching ? provider.searchHasMore : provider.feedHasMore;
    final selectedCat =
        isSearching ? provider.searchCategory : provider.selectedCategory;

    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOnline) const _OfflineBanner(),
            const SizedBox(height: 4),
            const _HeaderRow(),
            const SizedBox(height: 16),
            _SearchRow(
              controller: _searchCtrl,
              onChanged: _onQueryChanged,
              onTapClear: _clearQuery,
              avatarUrl: user?.avatar,
              avatarFallbackInitial: (user?.name.isNotEmpty == true)
                  ? user!.name[0].toUpperCase()
                  : '?',
              onTapRefresh: () => context
                  .read<KalaamProvider>()
                  .loadFeed(category: provider.selectedCategory),
              onTapAvatar: widget.onAvatarTap,
              onTapServerUrl: () async {
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
              serverUrlActive: AppConfig.isOverridden,
            ),
            const SizedBox(height: 14),
            _CategoryChips(
              selected: selectedCat,
              onSelected: _onCategorySelected,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: loading && list.isEmpty
                  ? Center(
                      child:
                          CircularProgressIndicator(color: palette.chipSelectedBg))
                  : error != null && list.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              error,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : list.isEmpty
                          ? Center(
                              child: Text(
                                isSearching
                                    ? 'No kalaams match "${provider.searchQuery}".'
                                    : 'No kalaams yet. Be the first!',
                                style: TextStyle(
                                    color: palette.textMuted, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 140),
                              itemCount: list.length + (hasMore ? 1 : 0),
                              itemBuilder: (ctx, i) {
                                if (hasMore && i == list.length - 3 && i >= 0) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    final p = context.read<KalaamProvider>();
                                    if (isSearching) {
                                      p.loadMoreSearch();
                                    } else {
                                      p.loadMoreFeed();
                                    }
                                  });
                                }
                                if (i >= list.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: palette.chipSelectedBg,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                // Stagger card entry by index for a soft cascade.
                                return _SlideFadeIn(
                                  delay: Duration(milliseconds: 40 * i),
                                  child: _FeedKalaamCard(kalaam: list[i]),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header row: wordmark + welcome + theme toggle ──────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    // SizedBox forces the Stack to take the full available width so that
    // `Positioned(right: 0)` anchors to the screen edge, not the column.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
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
                      fontSize: 40,
                      height: 1.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'اسلام علیکم بیاز میں خوش آمدید',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    color: palette.isDark
                        ? Colors.white.withValues(alpha: 0.85)
                        : _kTeal,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.56,
                  ),
                ),
              ],
            ),
            // BETA pill pinned to the left edge — mirrors the theme toggle.
            const Positioned(
              left: 0,
              top: 10,
              child: BetaPill.onLight(),
            ),
            // Theme toggle pinned to the right edge per Figma.
            Positioned(
              right: 0,
              top: 6,
              child: _ThemeToggleButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final theme = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: theme.toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 43,
        height: 30,
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: Tween<double>(begin: 0.6, end: 1.0).animate(anim),
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: Icon(
            theme.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            key: ValueKey(theme.isDark),
            size: 18,
            color: theme.isDark ? _kOrange : _kTeal,
          ),
        ),
      ),
    );
  }
}

// ─── Search row + avatar ─────────────────────────────────────────────────────

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onTapRefresh;
  final VoidCallback onTapClear;
  final String? avatarUrl;
  final String avatarFallbackInitial;
  final VoidCallback onTapAvatar;
  final VoidCallback onTapServerUrl;
  final bool serverUrlActive;

  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.onTapRefresh,
    required this.onTapClear,
    required this.avatarUrl,
    required this.avatarFallbackInitial,
    required this.onTapAvatar,
    required this.onTapServerUrl,
    required this.serverUrlActive,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final hasText = controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 43,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(27),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 22, color: palette.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      cursorColor: palette.chipSelectedBg,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.4,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.48,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  // Clear (X) when there's text; otherwise refresh.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: hasText
                        ? GestureDetector(
                            key: const ValueKey('clear'),
                            onTap: onTapClear,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.close_rounded,
                                  size: 20, color: palette.textMuted),
                            ),
                          )
                        : GestureDetector(
                            key: const ValueKey('refresh'),
                            onTap: onTapRefresh,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.refresh,
                                  size: 22, color: palette.textMuted),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Tap → profile sheet, long-press → hidden server URL override.
          GestureDetector(
            onTap: onTapAvatar,
            onLongPress: onTapServerUrl,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 21.5,
                  backgroundColor: _kTeal.withValues(alpha: 0.15),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          avatarFallbackInitial,
                          style: TextStyle(
                            fontSize: 16,
                            color: palette.isDark ? Colors.white : _kTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (serverUrlActive)
                  const Positioned(
                    right: -1,
                    bottom: -1,
                    child:
                        Icon(Icons.cloud, size: 12, color: _kOrangeGrad1),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category chips ──────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final String? selected;
  final void Function(String?) onSelected;

  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final cats = <String?>[null, ...kKalaamCategories];
    return SizedBox(
      height: 31,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = cats[i];
          final label = cat == null ? 'All' : _capitalise(cat);
          final isSelected = selected == cat;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? palette.chipSelectedBg : palette.chipBg,
                borderRadius: BorderRadius.circular(27),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? palette.chipSelectedText
                      : palette.chipText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Feed card (theme aware, Figma 13:5 / Pro-2) ─────────────────────────────

class _FeedKalaamCard extends StatelessWidget {
  final KalaamModel kalaam;
  const _FeedKalaamCard({required this.kalaam});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isOwner = kalaam.author.id == currentUserId;
    final isSaved = context.watch<KalaamProvider>().isSaved(kalaam.id);
    final cat = _CategoryGlyph.from(kalaam.category);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/kalaam', arguments: kalaam),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 118,
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: palette.cardShadow,
          border: palette.isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.05))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: _kTeal.withValues(alpha: 0.15),
                    backgroundImage: kalaam.author.avatar != null
                        ? NetworkImage(kalaam.author.avatar!)
                        : null,
                    child: kalaam.author.avatar == null
                        ? Text(
                            kalaam.author.name.isNotEmpty
                                ? kalaam.author.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 8,
                              color: palette.isDark ? Colors.white : _kTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      kalaam.author.name.isEmpty
                          ? 'Unknown'
                          : kalaam.author.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: palette.textBody,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (!isOwner)
                    Flexible(
                      child: Text(
                        'shared a kalaam',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: palette.textMuted,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    _formatDate(kalaam.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: palette.textMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 67,
                      height: 67,
                      decoration: BoxDecoration(
                        color: cat.tileColor,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat.glyph,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  kalaam.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.56,
                                  ),
                                ),
                              ),
                              if (kalaam.tags.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: palette.tagChipBg,
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                  child: Text(
                                    kalaam.tags.first,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: palette.textMuted,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.32,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              kalaam.previewText.isEmpty
                                  ? _categoryBlurb(kalaam.category)
                                  : kalaam.previewText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                color: palette.textSnippet,
                                height: 1.3,
                                letterSpacing: -0.32,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context
                                    .read<KalaamProvider>()
                                    .toggleLike(kalaam.id),
                                behavior: HitTestBehavior.opaque,
                                child: _ActionLabel(
                                  icon: kalaam.likedByMe
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  label: kalaam.likesCount > 0
                                      ? '${kalaam.likesCount} ${kalaam.likesCount == 1 ? 'Like' : 'Likes'}'
                                      : 'Like',
                                  color: kalaam.likedByMe
                                      ? Colors.redAccent
                                      : palette.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              GestureDetector(
                                onTap: () => context
                                    .read<KalaamProvider>()
                                    .toggleSave(kalaam.id),
                                behavior: HitTestBehavior.opaque,
                                child: _ActionLabel(
                                  icon: isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_outline,
                                  label: isSaved ? 'Saved' : 'Save',
                                  color: isSaved
                                      ? palette.chipSelectedBg
                                      : palette.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              _ActionLabel(
                                icon: Icons.menu_book_rounded,
                                label:
                                    '${kalaam.reads} ${kalaam.reads == 1 ? 'Read' : 'Reads'}',
                                color: palette.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _categoryBlurb(String category) {
    switch (category) {
      case 'nauha':
        return 'a heartfelt lament recited in remembrance of the martyrs of Karbala.';
      case 'marsiya':
        return 'a narrative elegy honouring the tragedy and valour of Imam Hussain (AS).';
      case 'qasida':
        return 'a praise-form ode composed for the Prophet (SAW) and Ahlul-Bayt.';
      case 'qata':
        return 'a short poetic fragment carrying a single resonant idea.';
      default:
        return '';
    }
  }
}

class _ActionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: color,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.32,
          ),
        ),
      ],
    );
  }
}

class _CategoryGlyph {
  final String glyph;
  final Color tileColor;
  const _CategoryGlyph(this.glyph, this.tileColor);

  static _CategoryGlyph from(String category) {
    switch (category) {
      case 'nauha':
        return const _CategoryGlyph('نوحہ', _kOrange);
      case 'marsiya':
        return const _CategoryGlyph('مرثیہ', Color(0xFFB45D2C));
      case 'qasida':
        return const _CategoryGlyph('قصیدہ', Color(0xFF2E7B7E));
      case 'qata':
        return const _CategoryGlyph('قطع', _kTeal);
      default:
        return const _CategoryGlyph('بیاض', _kTeal);
    }
  }
}

// ─── Bottom nav (split pills) ────────────────────────────────────────────────

class _HomeNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onCreate;

  const _HomeNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 57,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: palette.navBg,
              borderRadius: BorderRadius.circular(48),
              boxShadow: palette.pillShadow,
              border: palette.isDark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.05))
                  : null,
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'My Byaaz',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.group_rounded,
                  label: 'Group',
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 11),
        _PressableScale(
          onTap: onCreate,
          child: Container(
            height: 57,
            width: 125,
            decoration: BoxDecoration(
              color: palette.createCtaBg,
              borderRadius: BorderRadius.circular(48),
              boxShadow: palette.pillShadow,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note_rounded, size: 22, color: Colors.white),
                SizedBox(height: 2),
                Text(
                  'Create New Kalaam',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final activeColor = palette.isDark ? Colors.white : _kTeal;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: selected ? palette.navSelectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 22, color: selected ? activeColor : palette.navIcon),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? activeColor : palette.navIcon,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Container(
      width: double.infinity,
      color: _kOrange.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: _kOrange, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — showing cached kalaams',
              style: TextStyle(color: palette.textBody, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Bayaaz Tab (Figma Pro-9) ────────────────────────────────────────────

class _MyBayaazTab extends StatefulWidget {
  final VoidCallback onAvatarTap;
  const _MyBayaazTab({required this.onAvatarTap});

  @override
  State<_MyBayaazTab> createState() => _MyBayaazTabState();
}

class _MyBayaazTabState extends State<_MyBayaazTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _tab = 0; // 0 = Created, 1 = Saved

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  void _clearQuery() {
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<KalaamProvider>();

    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                'My Bayaaz',
                style: TextStyle(
                  fontSize: 24,
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            _SearchRow(
              controller: _searchCtrl,
              onChanged: _onQueryChanged,
              onTapClear: _clearQuery,
              avatarUrl: user?.avatar,
              avatarFallbackInitial: (user?.name.isNotEmpty == true)
                  ? user!.name[0].toUpperCase()
                  : '?',
              onTapRefresh: () {
                context.read<KalaamProvider>().loadMyKalaams();
                context.read<KalaamProvider>().loadSavedKalaams();
              },
              onTapAvatar: widget.onAvatarTap,
              onTapServerUrl: () async {
                await showServerUrlDialog(context);
              },
              serverUrlActive: AppConfig.isOverridden,
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _MyTabPill(
                    icon: Icons.edit_note_rounded,
                    label: 'My Created Kallams',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 10),
                  _MyTabPill(
                    icon: Icons.bookmark_outline_rounded,
                    label: 'My Saved Kalaams',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _tab == 0
                    ? _MyKalaamsList(
                        key: const ValueKey('created'),
                        provider: provider,
                        query: _query,
                      )
                    : _SavedKalaamsList(
                        key: const ValueKey('saved'),
                        provider: provider,
                        query: _query,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyTabPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MyTabPill({
    required this.icon,
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
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? palette.chipSelectedBg : palette.chipBg,
            borderRadius: BorderRadius.circular(40),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : palette.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
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

// Client-side filter — matches title / poet / tags / stanza lines.
List<KalaamModel> _filterByQuery(List<KalaamModel> items, String query) {
  if (query.isEmpty) return items;
  return items.where((k) {
    if (k.title.toLowerCase().contains(query)) return true;
    if ((k.poet ?? '').toLowerCase().contains(query)) return true;
    if (k.tags.any((t) => t.toLowerCase().contains(query))) return true;
    for (final stanza in k.content) {
      for (final line in stanza.lines) {
        if (line.toLowerCase().contains(query)) return true;
      }
    }
    return false;
  }).toList();
}

class _MyKalaamsList extends StatelessWidget {
  final KalaamProvider provider;
  final String query;
  const _MyKalaamsList({
    super.key,
    required this.provider,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    if (provider.myLoading && provider.myKalaams.isEmpty) {
      return Center(
          child: CircularProgressIndicator(color: palette.chipSelectedBg));
    }
    if (provider.myError != null && provider.myKalaams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: _ErrorRow(message: provider.myError!)),
      );
    }
    if (provider.myKalaams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: _EmptyRow(message: 'No kalaams yet. Tap Create to add one.'),
        ),
      );
    }
    final items = _filterByQuery(provider.myKalaams, query);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: _EmptyRow(message: 'No matches for "$query".'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final kalaam = items[i];
        return _SlideFadeIn(
          delay: Duration(milliseconds: 40 * i),
          child: _MyBayaazCard(
            kalaam: kalaam,
            showActions: true,
            onEdit: () =>
                Navigator.pushNamed(context, '/edit', arguments: kalaam),
            onDelete: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) {
                  final p = _Palette.of(context);
                  return AlertDialog(
                    backgroundColor: p.cardBg,
                    title: Text('Delete Kalaam',
                        style: TextStyle(color: p.textPrimary)),
                    content: Text('Are you sure?',
                        style: TextStyle(color: p.textBody)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red))),
                    ],
                  );
                },
              );
              if (confirmed == true && context.mounted) {
                context.read<KalaamProvider>().deleteKalaam(kalaam.id);
              }
            },
          ),
        );
      },
    );
  }
}

class _SavedKalaamsList extends StatelessWidget {
  final KalaamProvider provider;
  final String query;
  const _SavedKalaamsList({
    super.key,
    required this.provider,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    if (provider.savedLoading && provider.savedKalaams.isEmpty) {
      return Center(
          child: CircularProgressIndicator(color: palette.chipSelectedBg));
    }
    if (provider.savedError != null && provider.savedKalaams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: _ErrorRow(message: provider.savedError!)),
      );
    }
    if (provider.savedKalaams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: _EmptyRow(
            message:
                'No saved kalaams yet.\nTap the bookmark icon on any kalaam.',
          ),
        ),
      );
    }
    final items = _filterByQuery(provider.savedKalaams, query);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: _EmptyRow(message: 'No matches for "$query".'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: items.length,
      itemBuilder: (ctx, i) => _SlideFadeIn(
        delay: Duration(milliseconds: 40 * i),
        child: _MyBayaazCard(kalaam: items[i]),
      ),
    );
  }
}

// ─── My-Bayaaz card variant (Figma Pro-9) ───────────────────────────────────
// Wider/taller than the feed card; shows stat counts and (when the user owns
// the kalaam) edit & delete icons in the header row.

class _MyBayaazCard extends StatelessWidget {
  final KalaamModel kalaam;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _MyBayaazCard({
    required this.kalaam,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final cat = _CategoryGlyph.from(kalaam.category);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/kalaam', arguments: kalaam),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: palette.cardShadow,
          border: palette.isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.05))
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 9,
                  backgroundColor: _kTeal.withValues(alpha: 0.15),
                  backgroundImage: kalaam.author.avatar != null
                      ? NetworkImage(kalaam.author.avatar!)
                      : null,
                  child: kalaam.author.avatar == null
                      ? Text(
                          kalaam.author.name.isNotEmpty
                              ? kalaam.author.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 8,
                            color: palette.isDark ? Colors.white : _kTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    kalaam.author.name.isEmpty
                        ? 'Unknown'
                        : kalaam.author.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: palette.textBody,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _FeedKalaamCard._formatDate(kalaam.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: palette.textMuted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                if (showActions) ...[
                  if (onEdit != null)
                    _IconButtonSmall(
                      icon: Icons.edit_outlined,
                      color: palette.textSecondary,
                      onTap: onEdit!,
                    ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    _IconButtonSmall(
                      icon: Icons.delete_outline,
                      color: Colors.redAccent,
                      onTap: onDelete!,
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 67,
                  height: 67,
                  decoration: BoxDecoration(
                    color: cat.tileColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cat.glyph,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              kalaam.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.56,
                              ),
                            ),
                          ),
                          if (kalaam.tags.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: palette.tagChipBg,
                                borderRadius: BorderRadius.circular(27),
                              ),
                              child: Text(
                                kalaam.tags.first,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: palette.textMuted,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.32,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kalaam.previewText.isEmpty
                            ? _FeedKalaamCard._categoryBlurb(kalaam.category)
                            : kalaam.previewText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: palette.textSnippet,
                          height: 1.35,
                          letterSpacing: -0.32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _ActionLabel(
                            icon: kalaam.likedByMe
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: '${kalaam.likesCount} ${kalaam.likesCount == 1 ? 'Like' : 'Likes'}',
                            color: kalaam.likedByMe
                                ? Colors.redAccent
                                : palette.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          _ActionLabel(
                            icon: Icons.menu_book_rounded,
                            label:
                                '${kalaam.reads} ${kalaam.reads == 1 ? 'Read' : 'Reads'}',
                            color: palette.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButtonSmall extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconButtonSmall({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.textMuted, fontSize: 13),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message,
          style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
    );
  }
}

// ─── Profile sheet (avatar tap) ─────────────────────────────────────────────

class _ProfileSheet extends StatelessWidget {
  final VoidCallback onSignOut;
  const _ProfileSheet({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: palette.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            // Tap the avatar to open the edit dialog — a single, discoverable
            // affordance that doubles as the "change profile picture" entry.
            GestureDetector(
              onTap: () => _showEditAvatarDialog(context),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: _kTeal,
                    backgroundImage: user?.avatar != null
                        ? NetworkImage(user!.avatar!)
                        : null,
                    child: user?.avatar == null
                        ? Text(
                            user?.name.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  // Camera badge — signals "tap to edit".
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: palette.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.pageBg, width: 2),
                    ),
                    child: Icon(Icons.edit_rounded,
                        size: 14, color: palette.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(user?.name ?? '',
                style: TextStyle(
                    fontSize: 18,
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(user?.email ?? '',
                style: TextStyle(color: palette.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            // Quick theme toggle inside the sheet for discoverability.
            _ThemeRowInSheet(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Sign Out',
                    style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Opens the avatar-edit dialog. Kept top-level so it can be called from any
// surface that wants to expose the avatar editor in the future.
Future<void> _showEditAvatarDialog(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final user = auth.user;
  final palette = _Palette.of(context);
  final controller = TextEditingController(text: user?.avatar ?? '');
  bool saving = false;
  String? errorText;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            backgroundColor: palette.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Edit avatar',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste an https:// link to your avatar image.',
                  style: TextStyle(
                      color: palette.textBody, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    enabled: !saving,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'https://…',
                      hintStyle: TextStyle(color: palette.textMuted),
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(8, 0, 12, 12),
            actions: [
              if (user?.avatar != null)
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setLocal(() => saving = true);
                          final ok = await auth.updateProfile(clearAvatar: true);
                          if (!ctx.mounted) return;
                          if (ok) {
                            Navigator.pop(ctx);
                          } else {
                            setLocal(() {
                              saving = false;
                              errorText = auth.error ?? 'Failed to remove avatar';
                            });
                          }
                        },
                  child: const Text('Remove',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: palette.textMuted)),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          setLocal(() => errorText = 'Paste a URL or tap Remove.');
                          return;
                        }
                        final url = Uri.tryParse(value);
                        final valid = url != null &&
                            (url.scheme == 'http' || url.scheme == 'https') &&
                            url.host.isNotEmpty;
                        if (!valid) {
                          setLocal(() => errorText = 'Enter a valid http(s) URL.');
                          return;
                        }
                        setLocal(() {
                          saving = true;
                          errorText = null;
                        });
                        final ok = await auth.updateProfile(avatar: value);
                        if (!ctx.mounted) return;
                        if (ok) {
                          Navigator.pop(ctx);
                        } else {
                          setLocal(() {
                            saving = false;
                            errorText = auth.error ?? 'Failed to save avatar';
                          });
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: palette.chipSelectedBg,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ThemeRowInSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final theme = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: theme.toggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(theme.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                size: 18, color: theme.isDark ? _kOrange : _kTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                theme.isDark ? 'Switch to light mode' : 'Switch to dark mode',
                style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Switch.adaptive(
              value: theme.isDark,
              onChanged: (_) => theme.toggle(),
              activeThumbColor: _kOrange,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small reusable animation primitives ────────────────────────────────────

class _PressableScale extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _PressableScale({required this.onTap, required this.child});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _SlideFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _SlideFadeIn({required this.child, this.delay = Duration.zero});

  @override
  State<_SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<_SlideFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
