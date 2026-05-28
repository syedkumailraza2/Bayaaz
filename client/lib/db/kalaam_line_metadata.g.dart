// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kalaam_line_metadata.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKalaamLineMetadataCollection on Isar {
  IsarCollection<KalaamLineMetadata> get kalaamLineMetadatas =>
      this.collection();
}

const KalaamLineMetadataSchema = CollectionSchema(
  name: r'KalaamLineMetadata',
  id: -8916000661977819316,
  properties: {
    r'endSec': PropertySchema(
      id: 0,
      name: r'endSec',
      type: IsarType.double,
    ),
    r'kalaamId': PropertySchema(
      id: 1,
      name: r'kalaamId',
      type: IsarType.string,
    ),
    r'lineIndex': PropertySchema(
      id: 2,
      name: r'lineIndex',
      type: IsarType.long,
    ),
    r'lineText': PropertySchema(
      id: 3,
      name: r'lineText',
      type: IsarType.string,
    ),
    r'pauseAfterSec': PropertySchema(
      id: 4,
      name: r'pauseAfterSec',
      type: IsarType.double,
    ),
    r'speakingRateWpm': PropertySchema(
      id: 5,
      name: r'speakingRateWpm',
      type: IsarType.double,
    ),
    r'startSec': PropertySchema(
      id: 6,
      name: r'startSec',
      type: IsarType.double,
    )
  },
  estimateSize: _kalaamLineMetadataEstimateSize,
  serialize: _kalaamLineMetadataSerialize,
  deserialize: _kalaamLineMetadataDeserialize,
  deserializeProp: _kalaamLineMetadataDeserializeProp,
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _kalaamLineMetadataGetId,
  getLinks: _kalaamLineMetadataGetLinks,
  attach: _kalaamLineMetadataAttach,
  version: '3.1.0+1',
);

int _kalaamLineMetadataEstimateSize(
  KalaamLineMetadata object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.kalaamId.length * 3;
  bytesCount += 3 + object.lineText.length * 3;
  return bytesCount;
}

void _kalaamLineMetadataSerialize(
  KalaamLineMetadata object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.endSec);
  writer.writeString(offsets[1], object.kalaamId);
  writer.writeLong(offsets[2], object.lineIndex);
  writer.writeString(offsets[3], object.lineText);
  writer.writeDouble(offsets[4], object.pauseAfterSec);
  writer.writeDouble(offsets[5], object.speakingRateWpm);
  writer.writeDouble(offsets[6], object.startSec);
}

KalaamLineMetadata _kalaamLineMetadataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KalaamLineMetadata();
  object.endSec = reader.readDouble(offsets[0]);
  object.id = id;
  object.kalaamId = reader.readString(offsets[1]);
  object.lineIndex = reader.readLong(offsets[2]);
  object.lineText = reader.readString(offsets[3]);
  object.pauseAfterSec = reader.readDouble(offsets[4]);
  object.speakingRateWpm = reader.readDouble(offsets[5]);
  object.startSec = reader.readDouble(offsets[6]);
  return object;
}

P _kalaamLineMetadataDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _kalaamLineMetadataGetId(KalaamLineMetadata object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _kalaamLineMetadataGetLinks(
    KalaamLineMetadata object) {
  return [];
}

void _kalaamLineMetadataAttach(
    IsarCollection<dynamic> col, Id id, KalaamLineMetadata object) {
  object.id = id;
}

extension KalaamLineMetadataQueryWhereSort
    on QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QWhere> {
  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension KalaamLineMetadataQueryWhere
    on QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QWhereClause> {
  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterWhereClause>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterWhereClause>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterWhereClause>
      kalaamIdEqualTo(String kalaamId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'kalaamId',
        value: [kalaamId],
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterWhereClause>
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

extension KalaamLineMetadataQueryFilter
    on QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QFilterCondition> {
  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      endSecEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endSec',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      endSecGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endSec',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      endSecLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endSec',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      endSecBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endSec',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
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

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      kalaamIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kalaamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      kalaamIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kalaamId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      kalaamIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      kalaamIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kalaamId',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lineIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lineIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lineIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lineIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lineText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lineText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lineText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lineText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lineText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lineText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lineText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lineText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lineText',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      lineTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lineText',
        value: '',
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      pauseAfterSecEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pauseAfterSec',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      pauseAfterSecGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pauseAfterSec',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      pauseAfterSecLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pauseAfterSec',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      pauseAfterSecBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pauseAfterSec',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      speakingRateWpmEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speakingRateWpm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      speakingRateWpmGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speakingRateWpm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      speakingRateWpmLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speakingRateWpm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      speakingRateWpmBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speakingRateWpm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      startSecEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startSec',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      startSecGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startSec',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      startSecLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startSec',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterFilterCondition>
      startSecBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startSec',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension KalaamLineMetadataQueryObject
    on QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QFilterCondition> {}

extension KalaamLineMetadataQueryLinks
    on QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QFilterCondition> {}

extension KalaamLineMetadataQuerySortBy
    on QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QSortBy> {
  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByEndSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSec', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByEndSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSec', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByLineIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineIndex', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByLineIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineIndex', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByLineText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineText', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByLineTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineText', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByPauseAfterSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseAfterSec', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByPauseAfterSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseAfterSec', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortBySpeakingRateWpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speakingRateWpm', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortBySpeakingRateWpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speakingRateWpm', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByStartSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSec', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      sortByStartSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSec', Sort.desc);
    });
  }
}

extension KalaamLineMetadataQuerySortThenBy
    on QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QSortThenBy> {
  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByEndSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSec', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByEndSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSec', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByKalaamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByKalaamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kalaamId', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByLineIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineIndex', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByLineIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineIndex', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByLineText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineText', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByLineTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineText', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByPauseAfterSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseAfterSec', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByPauseAfterSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseAfterSec', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenBySpeakingRateWpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speakingRateWpm', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenBySpeakingRateWpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speakingRateWpm', Sort.desc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByStartSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSec', Sort.asc);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QAfterSortBy>
      thenByStartSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSec', Sort.desc);
    });
  }
}

extension KalaamLineMetadataQueryWhereDistinct
    on QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QDistinct> {
  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QDistinct>
      distinctByEndSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endSec');
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QDistinct>
      distinctByKalaamId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kalaamId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QDistinct>
      distinctByLineIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lineIndex');
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QDistinct>
      distinctByLineText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lineText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QDistinct>
      distinctByPauseAfterSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pauseAfterSec');
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QDistinct>
      distinctBySpeakingRateWpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speakingRateWpm');
    });
  }

  QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QDistinct>
      distinctByStartSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startSec');
    });
  }
}

extension KalaamLineMetadataQueryProperty
    on QueryBuilder<KalaamLineMetadata, KalaamLineMetadata, QQueryProperty> {
  QueryBuilder<KalaamLineMetadata, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<KalaamLineMetadata, double, QQueryOperations> endSecProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endSec');
    });
  }

  QueryBuilder<KalaamLineMetadata, String, QQueryOperations>
      kalaamIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kalaamId');
    });
  }

  QueryBuilder<KalaamLineMetadata, int, QQueryOperations> lineIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lineIndex');
    });
  }

  QueryBuilder<KalaamLineMetadata, String, QQueryOperations>
      lineTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lineText');
    });
  }

  QueryBuilder<KalaamLineMetadata, double, QQueryOperations>
      pauseAfterSecProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pauseAfterSec');
    });
  }

  QueryBuilder<KalaamLineMetadata, double, QQueryOperations>
      speakingRateWpmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speakingRateWpm');
    });
  }

  QueryBuilder<KalaamLineMetadata, double, QQueryOperations>
      startSecProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startSec');
    });
  }
}
