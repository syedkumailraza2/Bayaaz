import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kalaam_model.dart';
import '../providers/auth_provider.dart';
import '../providers/kalaam_provider.dart';

class KalaamCard extends StatelessWidget {
  final KalaamModel kalaam;
  final bool showDeleteButton;
  final bool showEditButton;
  final bool showVisibilityToggle;
  final VoidCallback? onDelete;

  /// If provided, tap calls this callback instead of navigating to the
  /// detail screen. Used by the queue picker bottom sheet so users select
  /// a kalaam rather than open it.
  final VoidCallback? onPick;

  const KalaamCard({
    super.key,
    required this.kalaam,
    this.showDeleteButton = false,
    this.showEditButton = false,
    this.showVisibilityToggle = false,
    this.onDelete,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(kalaam.category);
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isOwner = kalaam.author.id == currentUserId;
    final isSaved = context.watch<KalaamProvider>().isSaved(kalaam.id);

    return GestureDetector(
      onTap: onPick ?? () => Navigator.pushNamed(context, '/kalaam', arguments: kalaam),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: categoryColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      kalaam.category[0].toUpperCase() + kalaam.category.substring(1),
                      style: TextStyle(color: categoryColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  // Visibility toggle (owner only, in My Kalaams tab)
                  if (showVisibilityToggle && isOwner)
                    GestureDetector(
                      onTap: () => context.read<KalaamProvider>().toggleVisibility(kalaam.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kalaam.isPublic
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kalaam.isPublic
                                ? Colors.green.withValues(alpha: 0.4)
                                : Colors.orange.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              kalaam.isPublic ? Icons.public : Icons.lock_outline,
                              size: 12,
                              color: kalaam.isPublic ? Colors.greenAccent : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              kalaam.isPublic ? 'Public' : 'Private',
                              style: TextStyle(
                                fontSize: 11,
                                color: kalaam.isPublic ? Colors.greenAccent : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (!kalaam.isPublic)
                    const Icon(Icons.lock_outline, size: 14, color: Colors.white38),
                  // Save button (non-owners only)
                  if (!isOwner) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.read<KalaamProvider>().toggleSave(kalaam.id),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        size: 18,
                        color: isSaved ? const Color(0xFFe2b96f) : Colors.white38,
                      ),
                    ),
                  ],
                  // Edit button (owner only)
                  if (showEditButton && isOwner) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/edit', arguments: kalaam),
                      child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFe2b96f)),
                    ),
                  ],
                  // Delete button (owner only)
                  if (showDeleteButton && onDelete != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kalaam.title,
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (kalaam.poet != null && kalaam.poet!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '— ${kalaam.poet}',
                      style: const TextStyle(color: Color(0xFFe2b96f), fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (kalaam.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: kalaam.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(tag, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    kalaam.previewText,
                    style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.6),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: const Color(0xFFe2b96f),
                        backgroundImage: kalaam.author.avatar != null ? NetworkImage(kalaam.author.avatar!) : null,
                        child: kalaam.author.avatar == null
                            ? Text(
                                kalaam.author.name.isNotEmpty ? kalaam.author.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(kalaam.author.name, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      const Spacer(),
                      Text(
                        '${kalaam.createdAt.day}/${kalaam.createdAt.month}/${kalaam.createdAt.year}',
                        style: const TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'nauha':
        return const Color(0xFF5b8af5);
      case 'marsiya':
        return const Color(0xFFa855f7);
      case 'qasida':
        return const Color(0xFFe2b96f);
      case 'qata':
        return const Color(0xFF4ade80);
      default:
        return Colors.white54;
    }
  }
}
