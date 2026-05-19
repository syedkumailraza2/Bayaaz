// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_queue_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedQueueItemCollection on Isar {
  IsarCollection<CachedQueueItem> get cachedQueueItems => this.collection();
}

const CachedQueueItemSchema = CollectionSchema(
  name: r'CachedQueueItem',
  id: -8729603786093883280,
  properties: {
    r'addedAt': PropertySchema(
      id: 0,
      name: r'addedAt',
      type: IsarType.dateTime,
    ),
    r'addedById': PropertySchema(
      id: 1,
      name: r'addedById',
      type: IsarType.string,
    ),
    r'cachedAt': PropertySchema(
      id: 2,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'kalaamAuthorName': PropertySchema(
      id: 3,
      name: r'kalaamAuthorName',
      type: IsarType.string,
    ),
    r'kalaamCategory': PropertySchema(
      id: 4,
      name: r'kalaamCategory',
      type: IsarType.string,
    ),
    r'kalaamId': PropertySchema(
      id: 5,
      name: r'kalaamId',
      type: IsarType.string,
    ),
    r'kalaamTitle': PropertySchema(
      id: 6,
      name: r'kalaamTitle',
      type: IsarType.string,
    ),
    r'pendingSync': PropertySchema(
      id: 7,
      name: r'pendingSync',
      type: IsarType.bool,
    ),
    r'pinPosition': PropertySchema(
      id: 8,
      name: r'pinPosition',
      type: IsarType.long,
    ),
    r'pinned': PropertySchema(
      id: 9,
      name: r'pinned',
      type: IsarType.bool,
    ),
    r'sessionId': PropertySchema(
      id: 10,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'voters': PropertySchema(
      id: 11,
      name: r'voters',
      type: IsarType.stringList,
    )
  },
  estimateSize: _cachedQueueItemEstimateSize,
  serialize: _cachedQueueItemSerialize,
  deserialize: _cachedQueueItemDeserialize,
  deserializeProp: _cachedQueueItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionId': IndexSchema(
      id: 6949518585047923839,
      name: r'sessionId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'kalaamId': IndexSchema(
      id: 5658280144504471660,
      name: r'kalaamId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'kalaamId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedQueueItemGetId,
  getLinks: _cachedQueueItemGetLinks,
  attach: _cachedQueueItemAttach,
  version: '3.1.0+1',
);

int _cachedQueueItemEstimateSize(
  CachedQueueItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.addedById.length * 3;
  {
    final value = object.kalaamAuthorName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.kalaamCategory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.kalaamId.length * 3;
  {
    final value = object.kalaamTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sessionId.length * 3;
  bytesCount += 3 + object.voters.length * 3;
  {
    for (var i = 0; i < object.voters.length; i++) {
      final value = object.voters[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _cachedQueueItemSerialize(
  CachedQueueItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.addedAt);
  writer.writeString(offsets[1], object.addedById);
  writer.writeDateTime(offsets[2], object.cachedAt);
  writer.writeString(offsets[3], object.kalaamAuthorName);
  writer.writeString(offsets[4], object.kalaamCategory);
  writer.writeString(offsets[5], object.kalaamId);
  writer.writeString(offsets[6], object.kalaamTitle);
  writer.writeBool(offsets[7], object.pendingSync);
  writer.writeLong(offsets[8], object.pinPosition);
  writer.writeBool(offsets[9], object.pinned);
  writer.writeString(offsets[10], object.sessionId);
  writer.writeStringList(offsets[11], object.voters);
}

CachedQueueItem _cachedQueueItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedQueueItem();
  object.addedAt = reader.readDateTime(offsets[0]);
  object.addedById = reader.readString(offsets[1]);
  object.cachedAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.kalaamAuthorName = reader.readStringOrNull(offsets[3]);
  object.kalaamCategory = reader.readStringOrNull(offsets[4]);
  object.kalaamId = reader.readString(offsets[5]);
  object.kalaamTitle = reader.readStringOrNull(offsets[6]);
  object.pendingSync = reader.readBool(offsets[7]);
  object.pinPosition = reader.readLongOrNull(offsets[8]);
  object.pinned = reader.readBool(offsets[9]);
  object.sessionId = reader.readString(offsets[10]);
  object.voters = reader.readStringList(offsets[11]) ?? [];
  return object;
}

P _cachedQueueItemDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedQueueItemGetId(CachedQueueItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedQueueItemGetLinks(CachedQueueItem object) {
  return [];
}

void _cachedQueueItemAttach(
    IsarCollection<dynamic> col, Id id, CachedQueueItem object) {
  object.id = id;
}

extension CachedQueueItemQueryWhereSort
    on QueryBuilder<CachedQueueItem, CachedQueueItem, QWhere> {
  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedQueueItemQueryWhere
    on QueryBuilder<CachedQueueItem, CachedQueueItem, QWhereClause> {
  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhereClause>
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

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhereClause>
      sessionIdEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [sessionId],
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhereClause>
      sessionIdNotEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhereClause>
      kalaamIdEqualTo(String kalaamId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'kalaamId',
        value: [kalaamId],
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterWhereClause>
      kalaamIdNotEqualTo(String kalaamId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kalaamId',
              lower: [],
              upper: [kalaamId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kalaamId',
              lower: [kalaamId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kalaamId',
              lower: [kalaamId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kalaamId',
              lower: [],
              upper: [kalaamId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedQueueItemQueryFilter
    on QueryBuilder<CachedQueueItem, CachedQueueItem, QFilterCondition> {
  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'addedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'addedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'addedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'addedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'addedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'addedById',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'addedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'addedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'addedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'addedById',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addedById',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      addedByIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'addedById',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
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

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
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

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
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

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
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

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
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

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
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

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'kalaamAuthorName',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'kalaamAuthorName',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamAuthorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kalaamAuthorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kalaamAuthorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kalaamAuthorName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kalaamAuthorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kalaamAuthorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamAuthorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamAuthorName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamAuthorName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamAuthorNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamAuthorName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'kalaamCategory',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'kalaamCategory',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kalaamCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kalaamCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kalaamCategory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kalaamCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kalaamCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamCategory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kalaamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kalaamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kalaamId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kalaamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kalaamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'kalaamTitle',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'kalaamTitle',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kalaamTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kalaamTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kalaamTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kalaamTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kalaamTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      kalaamTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      pendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingSync',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      pinPositionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pinPosition',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      pinPositionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pinPosition',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      pinPositionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pinPosition',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      pinPositionGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pinPosition',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      pinPositionLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pinPosition',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      pinPositionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pinPosition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      pinnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pinned',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'voters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'voters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'voters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'voters',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'voters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'voters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'voters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'voters',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'voters',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'voters',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voters',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voters',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voters',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voters',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voters',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterFilterCondition>
      votersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voters',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension CachedQueueItemQueryObject
    on QueryBuilder<CachedQueueItem, CachedQueueItem, QFilterCondition> {}

extension CachedQueueItemQueryLinks
    on QueryBuilder<CachedQueueItem, CachedQueueItem, QFilterCondition> {}

extension CachedQueueItemQuerySortBy
    on QueryBuilder<CachedQueueItem, CachedQueueItem, QSortBy> {
  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy> sortByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByAddedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByAddedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedById', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByAddedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedById', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByKalaamAuthorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamAuthorName', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByKalaamAuthorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamAuthorName', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByKalaamCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamCategory', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByKalaamCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamCategory', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByKalaamTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamTitle', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByKalaamTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamTitle', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByPinPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinPosition', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByPinPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinPosition', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy> sortByPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinned', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortByPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinned', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }
}

extension CachedQueueItemQuerySortThenBy
    on QueryBuilder<CachedQueueItem, CachedQueueItem, QSortThenBy> {
  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy> thenByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByAddedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByAddedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedById', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByAddedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedById', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByKalaamAuthorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamAuthorName', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByKalaamAuthorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamAuthorName', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByKalaamCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamCategory', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByKalaamCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamCategory', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByKalaamTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamTitle', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByKalaamTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamTitle', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByPinPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinPosition', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByPinPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinPosition', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy> thenByPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinned', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenByPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinned', Sort.desc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }
}

extension CachedQueueItemQueryWhereDistinct
    on QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct> {
  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct>
      distinctByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addedAt');
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct> distinctByAddedById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addedById', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct>
      distinctByKalaamAuthorName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamAuthorName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct>
      distinctByKalaamCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamCategory',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct> distinctByKalaamId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct>
      distinctByKalaamTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct>
      distinctByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingSync');
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct>
      distinctByPinPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pinPosition');
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct> distinctByPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pinned');
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct> distinctBySessionId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedQueueItem, CachedQueueItem, QDistinct> distinctByVoters() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'voters');
    });
  }
}

extension CachedQueueItemQueryProperty
    on QueryBuilder<CachedQueueItem, CachedQueueItem, QQueryProperty> {
  QueryBuilder<CachedQueueItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedQueueItem, DateTime, QQueryOperations> addedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addedAt');
    });
  }

  QueryBuilder<CachedQueueItem, String, QQueryOperations> addedByIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addedById');
    });
  }

  QueryBuilder<CachedQueueItem, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedQueueItem, String?, QQueryOperations>
      kalaamAuthorNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamAuthorName');
    });
  }

  QueryBuilder<CachedQueueItem, String?, QQueryOperations>
      kalaamCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamCategory');
    });
  }

  QueryBuilder<CachedQueueItem, String, QQueryOperations> kalaamIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamId');
    });
  }

  QueryBuilder<CachedQueueItem, String?, QQueryOperations>
      kalaamTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamTitle');
    });
  }

  QueryBuilder<CachedQueueItem, bool, QQueryOperations> pendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingSync');
    });
  }

  QueryBuilder<CachedQueueItem, int?, QQueryOperations> pinPositionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pinPosition');
    });
  }

  QueryBuilder<CachedQueueItem, bool, QQueryOperations> pinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pinned');
    });
  }

  QueryBuilder<CachedQueueItem, String, QQueryOperations> sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<CachedQueueItem, List<String>, QQueryOperations>
      votersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'voters');
    });
  }
}
