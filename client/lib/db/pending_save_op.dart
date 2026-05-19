import 'package:isar/isar.dart';

part 'pending_save_op.g.dart';

@collection
class PendingSaveOp {
  Id id = Isar.autoIncrement;

  @Index()
  late String kalaamId;

  /// "save" or "unsave" — the desired terminal state.
  late String action;

  late DateTime createdAt;

  int attemptCount = 0;
}
