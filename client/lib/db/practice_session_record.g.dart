// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_session_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPracticeSessionRecordCollection on Isar {
  IsarCollection<PracticeSessionRecord> get practiceSessionRecords =>
      this.collection();
}

const PracticeSessionRecordSchema = CollectionSchema(
  name: r'PracticeSessionRecord',
  id: 8841401627965925348,
  properties: {
    r'accuracyScore': PropertySchema(
      id: 0,
      name: r'accuracyScore',
      type: IsarType.double,
    ),
    r'clientToken': PropertySchema(
      id: 1,
      name: r'clientToken',
      type: IsarType.string,
    ),
    r'completionScore': PropertySchema(
      id: 2,
      name: r'completionScore',
      type: IsarType.double,
    ),
    r'flowScore': PropertySchema(
      id: 3,
      name: r'flowScore',
      type: IsarType.double,
    ),
    r'kalaamId': PropertySchema(
      id: 4,
      name: r'kalaamId',
      type: IsarType.string,
    ),
    r'kalaamTitle': PropertySchema(
      id: 5,
      name: r'kalaamTitle',
      type: IsarType.string,
    ),
    r'mode': PropertySchema(
      id: 6,
      name: r'mode',
      type: IsarType.string,
    ),
    r'overallScore': PropertySchema(
      id: 7,
      name: r'overallScore',
      type: IsarType.double,
    ),
    r'pauseScore': PropertySchema(
      id: 8,
      name: r'pauseScore',
      type: IsarType.double,
    ),
    r'perLineScoresJson': PropertySchema(
      id: 9,
      name: r'perLineScoresJson',
      type: IsarType.string,
    ),
    r'sessionAt': PropertySchema(
      id: 10,
      name: r'sessionAt',
      type: IsarType.dateTime,
    ),
    r'syncedToServer': PropertySchema(
      id: 11,
      name: r'syncedToServer',
      type: IsarType.bool,
    )
  },
  estimateSize: _practiceSessionRecordEstimateSize,
  serialize: _practiceSessionRecordSerialize,
  deserialize: _practiceSessionRecordDeserialize,
  deserializeProp: _practiceSessionRecordDeserializeProp,
  idName: r'id',
  indexes: {
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
    ),
    r'sessionAt': IndexSchema(
      id: 4621250247647038200,
      name: r'sessionAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'clientToken': IndexSchema(
      id: 2591184540578518072,
      name: r'clientToken',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'clientToken',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'syncedToServer': IndexSchema(
      id: 5936619231729291709,
      name: r'syncedToServer',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncedToServer',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _practiceSessionRecordGetId,
  getLinks: _practiceSessionRecordGetLinks,
  attach: _practiceSessionRecordAttach,
  version: '3.1.0+1',
);

int _practiceSessionRecordEstimateSize(
  PracticeSessionRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.clientToken.length * 3;
  bytesCount += 3 + object.kalaamId.length * 3;
  bytesCount += 3 + object.kalaamTitle.length * 3;
  bytesCount += 3 + object.mode.length * 3;
  bytesCount += 3 + object.perLineScoresJson.length * 3;
  return bytesCount;
}

void _practiceSessionRecordSerialize(
  PracticeSessionRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.accuracyScore);
  writer.writeString(offsets[1], object.clientToken);
  writer.writeDouble(offsets[2], object.completionScore);
  writer.writeDouble(offsets[3], object.flowScore);
  writer.writeString(offsets[4], object.kalaamId);
  writer.writeString(offsets[5], object.kalaamTitle);
  writer.writeString(offsets[6], object.mode);
  writer.writeDouble(offsets[7], object.overallScore);
  writer.writeDouble(offsets[8], object.pauseScore);
  writer.writeString(offsets[9], object.perLineScoresJson);
  writer.writeDateTime(offsets[10], object.sessionAt);
  writer.writeBool(offsets[11], object.syncedToServer);
}

PracticeSessionRecord _practiceSessionRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PracticeSessionRecord();
  object.accuracyScore = reader.readDouble(offsets[0]);
  object.clientToken = reader.readString(offsets[1]);
  object.completionScore = reader.readDouble(offsets[2]);
  object.flowScore = reader.readDouble(offsets[3]);
  object.id = id;
  object.kalaamId = reader.readString(offsets[4]);
  object.kalaamTitle = reader.readString(offsets[5]);
  object.mode = reader.readString(offsets[6]);
  object.overallScore = reader.readDouble(offsets[7]);
  object.pauseScore = reader.readDouble(offsets[8]);
  object.perLineScoresJson = reader.readString(offsets[9]);
  object.sessionAt = reader.readDateTime(offsets[10]);
  object.syncedToServer = reader.readBool(offsets[11]);
  return object;
}

P _practiceSessionRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _practiceSessionRecordGetId(PracticeSessionRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _practiceSessionRecordGetLinks(
    PracticeSessionRecord object) {
  return [];
}

void _practiceSessionRecordAttach(
    IsarCollection<dynamic> col, Id id, PracticeSessionRecord object) {
  object.id = id;
}

extension PracticeSessionRecordByIndex
    on IsarCollection<PracticeSessionRecord> {
  Future<PracticeSessionRecord?> getByClientToken(String clientToken) {
    return getByIndex(r'clientToken', [clientToken]);
  }

  PracticeSessionRecord? getByClientTokenSync(String clientToken) {
    return getByIndexSync(r'clientToken', [clientToken]);
  }

  Future<bool> deleteByClientToken(String clientToken) {
    return deleteByIndex(r'clientToken', [clientToken]);
  }

  bool deleteByClientTokenSync(String clientToken) {
    return deleteByIndexSync(r'clientToken', [clientToken]);
  }

  Future<List<PracticeSessionRecord?>> getAllByClientToken(
      List<String> clientTokenValues) {
    final values = clientTokenValues.map((e) => [e]).toList();
    return getAllByIndex(r'clientToken', values);
  }

  List<PracticeSessionRecord?> getAllByClientTokenSync(
      List<String> clientTokenValues) {
    final values = clientTokenValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'clientToken', values);
  }

  Future<int> deleteAllByClientToken(List<String> clientTokenValues) {
    final values = clientTokenValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'clientToken', values);
  }

  int deleteAllByClientTokenSync(List<String> clientTokenValues) {
    final values = clientTokenValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'clientToken', values);
  }

  Future<Id> putByClientToken(PracticeSessionRecord object) {
    return putByIndex(r'clientToken', object);
  }

  Id putByClientTokenSync(PracticeSessionRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'clientToken', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByClientToken(List<PracticeSessionRecord> objects) {
    return putAllByIndex(r'clientToken', objects);
  }

  List<Id> putAllByClientTokenSync(List<PracticeSessionRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'clientToken', objects, saveLinks: saveLinks);
  }
}

extension PracticeSessionRecordQueryWhereSort
    on QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QWhere> {
  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhere>
      anySessionAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'sessionAt'),
      );
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhere>
      anySyncedToServer() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncedToServer'),
      );
    });
  }
}

extension PracticeSessionRecordQueryWhere on QueryBuilder<PracticeSessionRecord,
    PracticeSessionRecord, QWhereClause> {
  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      kalaamIdEqualTo(String kalaamId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'kalaamId',
        value: [kalaamId],
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      sessionAtEqualTo(DateTime sessionAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionAt',
        value: [sessionAt],
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      sessionAtNotEqualTo(DateTime sessionAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionAt',
              lower: [],
              upper: [sessionAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionAt',
              lower: [sessionAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionAt',
              lower: [sessionAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionAt',
              lower: [],
              upper: [sessionAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      sessionAtGreaterThan(
    DateTime sessionAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sessionAt',
        lower: [sessionAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      sessionAtLessThan(
    DateTime sessionAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sessionAt',
        lower: [],
        upper: [sessionAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      sessionAtBetween(
    DateTime lowerSessionAt,
    DateTime upperSessionAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sessionAt',
        lower: [lowerSessionAt],
        includeLower: includeLower,
        upper: [upperSessionAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      clientTokenEqualTo(String clientToken) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'clientToken',
        value: [clientToken],
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      clientTokenNotEqualTo(String clientToken) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientToken',
              lower: [],
              upper: [clientToken],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientToken',
              lower: [clientToken],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientToken',
              lower: [clientToken],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientToken',
              lower: [],
              upper: [clientToken],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      syncedToServerEqualTo(bool syncedToServer) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncedToServer',
        value: [syncedToServer],
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterWhereClause>
      syncedToServerNotEqualTo(bool syncedToServer) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncedToServer',
              lower: [],
              upper: [syncedToServer],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncedToServer',
              lower: [syncedToServer],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncedToServer',
              lower: [syncedToServer],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncedToServer',
              lower: [],
              upper: [syncedToServer],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PracticeSessionRecordQueryFilter on QueryBuilder<
    PracticeSessionRecord, PracticeSessionRecord, QFilterCondition> {
  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> accuracyScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accuracyScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> accuracyScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accuracyScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> accuracyScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accuracyScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> accuracyScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accuracyScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> clientTokenEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> clientTokenGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> clientTokenLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> clientTokenBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientToken',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> clientTokenStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> clientTokenEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      clientTokenContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      clientTokenMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientToken',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> clientTokenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientToken',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> clientTokenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientToken',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> completionScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completionScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> completionScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completionScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> completionScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completionScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> completionScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completionScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> flowScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flowScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> flowScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flowScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> flowScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flowScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> flowScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flowScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamIdEqualTo(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamIdGreaterThan(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamIdLessThan(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamIdBetween(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamIdStartsWith(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamIdEndsWith(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      kalaamIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      kalaamIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamTitleEqualTo(
    String value, {
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamTitleGreaterThan(
    String value, {
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamTitleLessThan(
    String value, {
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamTitleBetween(
    String lower,
    String upper, {
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamTitleStartsWith(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamTitleEndsWith(
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

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      kalaamTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      kalaamTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> kalaamTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> modeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> modeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> modeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> modeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> modeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> modeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      modeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      modeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> modeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mode',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> modeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mode',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> overallScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'overallScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> overallScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'overallScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> overallScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'overallScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> overallScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'overallScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> pauseScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pauseScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> pauseScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pauseScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> pauseScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pauseScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> pauseScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pauseScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> perLineScoresJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'perLineScoresJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> perLineScoresJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'perLineScoresJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> perLineScoresJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'perLineScoresJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> perLineScoresJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'perLineScoresJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> perLineScoresJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'perLineScoresJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> perLineScoresJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'perLineScoresJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      perLineScoresJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'perLineScoresJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
          QAfterFilterCondition>
      perLineScoresJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'perLineScoresJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> perLineScoresJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'perLineScoresJson',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> perLineScoresJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'perLineScoresJson',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> sessionAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> sessionAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> sessionAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> sessionAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord,
      QAfterFilterCondition> syncedToServerEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedToServer',
        value: value,
      ));
    });
  }
}

extension PracticeSessionRecordQueryObject on QueryBuilder<
    PracticeSessionRecord, PracticeSessionRecord, QFilterCondition> {}

extension PracticeSessionRecordQueryLinks on QueryBuilder<PracticeSessionRecord,
    PracticeSessionRecord, QFilterCondition> {}

extension PracticeSessionRecordQuerySortBy
    on QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QSortBy> {
  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByAccuracyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracyScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByAccuracyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracyScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByClientToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientToken', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByClientTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientToken', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByCompletionScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByCompletionScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByFlowScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flowScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByFlowScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flowScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByKalaamTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamTitle', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByKalaamTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamTitle', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByOverallScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByOverallScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByPauseScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByPauseScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByPerLineScoresJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perLineScoresJson', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortByPerLineScoresJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perLineScoresJson', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortBySessionAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionAt', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortBySessionAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionAt', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortBySyncedToServer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedToServer', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      sortBySyncedToServerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedToServer', Sort.desc);
    });
  }
}

extension PracticeSessionRecordQuerySortThenBy
    on QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QSortThenBy> {
  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByAccuracyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracyScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByAccuracyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracyScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByClientToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientToken', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByClientTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientToken', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByCompletionScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByCompletionScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByFlowScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flowScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByFlowScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flowScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByKalaamTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamTitle', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByKalaamTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamTitle', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByOverallScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByOverallScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByPauseScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseScore', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByPauseScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseScore', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByPerLineScoresJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perLineScoresJson', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenByPerLineScoresJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perLineScoresJson', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenBySessionAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionAt', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenBySessionAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionAt', Sort.desc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenBySyncedToServer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedToServer', Sort.asc);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QAfterSortBy>
      thenBySyncedToServerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedToServer', Sort.desc);
    });
  }
}

extension PracticeSessionRecordQueryWhereDistinct
    on QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct> {
  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByAccuracyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accuracyScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByClientToken({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientToken', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByCompletionScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completionScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByFlowScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flowScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByKalaamId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByKalaamTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByMode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByOverallScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'overallScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByPauseScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pauseScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctByPerLineScoresJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'perLineScoresJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctBySessionAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionAt');
    });
  }

  QueryBuilder<PracticeSessionRecord, PracticeSessionRecord, QDistinct>
      distinctBySyncedToServer() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedToServer');
    });
  }
}

extension PracticeSessionRecordQueryProperty on QueryBuilder<
    PracticeSessionRecord, PracticeSessionRecord, QQueryProperty> {
  QueryBuilder<PracticeSessionRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PracticeSessionRecord, double, QQueryOperations>
      accuracyScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accuracyScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, String, QQueryOperations>
      clientTokenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientToken');
    });
  }

  QueryBuilder<PracticeSessionRecord, double, QQueryOperations>
      completionScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completionScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, double, QQueryOperations>
      flowScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flowScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, String, QQueryOperations>
      kalaamIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamId');
    });
  }

  QueryBuilder<PracticeSessionRecord, String, QQueryOperations>
      kalaamTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamTitle');
    });
  }

  QueryBuilder<PracticeSessionRecord, String, QQueryOperations> modeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mode');
    });
  }

  QueryBuilder<PracticeSessionRecord, double, QQueryOperations>
      overallScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'overallScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, double, QQueryOperations>
      pauseScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pauseScore');
    });
  }

  QueryBuilder<PracticeSessionRecord, String, QQueryOperations>
      perLineScoresJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perLineScoresJson');
    });
  }

  QueryBuilder<PracticeSessionRecord, DateTime, QQueryOperations>
      sessionAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionAt');
    });
  }

  QueryBuilder<PracticeSessionRecord, bool, QQueryOperations>
      syncedToServerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedToServer');
    });
  }
}
