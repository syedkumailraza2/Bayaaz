// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPackRecordCollection on Isar {
  IsarCollection<PackRecord> get packRecords => this.collection();
}

const PackRecordSchema = CollectionSchema(
  name: r'PackRecord',
  id: 1530599493843158365,
  properties: {
    r'installedAt': PropertySchema(
      id: 0,
      name: r'installedAt',
      type: IsarType.dateTime,
    ),
    r'isValid': PropertySchema(
      id: 1,
      name: r'isValid',
      type: IsarType.bool,
    ),
    r'packId': PropertySchema(
      id: 2,
      name: r'packId',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 3,
      name: r'version',
      type: IsarType.string,
    )
  },
  estimateSize: _packRecordEstimateSize,
  serialize: _packRecordSerialize,
  deserialize: _packRecordDeserialize,
  deserializeProp: _packRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'packId': IndexSchema(
      id: 8730215967688696519,
      name: r'packId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'packId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _packRecordGetId,
  getLinks: _packRecordGetLinks,
  attach: _packRecordAttach,
  version: '3.1.0+1',
);

int _packRecordEstimateSize(
  PackRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.packId.length * 3;
  bytesCount += 3 + object.version.length * 3;
  return bytesCount;
}

void _packRecordSerialize(
  PackRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.installedAt);
  writer.writeBool(offsets[1], object.isValid);
  writer.writeString(offsets[2], object.packId);
  writer.writeString(offsets[3], object.version);
}

PackRecord _packRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PackRecord();
  object.id = id;
  object.installedAt = reader.readDateTime(offsets[0]);
  object.isValid = reader.readBool(offsets[1]);
  object.packId = reader.readString(offsets[2]);
  object.version = reader.readString(offsets[3]);
  return object;
}

P _packRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _packRecordGetId(PackRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _packRecordGetLinks(PackRecord object) {
  return [];
}

void _packRecordAttach(IsarCollection<dynamic> col, Id id, PackRecord object) {
  object.id = id;
}

extension PackRecordByIndex on IsarCollection<PackRecord> {
  Future<PackRecord?> getByPackId(String packId) {
    return getByIndex(r'packId', [packId]);
  }

  PackRecord? getByPackIdSync(String packId) {
    return getByIndexSync(r'packId', [packId]);
  }

  Future<bool> deleteByPackId(String packId) {
    return deleteByIndex(r'packId', [packId]);
  }

  bool deleteByPackIdSync(String packId) {
    return deleteByIndexSync(r'packId', [packId]);
  }

  Future<List<PackRecord?>> getAllByPackId(List<String> packIdValues) {
    final values = packIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'packId', values);
  }

  List<PackRecord?> getAllByPackIdSync(List<String> packIdValues) {
    final values = packIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'packId', values);
  }

  Future<int> deleteAllByPackId(List<String> packIdValues) {
    final values = packIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'packId', values);
  }

  int deleteAllByPackIdSync(List<String> packIdValues) {
    final values = packIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'packId', values);
  }

  Future<Id> putByPackId(PackRecord object) {
    return putByIndex(r'packId', object);
  }

  Id putByPackIdSync(PackRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'packId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPackId(List<PackRecord> objects) {
    return putAllByIndex(r'packId', objects);
  }

  List<Id> putAllByPackIdSync(List<PackRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'packId', objects, saveLinks: saveLinks);
  }
}

extension PackRecordQueryWhereSort
    on QueryBuilder<PackRecord, PackRecord, QWhere> {
  QueryBuilder<PackRecord, PackRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PackRecordQueryWhere
    on QueryBuilder<PackRecord, PackRecord, QWhereClause> {
  QueryBuilder<PackRecord, PackRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PackRecord, PackRecord, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<PackRecord, PackRecord, QAfterWhereClause> packIdEqualTo(
      String packId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'packId',
        value: [packId],
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterWhereClause> packIdNotEqualTo(
      String packId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'packId',
              lower: [],
              upper: [packId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'packId',
              lower: [packId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'packId',
              lower: [packId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'packId',
              lower: [],
              upper: [packId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PackRecordQueryFilter
    on QueryBuilder<PackRecord, PackRecord, QFilterCondition> {
  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition>
      installedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'installedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition>
      installedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'installedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition>
      installedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'installedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition>
      installedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'installedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> isValidEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isValid',
        value: value,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> packIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'packId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> packIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'packId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> packIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'packId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> packIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'packId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> packIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'packId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> packIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'packId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> packIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'packId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> packIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'packId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> packIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'packId',
        value: '',
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition>
      packIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'packId',
        value: '',
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> versionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition>
      versionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> versionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> versionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> versionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> versionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> versionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> versionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'version',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition> versionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: '',
      ));
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterFilterCondition>
      versionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'version',
        value: '',
      ));
    });
  }
}

extension PackRecordQueryObject
    on QueryBuilder<PackRecord, PackRecord, QFilterCondition> {}

extension PackRecordQueryLinks
    on QueryBuilder<PackRecord, PackRecord, QFilterCondition> {}

extension PackRecordQuerySortBy
    on QueryBuilder<PackRecord, PackRecord, QSortBy> {
  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> sortByInstalledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installedAt', Sort.asc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> sortByInstalledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installedAt', Sort.desc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> sortByIsValid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isValid', Sort.asc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> sortByIsValidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isValid', Sort.desc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> sortByPackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'packId', Sort.asc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> sortByPackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'packId', Sort.desc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension PackRecordQuerySortThenBy
    on QueryBuilder<PackRecord, PackRecord, QSortThenBy> {
  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenByInstalledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installedAt', Sort.asc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenByInstalledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installedAt', Sort.desc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenByIsValid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isValid', Sort.asc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenByIsValidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isValid', Sort.desc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenByPackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'packId', Sort.asc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenByPackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'packId', Sort.desc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension PackRecordQueryWhereDistinct
    on QueryBuilder<PackRecord, PackRecord, QDistinct> {
  QueryBuilder<PackRecord, PackRecord, QDistinct> distinctByInstalledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'installedAt');
    });
  }

  QueryBuilder<PackRecord, PackRecord, QDistinct> distinctByIsValid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isValid');
    });
  }

  QueryBuilder<PackRecord, PackRecord, QDistinct> distinctByPackId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'packId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PackRecord, PackRecord, QDistinct> distinctByVersion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version', caseSensitive: caseSensitive);
    });
  }
}

extension PackRecordQueryProperty
    on QueryBuilder<PackRecord, PackRecord, QQueryProperty> {
  QueryBuilder<PackRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PackRecord, DateTime, QQueryOperations> installedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'installedAt');
    });
  }

  QueryBuilder<PackRecord, bool, QQueryOperations> isValidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isValid');
    });
  }

  QueryBuilder<PackRecord, String, QQueryOperations> packIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'packId');
    });
  }

  QueryBuilder<PackRecord, String, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
