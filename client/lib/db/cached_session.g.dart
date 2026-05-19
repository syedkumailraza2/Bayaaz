// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedSessionCollection on Isar {
  IsarCollection<CachedSession> get cachedSessions => this.collection();
}

const CachedSessionSchema = CollectionSchema(
  name: r'CachedSession',
  id: -6186144986992044307,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'currentKalamId': PropertySchema(
      id: 1,
      name: r'currentKalamId',
      type: IsarType.string,
    ),
    r'currentLine': PropertySchema(
      id: 2,
      name: r'currentLine',
      type: IsarType.long,
    ),
    r'currentStanza': PropertySchema(
      id: 3,
      name: r'currentStanza',
      type: IsarType.long,
    ),
    r'groupId': PropertySchema(
      id: 4,
      name: r'groupId',
      type: IsarType.string,
    ),
    r'hostId': PropertySchema(
      id: 5,
      name: r'hostId',
      type: IsarType.string,
    ),
    r'isActive': PropertySchema(
      id: 6,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'isPlaying': PropertySchema(
      id: 7,
      name: r'isPlaying',
      type: IsarType.bool,
    ),
    r'serverId': PropertySchema(
      id: 8,
      name: r'serverId',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedSessionEstimateSize,
  serialize: _cachedSessionSerialize,
  deserialize: _cachedSessionDeserialize,
  deserializeProp: _cachedSessionDeserializeProp,
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedSessionGetId,
  getLinks: _cachedSessionGetLinks,
  attach: _cachedSessionAttach,
  version: '3.1.0+1',
);

int _cachedSessionEstimateSize(
  CachedSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.currentKalamId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.groupId.length * 3;
  bytesCount += 3 + object.hostId.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  return bytesCount;
}

void _cachedSessionSerialize(
  CachedSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.currentKalamId);
  writer.writeLong(offsets[2], object.currentLine);
  writer.writeLong(offsets[3], object.currentStanza);
  writer.writeString(offsets[4], object.groupId);
  writer.writeString(offsets[5], object.hostId);
  writer.writeBool(offsets[6], object.isActive);
  writer.writeBool(offsets[7], object.isPlaying);
  writer.writeString(offsets[8], object.serverId);
}

CachedSession _cachedSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedSession();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.currentKalamId = reader.readStringOrNull(offsets[1]);
  object.currentLine = reader.readLong(offsets[2]);
  object.currentStanza = reader.readLong(offsets[3]);
  object.groupId = reader.readString(offsets[4]);
  object.hostId = reader.readString(offsets[5]);
  object.id = id;
  object.isActive = reader.readBool(offsets[6]);
  object.isPlaying = reader.readBool(offsets[7]);
  object.serverId = reader.readString(offsets[8]);
  return object;
}

P _cachedSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedSessionGetId(CachedSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedSessionGetLinks(CachedSession object) {
  return [];
}

void _cachedSessionAttach(
    IsarCollection<dynamic> col, Id id, CachedSession object) {
  object.id = id;
}

extension CachedSessionByIndex on IsarCollection<CachedSession> {
  Future<CachedSession?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  CachedSession? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<CachedSession?>> getAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<CachedSession?> getAllByServerIdSync(List<String> serverIdValues) {
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

  Future<Id> putByServerId(CachedSession object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(CachedSession object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<CachedSession> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<CachedSession> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension CachedSessionQueryWhereSort
    on QueryBuilder<CachedSession, CachedSession, QWhere> {
  QueryBuilder<CachedSession, CachedSession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedSessionQueryWhere
    on QueryBuilder<CachedSession, CachedSession, QWhereClause> {
  QueryBuilder<CachedSession, CachedSession, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<CachedSession, CachedSession, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedSession, CachedSession, QAfterWhereClause> serverIdEqualTo(
      String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterWhereClause>
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
}

extension CachedSessionQueryFilter
    on QueryBuilder<CachedSession, CachedSession, QFilterCondition> {
  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currentKalamId',
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currentKalamId',
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentKalamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentKalamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentKalamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentKalamId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currentKalamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currentKalamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currentKalamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currentKalamId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentKalamId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentKalamIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currentKalamId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentLineEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentLine',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentLineGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentLine',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentLineLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentLine',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentLineBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentLine',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentStanzaEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStanza',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentStanzaGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentStanza',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentStanzaLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentStanza',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      currentStanzaBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentStanza',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      groupIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      groupIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      groupIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      groupIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hostId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hostId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hostId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hostId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hostId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hostId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hostId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hostId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hostId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      hostIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hostId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      isPlayingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPlaying',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
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

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }
}

extension CachedSessionQueryObject
    on QueryBuilder<CachedSession, CachedSession, QFilterCondition> {}

extension CachedSessionQueryLinks
    on QueryBuilder<CachedSession, CachedSession, QFilterCondition> {}

extension CachedSessionQuerySortBy
    on QueryBuilder<CachedSession, CachedSession, QSortBy> {
  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      sortByCurrentKalamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentKalamId', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      sortByCurrentKalamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentKalamId', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> sortByCurrentLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentLine', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      sortByCurrentLineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentLine', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      sortByCurrentStanza() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStanza', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      sortByCurrentStanzaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStanza', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> sortByGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> sortByGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> sortByHostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hostId', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> sortByHostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hostId', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> sortByIsPlaying() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPlaying', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      sortByIsPlayingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPlaying', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }
}

extension CachedSessionQuerySortThenBy
    on QueryBuilder<CachedSession, CachedSession, QSortThenBy> {
  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      thenByCurrentKalamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentKalamId', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      thenByCurrentKalamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentKalamId', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByCurrentLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentLine', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      thenByCurrentLineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentLine', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      thenByCurrentStanza() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStanza', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      thenByCurrentStanzaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStanza', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByHostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hostId', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByHostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hostId', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByIsPlaying() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPlaying', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      thenByIsPlayingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPlaying', Sort.desc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }
}

extension CachedSessionQueryWhereDistinct
    on QueryBuilder<CachedSession, CachedSession, QDistinct> {
  QueryBuilder<CachedSession, CachedSession, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedSession, CachedSession, QDistinct>
      distinctByCurrentKalamId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentKalamId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QDistinct>
      distinctByCurrentLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentLine');
    });
  }

  QueryBuilder<CachedSession, CachedSession, QDistinct>
      distinctByCurrentStanza() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStanza');
    });
  }

  QueryBuilder<CachedSession, CachedSession, QDistinct> distinctByGroupId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QDistinct> distinctByHostId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hostId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedSession, CachedSession, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<CachedSession, CachedSession, QDistinct> distinctByIsPlaying() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPlaying');
    });
  }

  QueryBuilder<CachedSession, CachedSession, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }
}

extension CachedSessionQueryProperty
    on QueryBuilder<CachedSession, CachedSession, QQueryProperty> {
  QueryBuilder<CachedSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedSession, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedSession, String?, QQueryOperations>
      currentKalamIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentKalamId');
    });
  }

  QueryBuilder<CachedSession, int, QQueryOperations> currentLineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentLine');
    });
  }

  QueryBuilder<CachedSession, int, QQueryOperations> currentStanzaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStanza');
    });
  }

  QueryBuilder<CachedSession, String, QQueryOperations> groupIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupId');
    });
  }

  QueryBuilder<CachedSession, String, QQueryOperations> hostIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hostId');
    });
  }

  QueryBuilder<CachedSession, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<CachedSession, bool, QQueryOperations> isPlayingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPlaying');
    });
  }

  QueryBuilder<CachedSession, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }
}
