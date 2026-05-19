import '../models/kalaam_model.dart';
import 'cached_kalaam.dart';
import 'my_kalaam_cache.dart';
import 'saved_kalaam_cache.dart';

CachedKalaam toCachedKalaam(KalaamModel m, {required int feedPosition}) {
  return CachedKalaam()
    ..serverId = m.id
    ..title = m.title
    ..content = m.content.map(_toCachedStanza).toList()
    ..category = m.category
    ..isPublic = m.isPublic
    ..poet = m.poet
    ..authorId = m.author.id
    ..authorName = m.author.name
    ..authorAvatar = m.author.avatar
    ..createdAt = m.createdAt
    ..tags = List<String>.from(m.tags)
    ..feedPosition = feedPosition
    ..cachedAt = DateTime.now();
}

KalaamModel fromCachedKalaam(CachedKalaam c) => KalaamModel(
      id: c.serverId,
      title: c.title,
      content: c.content.map(_fromCachedStanza).toList(),
      category: c.category,
      isPublic: c.isPublic,
      poet: c.poet,
      author: KalaamAuthor(
        id: c.authorId,
        name: c.authorName,
        avatar: c.authorAvatar,
      ),
      createdAt: c.createdAt,
      tags: List<String>.from(c.tags),
    );

SavedKalaamCache toSavedKalaamCache(KalaamModel m, {required bool pendingSync}) {
  return SavedKalaamCache()
    ..serverId = m.id
    ..title = m.title
    ..content = m.content.map(_toCachedStanza).toList()
    ..category = m.category
    ..isPublic = m.isPublic
    ..poet = m.poet
    ..authorId = m.author.id
    ..authorName = m.author.name
    ..authorAvatar = m.author.avatar
    ..createdAt = m.createdAt
    ..tags = List<String>.from(m.tags)
    ..cachedAt = DateTime.now()
    ..pendingSync = pendingSync;
}

KalaamModel fromSavedKalaamCache(SavedKalaamCache c) => KalaamModel(
      id: c.serverId,
      title: c.title,
      content: c.content.map(_fromCachedStanza).toList(),
      category: c.category,
      isPublic: c.isPublic,
      poet: c.poet,
      author: KalaamAuthor(
        id: c.authorId,
        name: c.authorName,
        avatar: c.authorAvatar,
      ),
      createdAt: c.createdAt,
      tags: List<String>.from(c.tags),
    );

MyKalaamCache toMyKalaamCache(KalaamModel m) {
  return MyKalaamCache()
    ..serverId = m.id
    ..title = m.title
    ..content = m.content.map(_toCachedStanza).toList()
    ..category = m.category
    ..isPublic = m.isPublic
    ..poet = m.poet
    ..authorId = m.author.id
    ..authorName = m.author.name
    ..authorAvatar = m.author.avatar
    ..createdAt = m.createdAt
    ..tags = List<String>.from(m.tags)
    ..cachedAt = DateTime.now();
}

KalaamModel fromMyKalaamCache(MyKalaamCache c) => KalaamModel(
      id: c.serverId,
      title: c.title,
      content: c.content.map(_fromCachedStanza).toList(),
      category: c.category,
      isPublic: c.isPublic,
      poet: c.poet,
      author: KalaamAuthor(
        id: c.authorId,
        name: c.authorName,
        avatar: c.authorAvatar,
      ),
      createdAt: c.createdAt,
      tags: List<String>.from(c.tags),
    );

CachedStanza _toCachedStanza(Stanza s) => CachedStanza()
  ..stanzaNumber = s.stanzaNumber
  ..lines = List<String>.from(s.lines);

Stanza _fromCachedStanza(CachedStanza c) =>
    Stanza(stanzaNumber: c.stanzaNumber, lines: List<String>.from(c.lines));
