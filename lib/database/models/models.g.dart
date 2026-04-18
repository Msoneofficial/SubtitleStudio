// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPreferencesCollection on Isar {
  IsarCollection<Preferences> get preferences => this.collection();
}

const PreferencesSchema = CollectionSchema(
  name: r'Preferences',
  id: 4252616732994050084,
  properties: {
    r'aiExplanationContextLines': PropertySchema(
      id: 0,
      name: r'aiExplanationContextLines',
      type: IsarType.long,
    ),
    r'aiExplanationPrompt': PropertySchema(
      id: 1,
      name: r'aiExplanationPrompt',
      type: IsarType.string,
    ),
    r'appFontName': PropertySchema(
      id: 2,
      name: r'appFontName',
      type: IsarType.string,
    ),
    r'appFontPath': PropertySchema(
      id: 3,
      name: r'appFontPath',
      type: IsarType.string,
    ),
    r'autoResizeOnKeyboard': PropertySchema(
      id: 4,
      name: r'autoResizeOnKeyboard',
      type: IsarType.bool,
    ),
    r'autoSave': PropertySchema(id: 5, name: r'autoSave', type: IsarType.bool),
    r'autoSaveWithNavigation': PropertySchema(
      id: 6,
      name: r'autoSaveWithNavigation',
      type: IsarType.bool,
    ),
    r'checkpointStrategy': PropertySchema(
      id: 7,
      name: r'checkpointStrategy',
      type: IsarType.string,
    ),
    r'colorHistory': PropertySchema(
      id: 8,
      name: r'colorHistory',
      type: IsarType.stringList,
    ),
    r'editLineResizeRatio': PropertySchema(
      id: 9,
      name: r'editLineResizeRatio',
      type: IsarType.double,
    ),
    r'editScreenResizeRatio': PropertySchema(
      id: 10,
      name: r'editScreenResizeRatio',
      type: IsarType.double,
    ),
    r'floatingControlsEnabled': PropertySchema(
      id: 11,
      name: r'floatingControlsEnabled',
      type: IsarType.bool,
    ),
    r'geminiApiKey': PropertySchema(
      id: 12,
      name: r'geminiApiKey',
      type: IsarType.string,
    ),
    r'geminiModel': PropertySchema(
      id: 13,
      name: r'geminiModel',
      type: IsarType.string,
    ),
    r'hideVideoOnKeyboard': PropertySchema(
      id: 14,
      name: r'hideVideoOnKeyboard',
      type: IsarType.bool,
    ),
    r'lastEditedSession': PropertySchema(
      id: 15,
      name: r'lastEditedSession',
      type: IsarType.long,
    ),
    r'lastUsedDirectory': PropertySchema(
      id: 16,
      name: r'lastUsedDirectory',
      type: IsarType.string,
    ),
    r'maxCheckpoints': PropertySchema(
      id: 17,
      name: r'maxCheckpoints',
      type: IsarType.long,
    ),
    r'maxLineLength': PropertySchema(
      id: 18,
      name: r'maxLineLength',
      type: IsarType.long,
    ),
    r'mobileVideoResizeRatio': PropertySchema(
      id: 19,
      name: r'mobileVideoResizeRatio',
      type: IsarType.double,
    ),
    r'msoneDictionaryEnabled': PropertySchema(
      id: 20,
      name: r'msoneDictionaryEnabled',
      type: IsarType.bool,
    ),
    r'msoneEnabled': PropertySchema(
      id: 21,
      name: r'msoneEnabled',
      type: IsarType.bool,
    ),
    r'olamCaseSensitiveSearch': PropertySchema(
      id: 22,
      name: r'olamCaseSensitiveSearch',
      type: IsarType.bool,
    ),
    r'olamLastUpdateDate': PropertySchema(
      id: 23,
      name: r'olamLastUpdateDate',
      type: IsarType.string,
    ),
    r'olamWholeWordSearch': PropertySchema(
      id: 24,
      name: r'olamWholeWordSearch',
      type: IsarType.bool,
    ),
    r'primarySubtitleVerticalPosition': PropertySchema(
      id: 25,
      name: r'primarySubtitleVerticalPosition',
      type: IsarType.double,
    ),
    r'saveToFileEnabled': PropertySchema(
      id: 26,
      name: r'saveToFileEnabled',
      type: IsarType.bool,
    ),
    r'secondarySubtitleVerticalPosition': PropertySchema(
      id: 27,
      name: r'secondarySubtitleVerticalPosition',
      type: IsarType.double,
    ),
    r'sessionSortOption': PropertySchema(
      id: 28,
      name: r'sessionSortOption',
      type: IsarType.byte,
      enumMap: _PreferencessessionSortOptionEnumValueMap,
    ),
    r'showAllComments': PropertySchema(
      id: 29,
      name: r'showAllComments',
      type: IsarType.bool,
    ),
    r'showOriginalLine': PropertySchema(
      id: 30,
      name: r'showOriginalLine',
      type: IsarType.bool,
    ),
    r'showOriginalTextField': PropertySchema(
      id: 31,
      name: r'showOriginalTextField',
      type: IsarType.bool,
    ),
    r'showSubtitleBackground': PropertySchema(
      id: 32,
      name: r'showSubtitleBackground',
      type: IsarType.bool,
    ),
    r'skipDurationSeconds': PropertySchema(
      id: 33,
      name: r'skipDurationSeconds',
      type: IsarType.long,
    ),
    r'snapshotInterval': PropertySchema(
      id: 34,
      name: r'snapshotInterval',
      type: IsarType.long,
    ),
    r'subtitleFontPath': PropertySchema(
      id: 35,
      name: r'subtitleFontPath',
      type: IsarType.string,
    ),
    r'subtitleFontSize': PropertySchema(
      id: 36,
      name: r'subtitleFontSize',
      type: IsarType.double,
    ),
    r'switchLayout': PropertySchema(
      id: 37,
      name: r'switchLayout',
      type: IsarType.string,
    ),
    r'themeMode': PropertySchema(
      id: 38,
      name: r'themeMode',
      type: IsarType.string,
    ),
    r'translatorContactId': PropertySchema(
      id: 39,
      name: r'translatorContactId',
      type: IsarType.string,
    ),
    r'translatorEmail': PropertySchema(
      id: 40,
      name: r'translatorEmail',
      type: IsarType.string,
    ),
    r'translatorName': PropertySchema(
      id: 41,
      name: r'translatorName',
      type: IsarType.string,
    ),
    r'videoVolume': PropertySchema(
      id: 42,
      name: r'videoVolume',
      type: IsarType.double,
    ),
    r'waveformMaxPixels': PropertySchema(
      id: 43,
      name: r'waveformMaxPixels',
      type: IsarType.long,
    ),
    r'waveformSampleRateFactor': PropertySchema(
      id: 44,
      name: r'waveformSampleRateFactor',
      type: IsarType.long,
    ),
    r'waveformZoomMultiplier': PropertySchema(
      id: 45,
      name: r'waveformZoomMultiplier',
      type: IsarType.double,
    ),
  },

  estimateSize: _preferencesEstimateSize,
  serialize: _preferencesSerialize,
  deserialize: _preferencesDeserialize,
  deserializeProp: _preferencesDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _preferencesGetId,
  getLinks: _preferencesGetLinks,
  attach: _preferencesAttach,
  version: '3.3.2',
);

int _preferencesEstimateSize(
  Preferences object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.aiExplanationPrompt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.appFontName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.appFontPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.checkpointStrategy.length * 3;
  bytesCount += 3 + object.colorHistory.length * 3;
  {
    for (var i = 0; i < object.colorHistory.length; i++) {
      final value = object.colorHistory[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.geminiApiKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.geminiModel.length * 3;
  {
    final value = object.lastUsedDirectory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.olamLastUpdateDate;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.subtitleFontPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.switchLayout.length * 3;
  {
    final value = object.themeMode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.translatorContactId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.translatorEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.translatorName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _preferencesSerialize(
  Preferences object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.aiExplanationContextLines);
  writer.writeString(offsets[1], object.aiExplanationPrompt);
  writer.writeString(offsets[2], object.appFontName);
  writer.writeString(offsets[3], object.appFontPath);
  writer.writeBool(offsets[4], object.autoResizeOnKeyboard);
  writer.writeBool(offsets[5], object.autoSave);
  writer.writeBool(offsets[6], object.autoSaveWithNavigation);
  writer.writeString(offsets[7], object.checkpointStrategy);
  writer.writeStringList(offsets[8], object.colorHistory);
  writer.writeDouble(offsets[9], object.editLineResizeRatio);
  writer.writeDouble(offsets[10], object.editScreenResizeRatio);
  writer.writeBool(offsets[11], object.floatingControlsEnabled);
  writer.writeString(offsets[12], object.geminiApiKey);
  writer.writeString(offsets[13], object.geminiModel);
  writer.writeBool(offsets[14], object.hideVideoOnKeyboard);
  writer.writeLong(offsets[15], object.lastEditedSession);
  writer.writeString(offsets[16], object.lastUsedDirectory);
  writer.writeLong(offsets[17], object.maxCheckpoints);
  writer.writeLong(offsets[18], object.maxLineLength);
  writer.writeDouble(offsets[19], object.mobileVideoResizeRatio);
  writer.writeBool(offsets[20], object.msoneDictionaryEnabled);
  writer.writeBool(offsets[21], object.msoneEnabled);
  writer.writeBool(offsets[22], object.olamCaseSensitiveSearch);
  writer.writeString(offsets[23], object.olamLastUpdateDate);
  writer.writeBool(offsets[24], object.olamWholeWordSearch);
  writer.writeDouble(offsets[25], object.primarySubtitleVerticalPosition);
  writer.writeBool(offsets[26], object.saveToFileEnabled);
  writer.writeDouble(offsets[27], object.secondarySubtitleVerticalPosition);
  writer.writeByte(offsets[28], object.sessionSortOption.index);
  writer.writeBool(offsets[29], object.showAllComments);
  writer.writeBool(offsets[30], object.showOriginalLine);
  writer.writeBool(offsets[31], object.showOriginalTextField);
  writer.writeBool(offsets[32], object.showSubtitleBackground);
  writer.writeLong(offsets[33], object.skipDurationSeconds);
  writer.writeLong(offsets[34], object.snapshotInterval);
  writer.writeString(offsets[35], object.subtitleFontPath);
  writer.writeDouble(offsets[36], object.subtitleFontSize);
  writer.writeString(offsets[37], object.switchLayout);
  writer.writeString(offsets[38], object.themeMode);
  writer.writeString(offsets[39], object.translatorContactId);
  writer.writeString(offsets[40], object.translatorEmail);
  writer.writeString(offsets[41], object.translatorName);
  writer.writeDouble(offsets[42], object.videoVolume);
  writer.writeLong(offsets[43], object.waveformMaxPixels);
  writer.writeLong(offsets[44], object.waveformSampleRateFactor);
  writer.writeDouble(offsets[45], object.waveformZoomMultiplier);
}

Preferences _preferencesDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Preferences(
    aiExplanationContextLines: reader.readLongOrNull(offsets[0]),
    aiExplanationPrompt: reader.readStringOrNull(offsets[1]),
    appFontName: reader.readStringOrNull(offsets[2]),
    appFontPath: reader.readStringOrNull(offsets[3]),
    autoResizeOnKeyboard: reader.readBoolOrNull(offsets[4]) ?? true,
    autoSave: reader.readBool(offsets[5]),
    autoSaveWithNavigation: reader.readBoolOrNull(offsets[6]) ?? false,
    checkpointStrategy: reader.readStringOrNull(offsets[7]) ?? 'hybrid',
    colorHistory: reader.readStringList(offsets[8]) ?? const [],
    editLineResizeRatio: reader.readDoubleOrNull(offsets[9]) ?? 0.35,
    editScreenResizeRatio: reader.readDoubleOrNull(offsets[10]) ?? 0.35,
    floatingControlsEnabled: reader.readBoolOrNull(offsets[11]) ?? false,
    geminiApiKey: reader.readStringOrNull(offsets[12]),
    geminiModel:
        reader.readStringOrNull(offsets[13]) ?? 'models/gemini-2.5-flash',
    hideVideoOnKeyboard: reader.readBoolOrNull(offsets[14]) ?? false,
    lastEditedSession: reader.readLongOrNull(offsets[15]),
    lastUsedDirectory: reader.readStringOrNull(offsets[16]),
    maxCheckpoints: reader.readLongOrNull(offsets[17]) ?? 25,
    maxLineLength: reader.readLongOrNull(offsets[18]) ?? 32,
    mobileVideoResizeRatio: reader.readDoubleOrNull(offsets[19]) ?? 0.4,
    msoneDictionaryEnabled: reader.readBoolOrNull(offsets[20]) ?? false,
    msoneEnabled: reader.readBoolOrNull(offsets[21]) ?? false,
    olamCaseSensitiveSearch: reader.readBoolOrNull(offsets[22]) ?? false,
    olamLastUpdateDate: reader.readStringOrNull(offsets[23]),
    olamWholeWordSearch: reader.readBoolOrNull(offsets[24]) ?? false,
    primarySubtitleVerticalPosition:
        reader.readDoubleOrNull(offsets[25]) ?? 0.0,
    saveToFileEnabled: reader.readBoolOrNull(offsets[26]) ?? false,
    secondarySubtitleVerticalPosition:
        reader.readDoubleOrNull(offsets[27]) ?? 0.0,
    sessionSortOption:
        _PreferencessessionSortOptionValueEnumMap[reader.readByteOrNull(
          offsets[28],
        )] ??
        SessionSortOption.lastOpened,
    showAllComments: reader.readBoolOrNull(offsets[29]) ?? false,
    showOriginalLine: reader.readBoolOrNull(offsets[30]) ?? false,
    showOriginalTextField: reader.readBoolOrNull(offsets[31]) ?? true,
    showSubtitleBackground: reader.readBoolOrNull(offsets[32]) ?? true,
    skipDurationSeconds: reader.readLongOrNull(offsets[33]) ?? 10,
    snapshotInterval: reader.readLongOrNull(offsets[34]) ?? 10,
    subtitleFontPath: reader.readStringOrNull(offsets[35]),
    subtitleFontSize: reader.readDoubleOrNull(offsets[36]) ?? 16.0,
    switchLayout: reader.readStringOrNull(offsets[37]) ?? 'layout1',
    themeMode: reader.readStringOrNull(offsets[38]),
    translatorContactId: reader.readStringOrNull(offsets[39]),
    translatorEmail: reader.readStringOrNull(offsets[40]),
    translatorName: reader.readStringOrNull(offsets[41]),
    videoVolume: reader.readDoubleOrNull(offsets[42]) ?? 100.0,
    waveformMaxPixels: reader.readLongOrNull(offsets[43]),
    waveformSampleRateFactor: reader.readLongOrNull(offsets[44]),
    waveformZoomMultiplier: reader.readDoubleOrNull(offsets[45]),
  );
  object.id = id;
  return object;
}

P _preferencesDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 7:
      return (reader.readStringOrNull(offset) ?? 'hybrid') as P;
    case 8:
      return (reader.readStringList(offset) ?? const []) as P;
    case 9:
      return (reader.readDoubleOrNull(offset) ?? 0.35) as P;
    case 10:
      return (reader.readDoubleOrNull(offset) ?? 0.35) as P;
    case 11:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset) ?? 'models/gemini-2.5-flash')
          as P;
    case 14:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readLongOrNull(offset) ?? 25) as P;
    case 18:
      return (reader.readLongOrNull(offset) ?? 32) as P;
    case 19:
      return (reader.readDoubleOrNull(offset) ?? 0.4) as P;
    case 20:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 21:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 22:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 25:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 26:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 27:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 28:
      return (_PreferencessessionSortOptionValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              SessionSortOption.lastOpened)
          as P;
    case 29:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 30:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 31:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 32:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 33:
      return (reader.readLongOrNull(offset) ?? 10) as P;
    case 34:
      return (reader.readLongOrNull(offset) ?? 10) as P;
    case 35:
      return (reader.readStringOrNull(offset)) as P;
    case 36:
      return (reader.readDoubleOrNull(offset) ?? 16.0) as P;
    case 37:
      return (reader.readStringOrNull(offset) ?? 'layout1') as P;
    case 38:
      return (reader.readStringOrNull(offset)) as P;
    case 39:
      return (reader.readStringOrNull(offset)) as P;
    case 40:
      return (reader.readStringOrNull(offset)) as P;
    case 41:
      return (reader.readStringOrNull(offset)) as P;
    case 42:
      return (reader.readDoubleOrNull(offset) ?? 100.0) as P;
    case 43:
      return (reader.readLongOrNull(offset)) as P;
    case 44:
      return (reader.readLongOrNull(offset)) as P;
    case 45:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PreferencessessionSortOptionEnumValueMap = {
  'lastOpened': 0,
  'lastCreated': 1,
  'name': 2,
  'nameDesc': 3,
};
const _PreferencessessionSortOptionValueEnumMap = {
  0: SessionSortOption.lastOpened,
  1: SessionSortOption.lastCreated,
  2: SessionSortOption.name,
  3: SessionSortOption.nameDesc,
};

Id _preferencesGetId(Preferences object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _preferencesGetLinks(Preferences object) {
  return [];
}

void _preferencesAttach(
  IsarCollection<dynamic> col,
  Id id,
  Preferences object,
) {
  object.id = id;
}

extension PreferencesQueryWhereSort
    on QueryBuilder<Preferences, Preferences, QWhere> {
  QueryBuilder<Preferences, Preferences, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PreferencesQueryWhere
    on QueryBuilder<Preferences, Preferences, QWhereClause> {
  QueryBuilder<Preferences, Preferences, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<Preferences, Preferences, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PreferencesQueryFilter
    on QueryBuilder<Preferences, Preferences, QFilterCondition> {
  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationContextLinesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'aiExplanationContextLines'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationContextLinesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'aiExplanationContextLines'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationContextLinesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'aiExplanationContextLines',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationContextLinesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'aiExplanationContextLines',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationContextLinesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'aiExplanationContextLines',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationContextLinesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'aiExplanationContextLines',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'aiExplanationPrompt'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'aiExplanationPrompt'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'aiExplanationPrompt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'aiExplanationPrompt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'aiExplanationPrompt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'aiExplanationPrompt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'aiExplanationPrompt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'aiExplanationPrompt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'aiExplanationPrompt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'aiExplanationPrompt',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'aiExplanationPrompt', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  aiExplanationPromptIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'aiExplanationPrompt',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'appFontName'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'appFontName'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'appFontName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'appFontName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'appFontName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'appFontName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'appFontName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'appFontName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'appFontName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'appFontName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'appFontName', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'appFontName', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'appFontPath'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'appFontPath'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'appFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'appFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'appFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'appFontPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'appFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'appFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'appFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'appFontPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'appFontPath', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  appFontPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'appFontPath', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  autoResizeOnKeyboardEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'autoResizeOnKeyboard',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition> autoSaveEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'autoSave', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  autoSaveWithNavigationEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'autoSaveWithNavigation',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'checkpointStrategy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'checkpointStrategy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'checkpointStrategy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'checkpointStrategy',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'checkpointStrategy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'checkpointStrategy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'checkpointStrategy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'checkpointStrategy',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'checkpointStrategy', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  checkpointStrategyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'checkpointStrategy', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'colorHistory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'colorHistory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'colorHistory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'colorHistory',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'colorHistory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'colorHistory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'colorHistory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'colorHistory',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'colorHistory', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'colorHistory', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'colorHistory', length, true, length, true);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'colorHistory', 0, true, 0, true);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'colorHistory', 0, false, 999999, true);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'colorHistory', 0, true, length, include);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'colorHistory', length, include, 999999, true);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  colorHistoryLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'colorHistory',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  editLineResizeRatioEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'editLineResizeRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  editLineResizeRatioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'editLineResizeRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  editLineResizeRatioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'editLineResizeRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  editLineResizeRatioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'editLineResizeRatio',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  editScreenResizeRatioEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'editScreenResizeRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  editScreenResizeRatioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'editScreenResizeRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  editScreenResizeRatioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'editScreenResizeRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  editScreenResizeRatioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'editScreenResizeRatio',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  floatingControlsEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'floatingControlsEnabled',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'geminiApiKey'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'geminiApiKey'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'geminiApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'geminiApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'geminiApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'geminiApiKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'geminiApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'geminiApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'geminiApiKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'geminiApiKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'geminiApiKey', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiApiKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'geminiApiKey', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'geminiModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'geminiModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'geminiModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'geminiModel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'geminiModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'geminiModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'geminiModel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'geminiModel',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'geminiModel', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  geminiModelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'geminiModel', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  hideVideoOnKeyboardEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hideVideoOnKeyboard', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastEditedSessionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastEditedSession'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastEditedSessionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastEditedSession'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastEditedSessionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastEditedSession', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastEditedSessionGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastEditedSession',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastEditedSessionLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastEditedSession',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastEditedSessionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastEditedSession',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUsedDirectory'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUsedDirectory'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastUsedDirectory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUsedDirectory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUsedDirectory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUsedDirectory',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastUsedDirectory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastUsedDirectory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastUsedDirectory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastUsedDirectory',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUsedDirectory', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  lastUsedDirectoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastUsedDirectory', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  maxCheckpointsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'maxCheckpoints', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  maxCheckpointsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'maxCheckpoints',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  maxCheckpointsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'maxCheckpoints',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  maxCheckpointsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'maxCheckpoints',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  maxLineLengthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'maxLineLength', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  maxLineLengthGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'maxLineLength',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  maxLineLengthLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'maxLineLength',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  maxLineLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'maxLineLength',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  mobileVideoResizeRatioEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mobileVideoResizeRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  mobileVideoResizeRatioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mobileVideoResizeRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  mobileVideoResizeRatioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mobileVideoResizeRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  mobileVideoResizeRatioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mobileVideoResizeRatio',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  msoneDictionaryEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'msoneDictionaryEnabled',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  msoneEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'msoneEnabled', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamCaseSensitiveSearchEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'olamCaseSensitiveSearch',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'olamLastUpdateDate'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'olamLastUpdateDate'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'olamLastUpdateDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'olamLastUpdateDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'olamLastUpdateDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'olamLastUpdateDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'olamLastUpdateDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'olamLastUpdateDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'olamLastUpdateDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'olamLastUpdateDate',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'olamLastUpdateDate', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamLastUpdateDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'olamLastUpdateDate', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  olamWholeWordSearchEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'olamWholeWordSearch', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  primarySubtitleVerticalPositionEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'primarySubtitleVerticalPosition',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  primarySubtitleVerticalPositionGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'primarySubtitleVerticalPosition',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  primarySubtitleVerticalPositionLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'primarySubtitleVerticalPosition',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  primarySubtitleVerticalPositionBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'primarySubtitleVerticalPosition',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  saveToFileEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'saveToFileEnabled', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  secondarySubtitleVerticalPositionEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'secondarySubtitleVerticalPosition',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  secondarySubtitleVerticalPositionGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'secondarySubtitleVerticalPosition',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  secondarySubtitleVerticalPositionLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'secondarySubtitleVerticalPosition',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  secondarySubtitleVerticalPositionBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'secondarySubtitleVerticalPosition',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  sessionSortOptionEqualTo(SessionSortOption value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sessionSortOption', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  sessionSortOptionGreaterThan(
    SessionSortOption value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sessionSortOption',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  sessionSortOptionLessThan(SessionSortOption value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sessionSortOption',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  sessionSortOptionBetween(
    SessionSortOption lower,
    SessionSortOption upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sessionSortOption',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  showAllCommentsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'showAllComments', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  showOriginalLineEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'showOriginalLine', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  showOriginalTextFieldEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'showOriginalTextField',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  showSubtitleBackgroundEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'showSubtitleBackground',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  skipDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'skipDurationSeconds', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  skipDurationSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'skipDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  skipDurationSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'skipDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  skipDurationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'skipDurationSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  snapshotIntervalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'snapshotInterval', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  snapshotIntervalGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'snapshotInterval',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  snapshotIntervalLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'snapshotInterval',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  snapshotIntervalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'snapshotInterval',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'subtitleFontPath'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'subtitleFontPath'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subtitleFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subtitleFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subtitleFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subtitleFontPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'subtitleFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'subtitleFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'subtitleFontPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'subtitleFontPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'subtitleFontPath', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'subtitleFontPath', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontSizeEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subtitleFontSize',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontSizeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subtitleFontSize',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontSizeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subtitleFontSize',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  subtitleFontSizeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subtitleFontSize',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'switchLayout',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'switchLayout',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'switchLayout',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'switchLayout',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'switchLayout',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'switchLayout',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'switchLayout',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'switchLayout',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'switchLayout', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  switchLayoutIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'switchLayout', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'themeMode'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'themeMode'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'themeMode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'themeMode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'themeMode', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  themeModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'themeMode', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'translatorContactId'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'translatorContactId'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'translatorContactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'translatorContactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'translatorContactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'translatorContactId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'translatorContactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'translatorContactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'translatorContactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'translatorContactId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'translatorContactId', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorContactIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'translatorContactId',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'translatorEmail'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'translatorEmail'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'translatorEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'translatorEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'translatorEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'translatorEmail',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'translatorEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'translatorEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'translatorEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'translatorEmail',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'translatorEmail', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'translatorEmail', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'translatorName'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'translatorName'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'translatorName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'translatorName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'translatorName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'translatorName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'translatorName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'translatorName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'translatorName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'translatorName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'translatorName', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  translatorNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'translatorName', value: ''),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  videoVolumeEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'videoVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  videoVolumeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'videoVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  videoVolumeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'videoVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  videoVolumeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'videoVolume',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformMaxPixelsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformMaxPixels'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformMaxPixelsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformMaxPixels'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformMaxPixelsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'waveformMaxPixels', value: value),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformMaxPixelsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformMaxPixels',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformMaxPixelsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformMaxPixels',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformMaxPixelsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformMaxPixels',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformSampleRateFactorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformSampleRateFactor'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformSampleRateFactorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformSampleRateFactor'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformSampleRateFactorEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'waveformSampleRateFactor',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformSampleRateFactorGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformSampleRateFactor',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformSampleRateFactorLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformSampleRateFactor',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformSampleRateFactorBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformSampleRateFactor',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformZoomMultiplierIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformZoomMultiplier'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformZoomMultiplierIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformZoomMultiplier'),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformZoomMultiplierEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'waveformZoomMultiplier',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformZoomMultiplierGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformZoomMultiplier',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformZoomMultiplierLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformZoomMultiplier',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterFilterCondition>
  waveformZoomMultiplierBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformZoomMultiplier',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension PreferencesQueryObject
    on QueryBuilder<Preferences, Preferences, QFilterCondition> {}

extension PreferencesQueryLinks
    on QueryBuilder<Preferences, Preferences, QFilterCondition> {}

extension PreferencesQuerySortBy
    on QueryBuilder<Preferences, Preferences, QSortBy> {
  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByAiExplanationContextLines() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanationContextLines', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByAiExplanationContextLinesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanationContextLines', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByAiExplanationPrompt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanationPrompt', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByAiExplanationPromptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanationPrompt', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByAppFontName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appFontName', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByAppFontNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appFontName', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByAppFontPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appFontPath', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByAppFontPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appFontPath', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByAutoResizeOnKeyboard() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoResizeOnKeyboard', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByAutoResizeOnKeyboardDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoResizeOnKeyboard', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByAutoSave() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSave', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByAutoSaveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSave', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByAutoSaveWithNavigation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveWithNavigation', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByAutoSaveWithNavigationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveWithNavigation', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByCheckpointStrategy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointStrategy', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByCheckpointStrategyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointStrategy', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByEditLineResizeRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editLineResizeRatio', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByEditLineResizeRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editLineResizeRatio', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByEditScreenResizeRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editScreenResizeRatio', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByEditScreenResizeRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editScreenResizeRatio', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByFloatingControlsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floatingControlsEnabled', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByFloatingControlsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floatingControlsEnabled', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByGeminiApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geminiApiKey', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByGeminiApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geminiApiKey', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByGeminiModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geminiModel', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByGeminiModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geminiModel', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByHideVideoOnKeyboard() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideVideoOnKeyboard', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByHideVideoOnKeyboardDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideVideoOnKeyboard', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByLastEditedSession() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedSession', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByLastEditedSessionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedSession', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByLastUsedDirectory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedDirectory', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByLastUsedDirectoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedDirectory', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByMaxCheckpoints() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCheckpoints', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByMaxCheckpointsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCheckpoints', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByMaxLineLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLineLength', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByMaxLineLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLineLength', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByMobileVideoResizeRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileVideoResizeRatio', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByMobileVideoResizeRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileVideoResizeRatio', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByMsoneDictionaryEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msoneDictionaryEnabled', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByMsoneDictionaryEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msoneDictionaryEnabled', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByMsoneEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msoneEnabled', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByMsoneEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msoneEnabled', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByOlamCaseSensitiveSearch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamCaseSensitiveSearch', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByOlamCaseSensitiveSearchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamCaseSensitiveSearch', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByOlamLastUpdateDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamLastUpdateDate', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByOlamLastUpdateDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamLastUpdateDate', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByOlamWholeWordSearch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamWholeWordSearch', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByOlamWholeWordSearchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamWholeWordSearch', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByPrimarySubtitleVerticalPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySubtitleVerticalPosition', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByPrimarySubtitleVerticalPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySubtitleVerticalPosition', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySaveToFileEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saveToFileEnabled', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySaveToFileEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saveToFileEnabled', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySecondarySubtitleVerticalPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySubtitleVerticalPosition', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySecondarySubtitleVerticalPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySubtitleVerticalPosition', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySessionSortOption() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionSortOption', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySessionSortOptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionSortOption', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByShowAllComments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showAllComments', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByShowAllCommentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showAllComments', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByShowOriginalLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOriginalLine', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByShowOriginalLineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOriginalLine', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByShowOriginalTextField() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOriginalTextField', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByShowOriginalTextFieldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOriginalTextField', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByShowSubtitleBackground() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubtitleBackground', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByShowSubtitleBackgroundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubtitleBackground', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySkipDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySkipDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySnapshotInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotInterval', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySnapshotIntervalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotInterval', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySubtitleFontPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleFontPath', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySubtitleFontPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleFontPath', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySubtitleFontSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleFontSize', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySubtitleFontSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleFontSize', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortBySwitchLayout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'switchLayout', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortBySwitchLayoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'switchLayout', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByTranslatorContactId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorContactId', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByTranslatorContactIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorContactId', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByTranslatorEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorEmail', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByTranslatorEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorEmail', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByTranslatorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorName', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByTranslatorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorName', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByVideoVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoVolume', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> sortByVideoVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoVolume', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByWaveformMaxPixels() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformMaxPixels', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByWaveformMaxPixelsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformMaxPixels', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByWaveformSampleRateFactor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformSampleRateFactor', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByWaveformSampleRateFactorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformSampleRateFactor', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByWaveformZoomMultiplier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformZoomMultiplier', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  sortByWaveformZoomMultiplierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformZoomMultiplier', Sort.desc);
    });
  }
}

extension PreferencesQuerySortThenBy
    on QueryBuilder<Preferences, Preferences, QSortThenBy> {
  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByAiExplanationContextLines() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanationContextLines', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByAiExplanationContextLinesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanationContextLines', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByAiExplanationPrompt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanationPrompt', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByAiExplanationPromptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanationPrompt', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByAppFontName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appFontName', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByAppFontNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appFontName', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByAppFontPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appFontPath', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByAppFontPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appFontPath', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByAutoResizeOnKeyboard() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoResizeOnKeyboard', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByAutoResizeOnKeyboardDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoResizeOnKeyboard', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByAutoSave() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSave', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByAutoSaveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSave', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByAutoSaveWithNavigation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveWithNavigation', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByAutoSaveWithNavigationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveWithNavigation', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByCheckpointStrategy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointStrategy', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByCheckpointStrategyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointStrategy', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByEditLineResizeRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editLineResizeRatio', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByEditLineResizeRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editLineResizeRatio', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByEditScreenResizeRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editScreenResizeRatio', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByEditScreenResizeRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editScreenResizeRatio', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByFloatingControlsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floatingControlsEnabled', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByFloatingControlsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floatingControlsEnabled', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByGeminiApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geminiApiKey', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByGeminiApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geminiApiKey', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByGeminiModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geminiModel', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByGeminiModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geminiModel', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByHideVideoOnKeyboard() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideVideoOnKeyboard', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByHideVideoOnKeyboardDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideVideoOnKeyboard', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByLastEditedSession() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedSession', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByLastEditedSessionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedSession', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByLastUsedDirectory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedDirectory', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByLastUsedDirectoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedDirectory', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByMaxCheckpoints() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCheckpoints', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByMaxCheckpointsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCheckpoints', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByMaxLineLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLineLength', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByMaxLineLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLineLength', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByMobileVideoResizeRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileVideoResizeRatio', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByMobileVideoResizeRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileVideoResizeRatio', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByMsoneDictionaryEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msoneDictionaryEnabled', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByMsoneDictionaryEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msoneDictionaryEnabled', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByMsoneEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msoneEnabled', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByMsoneEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msoneEnabled', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByOlamCaseSensitiveSearch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamCaseSensitiveSearch', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByOlamCaseSensitiveSearchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamCaseSensitiveSearch', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByOlamLastUpdateDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamLastUpdateDate', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByOlamLastUpdateDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamLastUpdateDate', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByOlamWholeWordSearch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamWholeWordSearch', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByOlamWholeWordSearchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'olamWholeWordSearch', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByPrimarySubtitleVerticalPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySubtitleVerticalPosition', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByPrimarySubtitleVerticalPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySubtitleVerticalPosition', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySaveToFileEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saveToFileEnabled', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySaveToFileEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saveToFileEnabled', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySecondarySubtitleVerticalPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySubtitleVerticalPosition', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySecondarySubtitleVerticalPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySubtitleVerticalPosition', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySessionSortOption() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionSortOption', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySessionSortOptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionSortOption', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByShowAllComments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showAllComments', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByShowAllCommentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showAllComments', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByShowOriginalLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOriginalLine', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByShowOriginalLineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOriginalLine', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByShowOriginalTextField() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOriginalTextField', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByShowOriginalTextFieldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOriginalTextField', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByShowSubtitleBackground() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubtitleBackground', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByShowSubtitleBackgroundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubtitleBackground', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySkipDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySkipDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySnapshotInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotInterval', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySnapshotIntervalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotInterval', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySubtitleFontPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleFontPath', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySubtitleFontPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleFontPath', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySubtitleFontSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleFontSize', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySubtitleFontSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleFontSize', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenBySwitchLayout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'switchLayout', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenBySwitchLayoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'switchLayout', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByTranslatorContactId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorContactId', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByTranslatorContactIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorContactId', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByTranslatorEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorEmail', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByTranslatorEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorEmail', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByTranslatorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorName', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByTranslatorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatorName', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByVideoVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoVolume', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy> thenByVideoVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoVolume', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByWaveformMaxPixels() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformMaxPixels', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByWaveformMaxPixelsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformMaxPixels', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByWaveformSampleRateFactor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformSampleRateFactor', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByWaveformSampleRateFactorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformSampleRateFactor', Sort.desc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByWaveformZoomMultiplier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformZoomMultiplier', Sort.asc);
    });
  }

  QueryBuilder<Preferences, Preferences, QAfterSortBy>
  thenByWaveformZoomMultiplierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformZoomMultiplier', Sort.desc);
    });
  }
}

extension PreferencesQueryWhereDistinct
    on QueryBuilder<Preferences, Preferences, QDistinct> {
  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByAiExplanationContextLines() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiExplanationContextLines');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByAiExplanationPrompt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'aiExplanationPrompt',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByAppFontName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appFontName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByAppFontPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appFontPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByAutoResizeOnKeyboard() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoResizeOnKeyboard');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByAutoSave() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSave');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByAutoSaveWithNavigation() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSaveWithNavigation');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByCheckpointStrategy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'checkpointStrategy',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByColorHistory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorHistory');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByEditLineResizeRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editLineResizeRatio');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByEditScreenResizeRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editScreenResizeRatio');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByFloatingControlsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'floatingControlsEnabled');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByGeminiApiKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'geminiApiKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByGeminiModel({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'geminiModel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByHideVideoOnKeyboard() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hideVideoOnKeyboard');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByLastEditedSession() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastEditedSession');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByLastUsedDirectory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastUsedDirectory',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByMaxCheckpoints() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxCheckpoints');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByMaxLineLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxLineLength');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByMobileVideoResizeRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobileVideoResizeRatio');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByMsoneDictionaryEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'msoneDictionaryEnabled');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByMsoneEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'msoneEnabled');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByOlamCaseSensitiveSearch() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'olamCaseSensitiveSearch');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByOlamLastUpdateDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'olamLastUpdateDate',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByOlamWholeWordSearch() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'olamWholeWordSearch');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByPrimarySubtitleVerticalPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'primarySubtitleVerticalPosition');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctBySaveToFileEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'saveToFileEnabled');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctBySecondarySubtitleVerticalPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secondarySubtitleVerticalPosition');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctBySessionSortOption() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionSortOption');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByShowAllComments() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showAllComments');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByShowOriginalLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showOriginalLine');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByShowOriginalTextField() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showOriginalTextField');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByShowSubtitleBackground() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showSubtitleBackground');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctBySkipDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skipDurationSeconds');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctBySnapshotInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snapshotInterval');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctBySubtitleFontPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'subtitleFontPath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctBySubtitleFontSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtitleFontSize');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctBySwitchLayout({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'switchLayout', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByThemeMode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeMode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByTranslatorContactId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'translatorContactId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByTranslatorEmail({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'translatorEmail',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByTranslatorName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'translatorName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct> distinctByVideoVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'videoVolume');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByWaveformMaxPixels() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waveformMaxPixels');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByWaveformSampleRateFactor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waveformSampleRateFactor');
    });
  }

  QueryBuilder<Preferences, Preferences, QDistinct>
  distinctByWaveformZoomMultiplier() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waveformZoomMultiplier');
    });
  }
}

extension PreferencesQueryProperty
    on QueryBuilder<Preferences, Preferences, QQueryProperty> {
  QueryBuilder<Preferences, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Preferences, int?, QQueryOperations>
  aiExplanationContextLinesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiExplanationContextLines');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations>
  aiExplanationPromptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiExplanationPrompt');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations> appFontNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appFontName');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations> appFontPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appFontPath');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  autoResizeOnKeyboardProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoResizeOnKeyboard');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations> autoSaveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSave');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  autoSaveWithNavigationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSaveWithNavigation');
    });
  }

  QueryBuilder<Preferences, String, QQueryOperations>
  checkpointStrategyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkpointStrategy');
    });
  }

  QueryBuilder<Preferences, List<String>, QQueryOperations>
  colorHistoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorHistory');
    });
  }

  QueryBuilder<Preferences, double, QQueryOperations>
  editLineResizeRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editLineResizeRatio');
    });
  }

  QueryBuilder<Preferences, double, QQueryOperations>
  editScreenResizeRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editScreenResizeRatio');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  floatingControlsEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'floatingControlsEnabled');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations> geminiApiKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'geminiApiKey');
    });
  }

  QueryBuilder<Preferences, String, QQueryOperations> geminiModelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'geminiModel');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  hideVideoOnKeyboardProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hideVideoOnKeyboard');
    });
  }

  QueryBuilder<Preferences, int?, QQueryOperations>
  lastEditedSessionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastEditedSession');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations>
  lastUsedDirectoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUsedDirectory');
    });
  }

  QueryBuilder<Preferences, int, QQueryOperations> maxCheckpointsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxCheckpoints');
    });
  }

  QueryBuilder<Preferences, int, QQueryOperations> maxLineLengthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxLineLength');
    });
  }

  QueryBuilder<Preferences, double, QQueryOperations>
  mobileVideoResizeRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobileVideoResizeRatio');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  msoneDictionaryEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'msoneDictionaryEnabled');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations> msoneEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'msoneEnabled');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  olamCaseSensitiveSearchProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'olamCaseSensitiveSearch');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations>
  olamLastUpdateDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'olamLastUpdateDate');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  olamWholeWordSearchProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'olamWholeWordSearch');
    });
  }

  QueryBuilder<Preferences, double, QQueryOperations>
  primarySubtitleVerticalPositionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primarySubtitleVerticalPosition');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  saveToFileEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'saveToFileEnabled');
    });
  }

  QueryBuilder<Preferences, double, QQueryOperations>
  secondarySubtitleVerticalPositionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondarySubtitleVerticalPosition');
    });
  }

  QueryBuilder<Preferences, SessionSortOption, QQueryOperations>
  sessionSortOptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionSortOption');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations> showAllCommentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showAllComments');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations> showOriginalLineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showOriginalLine');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  showOriginalTextFieldProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showOriginalTextField');
    });
  }

  QueryBuilder<Preferences, bool, QQueryOperations>
  showSubtitleBackgroundProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showSubtitleBackground');
    });
  }

  QueryBuilder<Preferences, int, QQueryOperations>
  skipDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skipDurationSeconds');
    });
  }

  QueryBuilder<Preferences, int, QQueryOperations> snapshotIntervalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snapshotInterval');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations>
  subtitleFontPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtitleFontPath');
    });
  }

  QueryBuilder<Preferences, double, QQueryOperations>
  subtitleFontSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtitleFontSize');
    });
  }

  QueryBuilder<Preferences, String, QQueryOperations> switchLayoutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'switchLayout');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations> themeModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeMode');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations>
  translatorContactIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translatorContactId');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations>
  translatorEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translatorEmail');
    });
  }

  QueryBuilder<Preferences, String?, QQueryOperations>
  translatorNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translatorName');
    });
  }

  QueryBuilder<Preferences, double, QQueryOperations> videoVolumeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'videoVolume');
    });
  }

  QueryBuilder<Preferences, int?, QQueryOperations>
  waveformMaxPixelsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformMaxPixels');
    });
  }

  QueryBuilder<Preferences, int?, QQueryOperations>
  waveformSampleRateFactorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformSampleRateFactor');
    });
  }

  QueryBuilder<Preferences, double?, QQueryOperations>
  waveformZoomMultiplierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformZoomMultiplier');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSessionCollection on Isar {
  IsarCollection<Session> get sessions => this.collection();
}

const SessionSchema = CollectionSchema(
  name: r'Session',
  id: 4817823809690647594,
  properties: {
    r'editMode': PropertySchema(id: 0, name: r'editMode', type: IsarType.bool),
    r'fileName': PropertySchema(
      id: 1,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'lastEditedIndex': PropertySchema(
      id: 2,
      name: r'lastEditedIndex',
      type: IsarType.long,
    ),
    r'projectFilePath': PropertySchema(
      id: 3,
      name: r'projectFilePath',
      type: IsarType.string,
    ),
    r'subtitleCollectionId': PropertySchema(
      id: 4,
      name: r'subtitleCollectionId',
      type: IsarType.long,
    ),
  },

  estimateSize: _sessionEstimateSize,
  serialize: _sessionSerialize,
  deserialize: _sessionDeserialize,
  deserializeProp: _sessionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _sessionGetId,
  getLinks: _sessionGetLinks,
  attach: _sessionAttach,
  version: '3.3.2',
);

int _sessionEstimateSize(
  Session object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fileName.length * 3;
  {
    final value = object.projectFilePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _sessionSerialize(
  Session object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.editMode);
  writer.writeString(offsets[1], object.fileName);
  writer.writeLong(offsets[2], object.lastEditedIndex);
  writer.writeString(offsets[3], object.projectFilePath);
  writer.writeLong(offsets[4], object.subtitleCollectionId);
}

Session _sessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Session(
    editMode: reader.readBoolOrNull(offsets[0]) ?? false,
    fileName: reader.readString(offsets[1]),
    lastEditedIndex: reader.readLongOrNull(offsets[2]),
    projectFilePath: reader.readStringOrNull(offsets[3]),
    subtitleCollectionId: reader.readLong(offsets[4]),
  );
  object.id = id;
  return object;
}

P _sessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _sessionGetId(Session object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _sessionGetLinks(Session object) {
  return [];
}

void _sessionAttach(IsarCollection<dynamic> col, Id id, Session object) {
  object.id = id;
}

extension SessionQueryWhereSort on QueryBuilder<Session, Session, QWhere> {
  QueryBuilder<Session, Session, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SessionQueryWhere on QueryBuilder<Session, Session, QWhereClause> {
  QueryBuilder<Session, Session, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Session, Session, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SessionQueryFilter
    on QueryBuilder<Session, Session, QFilterCondition> {
  QueryBuilder<Session, Session, QAfterFilterCondition> editModeEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'editMode', value: value),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  lastEditedIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastEditedIndex'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  lastEditedIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastEditedIndex'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> lastEditedIndexEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastEditedIndex', value: value),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  lastEditedIndexGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastEditedIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> lastEditedIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastEditedIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> lastEditedIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastEditedIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  projectFilePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'projectFilePath'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  projectFilePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'projectFilePath'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> projectFilePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'projectFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  projectFilePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'projectFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> projectFilePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'projectFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> projectFilePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'projectFilePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  projectFilePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'projectFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> projectFilePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'projectFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> projectFilePathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'projectFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> projectFilePathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'projectFilePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  projectFilePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'projectFilePath', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  projectFilePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'projectFilePath', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  subtitleCollectionIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subtitleCollectionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  subtitleCollectionIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subtitleCollectionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  subtitleCollectionIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subtitleCollectionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  subtitleCollectionIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subtitleCollectionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SessionQueryObject
    on QueryBuilder<Session, Session, QFilterCondition> {}

extension SessionQueryLinks
    on QueryBuilder<Session, Session, QFilterCondition> {}

extension SessionQuerySortBy on QueryBuilder<Session, Session, QSortBy> {
  QueryBuilder<Session, Session, QAfterSortBy> sortByEditMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editMode', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByEditModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editMode', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByLastEditedIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedIndex', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByLastEditedIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedIndex', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByProjectFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectFilePath', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByProjectFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectFilePath', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortBySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy>
  sortBySubtitleCollectionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.desc);
    });
  }
}

extension SessionQuerySortThenBy
    on QueryBuilder<Session, Session, QSortThenBy> {
  QueryBuilder<Session, Session, QAfterSortBy> thenByEditMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editMode', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByEditModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editMode', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByLastEditedIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedIndex', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByLastEditedIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedIndex', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByProjectFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectFilePath', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByProjectFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectFilePath', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenBySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy>
  thenBySubtitleCollectionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.desc);
    });
  }
}

extension SessionQueryWhereDistinct
    on QueryBuilder<Session, Session, QDistinct> {
  QueryBuilder<Session, Session, QDistinct> distinctByEditMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editMode');
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByFileName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByLastEditedIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastEditedIndex');
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByProjectFilePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'projectFilePath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctBySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtitleCollectionId');
    });
  }
}

extension SessionQueryProperty
    on QueryBuilder<Session, Session, QQueryProperty> {
  QueryBuilder<Session, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Session, bool, QQueryOperations> editModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editMode');
    });
  }

  QueryBuilder<Session, String, QQueryOperations> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<Session, int?, QQueryOperations> lastEditedIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastEditedIndex');
    });
  }

  QueryBuilder<Session, String?, QQueryOperations> projectFilePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectFilePath');
    });
  }

  QueryBuilder<Session, int, QQueryOperations> subtitleCollectionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtitleCollectionId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSubtitleCollectionCollection on Isar {
  IsarCollection<SubtitleCollection> get subtitleCollections =>
      this.collection();
}

const SubtitleCollectionSchema = CollectionSchema(
  name: r'SubtitleCollection',
  id: -8061165575534938219,
  properties: {
    r'encoding': PropertySchema(
      id: 0,
      name: r'encoding',
      type: IsarType.string,
    ),
    r'fileName': PropertySchema(
      id: 1,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'filePath': PropertySchema(
      id: 2,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'lines': PropertySchema(
      id: 3,
      name: r'lines',
      type: IsarType.objectList,

      target: r'SubtitleLine',
    ),
    r'macOsSrtBookmark': PropertySchema(
      id: 4,
      name: r'macOsSrtBookmark',
      type: IsarType.string,
    ),
    r'originalFileUri': PropertySchema(
      id: 5,
      name: r'originalFileUri',
      type: IsarType.string,
    ),
  },

  estimateSize: _subtitleCollectionEstimateSize,
  serialize: _subtitleCollectionSerialize,
  deserialize: _subtitleCollectionDeserialize,
  deserializeProp: _subtitleCollectionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'SubtitleLine': SubtitleLineSchema},

  getId: _subtitleCollectionGetId,
  getLinks: _subtitleCollectionGetLinks,
  attach: _subtitleCollectionAttach,
  version: '3.3.2',
);

int _subtitleCollectionEstimateSize(
  SubtitleCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.encoding.length * 3;
  bytesCount += 3 + object.fileName.length * 3;
  {
    final value = object.filePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.lines.length * 3;
  {
    final offsets = allOffsets[SubtitleLine]!;
    for (var i = 0; i < object.lines.length; i++) {
      final value = object.lines[i];
      bytesCount += SubtitleLineSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.macOsSrtBookmark;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.originalFileUri;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _subtitleCollectionSerialize(
  SubtitleCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.encoding);
  writer.writeString(offsets[1], object.fileName);
  writer.writeString(offsets[2], object.filePath);
  writer.writeObjectList<SubtitleLine>(
    offsets[3],
    allOffsets,
    SubtitleLineSchema.serialize,
    object.lines,
  );
  writer.writeString(offsets[4], object.macOsSrtBookmark);
  writer.writeString(offsets[5], object.originalFileUri);
}

SubtitleCollection _subtitleCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SubtitleCollection(
    encoding: reader.readString(offsets[0]),
    fileName: reader.readString(offsets[1]),
    filePath: reader.readStringOrNull(offsets[2]),
    lines:
        reader.readObjectList<SubtitleLine>(
          offsets[3],
          SubtitleLineSchema.deserialize,
          allOffsets,
          SubtitleLine(),
        ) ??
        [],
    macOsSrtBookmark: reader.readStringOrNull(offsets[4]),
    originalFileUri: reader.readStringOrNull(offsets[5]),
  );
  object.id = id;
  return object;
}

P _subtitleCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readObjectList<SubtitleLine>(
                offset,
                SubtitleLineSchema.deserialize,
                allOffsets,
                SubtitleLine(),
              ) ??
              [])
          as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _subtitleCollectionGetId(SubtitleCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _subtitleCollectionGetLinks(
  SubtitleCollection object,
) {
  return [];
}

void _subtitleCollectionAttach(
  IsarCollection<dynamic> col,
  Id id,
  SubtitleCollection object,
) {
  object.id = id;
}

extension SubtitleCollectionQueryWhereSort
    on QueryBuilder<SubtitleCollection, SubtitleCollection, QWhere> {
  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SubtitleCollectionQueryWhere
    on QueryBuilder<SubtitleCollection, SubtitleCollection, QWhereClause> {
  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterWhereClause>
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

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SubtitleCollectionQueryFilter
    on QueryBuilder<SubtitleCollection, SubtitleCollection, QFilterCondition> {
  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'encoding',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'encoding',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'encoding',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'encoding',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'encoding',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'encoding',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'encoding',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'encoding',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'encoding', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  encodingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'encoding', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'filePath'),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'filePath'),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'filePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'filePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'filePath', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'filePath', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  linesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lines', length, true, length, true);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  linesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lines', 0, true, 0, true);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  linesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lines', 0, false, 999999, true);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  linesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lines', 0, true, length, include);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  linesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lines', length, include, 999999, true);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  linesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lines',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'macOsSrtBookmark'),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'macOsSrtBookmark'),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'macOsSrtBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'macOsSrtBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'macOsSrtBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'macOsSrtBookmark',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'macOsSrtBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'macOsSrtBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'macOsSrtBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'macOsSrtBookmark',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'macOsSrtBookmark', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  macOsSrtBookmarkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'macOsSrtBookmark', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'originalFileUri'),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'originalFileUri'),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originalFileUri',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originalFileUri',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originalFileUri',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originalFileUri',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'originalFileUri',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'originalFileUri',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'originalFileUri',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'originalFileUri',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'originalFileUri', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  originalFileUriIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'originalFileUri', value: ''),
      );
    });
  }
}

extension SubtitleCollectionQueryObject
    on QueryBuilder<SubtitleCollection, SubtitleCollection, QFilterCondition> {
  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterFilterCondition>
  linesElement(FilterQuery<SubtitleLine> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'lines');
    });
  }
}

extension SubtitleCollectionQueryLinks
    on QueryBuilder<SubtitleCollection, SubtitleCollection, QFilterCondition> {}

extension SubtitleCollectionQuerySortBy
    on QueryBuilder<SubtitleCollection, SubtitleCollection, QSortBy> {
  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByEncoding() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encoding', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByEncodingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encoding', Sort.desc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByMacOsSrtBookmark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macOsSrtBookmark', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByMacOsSrtBookmarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macOsSrtBookmark', Sort.desc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByOriginalFileUri() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFileUri', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  sortByOriginalFileUriDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFileUri', Sort.desc);
    });
  }
}

extension SubtitleCollectionQuerySortThenBy
    on QueryBuilder<SubtitleCollection, SubtitleCollection, QSortThenBy> {
  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByEncoding() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encoding', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByEncodingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encoding', Sort.desc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByMacOsSrtBookmark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macOsSrtBookmark', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByMacOsSrtBookmarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macOsSrtBookmark', Sort.desc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByOriginalFileUri() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFileUri', Sort.asc);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QAfterSortBy>
  thenByOriginalFileUriDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFileUri', Sort.desc);
    });
  }
}

extension SubtitleCollectionQueryWhereDistinct
    on QueryBuilder<SubtitleCollection, SubtitleCollection, QDistinct> {
  QueryBuilder<SubtitleCollection, SubtitleCollection, QDistinct>
  distinctByEncoding({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encoding', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QDistinct>
  distinctByFileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QDistinct>
  distinctByFilePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QDistinct>
  distinctByMacOsSrtBookmark({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'macOsSrtBookmark',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SubtitleCollection, SubtitleCollection, QDistinct>
  distinctByOriginalFileUri({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'originalFileUri',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension SubtitleCollectionQueryProperty
    on QueryBuilder<SubtitleCollection, SubtitleCollection, QQueryProperty> {
  QueryBuilder<SubtitleCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SubtitleCollection, String, QQueryOperations>
  encodingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encoding');
    });
  }

  QueryBuilder<SubtitleCollection, String, QQueryOperations>
  fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<SubtitleCollection, String?, QQueryOperations>
  filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<SubtitleCollection, List<SubtitleLine>, QQueryOperations>
  linesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lines');
    });
  }

  QueryBuilder<SubtitleCollection, String?, QQueryOperations>
  macOsSrtBookmarkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'macOsSrtBookmark');
    });
  }

  QueryBuilder<SubtitleCollection, String?, QQueryOperations>
  originalFileUriProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalFileUri');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDictionaryEntryCollection on Isar {
  IsarCollection<DictionaryEntry> get dictionaryEntrys => this.collection();
}

const DictionaryEntrySchema = CollectionSchema(
  name: r'DictionaryEntry',
  id: 433168435156867289,
  properties: {
    r'dictionaryType': PropertySchema(
      id: 0,
      name: r'dictionaryType',
      type: IsarType.string,
    ),
    r'meaning': PropertySchema(id: 1, name: r'meaning', type: IsarType.string),
    r'partOfSpeech': PropertySchema(
      id: 2,
      name: r'partOfSpeech',
      type: IsarType.string,
    ),
    r'word': PropertySchema(id: 3, name: r'word', type: IsarType.string),
  },

  estimateSize: _dictionaryEntryEstimateSize,
  serialize: _dictionaryEntrySerialize,
  deserialize: _dictionaryEntryDeserialize,
  deserializeProp: _dictionaryEntryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _dictionaryEntryGetId,
  getLinks: _dictionaryEntryGetLinks,
  attach: _dictionaryEntryAttach,
  version: '3.3.2',
);

int _dictionaryEntryEstimateSize(
  DictionaryEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dictionaryType.length * 3;
  bytesCount += 3 + object.meaning.length * 3;
  bytesCount += 3 + object.partOfSpeech.length * 3;
  bytesCount += 3 + object.word.length * 3;
  return bytesCount;
}

void _dictionaryEntrySerialize(
  DictionaryEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dictionaryType);
  writer.writeString(offsets[1], object.meaning);
  writer.writeString(offsets[2], object.partOfSpeech);
  writer.writeString(offsets[3], object.word);
}

DictionaryEntry _dictionaryEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DictionaryEntry(
    dictionaryType: reader.readString(offsets[0]),
    meaning: reader.readString(offsets[1]),
    partOfSpeech: reader.readString(offsets[2]),
    word: reader.readString(offsets[3]),
  );
  object.id = id;
  return object;
}

P _dictionaryEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dictionaryEntryGetId(DictionaryEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dictionaryEntryGetLinks(DictionaryEntry object) {
  return [];
}

void _dictionaryEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  DictionaryEntry object,
) {
  object.id = id;
}

extension DictionaryEntryQueryWhereSort
    on QueryBuilder<DictionaryEntry, DictionaryEntry, QWhere> {
  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DictionaryEntryQueryWhere
    on QueryBuilder<DictionaryEntry, DictionaryEntry, QWhereClause> {
  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterWhereClause>
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

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DictionaryEntryQueryFilter
    on QueryBuilder<DictionaryEntry, DictionaryEntry, QFilterCondition> {
  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dictionaryType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dictionaryType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dictionaryType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dictionaryType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dictionaryType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dictionaryType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dictionaryType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dictionaryType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dictionaryType', value: ''),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  dictionaryTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dictionaryType', value: ''),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'meaning',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'meaning',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'meaning',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'meaning',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'meaning',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'meaning',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'meaning',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'meaning',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'meaning', value: ''),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  meaningIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'meaning', value: ''),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'partOfSpeech',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'partOfSpeech',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'partOfSpeech',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'partOfSpeech',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'partOfSpeech',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'partOfSpeech',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'partOfSpeech',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'partOfSpeech',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'partOfSpeech', value: ''),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  partOfSpeechIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'partOfSpeech', value: ''),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'word',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'word',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'word',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'word',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'word',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'word',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'word',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'word',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'word', value: ''),
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterFilterCondition>
  wordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'word', value: ''),
      );
    });
  }
}

extension DictionaryEntryQueryObject
    on QueryBuilder<DictionaryEntry, DictionaryEntry, QFilterCondition> {}

extension DictionaryEntryQueryLinks
    on QueryBuilder<DictionaryEntry, DictionaryEntry, QFilterCondition> {}

extension DictionaryEntryQuerySortBy
    on QueryBuilder<DictionaryEntry, DictionaryEntry, QSortBy> {
  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  sortByDictionaryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dictionaryType', Sort.asc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  sortByDictionaryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dictionaryType', Sort.desc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy> sortByMeaning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meaning', Sort.asc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  sortByMeaningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meaning', Sort.desc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  sortByPartOfSpeech() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partOfSpeech', Sort.asc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  sortByPartOfSpeechDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partOfSpeech', Sort.desc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy> sortByWord() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'word', Sort.asc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  sortByWordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'word', Sort.desc);
    });
  }
}

extension DictionaryEntryQuerySortThenBy
    on QueryBuilder<DictionaryEntry, DictionaryEntry, QSortThenBy> {
  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  thenByDictionaryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dictionaryType', Sort.asc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  thenByDictionaryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dictionaryType', Sort.desc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy> thenByMeaning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meaning', Sort.asc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  thenByMeaningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meaning', Sort.desc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  thenByPartOfSpeech() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partOfSpeech', Sort.asc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  thenByPartOfSpeechDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partOfSpeech', Sort.desc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy> thenByWord() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'word', Sort.asc);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QAfterSortBy>
  thenByWordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'word', Sort.desc);
    });
  }
}

extension DictionaryEntryQueryWhereDistinct
    on QueryBuilder<DictionaryEntry, DictionaryEntry, QDistinct> {
  QueryBuilder<DictionaryEntry, DictionaryEntry, QDistinct>
  distinctByDictionaryType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'dictionaryType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QDistinct> distinctByMeaning({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'meaning', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QDistinct>
  distinctByPartOfSpeech({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partOfSpeech', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DictionaryEntry, DictionaryEntry, QDistinct> distinctByWord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'word', caseSensitive: caseSensitive);
    });
  }
}

extension DictionaryEntryQueryProperty
    on QueryBuilder<DictionaryEntry, DictionaryEntry, QQueryProperty> {
  QueryBuilder<DictionaryEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DictionaryEntry, String, QQueryOperations>
  dictionaryTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dictionaryType');
    });
  }

  QueryBuilder<DictionaryEntry, String, QQueryOperations> meaningProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meaning');
    });
  }

  QueryBuilder<DictionaryEntry, String, QQueryOperations>
  partOfSpeechProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partOfSpeech');
    });
  }

  QueryBuilder<DictionaryEntry, String, QQueryOperations> wordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'word');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCheckpointCollection on Isar {
  IsarCollection<Checkpoint> get checkpoints => this.collection();
}

const CheckpointSchema = CollectionSchema(
  name: r'Checkpoint',
  id: 4021090492623714976,
  properties: {
    r'checkpointType': PropertySchema(
      id: 0,
      name: r'checkpointType',
      type: IsarType.string,
    ),
    r'deltas': PropertySchema(
      id: 1,
      name: r'deltas',
      type: IsarType.objectList,

      target: r'SubtitleLineDelta',
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'isActive': PropertySchema(id: 3, name: r'isActive', type: IsarType.bool),
    r'metadata': PropertySchema(
      id: 4,
      name: r'metadata',
      type: IsarType.string,
    ),
    r'operationType': PropertySchema(
      id: 5,
      name: r'operationType',
      type: IsarType.string,
    ),
    r'parentCheckpointId': PropertySchema(
      id: 6,
      name: r'parentCheckpointId',
      type: IsarType.long,
    ),
    r'sessionId': PropertySchema(
      id: 7,
      name: r'sessionId',
      type: IsarType.long,
    ),
    r'snapshot': PropertySchema(
      id: 8,
      name: r'snapshot',
      type: IsarType.objectList,

      target: r'SubtitleLine',
    ),
    r'subtitleCollectionId': PropertySchema(
      id: 9,
      name: r'subtitleCollectionId',
      type: IsarType.long,
    ),
    r'timestamp': PropertySchema(
      id: 10,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _checkpointEstimateSize,
  serialize: _checkpointSerialize,
  deserialize: _checkpointDeserialize,
  deserializeProp: _checkpointDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {
    r'SubtitleLineDelta': SubtitleLineDeltaSchema,
    r'SubtitleLine': SubtitleLineSchema,
  },

  getId: _checkpointGetId,
  getLinks: _checkpointGetLinks,
  attach: _checkpointAttach,
  version: '3.3.2',
);

int _checkpointEstimateSize(
  Checkpoint object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.checkpointType.length * 3;
  bytesCount += 3 + object.deltas.length * 3;
  {
    final offsets = allOffsets[SubtitleLineDelta]!;
    for (var i = 0; i < object.deltas.length; i++) {
      final value = object.deltas[i];
      bytesCount += SubtitleLineDeltaSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.description.length * 3;
  {
    final value = object.metadata;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.operationType.length * 3;
  bytesCount += 3 + object.snapshot.length * 3;
  {
    final offsets = allOffsets[SubtitleLine]!;
    for (var i = 0; i < object.snapshot.length; i++) {
      final value = object.snapshot[i];
      bytesCount += SubtitleLineSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _checkpointSerialize(
  Checkpoint object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.checkpointType);
  writer.writeObjectList<SubtitleLineDelta>(
    offsets[1],
    allOffsets,
    SubtitleLineDeltaSchema.serialize,
    object.deltas,
  );
  writer.writeString(offsets[2], object.description);
  writer.writeBool(offsets[3], object.isActive);
  writer.writeString(offsets[4], object.metadata);
  writer.writeString(offsets[5], object.operationType);
  writer.writeLong(offsets[6], object.parentCheckpointId);
  writer.writeLong(offsets[7], object.sessionId);
  writer.writeObjectList<SubtitleLine>(
    offsets[8],
    allOffsets,
    SubtitleLineSchema.serialize,
    object.snapshot,
  );
  writer.writeLong(offsets[9], object.subtitleCollectionId);
  writer.writeDateTime(offsets[10], object.timestamp);
}

Checkpoint _checkpointDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Checkpoint(
    checkpointType: reader.readStringOrNull(offsets[0]) ?? 'delta',
    deltas:
        reader.readObjectList<SubtitleLineDelta>(
          offsets[1],
          SubtitleLineDeltaSchema.deserialize,
          allOffsets,
          SubtitleLineDelta(),
        ) ??
        [],
    description: reader.readString(offsets[2]),
    isActive: reader.readBoolOrNull(offsets[3]) ?? true,
    metadata: reader.readStringOrNull(offsets[4]),
    operationType: reader.readString(offsets[5]),
    parentCheckpointId: reader.readLongOrNull(offsets[6]),
    sessionId: reader.readLong(offsets[7]),
    snapshot:
        reader.readObjectList<SubtitleLine>(
          offsets[8],
          SubtitleLineSchema.deserialize,
          allOffsets,
          SubtitleLine(),
        ) ??
        [],
    subtitleCollectionId: reader.readLong(offsets[9]),
    timestamp: reader.readDateTime(offsets[10]),
  );
  object.id = id;
  return object;
}

P _checkpointDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? 'delta') as P;
    case 1:
      return (reader.readObjectList<SubtitleLineDelta>(
                offset,
                SubtitleLineDeltaSchema.deserialize,
                allOffsets,
                SubtitleLineDelta(),
              ) ??
              [])
          as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readObjectList<SubtitleLine>(
                offset,
                SubtitleLineSchema.deserialize,
                allOffsets,
                SubtitleLine(),
              ) ??
              [])
          as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _checkpointGetId(Checkpoint object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _checkpointGetLinks(Checkpoint object) {
  return [];
}

void _checkpointAttach(IsarCollection<dynamic> col, Id id, Checkpoint object) {
  object.id = id;
}

extension CheckpointQueryWhereSort
    on QueryBuilder<Checkpoint, Checkpoint, QWhere> {
  QueryBuilder<Checkpoint, Checkpoint, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CheckpointQueryWhere
    on QueryBuilder<Checkpoint, Checkpoint, QWhereClause> {
  QueryBuilder<Checkpoint, Checkpoint, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Checkpoint, Checkpoint, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CheckpointQueryFilter
    on QueryBuilder<Checkpoint, Checkpoint, QFilterCondition> {
  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'checkpointType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'checkpointType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'checkpointType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'checkpointType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'checkpointType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'checkpointType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'checkpointType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'checkpointType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'checkpointType', value: ''),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  checkpointTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'checkpointType', value: ''),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  deltasLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'deltas', length, true, length, true);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> deltasIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'deltas', 0, true, 0, true);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  deltasIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'deltas', 0, false, 999999, true);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  deltasLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'deltas', 0, true, length, include);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  deltasLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'deltas', length, include, 999999, true);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  deltasLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'deltas',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'description',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'description',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> isActiveEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isActive', value: value),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> metadataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'metadata'),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  metadataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'metadata'),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> metadataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metadata',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  metadataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'metadata',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> metadataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'metadata',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> metadataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'metadata',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  metadataStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'metadata',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> metadataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'metadata',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> metadataContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'metadata',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> metadataMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'metadata',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  metadataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'metadata', value: ''),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  metadataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'metadata', value: ''),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'operationType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'operationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'operationType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'operationType', value: ''),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  operationTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'operationType', value: ''),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  parentCheckpointIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'parentCheckpointId'),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  parentCheckpointIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'parentCheckpointId'),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  parentCheckpointIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'parentCheckpointId', value: value),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  parentCheckpointIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'parentCheckpointId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  parentCheckpointIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'parentCheckpointId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  parentCheckpointIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'parentCheckpointId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> sessionIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sessionId', value: value),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  sessionIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sessionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> sessionIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sessionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> sessionIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sessionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  snapshotLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshot', length, true, length, true);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  snapshotIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshot', 0, true, 0, true);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  snapshotIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshot', 0, false, 999999, true);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  snapshotLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshot', 0, true, length, include);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  snapshotLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshot', length, include, 999999, true);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  snapshotLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'snapshot',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  subtitleCollectionIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subtitleCollectionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  subtitleCollectionIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subtitleCollectionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  subtitleCollectionIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subtitleCollectionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  subtitleCollectionIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subtitleCollectionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> timestampEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition>
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CheckpointQueryObject
    on QueryBuilder<Checkpoint, Checkpoint, QFilterCondition> {
  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> deltasElement(
    FilterQuery<SubtitleLineDelta> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'deltas');
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterFilterCondition> snapshotElement(
    FilterQuery<SubtitleLine> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'snapshot');
    });
  }
}

extension CheckpointQueryLinks
    on QueryBuilder<Checkpoint, Checkpoint, QFilterCondition> {}

extension CheckpointQuerySortBy
    on QueryBuilder<Checkpoint, Checkpoint, QSortBy> {
  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByCheckpointType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointType', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  sortByCheckpointTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointType', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByOperationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByOperationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  sortByParentCheckpointId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCheckpointId', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  sortByParentCheckpointIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCheckpointId', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  sortBySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  sortBySubtitleCollectionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension CheckpointQuerySortThenBy
    on QueryBuilder<Checkpoint, Checkpoint, QSortThenBy> {
  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByCheckpointType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointType', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  thenByCheckpointTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointType', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByOperationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByOperationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  thenByParentCheckpointId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCheckpointId', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  thenByParentCheckpointIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCheckpointId', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  thenBySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy>
  thenBySubtitleCollectionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.desc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension CheckpointQueryWhereDistinct
    on QueryBuilder<Checkpoint, Checkpoint, QDistinct> {
  QueryBuilder<Checkpoint, Checkpoint, QDistinct> distinctByCheckpointType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'checkpointType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QDistinct> distinctByDescription({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QDistinct> distinctByMetadata({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadata', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QDistinct> distinctByOperationType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'operationType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QDistinct>
  distinctByParentCheckpointId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentCheckpointId');
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QDistinct> distinctBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId');
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QDistinct>
  distinctBySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtitleCollectionId');
    });
  }

  QueryBuilder<Checkpoint, Checkpoint, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension CheckpointQueryProperty
    on QueryBuilder<Checkpoint, Checkpoint, QQueryProperty> {
  QueryBuilder<Checkpoint, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Checkpoint, String, QQueryOperations> checkpointTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkpointType');
    });
  }

  QueryBuilder<Checkpoint, List<SubtitleLineDelta>, QQueryOperations>
  deltasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deltas');
    });
  }

  QueryBuilder<Checkpoint, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<Checkpoint, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<Checkpoint, String?, QQueryOperations> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadata');
    });
  }

  QueryBuilder<Checkpoint, String, QQueryOperations> operationTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'operationType');
    });
  }

  QueryBuilder<Checkpoint, int?, QQueryOperations>
  parentCheckpointIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentCheckpointId');
    });
  }

  QueryBuilder<Checkpoint, int, QQueryOperations> sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<Checkpoint, List<SubtitleLine>, QQueryOperations>
  snapshotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snapshot');
    });
  }

  QueryBuilder<Checkpoint, int, QQueryOperations>
  subtitleCollectionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtitleCollectionId');
    });
  }

  QueryBuilder<Checkpoint, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVideoPreferencesCollection on Isar {
  IsarCollection<VideoPreferences> get videoPreferences => this.collection();
}

const VideoPreferencesSchema = CollectionSchema(
  name: r'VideoPreferences',
  id: 3960203580811845928,
  properties: {
    r'macOsBookmark': PropertySchema(
      id: 0,
      name: r'macOsBookmark',
      type: IsarType.string,
    ),
    r'secondaryIsOriginal': PropertySchema(
      id: 1,
      name: r'secondaryIsOriginal',
      type: IsarType.bool,
    ),
    r'secondarySubtitlePath': PropertySchema(
      id: 2,
      name: r'secondarySubtitlePath',
      type: IsarType.string,
    ),
    r'selectedAudioTrackId': PropertySchema(
      id: 3,
      name: r'selectedAudioTrackId',
      type: IsarType.string,
    ),
    r'selectedAudioTrackLanguage': PropertySchema(
      id: 4,
      name: r'selectedAudioTrackLanguage',
      type: IsarType.string,
    ),
    r'selectedAudioTrackTitle': PropertySchema(
      id: 5,
      name: r'selectedAudioTrackTitle',
      type: IsarType.string,
    ),
    r'subtitleCollectionId': PropertySchema(
      id: 6,
      name: r'subtitleCollectionId',
      type: IsarType.long,
    ),
    r'videoPath': PropertySchema(
      id: 7,
      name: r'videoPath',
      type: IsarType.string,
    ),
    r'waveformChannels': PropertySchema(
      id: 8,
      name: r'waveformChannels',
      type: IsarType.long,
    ),
    r'waveformGeneratedAt': PropertySchema(
      id: 9,
      name: r'waveformGeneratedAt',
      type: IsarType.dateTime,
    ),
    r'waveformPcmPath': PropertySchema(
      id: 10,
      name: r'waveformPcmPath',
      type: IsarType.string,
    ),
    r'waveformSampleRate': PropertySchema(
      id: 11,
      name: r'waveformSampleRate',
      type: IsarType.long,
    ),
    r'waveformTotalSamples': PropertySchema(
      id: 12,
      name: r'waveformTotalSamples',
      type: IsarType.long,
    ),
    r'waveformVerticalZoom': PropertySchema(
      id: 13,
      name: r'waveformVerticalZoom',
      type: IsarType.double,
    ),
    r'waveformZoomIndex': PropertySchema(
      id: 14,
      name: r'waveformZoomIndex',
      type: IsarType.long,
    ),
  },

  estimateSize: _videoPreferencesEstimateSize,
  serialize: _videoPreferencesSerialize,
  deserialize: _videoPreferencesDeserialize,
  deserializeProp: _videoPreferencesDeserializeProp,
  idName: r'id',
  indexes: {
    r'subtitleCollectionId': IndexSchema(
      id: -72977023152105094,
      name: r'subtitleCollectionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'subtitleCollectionId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _videoPreferencesGetId,
  getLinks: _videoPreferencesGetLinks,
  attach: _videoPreferencesAttach,
  version: '3.3.2',
);

int _videoPreferencesEstimateSize(
  VideoPreferences object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.macOsBookmark;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.secondarySubtitlePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.selectedAudioTrackId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.selectedAudioTrackLanguage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.selectedAudioTrackTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.videoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.waveformPcmPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _videoPreferencesSerialize(
  VideoPreferences object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.macOsBookmark);
  writer.writeBool(offsets[1], object.secondaryIsOriginal);
  writer.writeString(offsets[2], object.secondarySubtitlePath);
  writer.writeString(offsets[3], object.selectedAudioTrackId);
  writer.writeString(offsets[4], object.selectedAudioTrackLanguage);
  writer.writeString(offsets[5], object.selectedAudioTrackTitle);
  writer.writeLong(offsets[6], object.subtitleCollectionId);
  writer.writeString(offsets[7], object.videoPath);
  writer.writeLong(offsets[8], object.waveformChannels);
  writer.writeDateTime(offsets[9], object.waveformGeneratedAt);
  writer.writeString(offsets[10], object.waveformPcmPath);
  writer.writeLong(offsets[11], object.waveformSampleRate);
  writer.writeLong(offsets[12], object.waveformTotalSamples);
  writer.writeDouble(offsets[13], object.waveformVerticalZoom);
  writer.writeLong(offsets[14], object.waveformZoomIndex);
}

VideoPreferences _videoPreferencesDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VideoPreferences(
    macOsBookmark: reader.readStringOrNull(offsets[0]),
    secondaryIsOriginal: reader.readBoolOrNull(offsets[1]) ?? false,
    secondarySubtitlePath: reader.readStringOrNull(offsets[2]),
    selectedAudioTrackId: reader.readStringOrNull(offsets[3]),
    selectedAudioTrackLanguage: reader.readStringOrNull(offsets[4]),
    selectedAudioTrackTitle: reader.readStringOrNull(offsets[5]),
    subtitleCollectionId: reader.readLong(offsets[6]),
    videoPath: reader.readStringOrNull(offsets[7]),
    waveformChannels: reader.readLongOrNull(offsets[8]),
    waveformGeneratedAt: reader.readDateTimeOrNull(offsets[9]),
    waveformPcmPath: reader.readStringOrNull(offsets[10]),
    waveformSampleRate: reader.readLongOrNull(offsets[11]),
    waveformTotalSamples: reader.readLongOrNull(offsets[12]),
    waveformVerticalZoom: reader.readDoubleOrNull(offsets[13]),
    waveformZoomIndex: reader.readLongOrNull(offsets[14]),
  );
  object.id = id;
  return object;
}

P _videoPreferencesDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _videoPreferencesGetId(VideoPreferences object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _videoPreferencesGetLinks(VideoPreferences object) {
  return [];
}

void _videoPreferencesAttach(
  IsarCollection<dynamic> col,
  Id id,
  VideoPreferences object,
) {
  object.id = id;
}

extension VideoPreferencesByIndex on IsarCollection<VideoPreferences> {
  Future<VideoPreferences?> getBySubtitleCollectionId(
    int subtitleCollectionId,
  ) {
    return getByIndex(r'subtitleCollectionId', [subtitleCollectionId]);
  }

  VideoPreferences? getBySubtitleCollectionIdSync(int subtitleCollectionId) {
    return getByIndexSync(r'subtitleCollectionId', [subtitleCollectionId]);
  }

  Future<bool> deleteBySubtitleCollectionId(int subtitleCollectionId) {
    return deleteByIndex(r'subtitleCollectionId', [subtitleCollectionId]);
  }

  bool deleteBySubtitleCollectionIdSync(int subtitleCollectionId) {
    return deleteByIndexSync(r'subtitleCollectionId', [subtitleCollectionId]);
  }

  Future<List<VideoPreferences?>> getAllBySubtitleCollectionId(
    List<int> subtitleCollectionIdValues,
  ) {
    final values = subtitleCollectionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'subtitleCollectionId', values);
  }

  List<VideoPreferences?> getAllBySubtitleCollectionIdSync(
    List<int> subtitleCollectionIdValues,
  ) {
    final values = subtitleCollectionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'subtitleCollectionId', values);
  }

  Future<int> deleteAllBySubtitleCollectionId(
    List<int> subtitleCollectionIdValues,
  ) {
    final values = subtitleCollectionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'subtitleCollectionId', values);
  }

  int deleteAllBySubtitleCollectionIdSync(
    List<int> subtitleCollectionIdValues,
  ) {
    final values = subtitleCollectionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'subtitleCollectionId', values);
  }

  Future<Id> putBySubtitleCollectionId(VideoPreferences object) {
    return putByIndex(r'subtitleCollectionId', object);
  }

  Id putBySubtitleCollectionIdSync(
    VideoPreferences object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(
      r'subtitleCollectionId',
      object,
      saveLinks: saveLinks,
    );
  }

  Future<List<Id>> putAllBySubtitleCollectionId(
    List<VideoPreferences> objects,
  ) {
    return putAllByIndex(r'subtitleCollectionId', objects);
  }

  List<Id> putAllBySubtitleCollectionIdSync(
    List<VideoPreferences> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'subtitleCollectionId',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension VideoPreferencesQueryWhereSort
    on QueryBuilder<VideoPreferences, VideoPreferences, QWhere> {
  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhere>
  anySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'subtitleCollectionId'),
      );
    });
  }
}

extension VideoPreferencesQueryWhere
    on QueryBuilder<VideoPreferences, VideoPreferences, QWhereClause> {
  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause>
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

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause>
  subtitleCollectionIdEqualTo(int subtitleCollectionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'subtitleCollectionId',
          value: [subtitleCollectionId],
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause>
  subtitleCollectionIdNotEqualTo(int subtitleCollectionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subtitleCollectionId',
                lower: [],
                upper: [subtitleCollectionId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subtitleCollectionId',
                lower: [subtitleCollectionId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subtitleCollectionId',
                lower: [subtitleCollectionId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subtitleCollectionId',
                lower: [],
                upper: [subtitleCollectionId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause>
  subtitleCollectionIdGreaterThan(
    int subtitleCollectionId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'subtitleCollectionId',
          lower: [subtitleCollectionId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause>
  subtitleCollectionIdLessThan(
    int subtitleCollectionId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'subtitleCollectionId',
          lower: [],
          upper: [subtitleCollectionId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterWhereClause>
  subtitleCollectionIdBetween(
    int lowerSubtitleCollectionId,
    int upperSubtitleCollectionId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'subtitleCollectionId',
          lower: [lowerSubtitleCollectionId],
          includeLower: includeLower,
          upper: [upperSubtitleCollectionId],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension VideoPreferencesQueryFilter
    on QueryBuilder<VideoPreferences, VideoPreferences, QFilterCondition> {
  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'macOsBookmark'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'macOsBookmark'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'macOsBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'macOsBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'macOsBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'macOsBookmark',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'macOsBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'macOsBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'macOsBookmark',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'macOsBookmark',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'macOsBookmark', value: ''),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  macOsBookmarkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'macOsBookmark', value: ''),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondaryIsOriginalEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'secondaryIsOriginal', value: value),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'secondarySubtitlePath'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'secondarySubtitlePath'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'secondarySubtitlePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'secondarySubtitlePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'secondarySubtitlePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'secondarySubtitlePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'secondarySubtitlePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'secondarySubtitlePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'secondarySubtitlePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'secondarySubtitlePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'secondarySubtitlePath', value: ''),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  secondarySubtitlePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'secondarySubtitlePath',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'selectedAudioTrackId'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'selectedAudioTrackId'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'selectedAudioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'selectedAudioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'selectedAudioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'selectedAudioTrackId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'selectedAudioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'selectedAudioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'selectedAudioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'selectedAudioTrackId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'selectedAudioTrackId', value: ''),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'selectedAudioTrackId',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'selectedAudioTrackLanguage'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(
          property: r'selectedAudioTrackLanguage',
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'selectedAudioTrackLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'selectedAudioTrackLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'selectedAudioTrackLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'selectedAudioTrackLanguage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'selectedAudioTrackLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'selectedAudioTrackLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'selectedAudioTrackLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'selectedAudioTrackLanguage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'selectedAudioTrackLanguage',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackLanguageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'selectedAudioTrackLanguage',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'selectedAudioTrackTitle'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'selectedAudioTrackTitle'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'selectedAudioTrackTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'selectedAudioTrackTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'selectedAudioTrackTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'selectedAudioTrackTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'selectedAudioTrackTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'selectedAudioTrackTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'selectedAudioTrackTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'selectedAudioTrackTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'selectedAudioTrackTitle',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  selectedAudioTrackTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'selectedAudioTrackTitle',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  subtitleCollectionIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subtitleCollectionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  subtitleCollectionIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subtitleCollectionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  subtitleCollectionIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subtitleCollectionId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  subtitleCollectionIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subtitleCollectionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'videoPath'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'videoPath'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'videoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'videoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'videoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'videoPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'videoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'videoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'videoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'videoPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'videoPath', value: ''),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  videoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'videoPath', value: ''),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformChannelsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformChannels'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformChannelsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformChannels'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformChannelsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'waveformChannels', value: value),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformChannelsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformChannels',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformChannelsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformChannels',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformChannelsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformChannels',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformGeneratedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformGeneratedAt'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformGeneratedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformGeneratedAt'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformGeneratedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'waveformGeneratedAt', value: value),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformGeneratedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformGeneratedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformGeneratedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformGeneratedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformGeneratedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformGeneratedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformPcmPath'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformPcmPath'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'waveformPcmPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformPcmPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformPcmPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformPcmPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'waveformPcmPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'waveformPcmPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'waveformPcmPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'waveformPcmPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'waveformPcmPath', value: ''),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformPcmPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'waveformPcmPath', value: ''),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformSampleRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformSampleRate'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformSampleRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformSampleRate'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformSampleRateEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'waveformSampleRate', value: value),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformSampleRateGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformSampleRate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformSampleRateLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformSampleRate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformSampleRateBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformSampleRate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformTotalSamplesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformTotalSamples'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformTotalSamplesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformTotalSamples'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformTotalSamplesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'waveformTotalSamples',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformTotalSamplesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformTotalSamples',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformTotalSamplesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformTotalSamples',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformTotalSamplesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformTotalSamples',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformVerticalZoomIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformVerticalZoom'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformVerticalZoomIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformVerticalZoom'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformVerticalZoomEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'waveformVerticalZoom',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformVerticalZoomGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformVerticalZoom',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformVerticalZoomLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformVerticalZoom',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformVerticalZoomBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformVerticalZoom',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformZoomIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'waveformZoomIndex'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformZoomIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'waveformZoomIndex'),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformZoomIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'waveformZoomIndex', value: value),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformZoomIndexGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waveformZoomIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformZoomIndexLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waveformZoomIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterFilterCondition>
  waveformZoomIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waveformZoomIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension VideoPreferencesQueryObject
    on QueryBuilder<VideoPreferences, VideoPreferences, QFilterCondition> {}

extension VideoPreferencesQueryLinks
    on QueryBuilder<VideoPreferences, VideoPreferences, QFilterCondition> {}

extension VideoPreferencesQuerySortBy
    on QueryBuilder<VideoPreferences, VideoPreferences, QSortBy> {
  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByMacOsBookmark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macOsBookmark', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByMacOsBookmarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macOsBookmark', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySecondaryIsOriginal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryIsOriginal', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySecondaryIsOriginalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryIsOriginal', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySecondarySubtitlePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySubtitlePath', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySecondarySubtitlePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySubtitlePath', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySelectedAudioTrackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackId', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySelectedAudioTrackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackId', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySelectedAudioTrackLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackLanguage', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySelectedAudioTrackLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackLanguage', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySelectedAudioTrackTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackTitle', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySelectedAudioTrackTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackTitle', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortBySubtitleCollectionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByVideoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPath', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByVideoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPath', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformChannels() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformChannels', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformChannelsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformChannels', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformGeneratedAt', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformGeneratedAt', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformPcmPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformPcmPath', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformPcmPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformPcmPath', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformSampleRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformSampleRate', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformSampleRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformSampleRate', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformTotalSamples() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformTotalSamples', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformTotalSamplesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformTotalSamples', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformVerticalZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformVerticalZoom', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformVerticalZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformVerticalZoom', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformZoomIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformZoomIndex', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  sortByWaveformZoomIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformZoomIndex', Sort.desc);
    });
  }
}

extension VideoPreferencesQuerySortThenBy
    on QueryBuilder<VideoPreferences, VideoPreferences, QSortThenBy> {
  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByMacOsBookmark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macOsBookmark', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByMacOsBookmarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macOsBookmark', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySecondaryIsOriginal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryIsOriginal', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySecondaryIsOriginalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryIsOriginal', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySecondarySubtitlePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySubtitlePath', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySecondarySubtitlePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySubtitlePath', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySelectedAudioTrackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackId', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySelectedAudioTrackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackId', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySelectedAudioTrackLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackLanguage', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySelectedAudioTrackLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackLanguage', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySelectedAudioTrackTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackTitle', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySelectedAudioTrackTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAudioTrackTitle', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenBySubtitleCollectionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleCollectionId', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByVideoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPath', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByVideoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPath', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformChannels() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformChannels', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformChannelsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformChannels', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformGeneratedAt', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformGeneratedAt', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformPcmPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformPcmPath', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformPcmPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformPcmPath', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformSampleRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformSampleRate', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformSampleRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformSampleRate', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformTotalSamples() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformTotalSamples', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformTotalSamplesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformTotalSamples', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformVerticalZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformVerticalZoom', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformVerticalZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformVerticalZoom', Sort.desc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformZoomIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformZoomIndex', Sort.asc);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QAfterSortBy>
  thenByWaveformZoomIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waveformZoomIndex', Sort.desc);
    });
  }
}

extension VideoPreferencesQueryWhereDistinct
    on QueryBuilder<VideoPreferences, VideoPreferences, QDistinct> {
  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctByMacOsBookmark({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'macOsBookmark',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctBySecondaryIsOriginal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secondaryIsOriginal');
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctBySecondarySubtitlePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'secondarySubtitlePath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctBySelectedAudioTrackId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'selectedAudioTrackId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctBySelectedAudioTrackLanguage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'selectedAudioTrackLanguage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctBySelectedAudioTrackTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'selectedAudioTrackTitle',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctBySubtitleCollectionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtitleCollectionId');
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctByVideoPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'videoPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctByWaveformChannels() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waveformChannels');
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctByWaveformGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waveformGeneratedAt');
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctByWaveformPcmPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'waveformPcmPath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctByWaveformSampleRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waveformSampleRate');
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctByWaveformTotalSamples() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waveformTotalSamples');
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctByWaveformVerticalZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waveformVerticalZoom');
    });
  }

  QueryBuilder<VideoPreferences, VideoPreferences, QDistinct>
  distinctByWaveformZoomIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waveformZoomIndex');
    });
  }
}

extension VideoPreferencesQueryProperty
    on QueryBuilder<VideoPreferences, VideoPreferences, QQueryProperty> {
  QueryBuilder<VideoPreferences, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<VideoPreferences, String?, QQueryOperations>
  macOsBookmarkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'macOsBookmark');
    });
  }

  QueryBuilder<VideoPreferences, bool, QQueryOperations>
  secondaryIsOriginalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondaryIsOriginal');
    });
  }

  QueryBuilder<VideoPreferences, String?, QQueryOperations>
  secondarySubtitlePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondarySubtitlePath');
    });
  }

  QueryBuilder<VideoPreferences, String?, QQueryOperations>
  selectedAudioTrackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedAudioTrackId');
    });
  }

  QueryBuilder<VideoPreferences, String?, QQueryOperations>
  selectedAudioTrackLanguageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedAudioTrackLanguage');
    });
  }

  QueryBuilder<VideoPreferences, String?, QQueryOperations>
  selectedAudioTrackTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedAudioTrackTitle');
    });
  }

  QueryBuilder<VideoPreferences, int, QQueryOperations>
  subtitleCollectionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtitleCollectionId');
    });
  }

  QueryBuilder<VideoPreferences, String?, QQueryOperations>
  videoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'videoPath');
    });
  }

  QueryBuilder<VideoPreferences, int?, QQueryOperations>
  waveformChannelsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformChannels');
    });
  }

  QueryBuilder<VideoPreferences, DateTime?, QQueryOperations>
  waveformGeneratedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformGeneratedAt');
    });
  }

  QueryBuilder<VideoPreferences, String?, QQueryOperations>
  waveformPcmPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformPcmPath');
    });
  }

  QueryBuilder<VideoPreferences, int?, QQueryOperations>
  waveformSampleRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformSampleRate');
    });
  }

  QueryBuilder<VideoPreferences, int?, QQueryOperations>
  waveformTotalSamplesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformTotalSamples');
    });
  }

  QueryBuilder<VideoPreferences, double?, QQueryOperations>
  waveformVerticalZoomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformVerticalZoom');
    });
  }

  QueryBuilder<VideoPreferences, int?, QQueryOperations>
  waveformZoomIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waveformZoomIndex');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTutorialStatusCollection on Isar {
  IsarCollection<TutorialStatus> get tutorialStatus => this.collection();
}

const TutorialStatusSchema = CollectionSchema(
  name: r'TutorialStatus',
  id: 2915876176850760280,
  properties: {
    r'hasSeenTutorial': PropertySchema(
      id: 0,
      name: r'hasSeenTutorial',
      type: IsarType.bool,
    ),
    r'screenName': PropertySchema(
      id: 1,
      name: r'screenName',
      type: IsarType.string,
    ),
  },

  estimateSize: _tutorialStatusEstimateSize,
  serialize: _tutorialStatusSerialize,
  deserialize: _tutorialStatusDeserialize,
  deserializeProp: _tutorialStatusDeserializeProp,
  idName: r'id',
  indexes: {
    r'screenName': IndexSchema(
      id: -4096710223474587182,
      name: r'screenName',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'screenName',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _tutorialStatusGetId,
  getLinks: _tutorialStatusGetLinks,
  attach: _tutorialStatusAttach,
  version: '3.3.2',
);

int _tutorialStatusEstimateSize(
  TutorialStatus object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.screenName.length * 3;
  return bytesCount;
}

void _tutorialStatusSerialize(
  TutorialStatus object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.hasSeenTutorial);
  writer.writeString(offsets[1], object.screenName);
}

TutorialStatus _tutorialStatusDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TutorialStatus(
    hasSeenTutorial: reader.readBoolOrNull(offsets[0]) ?? false,
    screenName: reader.readString(offsets[1]),
  );
  object.id = id;
  return object;
}

P _tutorialStatusDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _tutorialStatusGetId(TutorialStatus object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _tutorialStatusGetLinks(TutorialStatus object) {
  return [];
}

void _tutorialStatusAttach(
  IsarCollection<dynamic> col,
  Id id,
  TutorialStatus object,
) {
  object.id = id;
}

extension TutorialStatusByIndex on IsarCollection<TutorialStatus> {
  Future<TutorialStatus?> getByScreenName(String screenName) {
    return getByIndex(r'screenName', [screenName]);
  }

  TutorialStatus? getByScreenNameSync(String screenName) {
    return getByIndexSync(r'screenName', [screenName]);
  }

  Future<bool> deleteByScreenName(String screenName) {
    return deleteByIndex(r'screenName', [screenName]);
  }

  bool deleteByScreenNameSync(String screenName) {
    return deleteByIndexSync(r'screenName', [screenName]);
  }

  Future<List<TutorialStatus?>> getAllByScreenName(
    List<String> screenNameValues,
  ) {
    final values = screenNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'screenName', values);
  }

  List<TutorialStatus?> getAllByScreenNameSync(List<String> screenNameValues) {
    final values = screenNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'screenName', values);
  }

  Future<int> deleteAllByScreenName(List<String> screenNameValues) {
    final values = screenNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'screenName', values);
  }

  int deleteAllByScreenNameSync(List<String> screenNameValues) {
    final values = screenNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'screenName', values);
  }

  Future<Id> putByScreenName(TutorialStatus object) {
    return putByIndex(r'screenName', object);
  }

  Id putByScreenNameSync(TutorialStatus object, {bool saveLinks = true}) {
    return putByIndexSync(r'screenName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByScreenName(List<TutorialStatus> objects) {
    return putAllByIndex(r'screenName', objects);
  }

  List<Id> putAllByScreenNameSync(
    List<TutorialStatus> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'screenName', objects, saveLinks: saveLinks);
  }
}

extension TutorialStatusQueryWhereSort
    on QueryBuilder<TutorialStatus, TutorialStatus, QWhere> {
  QueryBuilder<TutorialStatus, TutorialStatus, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TutorialStatusQueryWhere
    on QueryBuilder<TutorialStatus, TutorialStatus, QWhereClause> {
  QueryBuilder<TutorialStatus, TutorialStatus, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterWhereClause>
  screenNameEqualTo(String screenName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'screenName', value: [screenName]),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterWhereClause>
  screenNameNotEqualTo(String screenName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'screenName',
                lower: [],
                upper: [screenName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'screenName',
                lower: [screenName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'screenName',
                lower: [screenName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'screenName',
                lower: [],
                upper: [screenName],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension TutorialStatusQueryFilter
    on QueryBuilder<TutorialStatus, TutorialStatus, QFilterCondition> {
  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  hasSeenTutorialEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasSeenTutorial', value: value),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'screenName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'screenName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'screenName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'screenName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'screenName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'screenName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'screenName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'screenName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'screenName', value: ''),
      );
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterFilterCondition>
  screenNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'screenName', value: ''),
      );
    });
  }
}

extension TutorialStatusQueryObject
    on QueryBuilder<TutorialStatus, TutorialStatus, QFilterCondition> {}

extension TutorialStatusQueryLinks
    on QueryBuilder<TutorialStatus, TutorialStatus, QFilterCondition> {}

extension TutorialStatusQuerySortBy
    on QueryBuilder<TutorialStatus, TutorialStatus, QSortBy> {
  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy>
  sortByHasSeenTutorial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenTutorial', Sort.asc);
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy>
  sortByHasSeenTutorialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenTutorial', Sort.desc);
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy>
  sortByScreenName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'screenName', Sort.asc);
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy>
  sortByScreenNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'screenName', Sort.desc);
    });
  }
}

extension TutorialStatusQuerySortThenBy
    on QueryBuilder<TutorialStatus, TutorialStatus, QSortThenBy> {
  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy>
  thenByHasSeenTutorial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenTutorial', Sort.asc);
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy>
  thenByHasSeenTutorialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenTutorial', Sort.desc);
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy>
  thenByScreenName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'screenName', Sort.asc);
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QAfterSortBy>
  thenByScreenNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'screenName', Sort.desc);
    });
  }
}

extension TutorialStatusQueryWhereDistinct
    on QueryBuilder<TutorialStatus, TutorialStatus, QDistinct> {
  QueryBuilder<TutorialStatus, TutorialStatus, QDistinct>
  distinctByHasSeenTutorial() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasSeenTutorial');
    });
  }

  QueryBuilder<TutorialStatus, TutorialStatus, QDistinct> distinctByScreenName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'screenName', caseSensitive: caseSensitive);
    });
  }
}

extension TutorialStatusQueryProperty
    on QueryBuilder<TutorialStatus, TutorialStatus, QQueryProperty> {
  QueryBuilder<TutorialStatus, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TutorialStatus, bool, QQueryOperations>
  hasSeenTutorialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasSeenTutorial');
    });
  }

  QueryBuilder<TutorialStatus, String, QQueryOperations> screenNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'screenName');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SubtitleLineSchema = Schema(
  name: r'SubtitleLine',
  id: -1546090388837257561,
  properties: {
    r'comment': PropertySchema(id: 0, name: r'comment', type: IsarType.string),
    r'edited': PropertySchema(id: 1, name: r'edited', type: IsarType.string),
    r'endTime': PropertySchema(id: 2, name: r'endTime', type: IsarType.string),
    r'index': PropertySchema(id: 3, name: r'index', type: IsarType.long),
    r'marked': PropertySchema(id: 4, name: r'marked', type: IsarType.bool),
    r'original': PropertySchema(
      id: 5,
      name: r'original',
      type: IsarType.string,
    ),
    r'resolved': PropertySchema(id: 6, name: r'resolved', type: IsarType.bool),
    r'startTime': PropertySchema(
      id: 7,
      name: r'startTime',
      type: IsarType.string,
    ),
  },

  estimateSize: _subtitleLineEstimateSize,
  serialize: _subtitleLineSerialize,
  deserialize: _subtitleLineDeserialize,
  deserializeProp: _subtitleLineDeserializeProp,
);

int _subtitleLineEstimateSize(
  SubtitleLine object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.comment;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.edited;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.endTime.length * 3;
  bytesCount += 3 + object.original.length * 3;
  bytesCount += 3 + object.startTime.length * 3;
  return bytesCount;
}

void _subtitleLineSerialize(
  SubtitleLine object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.comment);
  writer.writeString(offsets[1], object.edited);
  writer.writeString(offsets[2], object.endTime);
  writer.writeLong(offsets[3], object.index);
  writer.writeBool(offsets[4], object.marked);
  writer.writeString(offsets[5], object.original);
  writer.writeBool(offsets[6], object.resolved);
  writer.writeString(offsets[7], object.startTime);
}

SubtitleLine _subtitleLineDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SubtitleLine();
  object.comment = reader.readStringOrNull(offsets[0]);
  object.edited = reader.readStringOrNull(offsets[1]);
  object.endTime = reader.readString(offsets[2]);
  object.index = reader.readLong(offsets[3]);
  object.marked = reader.readBool(offsets[4]);
  object.original = reader.readString(offsets[5]);
  object.resolved = reader.readBool(offsets[6]);
  object.startTime = reader.readString(offsets[7]);
  return object;
}

P _subtitleLineDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SubtitleLineQueryFilter
    on QueryBuilder<SubtitleLine, SubtitleLine, QFilterCondition> {
  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'comment'),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'comment'),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'comment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'comment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'comment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'comment',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'comment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'comment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'comment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'comment',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'comment', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  commentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'comment', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  editedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'edited'),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  editedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'edited'),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition> editedEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'edited',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  editedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'edited',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  editedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'edited',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition> editedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'edited',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  editedStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'edited',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  editedEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'edited',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  editedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'edited',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition> editedMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'edited',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  editedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'edited', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  editedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'edited', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'endTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'endTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'endTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'endTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'endTime',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endTime', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  endTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'endTime', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition> indexEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'index', value: value),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  indexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'index',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition> indexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'index',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition> indexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'index',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition> markedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'marked', value: value),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'original',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'original',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'original', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  originalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'original', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  resolvedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resolved', value: value),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'startTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'startTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'startTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'startTime',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'startTime',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startTime', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLine, SubtitleLine, QAfterFilterCondition>
  startTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'startTime', value: ''),
      );
    });
  }
}

extension SubtitleLineQueryObject
    on QueryBuilder<SubtitleLine, SubtitleLine, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SubtitleLineDeltaSchema = Schema(
  name: r'SubtitleLineDelta',
  id: 8119201510813867039,
  properties: {
    r'afterState': PropertySchema(
      id: 0,
      name: r'afterState',
      type: IsarType.object,

      target: r'SubtitleLine',
    ),
    r'beforeState': PropertySchema(
      id: 1,
      name: r'beforeState',
      type: IsarType.object,

      target: r'SubtitleLine',
    ),
    r'changeType': PropertySchema(
      id: 2,
      name: r'changeType',
      type: IsarType.string,
    ),
    r'lineIndex': PropertySchema(
      id: 3,
      name: r'lineIndex',
      type: IsarType.long,
    ),
  },

  estimateSize: _subtitleLineDeltaEstimateSize,
  serialize: _subtitleLineDeltaSerialize,
  deserialize: _subtitleLineDeltaDeserialize,
  deserializeProp: _subtitleLineDeltaDeserializeProp,
);

int _subtitleLineDeltaEstimateSize(
  SubtitleLineDelta object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.afterState;
    if (value != null) {
      bytesCount +=
          3 +
          SubtitleLineSchema.estimateSize(
            value,
            allOffsets[SubtitleLine]!,
            allOffsets,
          );
    }
  }
  {
    final value = object.beforeState;
    if (value != null) {
      bytesCount +=
          3 +
          SubtitleLineSchema.estimateSize(
            value,
            allOffsets[SubtitleLine]!,
            allOffsets,
          );
    }
  }
  bytesCount += 3 + object.changeType.length * 3;
  return bytesCount;
}

void _subtitleLineDeltaSerialize(
  SubtitleLineDelta object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<SubtitleLine>(
    offsets[0],
    allOffsets,
    SubtitleLineSchema.serialize,
    object.afterState,
  );
  writer.writeObject<SubtitleLine>(
    offsets[1],
    allOffsets,
    SubtitleLineSchema.serialize,
    object.beforeState,
  );
  writer.writeString(offsets[2], object.changeType);
  writer.writeLong(offsets[3], object.lineIndex);
}

SubtitleLineDelta _subtitleLineDeltaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SubtitleLineDelta();
  object.afterState = reader.readObjectOrNull<SubtitleLine>(
    offsets[0],
    SubtitleLineSchema.deserialize,
    allOffsets,
  );
  object.beforeState = reader.readObjectOrNull<SubtitleLine>(
    offsets[1],
    SubtitleLineSchema.deserialize,
    allOffsets,
  );
  object.changeType = reader.readString(offsets[2]);
  object.lineIndex = reader.readLong(offsets[3]);
  return object;
}

P _subtitleLineDeltaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<SubtitleLine>(
            offset,
            SubtitleLineSchema.deserialize,
            allOffsets,
          ))
          as P;
    case 1:
      return (reader.readObjectOrNull<SubtitleLine>(
            offset,
            SubtitleLineSchema.deserialize,
            allOffsets,
          ))
          as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SubtitleLineDeltaQueryFilter
    on QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QFilterCondition> {
  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  afterStateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'afterState'),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  afterStateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'afterState'),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  beforeStateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'beforeState'),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  beforeStateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'beforeState'),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'changeType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'changeType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'changeType', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  changeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'changeType', value: ''),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  lineIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lineIndex', value: value),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  lineIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lineIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  lineIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lineIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  lineIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lineIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SubtitleLineDeltaQueryObject
    on QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QFilterCondition> {
  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  afterState(FilterQuery<SubtitleLine> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'afterState');
    });
  }

  QueryBuilder<SubtitleLineDelta, SubtitleLineDelta, QAfterFilterCondition>
  beforeState(FilterQuery<SubtitleLine> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'beforeState');
    });
  }
}
