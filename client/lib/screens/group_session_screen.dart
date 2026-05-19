import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/queue_item_model.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/session_provider.dart';
import '../services/socket_service.dart';
import 'kalaam_picker_sheet.dart';

class GroupSessionScreen extends StatefulWidget {
  const GroupSessionScreen({super.key});

  @override
  State<GroupSessionScreen> createState() => _GroupSessionScreenState();
}

class _GroupSessionScreenState extends State<GroupSessionScreen> {
  SessionModel? _initialSession;
  bool _initialized = false;
  String? _sessionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is SessionModel) {
      _initialSession = arg;
      _sessionId = arg.id;
    } else if (arg is Map && arg['sessionId'] is String) {
      _sessionId = arg['sessionId'] as String;
    }

    final sid = _sessionId;
    if (sid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SessionProvider>().loadSession(sid);
        context.read<SessionProvider>().loadSuggestions(sid);
      });
    }
  }

  @override
  void dispose() {
    if (_sessionId != null) {
      SocketService().leaveSession(_sessionId!);
      for (final event in [
        'session:joined',
        'session:kalamChanged',
        'session:stanzaChanged',
        'session:playStateChanged',
        'session:queueUpdated',
        'session:newSuggestion',
        'session:suggestionHandled',
        'session:ended',
      ]) {
        SocketService().off(event);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final session = sessionProvider.session ?? _initialSession;
    final currentUserId = context.read<AuthProvider>().user?.id ?? '';
    final isHost = session?.hostId == currentUserId;
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    if (session == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0f0f1a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a1a2e),
          title: const Text('Session',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFe2b96f)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Session',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isHost)
            TextButton.icon(
              icon: const Icon(Icons.stop_circle_outlined,
                  color: Colors.redAccent, size: 18),
              label: const Text('End',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              onPressed: () async {
                final nav = Navigator.of(context);
                final ok = await context
                    .read<SessionProvider>()
                    .endSession(session.id);
                if (ok && mounted) nav.pop();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (!isOnline) const _OfflineBanner(),
          Expanded(
            child: _SessionBody(
              session: session,
              isHost: isHost,
              currentUserId: currentUserId,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFe2b96f),
        foregroundColor: Colors.black,
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final picked = await showKalaamPicker(context);
          if (picked == null || !context.mounted) return;
          final ok = await context
              .read<SessionProvider>()
              .addToQueue(session.id, picked);
          if (!ok) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not add to queue')),
            );
          }
        },
        icon: const Icon(Icons.playlist_add),
        label: const Text('Add'),
      ),
    );
  }
}

// ─── Offline banner ──────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.orange, size: 14),
          SizedBox(width: 6),
          Text(
            'Offline — changes will sync when you reconnect',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _SessionBody extends StatelessWidget {
  final SessionModel session;
  final bool isHost;
  final String currentUserId;
  const _SessionBody({
    required this.session,
    required this.isHost,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final currentKalam = session.currentKalam;
    final stanzaCount = currentKalam?.content.length ?? 0;
    final sorted = session.sortedQueue;
    final isPlaying = session.isPlaying;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(label: 'Now Playing'),
        const SizedBox(height: 10),
        _NowPlayingCard(
          kalamTitle: currentKalam?.title ?? session.currentKalamId ?? '—',
          stanza: session.currentStanza,
          stanzaCount: stanzaCount,
          isPlaying: isPlaying,
          readOnly: !isHost,
          onPlayPause: isHost
              ? () => context.read<SessionProvider>().setPlayState(
                    session.id,
                    !isPlaying,
                  )
              : null,
        ),
        const SizedBox(height: 12),
        if (session.currentKalamId != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe2b96f),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(isHost ? 'Open teleprompter' : 'Follow along'),
              onPressed: () => Navigator.pushNamed(
                context,
                '/group-teleprompter',
                arguments: {'sessionId': session.id},
              ),
            ),
          ),
        if (isHost && sorted.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFe2b96f)),
                foregroundColor: const Color(0xFFe2b96f),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Done — Next kalaam'),
              onPressed: () =>
                  context.read<SessionProvider>().advanceToNext(session.id),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _SectionHeader(label: 'Queue (${sorted.length})'),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Queue is empty. Tap “Add” to pick a kalaam.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          )
        else if (isHost)
          _HostQueueList(session: session, sorted: sorted, currentUserId: currentUserId)
        else
          _MemberQueueList(session: session, sorted: sorted, currentUserId: currentUserId),
        const SizedBox(height: 100),
      ],
    );
  }
}

// ─── Queue lists ─────────────────────────────────────────────────────────────

class _HostQueueList extends StatelessWidget {
  final SessionModel session;
  final List<SessionQueueItem> sorted;
  final String currentUserId;
  const _HostQueueList({
    required this.session,
    required this.sorted,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: sorted.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        HapticFeedback.selectionClick();
        // Reorder = "pin every item to the new index order". Server keeps votes.
        final reordered = List<SessionQueueItem>.from(sorted);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        final orderedIds = reordered.map((i) => i.kalaamId).toList();
        context.read<SessionProvider>().reorderQueue(session.id, orderedIds);
      },
      itemBuilder: (ctx, i) {
        final item = sorted[i];
        return _QueueRow(
          key: ValueKey(item.kalaamId),
          index: i,
          item: item,
          sessionId: session.id,
          currentUserId: currentUserId,
          isHost: true,
          isCurrent: session.currentKalamId == item.kalaamId,
          dragHandle: ReorderableDragStartListener(
            index: i,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.drag_handle, color: Colors.white24, size: 20),
            ),
          ),
        );
      },
    );
  }
}

class _MemberQueueList extends StatelessWidget {
  final SessionModel session;
  final List<SessionQueueItem> sorted;
  final String currentUserId;
  const _MemberQueueList({
    required this.session,
    required this.sorted,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < sorted.length; i++)
          _QueueRow(
            key: ValueKey(sorted[i].kalaamId),
            index: i,
            item: sorted[i],
            sessionId: session.id,
            currentUserId: currentUserId,
            isHost: false,
            isCurrent: session.currentKalamId == sorted[i].kalaamId,
          ),
      ],
    );
  }
}

// ─── Single queue row (vote + pin + drag affordances) ───────────────────────

class _QueueRow extends StatelessWidget {
  final int index;
  final SessionQueueItem item;
  final String sessionId;
  final String currentUserId;
  final bool isHost;
  final bool isCurrent;
  final Widget? dragHandle;

  const _QueueRow({
    super.key,
    required this.index,
    required this.item,
    required this.sessionId,
    required this.currentUserId,
    required this.isHost,
    required this.isCurrent,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final voted = item.hasVoteFrom(currentUserId);
    final pendingSync = item.pendingSync;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFFe2b96f).withValues(alpha: 0.1)
            : const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFe2b96f).withValues(alpha: 0.4)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isCurrent ? const Color(0xFFe2b96f) : Colors.white38,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.pinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.push_pin,
                            color: Color(0xFFe2b96f), size: 13),
                      ),
                    Flexible(
                      child: Text(
                        item.kalaamTitle ?? item.kalaamId,
                        style: TextStyle(
                          color: isCurrent
                              ? const Color(0xFFe2b96f)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (pendingSync)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.sync,
                            color: Colors.orangeAccent, size: 12),
                      ),
                  ],
                ),
                if (item.kalaamAuthorName != null &&
                    item.kalaamAuthorName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'by ${item.kalaamAuthorName}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          // Vote button
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context
                .read<SessionProvider>()
                .toggleVote(sessionId, item.kalaamId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    voted ? Icons.favorite : Icons.favorite_outline,
                    color: voted ? const Color(0xFFe2b96f) : Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${item.voteCount}',
                    style: TextStyle(
                      color: voted ? const Color(0xFFe2b96f) : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isHost)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
              color: const Color(0xFF1a1a2e),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                final p = context.read<SessionProvider>();
                if (value == 'pin') {
                  p.pinItem(sessionId, item.kalaamId,
                      pinned: true, pinPosition: index);
                } else if (value == 'unpin') {
                  p.pinItem(sessionId, item.kalaamId, pinned: false);
                } else if (value == 'remove') {
                  p.removeFromQueue(sessionId, item.kalaamId);
                }
              },
              itemBuilder: (_) => [
                if (!item.pinned)
                  const PopupMenuItem(value: 'pin', child: Text('Pin to position')),
                if (item.pinned)
                  const PopupMenuItem(value: 'unpin', child: Text('Unpin')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
          if (dragHandle != null) dragHandle!,
        ],
      ),
    );
  }
}

// ─── Now Playing Card ─────────────────────────────────────────────────────────

class _NowPlayingCard extends StatelessWidget {
  final String kalamTitle;
  final int stanza;
  final int stanzaCount;
  final bool isPlaying;
  final bool readOnly;
  final VoidCallback? onPlayPause;

  const _NowPlayingCard({
    required this.kalamTitle,
    required this.stanza,
    required this.stanzaCount,
    required this.isPlaying,
    this.readOnly = false,
    this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      isPlaying
          ? Icons.pause_circle_filled_rounded
          : Icons.play_circle_filled_rounded,
      color: readOnly
          ? const Color(0xFFe2b96f).withValues(alpha: 0.5)
          : const Color(0xFFe2b96f),
      size: 44,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFe2b96f).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (readOnly) icon else GestureDetector(onTap: onPlayPause, child: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kalamTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (stanzaCount > 0)
                  Text(
                    'Stanza ${stanza + 1} of $stanzaCount',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

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
