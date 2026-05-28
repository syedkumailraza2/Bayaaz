import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kalaam_model.dart';
import '../providers/practice_provider.dart';
import '../services/device_capability_service.dart';

void showPracticeLauncher(BuildContext context, KalaamModel kalaam) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1a1a2e),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) => _PracticeLauncherSheet(kalaam: kalaam),
  );
}

class _PracticeLauncherSheet extends StatelessWidget {
  final KalaamModel kalaam;
  const _PracticeLauncherSheet({required this.kalaam});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PracticeProvider>();
    final progress = provider.getProgress(kalaam.id);
    final hasResume = progress != null && !progress.completed;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                const Text(
                  'Practice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/packs');
                  },
                  child: const Icon(Icons.download_outlined,
                      color: Color(0xFFe2b96f), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              kalaam.title,
              style: const TextStyle(
                color: Color(0xFFe2b96f),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            // Mode cards
            _ModeCard(
              icon: Icons.touch_app_outlined,
              title: 'Solo',
              subtitle: 'Read at your own pace',
              mode: 'solo',
              showResume: hasResume && (progress!.mode == 'solo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/practice',
                  arguments: {'kalaam': kalaam, 'mode': 'solo'},
                );
              },
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.auto_stories,
              title: 'Follow',
              subtitle: 'Auto-advance line by line',
              mode: 'follow',
              showResume: hasResume && (progress!.mode == 'follow'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/practice',
                  arguments: {'kalaam': kalaam, 'mode': 'follow'},
                );
              },
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.headphones_outlined,
              title: 'Listen',
              subtitle: 'Recite and get scored',
              mode: 'listen',
              showResume: false,
              tierBadge: _tierLabel(DeviceCapabilityService.instance.tier),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/practice',
                  arguments: {'kalaam': kalaam, 'mode': 'listen'},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String? _tierLabel(DeviceTier tier) => switch (tier) {
      DeviceTier.low => 'Basic',
      DeviceTier.mid => 'AI Ready',
      DeviceTier.high => 'AI Coaching',
    };

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String mode;
  final bool showResume;
  final bool disabled;
  final String? tierBadge;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.showResume,
    required this.onTap,
    // ignore: unused_element_parameter
    this.disabled = false,
    this.tierBadge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFF0f0f1a).withValues(alpha: 0.5)
              : const Color(0xFF0f0f1a),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled ? Colors.white12 : const Color(0xFFe2b96f).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: disabled
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFe2b96f).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: disabled ? Colors.white24 : const Color(0xFFe2b96f),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: disabled ? Colors.white38 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: disabled ? Colors.white24 : Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  if (showResume) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe2b96f).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFe2b96f).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'Resume',
                        style: TextStyle(
                          color: Color(0xFFe2b96f),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (tierBadge != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tierBadge!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!disabled)
              const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
