// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kalaam_practice_meta.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKalaamPracticeMetaCollection on Isar {
  IsarCollection<KalaamPracticeMeta> get kalaamPracticeMetas =>
      this.collection();
}

const KalaamPracticeMetaSchema = CollectionSchema(
  name: r'KalaamPracticeMeta',
  id: 6194557476132968927,
  properties: {
    r'bestOverallScore': PropertySchema(
      id: 0,
      name: r'bestOverallScore',
      type: IsarType.double,
    ),
    r'currentStreak': PropertySchema(
      id: 1,
      name: r'currentStreak',
      type: IsarType.long,
    ),
    r'kalaamId': PropertySchema(
      id: 2,
      name: r'kalaamId',
      type: IsarType.string,
    ),
    r'lastPracticedAt': PropertySchema(
      id: 3,
      name: r'lastPracticedAt',
      type: IsarType.dateTime,
    ),
    r'longestStreak': PropertySchema(
      id: 4,
      name: r'longestStreak',
      type: IsarType.long,
    ),
    r'totalSessions': PropertySchema(
      id: 5,
      name: r'totalSessions',
      type: IsarType.long,
    ),
    r'weakLineIndices': PropertySchema(
      id: 6,
      name: r'weakLineIndices',
      type: IsarType.string,
    )
  },
  estimateSize: _kalaamPracticeMetaEstimateSize,
  serialize: _kalaamPracticeMetaSerialize,
  deserialize: _kalaamPracticeMetaDeserialize,
  deserializeProp: _kalaamPracticeMetaDeserializeProp,
  idName: r'id',
  indexes: {
    r'kalaamId': IndexSchema(
      id: 5658280144504471660,
      name: r'kalaamId',
      unique: true,
      replace: true,
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
  getId: _kalaamPracticeMetaGetId,
  getLinks: _kalaamPracticeMetaGetLinks,
  attach: _kalaamPracticeMetaAttach,
  version: '3.1.0+1',
);

int _kalaamPracticeMetaEstimateSize(
  KalaamPracticeMeta object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.kalaamId.length * 3;
  bytesCount += 3 + object.weakLineIndices.length * 3;
  return bytesCount;
}

void _kalaamPracticeMetaSerialize(
  KalaamPracticeMeta object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.bestOverallScore);
  writer.writeLong(offsets[1], object.currentStreak);
  writer.writeString(offsets[2], object.kalaamId);
  writer.writeDateTime(offsets[3], object.lastPracticedAt);
  writer.writeLong(offsets[4], object.longestStreak);
  writer.writeLong(offsets[5], object.totalSessions);
  writer.writeString(offsets[6], object.weakLineIndices);
}

KalaamPracticeMeta _kalaamPracticeMetaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KalaamPracticeMeta();
  object.bestOverallScore = reader.readDouble(offsets[0]);
  object.currentStreak = reader.readLong(offsets[1]);
  object.id = id;
  object.kalaamId = reader.readString(offsets[2]);
  object.lastPracticedAt = reader.readDateTime(offsets[3]);
  object.longestStreak = reader.readLong(offsets[4]);
  object.totalSessions = reader.readLong(offsets[5]);
  object.weakLineIndices = reader.readString(offsets[6]);
  return object;
}

P _kalaamPracticeMetaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _kalaamPracticeMetaGetId(KalaamPracticeMeta object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _kalaamPracticeMetaGetLinks(
    KalaamPracticeMeta object) {
  return [];
}

void _kalaamPracticeMetaAttach(
    IsarCollection<dynamic> col, Id id, KalaamPracticeMeta object) {
  object.id = id;
}

extension KalaamPracticeMetaByIndex on IsarCollection<KalaamPracticeMeta> {
  Future<KalaamPracticeMeta?> getByKalaamId(String kalaamId) {
    return getByIndex(r'kalaamId', [kalaamId]);
  }

  KalaamPracticeMeta? getByKalaamIdSync(String kalaamId) {
    return getByIndexSync(r'kalaamId', [kalaamId]);
  }

  Future<bool> deleteByKalaamId(String kalaamId) {
    return deleteByIndex(r'kalaamId', [kalaamId]);
  }

  bool deleteByKalaamIdSync(String kalaamId) {
    return deleteByIndexSync(r'kalaamId', [kalaamId]);
  }

  Future<List<KalaamPracticeMeta?>> getAllByKalaamId(
      List<String> kalaamIdValues) {
    final values = kalaamIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'kalaamId', values);
  }

  List<KalaamPracticeMeta?> getAllByKalaamIdSync(List<String> kalaamIdValues) {
    final values = kalaamIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'kalaamId', values);
  }

  Future<int> deleteAllByKalaamId(List<String> kalaamIdValues) {
    final values = kalaamIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'kalaamId', values);
  }

  int deleteAllByKalaamIdSync(List<String> kalaamIdValues) {
    final values = kalaamIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'kalaamId', values);
  }

  Future<Id> putByKalaamId(KalaamPracticeMeta object) {
    return putByIndex(r'kalaamId', object);
  }

  Id putByKalaamIdSync(KalaamPracticeMeta object, {bool saveLinks = true}) {
    return putByIndexSync(r'kalaamId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKalaamId(List<KalaamPracticeMeta> objects) {
    return putAllByIndex(r'kalaamId', objects);
  }

  List<Id> putAllByKalaamIdSync(List<KalaamPracticeMeta> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'kalaamId', objects, saveLinks: saveLinks);
  }
}

extension KalaamPracticeMetaQueryWhereSort
    on QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QWhere> {
  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension KalaamPracticeMetaQueryWhere
    on QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QWhereClause> {
  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterWhereClause>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterWhereClause>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterWhereClause>
      kalaamIdEqualTo(String kalaamId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'kalaamId',
        value: [kalaamId],
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterWhereClause>
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

extension KalaamPracticeMetaQueryFilter
    on QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QFilterCondition> {
  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      bestOverallScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bestOverallScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      bestOverallScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bestOverallScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      bestOverallScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bestOverallScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      bestOverallScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bestOverallScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      currentStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      currentStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      currentStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      currentStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
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

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      kalaamIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      kalaamIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      kalaamIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      kalaamIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      lastPracticedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastPracticedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      lastPracticedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastPracticedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      lastPracticedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastPracticedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      lastPracticedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastPracticedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      longestStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      longestStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      longestStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      longestStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longestStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      totalSessionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalSessions',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      totalSessionsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalSessions',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      totalSessionsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalSessions',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      totalSessionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalSessions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weakLineIndices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weakLineIndices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weakLineIndices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weakLineIndices',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'weakLineIndices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'weakLineIndices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'weakLineIndices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'weakLineIndices',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weakLineIndices',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterFilterCondition>
      weakLineIndicesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'weakLineIndices',
        value: '',
      ));
    });
  }
}

extension KalaamPracticeMetaQueryObject
    on QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QFilterCondition> {}

extension KalaamPracticeMetaQueryLinks
    on QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QFilterCondition> {}

extension KalaamPracticeMetaQuerySortBy
    on QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QSortBy> {
  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByBestOverallScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestOverallScore', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByBestOverallScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestOverallScore', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByLastPracticedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPracticedAt', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByLastPracticedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPracticedAt', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByTotalSessions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSessions', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByTotalSessionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSessions', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByWeakLineIndices() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weakLineIndices', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      sortByWeakLineIndicesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weakLineIndices', Sort.desc);
    });
  }
}

extension KalaamPracticeMetaQuerySortThenBy
    on QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QSortThenBy> {
  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByBestOverallScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestOverallScore', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByBestOverallScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestOverallScore', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByLastPracticedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPracticedAt', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByLastPracticedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPracticedAt', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByTotalSessions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSessions', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByTotalSessionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSessions', Sort.desc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByWeakLineIndices() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weakLineIndices', Sort.asc);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QAfterSortBy>
      thenByWeakLineIndicesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weakLineIndices', Sort.desc);
    });
  }
}

extension KalaamPracticeMetaQueryWhereDistinct
    on QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QDistinct> {
  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QDistinct>
      distinctByBestOverallScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bestOverallScore');
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QDistinct>
      distinctByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStreak');
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QDistinct>
      distinctByKalaamId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QDistinct>
      distinctByLastPracticedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastPracticedAt');
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QDistinct>
      distinctByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longestStreak');
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QDistinct>
      distinctByTotalSessions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalSessions');
    });
  }

  QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QDistinct>
      distinctByWeakLineIndices({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weakLineIndices',
          caseSensitive: caseSensitive);
    });
  }
}

extension KalaamPracticeMetaQueryProperty
    on QueryBuilder<KalaamPracticeMeta, KalaamPracticeMeta, QQueryProperty> {
  QueryBuilder<KalaamPracticeMeta, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<KalaamPracticeMeta, double, QQueryOperations>
      bestOverallScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bestOverallScore');
    });
  }

  QueryBuilder<KalaamPracticeMeta, int, QQueryOperations>
      currentStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStreak');
    });
  }

  QueryBuilder<KalaamPracticeMeta, String, QQueryOperations>
      kalaamIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamId');
    });
  }

  QueryBuilder<KalaamPracticeMeta, DateTime, QQueryOperations>
      lastPracticedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastPracticedAt');
    });
  }

  QueryBuilder<KalaamPracticeMeta, int, QQueryOperations>
      longestStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longestStreak');
    });
  }

  QueryBuilder<KalaamPracticeMeta, int, QQueryOperations>
      totalSessionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalSessions');
    });
  }

  QueryBuilder<KalaamPracticeMeta, String, QQueryOperations>
      weakLineIndicesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weakLineIndices');
    });
  }
}
