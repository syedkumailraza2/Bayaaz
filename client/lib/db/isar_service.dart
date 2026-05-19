import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'cached_kalaam.dart';
import 'cached_queue_item.dart';
import 'cached_queue_snapshot.dart';
import 'cached_session.dart';
import 'my_kalaam_cache.dart';
import 'pending_save_op.dart';
import 'pending_session_op.dart';
import 'saved_kalaam_cache.dart';
import 'sync_meta.dart';

class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Isar? _isar;
  Future<Isar>? _opening;

  Isar get db {
    final isar = _isar;
    if (isar == null) {
      throw StateError('IsarService.open() must be awaited before db is read');
    }
    return isar;
  }

  bool get isOpen => _isar != null;

  Future<Isar> open() async {
    if (_isar != null) return _isar!;
    return _opening ??= _doOpen();
  }

  Future<Isar> _doOpen() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        CachedKalaamSchema,
        SavedKalaamCacheSchema,
        MyKalaamCacheSchema,
        PendingSaveOpSchema,
        SyncMetaSchema,
        CachedSessionSchema,
        CachedQueueItemSchema,
        CachedQueueSnapshotSchema,
        PendingSessionOpSchema,
      ],
      directory: dir.path,
      name: 'bayaaz',
      inspector: false,
    );
    _isar = isar;
    return isar;
  }

  Future<void> close() async {
    final isar = _isar;
    _isar = null;
    _opening = null;
    if (isar != null) {
      await isar.close();
    }
  }
}
