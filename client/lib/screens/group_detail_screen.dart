import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_model.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../services/api_service.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupModel? _group;
  SessionModel? _activeSession;
  bool _loadingSession = false;
  bool _loadingGroup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_group == null) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is GroupModel) {
        _group = arg;
        _loadFreshData(arg.id);
      }
    }
  }

  Future<void> _loadFreshData(String groupId) async {
    setState(() => _loadingGroup = true);
    try {
      final fresh = await ApiService.getGroup(groupId);
      if (!mounted) return;
      setState(() => _group = fresh);
    } catch (_) {
      // keep stale data
    } finally {
      if (mounted) setState(() => _loadingGroup = false);
    }

    // also check for active session
    setState(() => _loadingSession = true);
    try {
      final active =
          await context.read<GroupProvider>().getActiveSession(groupId);
      if (!mounted) return;
      setState(() => _activeSession = active);
    } finally {
      if (mounted) setState(() => _loadingSession = false);
    }
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
            hintText: 'User ID or email',
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

  Future<void> _startSession() async {
    final group = _group;
    if (group == null) return;
    final session =
        await context.read<GroupProvider>().startSession(group.id);
    if (session != null && mounted) {
      Navigator.pushNamed(context, '/session', arguments: session);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start session')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (group == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0f0f1a),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFe2b96f))),
      );
    }

    final currentUserId =
        context.read<AuthProvider>().user?.id ?? '';
    final currentMember = group.members.firstWhere(
      (m) => m.id == currentUserId,
      orElse: () => GroupMember(id: '', name: '', role: 'member'),
    );
    final isAdmin = currentMember.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(group.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Members section ──
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

            // ── Session controls ──
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/session',
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: _startSession,
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFe2b96f),
              onPressed: _showAddMemberDialog,
              child: const Icon(Icons.person_add, color: Colors.black),
            )
          : null,
    );
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
                border:
                    Border.all(color: const Color(0xFFe2b96f).withValues(alpha: 0.4)),
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
