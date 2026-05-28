import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Small "BETA · 1.0.0-beta.1" chip rendered in two flavours:
///   - [BetaPill.onLight]  → ink-on-amber pill for the home header.
///   - [BetaPill.onTeal]   → translucent white pill for the splash screen.
///
/// Returns `SizedBox.shrink()` when [kIsBeta] is false, so production
/// builds drop it entirely without callers needing to gate.
class BetaPill extends StatelessWidget {
  final Color background;
  final Color foreground;
  final Color border;
  final bool showVersion;

  const BetaPill._({
    required this.background,
    required this.foreground,
    required this.border,
    this.showVersion = true,
  });

  /// Amber pill that reads well on light surfaces (home header).
  const BetaPill.onLight({bool showVersion = true})
      : this._(
          background: const Color(0xFFFFF4D6),
          foreground: const Color(0xFF8A5A00),
          border: const Color(0xFFE0B848),
          showVersion: showVersion,
        );

  /// Translucent white pill for the teal splash screen.
  const BetaPill.onTeal({bool showVersion = true})
      : this._(
          background: const Color(0x33FFFFFF),
          foreground: Colors.white,
          border: const Color(0x55FFFFFF),
          showVersion: showVersion,
        );

  @override
  Widget build(BuildContext context) {
    if (!kIsBeta) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BETA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: foreground,
            ),
          ),
          if (showVersion) ...[
            const SizedBox(width: 6),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: foreground.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              kAppVersionLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: foreground.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
