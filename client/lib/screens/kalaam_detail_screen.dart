import 'package:flutter/material.dart';
import '../models/kalaam_model.dart';
import 'practice_launcher_sheet.dart';

class KalaamDetailScreen extends StatelessWidget {
  const KalaamDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kalaam = ModalRoute.of(context)!.settings.arguments as KalaamModel;

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        title: Text(
          kalaam.category[0].toUpperCase() + kalaam.category.substring(1),
          style: const TextStyle(color: Color(0xFFe2b96f)),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => showPracticeLauncher(context, kalaam),
            icon: const Icon(Icons.school_outlined, color: Color(0xFFe2b96f), size: 18),
            label: const Text('Practice', style: TextStyle(color: Color(0xFFe2b96f), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/majlis', arguments: kalaam),
            icon: const Icon(Icons.mic_none, color: Color(0xFFe2b96f), size: 18),
            label: const Text('Recite', style: TextStyle(color: Color(0xFFe2b96f), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kalaam.isPublic
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  kalaam.isPublic ? Icons.public : Icons.lock_outline,
                  size: 14,
                  color: kalaam.isPublic ? Colors.greenAccent : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  kalaam.isPublic ? 'Public' : 'Private',
                  style: TextStyle(
                    fontSize: 12,
                    color: kalaam.isPublic ? Colors.greenAccent : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Decorative top bar
            Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFe2b96f),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              kalaam.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold, height: 1.3),
            ),
            if (kalaam.poet != null && kalaam.poet!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '— ${kalaam.poet}',
                style: const TextStyle(color: Color(0xFFe2b96f), fontSize: 15, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 10),
            // Author row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFe2b96f),
                  backgroundImage: kalaam.author.avatar != null ? NetworkImage(kalaam.author.avatar!) : null,
                  child: kalaam.author.avatar == null
                      ? Text(
                          kalaam.author.name.isNotEmpty ? kalaam.author.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(kalaam.author.name, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(width: 16),
                Text(_formatDate(kalaam.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            // Tags
            if (kalaam.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: kalaam.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFe2b96f).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFe2b96f).withValues(alpha: 0.3)),
                  ),
                  child: Text(tag, style: const TextStyle(color: Color(0xFFe2b96f), fontSize: 11)),
                )).toList(),
              ),
            ],
            // Divider separating metadata from content
            const Divider(color: Colors.white10, height: 48),
            // Stanzas
            ...kalaam.content.asMap().entries.map((e) => _StanzaBlock(
              stanza: e.value,
              isLast: e.key == kalaam.content.length - 1,
            )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _StanzaBlock extends StatelessWidget {
  final Stanza stanza;
  final bool isLast;
  const _StanzaBlock({required this.stanza, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lines of the stanza — centered, flowing
        ...stanza.lines.map(
          (line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xDEFFFFFF),
                fontSize: 17,
                height: 1.8,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
        // Stanza divider (ornamental, not shown after last stanza)
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 40, height: 1, color: Colors.white12),
                const SizedBox(width: 10),
                const Text('✦', style: TextStyle(color: Color(0xFFe2b96f), fontSize: 12)),
                const SizedBox(width: 10),
                Container(width: 40, height: 1, color: Colors.white12),
              ],
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }
}
