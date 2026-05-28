import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../db/isar_service.dart';
import '../models/kalaam_model.dart';
import '../services/api_service.dart';
import '../services/offline_sync_service.dart';
import '../services/socket_service.dart';
import 'connectivity_provider.dart';

class KalaamProvider extends ChangeNotifier {
  // Feed (home tab) — paginated, filtered server-side by category
  List<KalaamModel> _feed = [];
  bool _feedLoading = false;
  bool _feedLoadingMore = false;
  String? _feedError;
  String? _selectedCategory;
  int _feedPage = 1;
  bool _feedHasMore = false;
  static const int _feedLimit = 20;

  // My / Saved
  List<KalaamModel> _myKalaams = [];
  List<KalaamModel> _savedKalaams = [];
  Set<String> _savedIds = {};
  bool _myLoading = false;
  bool _savedLoading = false;
  String? _myError;
  String? _savedError;

  // Search (search screen) — paginated, server-side q/tag/category
  List<KalaamModel> _searchResults = [];
  bool _searchLoading = false;
  bool _searchLoadingMore = false;
  String? _searchError;
  String _searchQuery = '';
  String? _searchTag;
  String? _searchCategory;
  int _searchPage = 1;
  bool _searchHasMore = false;
  static const int _searchLimit = 20;

  ConnectivityProvider? _connectivity;
  bool get _isOnline => _connectivity?.isOnline ?? true;
  OfflineSyncService get _sync => OfflineSyncService.instance;

  // ── Realtime engagement plumbing ────────────────────────────────────────
  // The detail screen calls subscribeKalaam(id) on open and unsubscribe on
  // close. We attach a single `kalaam:engagement` listener the first time a
  // subscription is requested and reference-count it so we don't tear it
  // down while another card/screen still cares.
  final Set<String> _subscribedKalaamIds = <String>{};
  bool _engagementListenerAttached = false;

  /// Wired from main.dart via ChangeNotifierProxyProvider.
  void attachConnectivity(ConnectivityProvider c) {
    _connectivity = c;
  }

  // ── Realtime engagement broadcasts ──────────────────────────────────────

  /// Joins the kalaam's engagement room so this client receives realtime
  /// like / save / view updates whenever any other user interacts. Lazy:
  /// the first call attaches the singleton socket listener; subsequent
  /// calls just register the id.
  Future<void> subscribeKalaam(String id) async {
    if (id.isEmpty) return;
    _subscribedKalaamIds.add(id);
    if (!_engagementListenerAttached) {
      _engagementListenerAttached = true;
      try {
        await SocketService().connect();
      } catch (e) {
        debugPrint('[engagement] socket connect failed: $e');
      }
      SocketService().on('kalaam:engagement', _onEngagementEvent);
    }
    SocketService().joinKalaam(id);
  }

  /// Stops listening for engagement updates for the given kalaam. We keep
  /// the global listener attached because re-attaching on every screen
  /// open would race against in-flight events.
  void unsubscribeKalaam(String id) {
    if (id.isEmpty) return;
    _subscribedKalaamIds.remove(id);
    SocketService().leaveKalaam(id);
  }

  void _onEngagementEvent(dynamic data) {
    if (data is! Map) return;
    final id = data['kalaamId']?.toString();
    if (id == null || id.isEmpty) return;
    final source = _findKalaamInMemory(id);
    if (source == null) return;
    final likesCount = (data['likesCount'] as num?)?.toInt();
    final savesCount = (data['savesCount'] as num?)?.toInt();
    final reads = (data['reads'] as num?)?.toInt();
    if (likesCount == null && savesCount == null && reads == null) return;
    _applyKalaamUpdate(source.copyWith(
      likesCount: likesCount ?? source.likesCount,
      savesCount: savesCount ?? source.savesCount,
      reads: reads ?? source.reads,
    ));
    notifyListeners();
  }

  // Getters — feed
  List<KalaamModel> get feed => _feed;
  bool get feedLoading => _feedLoading;
  bool get feedLoadingMore => _feedLoadingMore;
  String? get feedError => _feedError;
  String? get selectedCategory => _selectedCategory;
  bool get feedHasMore => _feedHasMore;

  // Getters — my / saved
  List<KalaamModel> get myKalaams => _myKalaams;
  List<KalaamModel> get savedKalaams => _savedKalaams;
  Set<String> get savedIds => _savedIds;
  bool get myLoading => _myLoading;
  bool get savedLoading => _savedLoading;
  String? get myError => _myError;
  String? get savedError => _savedError;

  // Getters — search
  List<KalaamModel> get searchResults => _searchResults;
  bool get searchLoading => _searchLoading;
  bool get searchLoadingMore => _searchLoadingMore;
  String? get searchError => _searchError;
  String get searchQuery => _searchQuery;
  String? get searchTag => _searchTag;
  String? get searchCategory => _searchCategory;
  bool get searchHasMore => _searchHasMore;

  bool isSaved(String id) => _savedIds.contains(id);

  /// Hydrate the feed list from Isar without making a network call.
  /// Safe to call before the first network sync; serves the cached 40.
  Future<void> hydrateFeedFromCache() async {
    if (!IsarService.instance.isOpen) return;
    final cached = await _sync.readCachedFeed();
    if (cached.isEmpty) return;
    _feed = cached;
    _feedHasMore = false;
    notifyListeners();
  }

  /// Hydrate the saved (Bayaaz) list and my-kalaams list from Isar so the
  /// My Bayaaz tab paints from cache before any network call resolves.
  Future<void> hydrateMyBayaazFromCache() async {
    if (!IsarService.instance.isOpen) return;
    final saved = await _sync.readCachedSaved();
    if (saved.isNotEmpty) {
      _savedKalaams = saved;
      _savedIds = saved.map((k) => k.id).toSet();
    }
    final mine = await _sync.readCachedMy();
    if (mine.isNotEmpty) {
      _myKalaams = mine;
    }
    if (saved.isNotEmpty || mine.isNotEmpty) {
      notifyListeners();
    }
  }

  // ─── Feed ─────────────────────────────────────────────────────────────────

  Future<void> loadFeed({String? category}) async {
    // Show spinner only when we have nothing to render. If the splash already
    // hydrated a cached feed, keep it visible while we refresh in the background.
    _feedLoading = _feed.isEmpty;
    _feedError = null;
    _selectedCategory = category;
    _feedPage = 1;
    notifyListeners();

    if (!_isOnline) {
      try {
        final cached = await _sync.readCachedFeed();
        _feed = category == null
            ? cached
            : cached.where((k) => k.category == category).toList();
        _feedHasMore = false;
      } catch (e) {
        _feedError = 'Offline cache unavailable';
      } finally {
        _feedLoading = false;
        notifyListeners();
      }
      return;
    }

    try {
      final pageData = await ApiService.getPublicKalaams(
        category: category,
        page: _feedPage,
        limit: _feedLimit,
      );
      _feed = pageData.items;
      _feedHasMore = pageData.hasMore;
      // Cache the unfiltered first page only.
      if (category == null) {
        await _sync.writeFeedPage(1, pageData.items);
      }
    } catch (e) {
      // Online fetch failed — fall back to cache so the user sees content.
      try {
        final cached = await _sync.readCachedFeed();
        if (cached.isNotEmpty) {
          _feed = category == null
              ? cached
              : cached.where((k) => k.category == category).toList();
          _feedHasMore = false;
          _feedError = null;
        } else {
          _feedError = _humanizeError(e);
        }
      } catch (_) {
        _feedError = _humanizeError(e);
      }
    } finally {
      _feedLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreFeed() async {
    if (_feedLoading || _feedLoadingMore || !_feedHasMore) return;
    if (!_isOnline) return; // offline: cache caps at 40, no load-more
    _feedLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _feedPage + 1;
      final pageData = await ApiService.getPublicKalaams(
        category: _selectedCategory,
        page: nextPage,
        limit: _feedLimit,
      );
      _feed.addAll(pageData.items);
      _feedPage = pageData.page;
      _feedHasMore = pageData.hasMore;
      // Persist the unfiltered second page; pages ≥3 stay memory-only.
      if (_selectedCategory == null && nextPage == 2) {
        await _sync.writeFeedPage(2, pageData.items);
      }
    } catch (_) {
      // swallow — keep existing items
    } finally {
      _feedLoadingMore = false;
      notifyListeners();
    }
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  Future<void> runSearch({
    String? q,
    String? tag,
    String? category,
  }) async {
    _searchQuery = q ?? '';
    _searchTag = tag;
    _searchCategory = category;
    _searchPage = 1;
    _searchLoading = true;
    _searchError = null;
    notifyListeners();

    if (!_isOnline) {
      try {
        final cached = await _sync.readCachedFeed();
        _searchResults = _applyFiltersOffline(cached);
        _searchHasMore = false;
      } catch (_) {
        _searchError = 'Offline cache unavailable';
      } finally {
        _searchLoading = false;
        notifyListeners();
      }
      return;
    }

    try {
      final pageData = await ApiService.getPublicKalaams(
        q: _searchQuery.isEmpty ? null : _searchQuery,
        tag: _searchTag,
        category: _searchCategory,
        page: _searchPage,
        limit: _searchLimit,
      );
      _searchResults = pageData.items;
      _searchHasMore = pageData.hasMore;
    } catch (e) {
      // Network failed — fall back to filtering the cached 40.
      try {
        final cached = await _sync.readCachedFeed();
        if (cached.isNotEmpty) {
          _searchResults = _applyFiltersOffline(cached);
          _searchHasMore = false;
        } else {
          _searchError = _humanizeError(e);
        }
      } catch (_) {
        _searchError = _humanizeError(e);
      }
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSearch() async {
    if (_searchLoading || _searchLoadingMore || !_searchHasMore) return;
    if (!_isOnline) return;
    _searchLoadingMore = true;
    notifyListeners();
    try {
      final pageData = await ApiService.getPublicKalaams(
        q: _searchQuery.isEmpty ? null : _searchQuery,
        tag: _searchTag,
        category: _searchCategory,
        page: _searchPage + 1,
        limit: _searchLimit,
      );
      _searchResults.addAll(pageData.items);
      _searchPage = pageData.page;
      _searchHasMore = pageData.hasMore;
    } catch (_) {
      // swallow
    } finally {
      _searchLoadingMore = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchTag = null;
    _searchCategory = null;
    _searchResults = [];
    _searchHasMore = false;
    _searchPage = 1;
    notifyListeners();
  }

  /// Mirror of the server-side `q`/`tag`/`category` filter for offline mode.
  List<KalaamModel> _applyFiltersOffline(List<KalaamModel> source) {
    final q = _searchQuery.trim().toLowerCase();
    return source.where((k) {
      if (_searchCategory != null && k.category != _searchCategory) return false;
      if (_searchTag != null && !k.tags.contains(_searchTag)) return false;
      if (q.isEmpty) return true;
      if (k.title.toLowerCase().contains(q)) return true;
      if ((k.poet ?? '').toLowerCase().contains(q)) return true;
      if (k.tags.any((t) => t.toLowerCase().contains(q))) return true;
      for (final stanza in k.content) {
        for (final line in stanza.lines) {
          if (line.toLowerCase().contains(q)) return true;
        }
      }
      return false;
    }).toList();
  }

  // ─── My / Saved ───────────────────────────────────────────────────────────

  Future<void> loadMyKalaams() async {
    _myLoading = _myKalaams.isEmpty;
    _myError = null;
    notifyListeners();

    if (!_isOnline) {
      try {
        _myKalaams = await _sync.readCachedMy();
        if (_myKalaams.isEmpty) {
          _myError = 'No cached kalaams. Connect to load yours.';
        }
      } catch (_) {
        _myError = 'Offline cache unavailable';
      } finally {
        _myLoading = false;
        notifyListeners();
      }
      return;
    }

    try {
      final stale = await _sync.isMyCacheStale();
      if (!stale) {
        final cached = await _sync.readCachedMy();
        if (cached.isNotEmpty) {
          _myKalaams = cached;
          _myLoading = false;
          notifyListeners();
          return;
        }
      }
      _myKalaams = await ApiService.getMyKalaams();
      await _sync.replaceMyCache(_myKalaams);
    } catch (e) {
      // Network failed — fall back to cache.
      try {
        final cached = await _sync.readCachedMy();
        if (cached.isNotEmpty) {
          _myKalaams = cached;
        } else {
          _myError = _humanizeError(e);
        }
      } catch (_) {
        _myError = _humanizeError(e);
      }
    } finally {
      _myLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedKalaams() async {
    _savedLoading = _savedKalaams.isEmpty;
    _savedError = null;
    notifyListeners();

    if (!_isOnline) {
      try {
        _savedKalaams = await _sync.readCachedSaved();
        _savedIds = _savedKalaams.map((k) => k.id).toSet();
      } catch (_) {
        _savedError = 'Offline cache unavailable';
      } finally {
        _savedLoading = false;
        notifyListeners();
      }
      return;
    }

    // Online: serve cache when fresh, refetch+replace when stale.
    try {
      final stale = await _sync.isSavedCacheStale();
      if (!stale) {
        final cached = await _sync.readCachedSaved();
        if (cached.isNotEmpty) {
          _savedKalaams = cached;
          _savedIds = _savedKalaams.map((k) => k.id).toSet();
          _savedLoading = false;
          notifyListeners();
          return;
        }
      }
      _savedKalaams = await ApiService.getSavedKalaams();
      _savedIds = _savedKalaams.map((k) => k.id).toSet();
      await _sync.replaceSavedCache(_savedKalaams);
    } catch (e) {
      // Network failed — fall back to whatever is cached.
      try {
        final cached = await _sync.readCachedSaved();
        if (cached.isNotEmpty) {
          _savedKalaams = cached;
          _savedIds = _savedKalaams.map((k) => k.id).toSet();
        } else {
          _savedError = _humanizeError(e);
        }
      } catch (_) {
        _savedError = _humanizeError(e);
      }
    } finally {
      _savedLoading = false;
      notifyListeners();
    }
  }

  /// Strip stack traces and socket-level details from network errors so the UI
  /// doesn't render `ClientException with SocketConnection refused...` blobs.
  String _humanizeError(Object e) {
    final raw = e.toString();
    final isNetworky = raw.contains('SocketException') ||
        raw.contains('SocketConnection') ||
        raw.contains('Connection refused') ||
        raw.contains('Cannot reach') ||
        raw.contains('Failed host lookup') ||
        raw.contains('ClientException') ||
        raw.contains('TimeoutException');
    if (isNetworky) {
      return 'Couldn\'t reach server. Check your connection.';
    }
    return raw.replaceAll('Exception: ', '');
  }

  // ─── Mutations ────────────────────────────────────────────────────────────

  Future<bool> toggleSave(String id) async {
    final wasSaved = _savedIds.contains(id);
    final willSave = !wasSaved;

    // Look up the kalaam in any in-memory list — we need full content to
    // mirror it into _savedKalaams and the Isar cache.
    final source = _findKalaamInMemory(id);

    // Apply the optimistic save-count bump everywhere the kalaam appears
    // so the detail screen counter ticks the moment the user taps.
    void applyOptimistic({required bool saved}) {
      if (source == null) return;
      final delta = saved ? 1 : -1;
      _applyKalaamUpdate(source.copyWith(
        savedByMe: saved,
        savesCount: (source.savesCount + delta).clamp(0, 1 << 31),
      ));
    }

    if (!_isOnline) {
      if (willSave) {
        if (source == null) return false; // nothing to save offline
        _savedIds.add(id);
        _savedKalaams.removeWhere((k) => k.id == id);
        applyOptimistic(saved: true);
        // Use the patched copy so the cached list matches the live counters.
        final patched = _findKalaamInMemory(id) ?? source;
        _savedKalaams.insert(0, patched);
        await _sync.stashOfflineSave(patched);
      } else {
        _savedIds.remove(id);
        _savedKalaams.removeWhere((k) => k.id == id);
        applyOptimistic(saved: false);
        await _sync.stashOfflineUnsave(id);
      }
      notifyListeners();
      return willSave;
    }

    // Optimistic flip — the server response below reconciles the exact
    // count (and rolls us back if the round-trip fails).
    applyOptimistic(saved: willSave);
    if (willSave) {
      _savedIds.add(id);
    } else {
      _savedIds.remove(id);
      _savedKalaams.removeWhere((k) => k.id == id);
    }
    notifyListeners();

    try {
      final result = await ApiService.toggleSave(id);
      final saved = result['saved'] as bool;
      final savesCount = (result['savesCount'] as num?)?.toInt();
      final latest = _findKalaamInMemory(id);
      if (latest != null) {
        _applyKalaamUpdate(latest.copyWith(
          savedByMe: saved,
          savesCount: savesCount ?? latest.savesCount,
        ));
      }
      if (saved) {
        _savedIds.add(id);
        final s = _findKalaamInMemory(id) ?? source;
        if (s != null) {
          _savedKalaams.removeWhere((k) => k.id == id);
          _savedKalaams.insert(0, s);
          await _sync.mirrorOnlineSave(s);
        }
      } else {
        _savedIds.remove(id);
        _savedKalaams.removeWhere((k) => k.id == id);
        await _sync.mirrorOnlineUnsave(id);
      }
      notifyListeners();
      return saved;
    } catch (e) {
      // Roll back the optimistic flip so the UI stays honest.
      if (source != null) {
        _applyKalaamUpdate(source);
      }
      if (wasSaved) {
        _savedIds.add(id);
      } else {
        _savedIds.remove(id);
      }
      notifyListeners();
      return wasSaved;
    }
  }

  KalaamModel? _findKalaamInMemory(String id) {
    for (final list in [_feed, _searchResults, _savedKalaams, _myKalaams]) {
      for (final k in list) {
        if (k.id == id) return k;
      }
    }
    return null;
  }

  /// Optimistically toggle the current user's like and reconcile with the
  /// server. Returns the post-toggle liked state. When offline, the flip is
  /// stashed via OfflineSyncService and replayed on the next reconnect so
  /// the user's intent doesn't get silently dropped.
  Future<bool> toggleLike(String id) async {
    final source = _findKalaamInMemory(id);
    if (source == null) return false;

    final willLike = !source.likedByMe;
    final optimistic = source.copyWith(
      likedByMe: willLike,
      likesCount: (source.likesCount + (willLike ? 1 : -1)).clamp(0, 1 << 31),
    );
    _applyKalaamUpdate(optimistic);
    notifyListeners();

    if (!_isOnline) {
      // Server toggles are idempotent on user→post pairs, but the wire
      // format is a toggle, so two queued flips cancel out. Use the
      // queue's odd/even semantics: each stash records a single intent.
      await _sync.stashPendingLikeToggle(id);
      return willLike;
    }

    try {
      final result = await ApiService.toggleLike(id);
      final liked = result['liked'] == true;
      final count = (result['likesCount'] as num?)?.toInt() ?? optimistic.likesCount;
      _applyKalaamUpdate(source.copyWith(likedByMe: liked, likesCount: count));
      notifyListeners();
      return liked;
    } catch (_) {
      // Network failed mid-flight — keep the optimistic flip and queue the
      // intent so the drain replays it. Server is the canonical authority,
      // the engagement broadcast will fix the count on reconnect.
      await _sync.stashPendingLikeToggle(id);
      return willLike;
    }
  }

  // Kalaams the current process has already pinged /view for. The server
  // is idempotent per user (Kalaam.readers gates the increment), but we
  // dedupe here too so reopening the detail screen doesn't burn requests
  // or briefly flash an optimistic +1 the server then walks back.
  final Set<String> _viewedThisSession = <String>{};

  /// Records a detail-screen open. The server only bumps once per
  /// authenticated user; we never apply an optimistic +1 because reopens
  /// would otherwise show a 5→6→5 flicker as the authoritative count
  /// reconciles. When offline we stash the intent so the first view on a
  /// flaky connection still counts after the next sync.
  Future<void> recordView(String id) async {
    if (id.isEmpty) return;
    if (_viewedThisSession.contains(id)) return;
    _viewedThisSession.add(id);
    if (!_isOnline) {
      await _sync.stashPendingView(id);
      return;
    }
    try {
      final result = await ApiService.recordView(id);
      final reads = (result['reads'] as num?)?.toInt();
      if (reads == null) return;
      final latest = _findKalaamInMemory(id);
      if (latest != null && latest.reads != reads) {
        _applyKalaamUpdate(latest.copyWith(reads: reads));
        notifyListeners();
      }
    } catch (_) {
      // Counter is best-effort but we still want to count the view once
      // the connection recovers. Drop the in-process dedupe so the next
      // open retries, and queue an intent for the offline drain.
      _viewedThisSession.remove(id);
      await _sync.stashPendingView(id);
    }
  }

  /// Mirror an updated kalaam into every list that holds it. Used by the
  /// engagement endpoints (like / view) so a single tap stays consistent
  /// across feed, search, my-kalaams, and saved views.
  void _applyKalaamUpdate(KalaamModel updated) {
    _replaceInList(_feed, updated);
    _replaceInList(_searchResults, updated);
    _replaceInList(_savedKalaams, updated);
    _replaceInList(_myKalaams, updated);
  }

  /// Public accessor used by background sync paths (reference-audio upload
  /// drain, etc.) that receive a server-fresh kalaam outside the normal
  /// list-fetch flow and need to fan it into every cached list.
  void applyServerKalaam(KalaamModel updated) {
    _applyKalaamUpdate(updated);
    notifyListeners();
    unawaited(_persistMyCache());
    unawaited(_persistFeedFirstPage());
  }

  Future<bool> toggleVisibility(String id) async {
    if (!_isOnline) return false;
    try {
      final updated = await ApiService.toggleVisibility(id);
      final idx = _myKalaams.indexWhere((k) => k.id == id);
      if (idx != -1) {
        _myKalaams[idx] = updated;
        final feedIdx = _feed.indexWhere((k) => k.id == id);
        if (updated.isPublic && feedIdx == -1) {
          _feed.insert(0, updated);
        } else if (!updated.isPublic && feedIdx != -1) {
          _feed.removeAt(feedIdx);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<KalaamModel?> addKalaam({
    required String title,
    required List<Map<String, dynamic>> content,
    required String category,
    required bool isPublic,
    String? poet,
    List<String> tags = const [],
  }) async {
    if (!_isOnline) return null;
    try {
      final kalaam = await ApiService.createKalaam(
        title: title,
        content: content,
        category: category,
        isPublic: isPublic,
        poet: poet,
        tags: tags,
      );
      _myKalaams.insert(0, kalaam);
      if (isPublic) _feed.insert(0, kalaam);
      notifyListeners();
      // Mirror the new row into the Isar cache. Without this, the next
      // `loadMyKalaams` (fired by switching to the My tab) sees a fresh
      // cache and replaces `_myKalaams` with the cached list — silently
      // dropping the just-created kalaam.
      unawaited(_persistMyCache());
      if (isPublic) unawaited(_persistFeedFirstPage());
      return kalaam;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateKalaam({
    required String id,
    required String title,
    required List<Map<String, dynamic>> content,
    required String category,
    required bool isPublic,
    String? poet,
    List<String> tags = const [],
  }) async {
    if (!_isOnline) return false;
    try {
      final updated = await ApiService.updateKalaam(
        id: id,
        title: title,
        content: content,
        category: category,
        isPublic: isPublic,
        poet: poet,
        tags: tags,
      );
      _replaceInList(_myKalaams, updated);
      _replaceInList(_savedKalaams, updated);
      _replaceInList(_searchResults, updated);
      // Sync feed visibility
      final feedIdx = _feed.indexWhere((k) => k.id == updated.id);
      if (updated.isPublic) {
        if (feedIdx == -1) {
          _feed.insert(0, updated);
        } else {
          _feed[feedIdx] = updated;
        }
      } else if (feedIdx != -1) {
        _feed.removeAt(feedIdx);
      }
      notifyListeners();
      // Mirror mutations into the Isar caches so a subsequent tab-switch
      // doesn't clobber the in-memory list with the stale cached copy.
      unawaited(_persistMyCache());
      unawaited(_persistFeedFirstPage());
      return true;
    } catch (e) {
      return false;
    }
  }

  void _replaceInList(List<KalaamModel> list, KalaamModel updated) {
    final idx = list.indexWhere((k) => k.id == updated.id);
    if (idx != -1) list[idx] = updated;
  }

  /// Mirror the in-memory my-kalaams list into the Isar cache. Called after
  /// every local mutation (create/update/delete) so a follow-up
  /// `loadMyKalaams` that hits the fresh-TTL fast path doesn't replace
  /// the in-memory list with a stale cached snapshot.
  Future<void> _persistMyCache() async {
    if (!IsarService.instance.isOpen) return;
    try {
      await _sync.replaceMyCache(_myKalaams);
    } catch (_) {
      // Cache mirror is best-effort; an Isar transient won't block the UI.
    }
  }

  /// Mirror the head of the feed (page 1, top 20) into the Isar cache so
  /// public additions/edits/deletes survive the same fresh-TTL race as
  /// `_persistMyCache` above.
  Future<void> _persistFeedFirstPage() async {
    if (!IsarService.instance.isOpen) return;
    try {
      await _sync.writeFeedPage(1, _feed.take(20).toList());
    } catch (_) {
      // ditto — feed cache is a perf nicety, not a source of truth.
    }
  }

  Future<bool> deleteKalaam(String id) async {
    if (!_isOnline) return false;
    try {
      await ApiService.deleteKalaam(id);
      _myKalaams.removeWhere((k) => k.id == id);
      _feed.removeWhere((k) => k.id == id);
      _savedKalaams.removeWhere((k) => k.id == id);
      _searchResults.removeWhere((k) => k.id == id);
      _savedIds.remove(id);
      notifyListeners();
      unawaited(_persistMyCache());
      unawaited(_persistFeedFirstPage());
      return true;
    } catch (e) {
      return false;
    }
  }
}
