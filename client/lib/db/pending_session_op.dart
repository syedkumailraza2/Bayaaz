import 'package:isar/isar.dart';

part 'pending_session_op.g.dart';

/// One queued offline mutation against a session. Drained FIFO in
/// [OfflineSyncService.drainPendingSessionOps]. Payload is opaque JSON the
/// drain decodes per [action].
///
/// Supported actions today:
///   - `addQueue`      payload: {kalaamId}
///   - `vote`          payload: {kalaamId}
///   - `removeQueue`   payload: {kalaamId}
///   - `pin`           payload: {kalaamId, pinned, pinPosition?}
///   - `lineAdvance`   payload: {stanza, line}
///   - `advanceToNext` payload: {}
@collection
class PendingSessionOp {
  Id id = Isar.autoIncrement;

  @Index()
  late String sessionId;

  late String action;

  /// JSON-encoded payload — see action comments above.
  late String payloadJson;

  late DateTime createdAt;

  int attemptCount = 0;
}
