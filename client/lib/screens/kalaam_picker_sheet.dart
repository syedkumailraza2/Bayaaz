import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kalaam_model.dart';
import '../providers/kalaam_provider.dart';
import '../widgets/kalaam_card.dart';

/// Bottom sheet that lets the user pick a single kalaam from their saved
/// list or via search. Pops the picked [KalaamModel] back to the caller via
/// [Navigator.pop].
Future<KalaamModel?> showKalaamPicker(BuildContext context) {
  return showModalBottomSheet<KalaamModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0f0f1a),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.85,
      child: _KalaamPickerSheet(),
    ),
  );
}

/// Multi-select bottom sheet used when starting a session. The host taps
/// kalaams to toggle them into the initial session queue, then hits
/// "Start Session" to commit. Returns the chosen kalaam IDs in pick order,
/// or null if the host cancels.
Future<List<String>?> showSessionQueueBuilder(BuildContext context) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0f0f1a),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.9,
      child: _SessionQueueBuilderSheet(),
    ),
  );
}

class _KalaamPickerSheet extends StatefulWidget {
  const _KalaamPickerSheet();

  @override
  State<_KalaamPickerSheet> createState() => _KalaamPickerSheetState();
}

class _KalaamPickerSheetState extends State<_KalaamPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Kick off a refresh of the saved list so the user sees their latest
    // saves even if they just saved something on another device.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<KalaamProvider>();
      if (p.savedKalaams.isEmpty) p.loadSavedKalaams();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      context.read<KalaamProvider>().runSearch(q: v.trim().isEmpty ? null : v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Add to queue',
            style: TextStyle(
              color: Color(0xFFe2b96f),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFFe2b96f),
            labelColor: const Color(0xFFe2b96f),
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Saved'),
              Tab(text: 'Search'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _SavedList(onPick: (k) => Navigator.pop(context, k)),
                _SearchList(
                  searchController: _searchCtrl,
                  onSearchChanged: _onSearchChanged,
                  onPick: (k) => Navigator.pop(context, k),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedList extends StatelessWidget {
  final ValueChanged<KalaamModel> onPick;
  const _SavedList({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KalaamProvider>();
    if (p.savedLoading && p.savedKalaams.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFe2b96f)));
    }
    if (p.savedKalaams.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nothing in your Bayaaz yet.\nSave a kalaam to use it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: p.savedKalaams.length,
      itemBuilder: (_, i) {
        final k = p.savedKalaams[i];
        return KalaamCard(kalaam: k, onPick: () => onPick(k));
      },
    );
  }
}

class _SearchList extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<KalaamModel> onPick;
  const _SearchList({
    required this.searchController,
    required this.onSearchChanged,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KalaamProvider>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            autofocus: false,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search kalaams',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
              filled: true,
              fillColor: const Color(0xFF1a1a2e),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: () {
            if (p.searchLoading && p.searchResults.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFe2b96f)),
              );
            }
            if (p.searchResults.isEmpty) {
              return const Center(
                child: Text(
                  'Type to search.',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: p.searchResults.length,
              itemBuilder: (_, i) {
                final k = p.searchResults[i];
                return KalaamCard(kalaam: k, onPick: () => onPick(k));
              },
            );
          }(),
        ),
      ],
    );
  }
}

// ─── Multi-select queue builder ──────────────────────────────────────────────

class _SessionQueueBuilderSheet extends StatefulWidget {
  const _SessionQueueBuilderSheet();

  @override
  State<_SessionQueueBuilderSheet> createState() =>
      _SessionQueueBuilderSheetState();
}

class _SessionQueueBuilderSheetState extends State<_SessionQueueBuilderSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  // Ordered set of selected kalaam IDs — the queue order reflects pick order.
  final List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<KalaamProvider>();
      if (p.savedKalaams.isEmpty) p.loadSavedKalaams();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      context.read<KalaamProvider>().runSearch(q: v.trim().isEmpty ? null : v.trim());
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Build your session queue',
            style: TextStyle(
              color: Color(0xFFe2b96f),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to add kalaams. The host can rearrange or remove later.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFFe2b96f),
            labelColor: const Color(0xFFe2b96f),
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Saved'),
              Tab(text: 'Search'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _MultiSelectSavedList(
                  selectedIds: _selectedIds,
                  onToggle: _toggle,
                ),
                _MultiSelectSearchList(
                  searchController: _searchCtrl,
                  onSearchChanged: _onSearchChanged,
                  selectedIds: _selectedIds,
                  onToggle: _toggle,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFe2b96f),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_fill, size: 20),
                  label: Text(
                    _selectedIds.isEmpty
                        ? 'Start empty'
                        : 'Start Session (${_selectedIds.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => Navigator.pop(
                    context,
                    List<String>.from(_selectedIds),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSelectSavedList extends StatelessWidget {
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;
  const _MultiSelectSavedList({
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KalaamProvider>();
    if (p.savedLoading && p.savedKalaams.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFe2b96f)),
      );
    }
    if (p.savedKalaams.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nothing in your Bayaaz yet.\nSave a kalaam to use it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: p.savedKalaams.length,
      itemBuilder: (_, i) {
        final k = p.savedKalaams[i];
        final idx = selectedIds.indexOf(k.id);
        return Stack(
          children: [
            Opacity(
              opacity: idx >= 0 ? 1.0 : 0.85,
              child: KalaamCard(kalaam: k, onPick: () => onToggle(k.id)),
            ),
            if (idx >= 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFe2b96f),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MultiSelectSearchList extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;
  const _MultiSelectSearchList({
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KalaamProvider>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search kalaams',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
              filled: true,
              fillColor: const Color(0xFF1a1a2e),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: () {
            if (p.searchLoading && p.searchResults.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFe2b96f)),
              );
            }
            if (p.searchResults.isEmpty) {
              return const Center(
                child: Text(
                  'Type to search.',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              itemCount: p.searchResults.length,
              itemBuilder: (_, i) {
                final k = p.searchResults[i];
                final idx = selectedIds.indexOf(k.id);
                return Stack(
                  children: [
                    Opacity(
                      opacity: idx >= 0 ? 1.0 : 0.85,
                      child: KalaamCard(kalaam: k, onPick: () => onToggle(k.id)),
                    ),
                    if (idx >= 0)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFe2b96f),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          }(),
        ),
      ],
    );
  }
}
