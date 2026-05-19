import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/group_model.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../services/api_service.dart';
import 'kalaam_picker_sheet.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupModel? _group;
  String? _pendingGroupId; // arrived via deep-link Map arg
  String? _pendingGroupName;
  String? _loadError;
  SessionModel? _activeSession;
  bool _loadingSession = false;
  bool _loadingGroup = false;
  List<QueueSnapshotSummary> _snapshots = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_group != null || _pendingGroupId != null) return;

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is GroupModel) {
      _group = arg;
      _loadFreshData(arg.id);
    } else if (arg is Map && arg['groupId'] is String) {
      // Came from the deep-link redeem flow. We only have the id; fetch the rest.
      _pendingGroupId = arg['groupId'] as String;
      _pendingGroupName = arg['groupName'] is String ? arg['groupName'] as String : null;
      _loadFreshData(_pendingGroupId!);
    }
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
      // Only surface the error when we have nothing else to render.
      if (_group == null) {
        setState(() => _loadError = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loadingGroup = false);
    }
    if (_group == null) return; // bail out of follow-up loads if group never resolved

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

  Future<void> _showAddMemberDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Add Member',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'User ID',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFe2b96f)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add', style: TextStyle(color: Color(0xFFe2b96f))),
          ),
        ],
      ),
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
      messenger.showSnackBar(const SnackBar(content: Text('Could not create invite')));
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

    // Let the host pick kalaams for the initial queue. Returns the picked
    // IDs in tap order; null means the host cancelled.
    final picked = await showSessionQueueBuilder(context);
    if (picked == null) return; // host cancelled
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = await context.read<GroupProvider>().startSession(
            group.id,
            kalaamIds: picked.isEmpty ? null : picked,
          );
      if (!mounted) return;
      if (session != null) {
        Navigator.pushNamed(context, '/group-teleprompter', arguments: session);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (group == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0f0f1a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a1a2e),
          title: Text(
            _pendingGroupName ?? 'Group',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: _loadError != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFe2b96f),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () =>
                            _loadFreshData(_pendingGroupId ?? group?.id ?? ''),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(color: Color(0xFFe2b96f)),
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
      backgroundColor: const Color(0xFF0f0f1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(group.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_loadingGroup)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Color(0xFFe2b96f), strokeWidth: 2),
              ),
            ),
          if (isMember)
            PopupMenuButton<String>(
              icon: const Icon(Icons.share, color: Color(0xFFe2b96f)),
              color: const Color(0xFF1a1a2e),
              onSelected: _createAndShareInvite,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'permanent',
                  child: ListTile(
                    leading: Icon(Icons.person_add, color: Color(0xFFe2b96f)),
                    title: Text('Invite member (permanent)',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                PopupMenuItem(
                  value: 'guest',
                  child: ListTile(
                    leading: Icon(Icons.flash_on, color: Color(0xFFe2b96f)),
                    title: Text('Guest pass (one session)',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(label: 'Members (${group.members.length})'),
            const SizedBox(height: 8),
            ...group.members.map((member) => _MemberTile(
                  member: member,
                  canDelete: isAdmin &&
                      member.id != group.createdById &&
                      member.id != currentUserId,
                  onDelete: () => _removeMember(member.id),
                )),
            const SizedBox(height: 32),
            _SectionHeader(label: 'Session'),
            const SizedBox(height: 12),
            if (_loadingSession)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFe2b96f)),
              )
            else if (_activeSession != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe2b96f),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Join Session',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/group-teleprompter',
                    arguments: _activeSession,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe2b96f),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.fiber_manual_record, size: 14),
                  label: const Text('Start Session',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: _startSession,
                ),
              ),
            const SizedBox(height: 24),
            if (_snapshots.isNotEmpty) ...[
              _SectionHeader(label: 'Past queues'),
              const SizedBox(height: 8),
              ..._snapshots.map(_buildSnapshotTile),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      // floatingActionButton: isAdmin
      //     ? FloatingActionButton(
      //         backgroundColor: const Color(0xFFe2b96f),
      //         onPressed: _showAddMemberDialog,
      //         child: const Icon(Icons.person_add, color: Colors.black),
      //       )
      //     : null,
    );
  }

  Widget _buildSnapshotTile(QueueSnapshotSummary s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.items.length} kalaams',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatDate(s.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                if (s.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.items.take(3).map((k) => k.title).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.replay,
                color: Color(0xFFe2b96f), size: 20),
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
        Navigator.pushNamed(context, '/group-teleprompter', arguments: session);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFe2b96f),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMember member;
  final bool canDelete;
  final VoidCallback onDelete;

  const _MemberTile({
    required this.member,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFe2b96f),
            backgroundImage:
                member.avatar != null ? NetworkImage(member.avatar!) : null,
            child: member.avatar == null
                ? Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          if (member.role == 'admin')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFe2b96f).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFe2b96f).withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                    color: Color(0xFFe2b96f),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
