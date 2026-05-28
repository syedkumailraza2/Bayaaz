import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/group_model.dart';

// ─── Brand tokens ─────────────────────────────────────────────────────────────
const _kTeal = Color(0xFF234547);

class _Palette {
  final bool isDark;
  const _Palette._(this.isDark);
  factory _Palette.of(BuildContext c) =>
      _Palette._(Theme.of(c).brightness == Brightness.dark);

  Color get pageBg => isDark ? const Color(0xFF0A0A0A) : Colors.white;
  Color get cardBg => isDark ? const Color(0xFF161616) : Colors.white;
  Color get surfaceMuted =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);
  Color get textPrimary => isDark ? Colors.white : Colors.black;
  Color get textMuted => const Color(0xFFA0A0A0);
  Color get borderColor => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.07);
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 9.5,
            offset: const Offset(0, 4),
          ),
        ];
}

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GroupProvider>().loadGroups();
    });
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final p = _Palette.of(ctx);
        return AlertDialog(
          backgroundColor: p.cardBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'New Group',
            style: TextStyle(
              color: p.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              hintText: 'Group name',
              hintStyle: TextStyle(color: p.textMuted, fontSize: 14),
              filled: true,
              fillColor: p.surfaceMuted,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _kTeal, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: p.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Create',
                style: TextStyle(color: _kTeal, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && controller.text.trim().isNotEmpty && mounted) {
      await context.read<GroupProvider>().createGroup(controller.text.trim());
    }
    // Defer disposal — showDialog returns while the dialog's exit animation
    // is still running. Disposing immediately causes the still-mounted
    // TextField to call removeListener on an already-disposed controller.
    Future.delayed(const Duration(milliseconds: 300), controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();
    final palette = _Palette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupsHeader(
              onRefresh: () => context.read<GroupProvider>().loadGroups(),
              onCreate: _showCreateDialog,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: provider.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _kTeal,
                        strokeWidth: 2,
                      ),
                    )
                  : provider.error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              provider.error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : provider.groups.isEmpty
                          ? _EmptyState(palette: palette)
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 140),
                              itemCount: provider.groups.length,
                              itemBuilder: (ctx, i) => _GroupCard(
                                group: provider.groups[i],
                                palette: palette,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  const _GroupsHeader({required this.onRefresh, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gatherings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'مجلس',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.isDark
                        ? Colors.white.withValues(alpha: 0.40)
                        : _kTeal.withValues(alpha: 0.60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon:
                Icon(Icons.refresh_rounded, color: palette.textMuted, size: 21),
            onPressed: onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCreate,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kTeal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _Palette palette;
  const _EmptyState({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color:
                  _kTeal.withValues(alpha: palette.isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.groups_rounded, color: _kTeal, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'No gatherings yet',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to create your first group.',
            style: TextStyle(color: palette.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final _Palette palette;
  const _GroupCard({required this.group, required this.palette});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/group', arguments: group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.borderColor),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color:
                    _kTeal.withValues(alpha: palette.isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child:
                  const Icon(Icons.groups_rounded, color: _kTeal, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.textMuted.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
