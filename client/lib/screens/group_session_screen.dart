import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../services/socket_service.dart';

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
    if (!_initialized) {
      _initialized = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is SessionModel) {
        _initialSession = arg;
        _sessionId = arg.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<SessionProvider>().loadSession(arg.id);
          context.read<SessionProvider>().loadSuggestions(arg.id);
        });
      }
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
    final currentUserId =
        context.read<AuthProvider>().user?.id ?? '';
    final isHost = session?.hostId == currentUserId;

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
                final ok = await context
                    .read<SessionProvider>()
                    .endSession(session.id);
                if (ok && mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: isHost
          ? _HostView(session: session)
          : _MemberView(session: session),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFe2b96f),
        onPressed: () => _showKalamInputSheet(
          context: context,
          session: session,
          isHost: isHost,
        ),
        child: Icon(
          isHost ? Icons.playlist_add : Icons.add_comment_outlined,
          color: Colors.black,
        ),
      ),
    );
  }

  void _showKalamInputSheet({
    required BuildContext context,
    required SessionModel session,
    required bool isHost,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHost ? 'Add to Queue' : 'Suggest a Kalaam',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Kalaam ID',
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
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe2b96f),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final kalamId = controller.text.trim();
                  if (kalamId.isEmpty) return;
                  Navigator.pop(ctx);
                  if (isHost) {
                    await context
                        .read<SessionProvider>()
                        .addToQueue(session.id, kalamId);
                  } else {
                    await context
                        .read<SessionProvider>()
                        .suggestKalam(session.id, kalamId);
                  }
                },
                child: Text(
                  isHost ? 'Add to Queue' : 'Submit Suggestion',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Host View ───────────────────────────────────────────────────────────────

class _HostView extends StatelessWidget {
  final SessionModel session;
  const _HostView({required this.session});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    final currentKalam = session.currentKalam;
    final stanzaCount = currentKalam?.content.length ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Now Playing ──
        _SectionHeader(label: 'Now Playing'),
        const SizedBox(height: 10),
        _NowPlayingCard(
          kalamTitle: currentKalam?.title ?? session.currentKalamId ?? '—',
          stanza: session.currentStanza,
          stanzaCount: stanzaCount,
          isPlaying: session.isPlaying,
          onPlayPause: () => context.read<SessionProvider>().setPlayState(
                session.id,
                !session.isPlaying,
              ),
        ),
        const SizedBox(height: 12),

        // ── Stanza controls ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded,
                  color: Color(0xFFe2b96f), size: 30),
              onPressed: session.currentStanza > 0
                  ? () => context.read<SessionProvider>().setStanza(
                        session.id,
                        session.currentStanza - 1,
                        0,
                      )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              stanzaCount > 0
                  ? 'Stanza ${session.currentStanza + 1} / $stanzaCount'
                  : 'No kalam selected',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded,
                  color: Color(0xFFe2b96f), size: 30),
              onPressed: stanzaCount > 0 &&
                      session.currentStanza < stanzaCount - 1
                  ? () => context.read<SessionProvider>().setStanza(
                        session.id,
                        session.currentStanza + 1,
                        0,
                      )
                  : null,
            ),
          ],
        ),

        // ── Next Kalam button ──
        if (session.queue.length > session.currentQueueIndex + 1) ...[
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
              icon: const Icon(Icons.fast_forward_rounded),
              label: const Text('Next Kalam'),
              onPressed: () =>
                  context.read<SessionProvider>().skipToNext(session.id),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ── Queue ──
        _SectionHeader(label: 'Queue (${session.queue.length})'),
        const SizedBox(height: 8),
        if (session.queue.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Queue is empty. Tap + to add kalaams.',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          )
        else
          _ReorderableQueue(session: session),

        const SizedBox(height: 24),

        // ── Suggestions ──
        _SectionHeader(label: 'Suggestions'),
        const SizedBox(height: 8),
        _SuggestionsList(session: session, isHost: true),

        const SizedBox(height: 80),
      ],
    );
  }
}

// ─── Member View ─────────────────────────────────────────────────────────────

class _MemberView extends StatelessWidget {
  final SessionModel session;
  const _MemberView({required this.session});

  @override
  Widget build(BuildContext context) {
    final currentKalam = session.currentKalam;
    final stanzaCount = currentKalam?.content.length ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Now Playing (read-only) ──
        _SectionHeader(label: 'Now Playing'),
        const SizedBox(height: 10),
        _NowPlayingCard(
          kalamTitle: currentKalam?.title ?? session.currentKalamId ?? '—',
          stanza: session.currentStanza,
          stanzaCount: stanzaCount,
          isPlaying: session.isPlaying,
          readOnly: true,
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            stanzaCount > 0
                ? 'Stanza ${session.currentStanza + 1} / $stanzaCount'
                : 'No kalam selected',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),

        const SizedBox(height: 24),

        // ── Queue (read-only) ──
        _SectionHeader(label: 'Queue (${session.queue.length})'),
        const SizedBox(height: 8),
        if (session.queue.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Queue is empty.',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          )
        else
          ...List.generate(session.queue.length, (i) {
            final hasKalam = i < session.queueKalaams.length;
            final title = hasKalam
                ? session.queueKalaams[i].title
                : session.queue[i];
            final isCurrent = i == session.currentQueueIndex;
            return _QueueItemTile(
              index: i,
              title: title,
              isCurrent: isCurrent,
            );
          }),

        const SizedBox(height: 80),
      ],
    );
  }
}

// ─── Reorderable Queue ───────────────────────────────────────────────────────

class _ReorderableQueue extends StatelessWidget {
  final SessionModel session;
  const _ReorderableQueue({required this.session});

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: session.queue.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final reordered = List<String>.from(session.queue);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        context
            .read<SessionProvider>()
            .reorderQueue(session.id, reordered);
      },
      itemBuilder: (ctx, i) {
        final hasKalam = i < session.queueKalaams.length;
        final title =
            hasKalam ? session.queueKalaams[i].title : session.queue[i];
        final isCurrent = i == session.currentQueueIndex;
        return Container(
          key: ValueKey(session.queue[i]),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFFe2b96f).withValues(alpha: 0.1)
                : const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFFe2b96f).withValues(alpha: 0.4)
                  : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Text(
                '${i + 1}.',
                style: TextStyle(
                  color: isCurrent
                      ? const Color(0xFFe2b96f)
                      : Colors.white38,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isCurrent ? const Color(0xFFe2b96f) : Colors.white,
                    fontSize: 14,
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.redAccent, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => context
                    .read<SessionProvider>()
                    .removeFromQueue(session.id, session.queue[i]),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.drag_handle, color: Colors.white24, size: 18),
            ],
          ),
        );
      },
    );
  }
}

// ─── Suggestions List ────────────────────────────────────────────────────────

class _SuggestionsList extends StatelessWidget {
  final SessionModel session;
  final bool isHost;
  const _SuggestionsList({required this.session, required this.isHost});

  @override
  Widget build(BuildContext context) {
    final suggestions = context.watch<SessionProvider>().suggestions;
    final pending =
        suggestions.where((s) => s.status == 'pending').toList();

    if (pending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No pending suggestions.',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      );
    }

    return Column(
      children: pending.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.kalamTitle ?? s.kalamId,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    if (s.suggestedByName != null)
                      Text(
                        'by ${s.suggestedByName}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (isHost) ...[
                IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.greenAccent, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => context
                      .read<SessionProvider>()
                      .handleSuggestion(session.id, s.id, 'accepted'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined,
                      color: Colors.redAccent, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => context
                      .read<SessionProvider>()
                      .handleSuggestion(session.id, s.id, 'rejected'),
                ),
              ],
            ],
          ),
        );
      }).toList(),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe2b96f).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (!readOnly)
            GestureDetector(
              onTap: onPlayPause,
              child: Icon(
                isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                color: const Color(0xFFe2b96f),
                size: 44,
              ),
            )
          else
            Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: const Color(0xFFe2b96f).withValues(alpha: 0.5),
              size: 44,
            ),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Queue Item Tile (read-only) ─────────────────────────────────────────────

class _QueueItemTile extends StatelessWidget {
  final int index;
  final String title;
  final bool isCurrent;

  const _QueueItemTile({
    required this.index,
    required this.title,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFFe2b96f).withValues(alpha: 0.1)
            : const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFe2b96f).withValues(alpha: 0.4)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}.',
            style: TextStyle(
              color: isCurrent ? const Color(0xFFe2b96f) : Colors.white38,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isCurrent ? const Color(0xFFe2b96f) : Colors.white,
                fontSize: 14,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isCurrent)
            const Icon(Icons.graphic_eq, color: Color(0xFFe2b96f), size: 16),
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
