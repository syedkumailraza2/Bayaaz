import 'package:flutter/material.dart';

import '../services/device_capability_service.dart';
import '../services/pack_manager.dart';

const _kTeal = Color(0xFF234547);
const _kTealDeep = Color(0xFF1B3739);
const _kOrange = Color(0xFFFDA944);
const _kSurfaceMuted = Color(0xFFF4F4F4);
const _kInkPrimary = Color(0xFF1F1F1F);
const _kInkMuted = Color(0xFF9CA3AF);

class PackDownloadScreen extends StatefulWidget {
  const PackDownloadScreen({super.key});

  @override
  State<PackDownloadScreen> createState() => _PackDownloadScreenState();
}

class _PackDownloadScreenState extends State<PackDownloadScreen> {
  final Map<PackId, bool> _installed = {};
  final Map<PackId, double?> _progress = {};
  final Map<PackId, bool> _downloading = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkInstalled();
  }

  Future<void> _checkInstalled() async {
    for (final id in PackId.values) {
      _installed[id] = await PackManager.instance.isPackInstalled(id);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _download(PackId id) async {
    setState(() {
      _downloading[id] = true;
      _progress[id] = 0.0;
    });

    try {
      // Pass a real CDN URL when packs are hosted.
      await PackManager.instance.downloadPack(
        id,
        downloadUrl: null,
        onProgress: (p) {
          if (mounted) setState(() => _progress[id] = p);
        },
      );
      if (mounted) {
        setState(() {
          _installed[id] = true;
          _downloading[id] = false;
          _progress[id] = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloading[id] = false;
          _progress[id] = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed. Pack hosting not yet configured.')),
        );
      }
    }
  }

  Future<void> _delete(PackId id) async {
    await PackManager.instance.deletePack(id);
    if (mounted) setState(() => _installed[id] = false);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _Header(topPadding: top),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _TierBadge(tier: DeviceCapabilityService.instance.tier),
                  const SizedBox(height: 20),
                  for (final id in PackId.values) ...[
                    _PackCard(
                      id: id,
                      installed: _installed[id] ?? false,
                      downloading: _downloading[id] ?? false,
                      progress: _progress[id],
                      onDownload: () => _download(id),
                      onDelete: () => _delete(id),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPadding;
  const _Header({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kTealDeep, _kTeal],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'AI Packs',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final DeviceTier tier;
  const _TierBadge({required this.tier});

  String get _label => switch (tier) {
        DeviceTier.low => 'Low-end device',
        DeviceTier.mid => 'Mid-range device',
        DeviceTier.high => 'High-end device',
      };

  String get _note => switch (tier) {
        DeviceTier.low => 'Basic packs only. AI Coach requires a newer device.',
        DeviceTier.mid => 'All packs supported. AI Coach available.',
        DeviceTier.high =>
          'Full AI coaching available on this device.',
      };

  Color get _color => switch (tier) {
        DeviceTier.low => const Color(0xFFF87171),
        DeviceTier.mid => _kOrange,
        DeviceTier.high => const Color(0xFF22C55E),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kInkPrimary)),
                const SizedBox(height: 2),
                Text(_note,
                    style: const TextStyle(
                        fontSize: 12, color: _kInkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final PackId id;
  final bool installed;
  final bool downloading;
  final double? progress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _PackCard({
    required this.id,
    required this.installed,
    required this.downloading,
    required this.progress,
    required this.onDownload,
    required this.onDelete,
  });

  IconData get _icon => switch (id) {
        PackId.speech => Icons.record_voice_over_outlined,
        PackId.coach => Icons.psychology_outlined,
        PackId.pronunciation => Icons.spatial_audio_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _kTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kInkPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${id.version}',
                      style: const TextStyle(
                          fontSize: 12, color: _kInkMuted),
                    ),
                  ],
                ),
              ),
              if (installed && !downloading)
                _ActionChip(
                  label: 'Remove',
                  color: const Color(0xFFEF4444),
                  onTap: onDelete,
                )
              else if (!downloading)
                _ActionChip(
                  label: 'Download',
                  color: _kTeal,
                  onTap: onDownload,
                ),
            ],
          ),
          if (downloading && progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation(_kOrange),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${((progress ?? 0) * 100).round()}%',
              style:
                  const TextStyle(fontSize: 11, color: _kInkMuted),
            ),
          ] else if (installed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 14, color: Color(0xFF22C55E)),
                const SizedBox(width: 4),
                const Text(
                  'Installed',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF22C55E)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
