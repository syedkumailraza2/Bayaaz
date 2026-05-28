// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kalaam_reference_audio.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKalaamReferenceAudioCollection on Isar {
  IsarCollection<KalaamReferenceAudio> get kalaamReferenceAudios =>
      this.collection();
}

const KalaamReferenceAudioSchema = CollectionSchema(
  name: r'KalaamReferenceAudio',
  id: 6498964027863455489,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'durationMs': PropertySchema(
      id: 1,
      name: r'durationMs',
      type: IsarType.long,
    ),
    r'kalaamId': PropertySchema(
      id: 2,
      name: r'kalaamId',
      type: IsarType.string,
    ),
    r'localWavPath': PropertySchema(
      id: 3,
      name: r'localWavPath',
      type: IsarType.string,
    ),
    r'metadataGenerated': PropertySchema(
      id: 4,
      name: r'metadataGenerated',
      type: IsarType.bool,
    ),
    r'sourceType': PropertySchema(
      id: 5,
      name: r'sourceType',
      type: IsarType.string,
    ),
    r'sourceUrl': PropertySchema(
      id: 6,
      name: r'sourceUrl',
      type: IsarType.string,
    )
  },
  estimateSize: _kalaamReferenceAudioEstimateSize,
  serialize: _kalaamReferenceAudioSerialize,
  deserialize: _kalaamReferenceAudioDeserialize,
  deserializeProp: _kalaamReferenceAudioDeserializeProp,
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
  getId: _kalaamReferenceAudioGetId,
  getLinks: _kalaamReferenceAudioGetLinks,
  attach: _kalaamReferenceAudioAttach,
  version: '3.1.0+1',
);

int _kalaamReferenceAudioEstimateSize(
  KalaamReferenceAudio object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.kalaamId.length * 3;
  bytesCount += 3 + object.localWavPath.length * 3;
  bytesCount += 3 + object.sourceType.length * 3;
  {
    final value = object.sourceUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _kalaamReferenceAudioSerialize(
  KalaamReferenceAudio object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.durationMs);
  writer.writeString(offsets[2], object.kalaamId);
  writer.writeString(offsets[3], object.localWavPath);
  writer.writeBool(offsets[4], object.metadataGenerated);
  writer.writeString(offsets[5], object.sourceType);
  writer.writeString(offsets[6], object.sourceUrl);
}

KalaamReferenceAudio _kalaamReferenceAudioDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KalaamReferenceAudio();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.durationMs = reader.readLong(offsets[1]);
  object.id = id;
  object.kalaamId = reader.readString(offsets[2]);
  object.localWavPath = reader.readString(offsets[3]);
  object.metadataGenerated = reader.readBool(offsets[4]);
  object.sourceType = reader.readString(offsets[5]);
  object.sourceUrl = reader.readStringOrNull(offsets[6]);
  return object;
}

P _kalaamReferenceAudioDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _kalaamReferenceAudioGetId(KalaamReferenceAudio object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _kalaamReferenceAudioGetLinks(
    KalaamReferenceAudio object) {
  return [];
}

void _kalaamReferenceAudioAttach(
    IsarCollection<dynamic> col, Id id, KalaamReferenceAudio object) {
  object.id = id;
}

extension KalaamReferenceAudioByIndex on IsarCollection<KalaamReferenceAudio> {
  Future<KalaamReferenceAudio?> getByKalaamId(String kalaamId) {
    return getByIndex(r'kalaamId', [kalaamId]);
  }

  KalaamReferenceAudio? getByKalaamIdSync(String kalaamId) {
    return getByIndexSync(r'kalaamId', [kalaamId]);
  }

  Future<bool> deleteByKalaamId(String kalaamId) {
    return deleteByIndex(r'kalaamId', [kalaamId]);
  }

  bool deleteByKalaamIdSync(String kalaamId) {
    return deleteByIndexSync(r'kalaamId', [kalaamId]);
  }

  Future<List<KalaamReferenceAudio?>> getAllByKalaamId(
      List<String> kalaamIdValues) {
    final values = kalaamIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'kalaamId', values);
  }

  List<KalaamReferenceAudio?> getAllByKalaamIdSync(
      List<String> kalaamIdValues) {
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

  Future<Id> putByKalaamId(KalaamReferenceAudio object) {
    return putByIndex(r'kalaamId', object);
  }

  Id putByKalaamIdSync(KalaamReferenceAudio object, {bool saveLinks = true}) {
    return putByIndexSync(r'kalaamId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKalaamId(List<KalaamReferenceAudio> objects) {
    return putAllByIndex(r'kalaamId', objects);
  }

  List<Id> putAllByKalaamIdSync(List<KalaamReferenceAudio> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'kalaamId', objects, saveLinks: saveLinks);
  }
}

extension KalaamReferenceAudioQueryWhereSort
    on QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QWhere> {
  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension KalaamReferenceAudioQueryWhere
    on QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QWhereClause> {
  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterWhereClause>
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterWhereClause>
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterWhereClause>
      kalaamIdEqualTo(String kalaamId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'kalaamId',
        value: [kalaamId],
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterWhereClause>
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

extension KalaamReferenceAudioQueryFilter on QueryBuilder<KalaamReferenceAudio,
    KalaamReferenceAudio, QFilterCondition> {
  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> durationMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> durationMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> durationMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> durationMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
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

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> kalaamIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> kalaamIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> localWavPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> localWavPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> localWavPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> localWavPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localWavPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> localWavPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> localWavPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
          QAfterFilterCondition>
      localWavPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
          QAfterFilterCondition>
      localWavPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localWavPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> localWavPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localWavPath',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> localWavPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localWavPath',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> metadataGeneratedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadataGenerated',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
          QAfterFilterCondition>
      sourceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
          QAfterFilterCondition>
      sourceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceType',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceType',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceUrl',
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceUrl',
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
          QAfterFilterCondition>
      sourceUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
          QAfterFilterCondition>
      sourceUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio,
      QAfterFilterCondition> sourceUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceUrl',
        value: '',
      ));
    });
  }
}

extension KalaamReferenceAudioQueryObject on QueryBuilder<KalaamReferenceAudio,
    KalaamReferenceAudio, QFilterCondition> {}

extension KalaamReferenceAudioQueryLinks on QueryBuilder<KalaamReferenceAudio,
    KalaamReferenceAudio, QFilterCondition> {}

extension KalaamReferenceAudioQuerySortBy
    on QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QSortBy> {
  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByLocalWavPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localWavPath', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByLocalWavPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localWavPath', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByMetadataGenerated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataGenerated', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortByMetadataGeneratedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataGenerated', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortBySourceUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      sortBySourceUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.desc);
    });
  }
}

extension KalaamReferenceAudioQuerySortThenBy
    on QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QSortThenBy> {
  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByLocalWavPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localWavPath', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByLocalWavPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localWavPath', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByMetadataGenerated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataGenerated', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenByMetadataGeneratedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataGenerated', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenBySourceUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.asc);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QAfterSortBy>
      thenBySourceUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.desc);
    });
  }
}

extension KalaamReferenceAudioQueryWhereDistinct
    on QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QDistinct> {
  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QDistinct>
      distinctByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMs');
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QDistinct>
      distinctByKalaamId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QDistinct>
      distinctByLocalWavPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localWavPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QDistinct>
      distinctByMetadataGenerated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadataGenerated');
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QDistinct>
      distinctBySourceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KalaamReferenceAudio, KalaamReferenceAudio, QDistinct>
      distinctBySourceUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceUrl', caseSensitive: caseSensitive);
    });
  }
}

extension KalaamReferenceAudioQueryProperty on QueryBuilder<
    KalaamReferenceAudio, KalaamReferenceAudio, QQueryProperty> {
  QueryBuilder<KalaamReferenceAudio, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<KalaamReferenceAudio, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<KalaamReferenceAudio, int, QQueryOperations>
      durationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMs');
    });
  }

  QueryBuilder<KalaamReferenceAudio, String, QQueryOperations>
      kalaamIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamId');
    });
  }

  QueryBuilder<KalaamReferenceAudio, String, QQueryOperations>
      localWavPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localWavPath');
    });
  }

  QueryBuilder<KalaamReferenceAudio, bool, QQueryOperations>
      metadataGeneratedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataGenerated');
    });
  }

  QueryBuilder<KalaamReferenceAudio, String, QQueryOperations>
      sourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceType');
    });
  }

  QueryBuilder<KalaamReferenceAudio, String?, QQueryOperations>
      sourceUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceUrl');
    });
  }
}
