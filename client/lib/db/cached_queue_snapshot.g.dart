// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_queue_snapshot.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedQueueSnapshotCollection on Isar {
  IsarCollection<CachedQueueSnapshot> get cachedQueueSnapshots =>
      this.collection();
}

const CachedQueueSnapshotSchema = CollectionSchema(
  name: r'CachedQueueSnapshot',
  id: -6907088155757781569,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'groupId': PropertySchema(
      id: 1,
      name: r'groupId',
      type: IsarType.string,
    ),
    r'kalaamIds': PropertySchema(
      id: 2,
      name: r'kalaamIds',
      type: IsarType.stringList,
    ),
    r'kalaamTitles': PropertySchema(
      id: 3,
      name: r'kalaamTitles',
      type: IsarType.stringList,
    ),
    r'serverId': PropertySchema(
      id: 4,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'snapshotCreatedAt': PropertySchema(
      id: 5,
      name: r'snapshotCreatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _cachedQueueSnapshotEstimateSize,
  serialize: _cachedQueueSnapshotSerialize,
  deserialize: _cachedQueueSnapshotDeserialize,
  deserializeProp: _cachedQueueSnapshotDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'groupId': IndexSchema(
      id: -8523216633229774932,
      name: r'groupId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'groupId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedQueueSnapshotGetId,
  getLinks: _cachedQueueSnapshotGetLinks,
  attach: _cachedQueueSnapshotAttach,
  version: '3.1.0+1',
);

int _cachedQueueSnapshotEstimateSize(
  CachedQueueSnapshot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.groupId.length * 3;
  bytesCount += 3 + object.kalaamIds.length * 3;
  {
    for (var i = 0; i < object.kalaamIds.length; i++) {
      final value = object.kalaamIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.kalaamTitles.length * 3;
  {
    for (var i = 0; i < object.kalaamTitles.length; i++) {
      final value = object.kalaamTitles[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.serverId.length * 3;
  return bytesCount;
}

void _cachedQueueSnapshotSerialize(
  CachedQueueSnapshot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.groupId);
  writer.writeStringList(offsets[2], object.kalaamIds);
  writer.writeStringList(offsets[3], object.kalaamTitles);
  writer.writeString(offsets[4], object.serverId);
  writer.writeDateTime(offsets[5], object.snapshotCreatedAt);
}

CachedQueueSnapshot _cachedQueueSnapshotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedQueueSnapshot();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.groupId = reader.readString(offsets[1]);
  object.id = id;
  object.kalaamIds = reader.readStringList(offsets[2]) ?? [];
  object.kalaamTitles = reader.readStringList(offsets[3]) ?? [];
  object.serverId = reader.readString(offsets[4]);
  object.snapshotCreatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _cachedQueueSnapshotDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedQueueSnapshotGetId(CachedQueueSnapshot object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedQueueSnapshotGetLinks(
    CachedQueueSnapshot object) {
  return [];
}

void _cachedQueueSnapshotAttach(
    IsarCollection<dynamic> col, Id id, CachedQueueSnapshot object) {
  object.id = id;
}

extension CachedQueueSnapshotByIndex on IsarCollection<CachedQueueSnapshot> {
  Future<CachedQueueSnapshot?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  CachedQueueSnapshot? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<CachedQueueSnapshot?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<CachedQueueSnapshot?> getAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'serverId', values);
  }

  Future<int> deleteAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'serverId', values);
  }

  int deleteAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'serverId', values);
  }

  Future<Id> putByServerId(CachedQueueSnapshot object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(CachedQueueSnapshot object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<CachedQueueSnapshot> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<CachedQueueSnapshot> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension CachedQueueSnapshotQueryWhereSort
    on QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QWhere> {
  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedQueueSnapshotQueryWhere
    on QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QWhereClause> {
  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhereClause>
      serverIdNotEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhereClause>
      groupIdEqualTo(String groupId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'groupId',
        value: [groupId],
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterWhereClause>
      groupIdNotEqualTo(String groupId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupId',
              lower: [],
              upper: [groupId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupId',
              lower: [groupId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupId',
              lower: [groupId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupId',
              lower: [],
              upper: [groupId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedQueueSnapshotQueryFilter on QueryBuilder<CachedQueueSnapshot,
    CachedQueueSnapshot, QFilterCondition> {
  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      cachedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      cachedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      cachedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      groupIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kalaamIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kalaamIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kalaamIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kalaamIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kalaamIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamIds',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamIds',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamTitles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kalaamTitles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kalaamTitles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kalaamTitles',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kalaamTitles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kalaamTitles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamTitles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamTitles',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamTitles',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamTitles',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamTitles',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamTitles',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamTitles',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamTitles',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamTitles',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      kalaamTitlesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kalaamTitles',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      snapshotCreatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'snapshotCreatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      snapshotCreatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'snapshotCreatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      snapshotCreatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'snapshotCreatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterFilterCondition>
      snapshotCreatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'snapshotCreatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedQueueSnapshotQueryObject on QueryBuilder<CachedQueueSnapshot,
    CachedQueueSnapshot, QFilterCondition> {}

extension CachedQueueSnapshotQueryLinks on QueryBuilder<CachedQueueSnapshot,
    CachedQueueSnapshot, QFilterCondition> {}

extension CachedQueueSnapshotQuerySortBy
    on QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QSortBy> {
  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      sortByGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      sortByGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      sortBySnapshotCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotCreatedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      sortBySnapshotCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotCreatedAt', Sort.desc);
    });
  }
}

extension CachedQueueSnapshotQuerySortThenBy
    on QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QSortThenBy> {
  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenByGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenByGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenBySnapshotCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotCreatedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QAfterSortBy>
      thenBySnapshotCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotCreatedAt', Sort.desc);
    });
  }
}

extension CachedQueueSnapshotQueryWhereDistinct
    on QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QDistinct> {
  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QDistinct>
      distinctByGroupId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QDistinct>
      distinctByKalaamIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamIds');
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QDistinct>
      distinctByKalaamTitles() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamTitles');
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QDistinct>
      distinctBySnapshotCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snapshotCreatedAt');
    });
  }
}

extension CachedQueueSnapshotQueryProperty
    on QueryBuilder<CachedQueueSnapshot, CachedQueueSnapshot, QQueryProperty> {
  QueryBuilder<CachedQueueSnapshot, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedQueueSnapshot, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedQueueSnapshot, String, QQueryOperations>
      groupIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupId');
    });
  }

  QueryBuilder<CachedQueueSnapshot, List<String>, QQueryOperations>
      kalaamIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamIds');
    });
  }

  QueryBuilder<CachedQueueSnapshot, List<String>, QQueryOperations>
      kalaamTitlesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamTitles');
    });
  }

  QueryBuilder<CachedQueueSnapshot, String, QQueryOperations>
      serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<CachedQueueSnapshot, DateTime, QQueryOperations>
      snapshotCreatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snapshotCreatedAt');
    });
  }
}
