import 'dart:async';
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
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  String? _selectedCategory;
  String? _selectedTag;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      final provider = context.read<KalaamProvider>();
      // Ensure feed is loaded (powers the popular-tag panel)
      if (provider.feed.isEmpty && !provider.feedLoading) {
        provider.loadFeed();
      }
      // Run an initial empty search so popular tags + default results render
      provider.runSearch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      context.read<KalaamProvider>().loadMoreSearch();
    }
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  void _runSearch() {
    context.read<KalaamProvider>().runSearch(
          q: _query,
          tag: _selectedTag,
          category: _selectedCategory,
        );
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
    _runSearch();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KalaamProvider>();

    // Tag frequency from feed → popular tags
    final tagCounts = <String, int>{};
    for (final k in provider.feed) {
      for (final tag in k.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final popularTags = tagCounts.keys.toList()
      ..sort((a, b) {
        final byCount = tagCounts[b]!.compareTo(tagCounts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    final topPopularTags = popularTags.take(15).toList();

    final results = provider.searchResults;

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
                    onTap: () {
                      setState(() {
                        _query = '';
                        _searchController.clear();
                      });
                      _runSearch();
                    },
                    child: const Icon(Icons.close, color: Colors.white38, size: 18),
                  )
                : null,
          ),
          onChanged: (v) {
            setState(() => _query = v);
            _scheduleSearch();
          },
          onSubmitted: (_) {
            _debounce?.cancel();
            _runSearch();
          },
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
          // ── Popular tags (just below search bar) ─────────────────────
          if (topPopularTags.isNotEmpty)
            _FilterSection(
              label: 'Popular tags',
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: topPopularTags
                      .map((tag) => _FilterChip(
                            label: tag,
                            selected: _selectedTag == tag,
                            onTap: () {
                              setState(() => _selectedTag = _selectedTag == tag ? null : tag);
                              _runSearch();
                            },
                          ))
                      .toList(),
                ),
              ),
            ),

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
                    onTap: () {
                      setState(() => _selectedCategory = null);
                      _runSearch();
                    },
                  ),
                  ...kKalaamCategories.map((cat) => _FilterChip(
                        label: cat[0].toUpperCase() + cat.substring(1),
                        selected: _selectedCategory == cat,
                        color: _categoryColor(cat),
                        onTap: () {
                          setState(() =>
                              _selectedCategory = _selectedCategory == cat ? null : cat);
                          _runSearch();
                        },
                      )),
                ],
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
                      onRemove: () {
                        setState(() {
                          _query = '';
                          _searchController.clear();
                        });
                        _runSearch();
                      },
                    ),
                  if (_selectedCategory != null)
                    _ActivePill(
                      label: _selectedCategory![0].toUpperCase() +
                          _selectedCategory!.substring(1),
                      onRemove: () {
                        setState(() => _selectedCategory = null);
                        _runSearch();
                      },
                    ),
                  if (_selectedTag != null)
                    _ActivePill(
                      label: _selectedTag!,
                      onRemove: () {
                        setState(() => _selectedTag = null);
                        _runSearch();
                      },
                    ),
                ],
              ),
            ),

          // ── Result count ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              provider.searchLoading
                  ? 'Loading…'
                  : '${results.length} result${results.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),

          // ── Results ──────────────────────────────────────────────────
          Expanded(
            child: provider.searchLoading && results.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFe2b96f)))
                : provider.searchError != null
                    ? Center(
                        child: Text(provider.searchError!,
                            style: const TextStyle(color: Colors.redAccent)),
                      )
                    : results.isEmpty
                        ? _EmptyState(hasQuery: _hasActiveFilters)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: results.length + (provider.searchHasMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i >= results.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFe2b96f),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return KalaamCard(kalaam: results[i]);
                            },
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
                : 'Search for kalaams, poets, or lines',
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
