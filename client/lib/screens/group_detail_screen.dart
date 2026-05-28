import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/group_model.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'kalaam_picker_sheet.dart';

// ─── Brand tokens ─────────────────────────────────────────────────────────────
const _kTeal = Color(0xFF234547);
const _kOrangeGrad1 = Color(0xFFFDA43F);
const _kOrangeGrad2 = Color(0xFFFDBA55);

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
  Color get textSecondary =>
      isDark ? const Color(0xFFCFCFCF) : const Color(0xFF545454);
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

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupModel? _group;
  String? _pendingGroupId;
  String? _pendingGroupName;
  String? _loadError;
  SessionModel? _activeSession;
  bool _loadingSession = false;
  bool _loadingGroup = false;
  List<QueueSnapshotSummary> _snapshots = const [];
  String? _joinedGroupId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_group != null || _pendingGroupId != null) return;

    final arg = ModalRoute.of(context)?.settings.arguments;
    String? groupId;
    if (arg is GroupModel) {
      _group = arg;
      groupId = arg.id;
      _loadFreshData(arg.id);
    } else if (arg is Map && arg['groupId'] is String) {
      _pendingGroupId = arg['groupId'] as String;
      _pendingGroupName =
          arg['groupName'] is String ? arg['groupName'] as String : null;
      groupId = _pendingGroupId;
      _loadFreshData(_pendingGroupId!);
    }
    if (groupId != null) _attachGroupSocket(groupId);
  }

  bool _attachingSocket = false;
  Future<void> _attachGroupSocket(String groupId) async {
    if (_joinedGroupId == groupId || _attachingSocket) return;
    _attachingSocket = true;
    final socket = SocketService();
    try {
      await socket.connect();
    } catch (e) {
      debugPrint('[group-detail] socket connect failed: $e');
      _attachingSocket = false;
      return;
    }
    if (!mounted) {
      _attachingSocket = false;
      return;
    }
    socket.on('group:sessionStarted', _onGroupSessionStarted);
    socket.on('group:sessionEnded', _onGroupSessionEnded);
    socket.joinGroup(groupId);
    _joinedGroupId = groupId;
    _attachingSocket = false;
    debugPrint(
        '[group-detail] joined group:$groupId  connected=${socket.isConnected}');
  }

  void _onGroupSessionStarted(dynamic data) {
    debugPrint('[group-detail] group:sessionStarted received: $data');
    if (!mounted || data is! Map) return;
    if (data['groupId']?.toString() != (_group?.id ?? _pendingGroupId)) return;
    final raw = data['session'];
    if (raw is! Map) return;
    try {
      final session =
          SessionModel.fromJson(Map<String, dynamic>.from(raw));
      if (!session.isActive) return;
      setState(() => _activeSession = session);
    } catch (e) {
      debugPrint('[group-detail] bad sessionStarted payload: $e');
    }
  }

  void _onGroupSessionEnded(dynamic data) {
    debugPrint('[group-detail] group:sessionEnded received: $data');
    if (!mounted || data is! Map) return;
    if (data['groupId']?.toString() != (_group?.id ?? _pendingGroupId)) return;
    setState(() => _activeSession = null);
  }

  @override
  void dispose() {
    final gid = _joinedGroupId;
    if (gid != null) {
      final socket = SocketService();
      socket.leaveGroup(gid);
      socket.off('group:sessionStarted');
      socket.off('group:sessionEnded');
    }
    super.dispose();
  }

  Future<void> _loadFreshData(String groupId) async {
    setState(() {
      _loadingGroup = true;
      _loadError = null;
    });
    try {
      final fresh = await ApiService.getGroup(groupId);
      if (!mounted) return;
      setState(() => _group = fresh);
    } catch (e) {
      if (!mounted) return;
      if (_group == null) {
        setState(() =>
            _loadError = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loadingGroup = false);
    }
    if (_group == null) return;

    setState(() => _loadingSession = true);
    try {
      final active =
          await context.read<GroupProvider>().getActiveSession(groupId);
      if (!mounted) return;
      setState(() => _activeSession = active);
    } finally {
      if (mounted) setState(() => _loadingSession = false);
    }

    final snaps =
        await context.read<GroupProvider>().getQueueSnapshots(groupId);
    if (!mounted) return;
    setState(() => _snapshots = snaps);
  }

  // ignore: unused_element
  Future<void> _showAddMemberDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final p = _Palette.of(ctx);
        return AlertDialog(
          backgroundColor: p.cardBg,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Add Member',
            style: TextStyle(
                color: p.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              hintText: 'User ID',
              hintStyle: TextStyle(color: p.textMuted),
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
                'Add',
                style:
                    TextStyle(color: _kTeal, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && controller.text.trim().isNotEmpty && mounted) {
      final group = _group;
      if (group == null) return;
      final ok = await context
          .read<GroupProvider>()
          .addMember(group.id, controller.text.trim());
      if (ok && mounted) {
        await _loadFreshData(group.id);
      }
    }
    controller.dispose();
  }

  Future<void> _removeMember(String userId) async {
    final group = _group;
    if (group == null) return;
    final ok =
        await context.read<GroupProvider>().removeMember(group.id, userId);
    if (ok && mounted) {
      await _loadFreshData(group.id);
    }
  }

  Future<void> _createAndShareInvite(String type) async {
    final group = _group;
    if (group == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final invite =
        await context.read<GroupProvider>().createInvite(group.id, type: type);
    if (invite == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not create invite')));
      return;
    }
    final label = type == 'guest' ? 'guest pass' : 'invite';
    await Share.share(
      'Join "${group.name}" on Bayaaz with this $label:\n${invite.link}',
      subject: 'Bayaaz $label',
    );
  }

  Future<void> _startSession() async {
    final group = _group;
    if (group == null) return;

    final picked = await showSessionQueueBuilder(context);
    if (picked == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = await context.read<GroupProvider>().startSession(
            group.id,
            kalaamIds: picked.isEmpty ? null : picked,
          );
      if (!mounted) return;
      if (session != null) {
        Navigator.pushNamed(context, '/group-teleprompter',
            arguments: session);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final group = _group;

    if (group == null) {
      return Scaffold(
        backgroundColor: palette.pageBg,
        appBar: AppBar(
          backgroundColor: _kTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _pendingGroupName ?? 'Group',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: _loadError != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () =>
                            _loadFreshData(_pendingGroupId ?? ''),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(
                  color: _kTeal, strokeWidth: 2),
        ),
      );
    }

    final currentUserId = context.read<AuthProvider>().user?.id ?? '';
    final currentMember = group.members.firstWhere(
      (m) => m.id == currentUserId,
      orElse: () => GroupMember(id: '', name: '', role: 'member'),
    );
    final isAdmin = currentMember.role == 'admin';
    final isMember = group.members.any((m) => m.id == currentUserId);

    return Scaffold(
      backgroundColor: palette.pageBg,
      appBar: AppBar(
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          group.name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_loadingGroup)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            ),
          if (isMember)
            PopupMenuButton<String>(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              color: palette.cardBg,
              onSelected: _createAndShareInvite,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'permanent',
                  child: ListTile(
                    leading:
                        const Icon(Icons.person_add, color: _kTeal),
                    title: Text('Invite member',
                        style: TextStyle(color: palette.textPrimary)),
                    subtitle: Text('Permanent access',
                        style: TextStyle(
                            color: palette.textMuted, fontSize: 12)),
                  ),
                ),
                PopupMenuItem(
                  value: 'guest',
                  child: ListTile(
                    leading:
                        const Icon(Icons.bolt, color: _kOrangeGrad1),
                    title: Text('Guest pass',
                        style: TextStyle(color: palette.textPrimary)),
                    subtitle: Text('One session only',
                        style: TextStyle(
                            color: palette.textMuted, fontSize: 12)),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            _SectionHeader(
              label: 'Members',
              count: group.members.length,
              palette: palette,
            ),
            const SizedBox(height: 10),
            ...group.members.map((member) => _MemberTile(
                  member: member,
                  palette: palette,
                  canDelete: isAdmin &&
                      member.id != group.createdById &&
                      member.id != currentUserId,
                  onDelete: () => _removeMember(member.id),
                )),
            const SizedBox(height: 28),
            _SectionHeader(label: 'Session', palette: palette),
            const SizedBox(height: 14),
            _SessionCta(
              loadingSession: _loadingSession,
              activeSession: _activeSession,
              onJoin: () => Navigator.pushNamed(
                context,
                '/group-teleprompter',
                arguments: _activeSession,
              ),
              onStart: _startSession,
            ),
            if (_snapshots.isNotEmpty) ...[
              const SizedBox(height: 28),
              _SectionHeader(label: 'Past queues', palette: palette),
              const SizedBox(height: 10),
              ..._snapshots.map(_buildSnapshotTile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotTile(QueueSnapshotSummary s) {
    final palette = _Palette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderColor),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.items.length} kalaam${s.items.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(s.createdAt),
                  style:
                      TextStyle(color: palette.textMuted, fontSize: 12),
                ),
                if (s.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.items.take(3).map((k) => k.title).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: palette.textMuted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.replay_rounded,
                color: _kTeal, size: 20),
            tooltip: 'Start session with this queue',
            onPressed: _activeSession != null
                ? null
                : () => _startSessionWithSnapshot(s.id),
          ),
        ],
      ),
    );
  }

  Future<void> _startSessionWithSnapshot(String snapshotId) async {
    final group = _group;
    if (group == null) return;
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = await context
          .read<GroupProvider>()
          .startSession(group.id, loadFromSnapshotId: snapshotId);
      if (!mounted) return;
      if (session != null) {
        Navigator.pushNamed(context, '/group-teleprompter',
            arguments: session);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Session CTA ─────────────────────────────────────────────────────────────

class _SessionCta extends StatelessWidget {
  final bool loadingSession;
  final SessionModel? activeSession;
  final VoidCallback onJoin;
  final VoidCallback onStart;

  const _SessionCta({
    required this.loadingSession,
    required this.activeSession,
    required this.onJoin,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    if (loadingSession) {
      return const Center(
        child: CircularProgressIndicator(color: _kTeal, strokeWidth: 2),
      );
    }
    if (activeSession != null) {
      return _GradientCta(
        label: 'Join Session',
        icon: Icons.play_circle_outline_rounded,
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF2E5B5E), _kTeal],
        ),
        onTap: onJoin,
      );
    }
    return _GradientCta(
      label: 'Start Session',
      icon: Icons.fiber_manual_record_rounded,
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [_kOrangeGrad1, _kOrangeGrad2],
      ),
      onTap: onStart,
    );
  }
}

class _GradientCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _GradientCta({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int? count;
  final _Palette palette;

  const _SectionHeader({
    required this.label,
    required this.palette,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final display = count != null ? '$label ($count)' : label;
    return Row(
      children: [
        Text(
          display,
          style: TextStyle(
            color: palette.isDark
                ? Colors.white.withValues(alpha: 0.45)
                : _kTeal,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: palette.borderColor,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

// ─── Member tile ──────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final GroupMember member;
  final bool canDelete;
  final VoidCallback onDelete;
  final _Palette palette;

  const _MemberTile({
    required this.member,
    required this.canDelete,
    required this.onDelete,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderColor),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _kTeal.withValues(alpha: 0.15),
            backgroundImage: member.avatar != null
                ? NetworkImage(member.avatar!)
                : null,
            child: member.avatar == null
                ? Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: _kTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.name,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (member.role == 'admin')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: _kTeal.withValues(alpha: 0.30)),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                  color: palette.isDark
                      ? Colors.white.withValues(alpha: 0.80)
                      : _kTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.remove_circle_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
