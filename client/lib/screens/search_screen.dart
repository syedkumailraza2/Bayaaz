import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kalaam_model.dart';
import '../providers/kalaam_provider.dart';
import '../widgets/kalaam_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = '';
  String? _selectedCategory;
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Ensure feed is loaded
      final provider = context.read<KalaamProvider>();
      if (provider.feed.isEmpty && !provider.feedLoading) {
        provider.loadFeed();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<KalaamModel> _applyFilters(List<KalaamModel> feed) {
    var result = feed;

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result.where((k) {
        if (k.title.toLowerCase().contains(q)) return true;
        if (k.poet != null && k.poet!.toLowerCase().contains(q)) return true;
        return k.content
            .any((s) => s.lines.any((l) => l.toLowerCase().contains(q)));
      }).toList();
    }

    if (_selectedCategory != null) {
      result = result.where((k) => k.category == _selectedCategory).toList();
    }

    if (_selectedTag != null) {
      result = result.where((k) => k.tags.contains(_selectedTag)).toList();
    }

    return result;
  }

  bool get _hasActiveFilters =>
      _query.isNotEmpty || _selectedCategory != null || _selectedTag != null;

  void _clearAll() {
    setState(() {
      _query = '';
      _selectedCategory = null;
      _selectedTag = null;
      _searchController.clear();
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KalaamProvider>();
    final allTags = provider.feed.expand((k) => k.tags).toSet().toList()..sort();
    final results = _applyFilters(provider.feed);

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: const Color(0xFFe2b96f),
          decoration: InputDecoration(
            hintText: 'Search kalaams, poets, lines…',
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(
                    onTap: () => setState(() {
                      _query = '';
                      _searchController.clear();
                    }),
                    child: const Icon(Icons.close, color: Colors.white38, size: 18),
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear', style: TextStyle(color: Color(0xFFe2b96f), fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category filter ──────────────────────────────────────────
          _FilterSection(
            label: 'Type',
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ...kKalaamCategories.map((cat) => _FilterChip(
                        label: cat[0].toUpperCase() + cat.substring(1),
                        selected: _selectedCategory == cat,
                        color: _categoryColor(cat),
                        onTap: () => setState(() =>
                            _selectedCategory = _selectedCategory == cat ? null : cat),
                      )),
                ],
              ),
            ),
          ),

          // ── Tag filter (only when tags exist) ────────────────────────
          if (allTags.isNotEmpty)
            _FilterSection(
              label: 'Tags',
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: allTags
                      .map((tag) => _FilterChip(
                            label: tag,
                            selected: _selectedTag == tag,
                            onTap: () => setState(() =>
                                _selectedTag = _selectedTag == tag ? null : tag),
                          ))
                      .toList(),
                ),
              ),
            ),

          const SizedBox(height: 4),

          // ── Active filter pills ──────────────────────────────────────
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (_query.isNotEmpty)
                    _ActivePill(
                      label: '"$_query"',
                      onRemove: () => setState(() {
                        _query = '';
                        _searchController.clear();
                      }),
                    ),
                  if (_selectedCategory != null)
                    _ActivePill(
                      label: _selectedCategory![0].toUpperCase() +
                          _selectedCategory!.substring(1),
                      onRemove: () => setState(() => _selectedCategory = null),
                    ),
                  if (_selectedTag != null)
                    _ActivePill(
                      label: '#$_selectedTag',
                      onRemove: () => setState(() => _selectedTag = null),
                    ),
                ],
              ),
            ),

          // ── Result count ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              provider.feedLoading
                  ? 'Loading…'
                  : _hasActiveFilters
                      ? '${results.length} result${results.length == 1 ? '' : 's'}'
                      : '${provider.feed.length} kalaam${provider.feed.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),

          // ── Results ──────────────────────────────────────────────────
          Expanded(
            child: provider.feedLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFe2b96f)))
                : results.isEmpty
                    ? _EmptyState(hasQuery: _hasActiveFilters)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: results.length,
                        itemBuilder: (ctx, i) => KalaamCard(kalaam: results[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'nauha':   return const Color(0xFF5b8af5);
      case 'marsiya': return const Color(0xFFa855f7);
      case 'qasida':  return const Color(0xFFe2b96f);
      case 'qata':    return const Color(0xFF4ade80);
      default:        return Colors.white54;
    }
  }
}

// ─── Filter Section Label ────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FilterSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFe2b96f);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.18) : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.withValues(alpha: 0.7) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : Colors.white60,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Active Filter Pill (removable) ─────────────────────────────────────────

class _ActivePill extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActivePill({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFe2b96f).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2b96f).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFe2b96f), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFFe2b96f)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off : Icons.auto_stories_outlined,
            size: 48,
            color: Colors.white12,
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery
                ? 'No kalaams match your search'
                : 'Start typing to search',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          if (hasQuery) ...[
            const SizedBox(height: 6),
            const Text(
              'Try different keywords or clear filters',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
