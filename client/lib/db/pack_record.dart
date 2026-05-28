import 'package:isar/isar.dart';

part 'pack_record.g.dart';

@collection
class PackRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String packId;

  late String version;
  late DateTime installedAt;
  late bool isValid;
}
