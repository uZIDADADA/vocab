// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VocabularyEntriesTable extends VocabularyEntries
    with TableInfo<$VocabularyEntriesTable, VocabularyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 240,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionMeta = const VerificationMeta(
    'definition',
  );
  @override
  late final GeneratedColumn<String> definition = GeneratedColumn<String>(
    'definition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('手动添加'),
  );
  static const VerificationMeta _sourceContextMeta = const VerificationMeta(
    'sourceContext',
  );
  @override
  late final GeneratedColumn<String> sourceContext = GeneratedColumn<String>(
    'source_context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('未分类'),
  );
  static const VerificationMeta _masteryMeta = const VerificationMeta(
    'mastery',
  );
  @override
  late final GeneratedColumn<int> mastery = GeneratedColumn<int>(
    'mastery',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reviewDueAtMeta = const VerificationMeta(
    'reviewDueAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewDueAt = GeneratedColumn<DateTime>(
    'review_due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncRevisionMeta = const VerificationMeta(
    'syncRevision',
  );
  @override
  late final GeneratedColumn<int> syncRevision = GeneratedColumn<int>(
    'sync_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    term,
    definition,
    partOfSpeech,
    source,
    sourceContext,
    tag,
    mastery,
    isFavorite,
    reviewDueAt,
    syncRevision,
    isDirty,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabularyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('definition')) {
      context.handle(
        _definitionMeta,
        definition.isAcceptableOrUnknown(data['definition']!, _definitionMeta),
      );
    } else if (isInserting) {
      context.missing(_definitionMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_context')) {
      context.handle(
        _sourceContextMeta,
        sourceContext.isAcceptableOrUnknown(
          data['source_context']!,
          _sourceContextMeta,
        ),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('mastery')) {
      context.handle(
        _masteryMeta,
        mastery.isAcceptableOrUnknown(data['mastery']!, _masteryMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('review_due_at')) {
      context.handle(
        _reviewDueAtMeta,
        reviewDueAt.isAcceptableOrUnknown(
          data['review_due_at']!,
          _reviewDueAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_revision')) {
      context.handle(
        _syncRevisionMeta,
        syncRevision.isAcceptableOrUnknown(
          data['sync_revision']!,
          _syncRevisionMeta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      definition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition'],
      )!,
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceContext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_context'],
      ),
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
      mastery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      reviewDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}review_due_at'],
      ),
      syncRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_revision'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $VocabularyEntriesTable createAlias(String alias) {
    return $VocabularyEntriesTable(attachedDatabase, alias);
  }
}

class VocabularyEntry extends DataClass implements Insertable<VocabularyEntry> {
  final String id;
  final String term;
  final String definition;
  final String? partOfSpeech;
  final String source;
  final String? sourceContext;
  final String tag;
  final int mastery;
  final bool isFavorite;
  final DateTime? reviewDueAt;
  final int syncRevision;
  final bool isDirty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const VocabularyEntry({
    required this.id,
    required this.term,
    required this.definition,
    this.partOfSpeech,
    required this.source,
    this.sourceContext,
    required this.tag,
    required this.mastery,
    required this.isFavorite,
    this.reviewDueAt,
    required this.syncRevision,
    required this.isDirty,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['term'] = Variable<String>(term);
    map['definition'] = Variable<String>(definition);
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceContext != null) {
      map['source_context'] = Variable<String>(sourceContext);
    }
    map['tag'] = Variable<String>(tag);
    map['mastery'] = Variable<int>(mastery);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || reviewDueAt != null) {
      map['review_due_at'] = Variable<DateTime>(reviewDueAt);
    }
    map['sync_revision'] = Variable<int>(syncRevision);
    map['is_dirty'] = Variable<bool>(isDirty);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  VocabularyEntriesCompanion toCompanion(bool nullToAbsent) {
    return VocabularyEntriesCompanion(
      id: Value(id),
      term: Value(term),
      definition: Value(definition),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      source: Value(source),
      sourceContext: sourceContext == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceContext),
      tag: Value(tag),
      mastery: Value(mastery),
      isFavorite: Value(isFavorite),
      reviewDueAt: reviewDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewDueAt),
      syncRevision: Value(syncRevision),
      isDirty: Value(isDirty),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory VocabularyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyEntry(
      id: serializer.fromJson<String>(json['id']),
      term: serializer.fromJson<String>(json['term']),
      definition: serializer.fromJson<String>(json['definition']),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      source: serializer.fromJson<String>(json['source']),
      sourceContext: serializer.fromJson<String?>(json['sourceContext']),
      tag: serializer.fromJson<String>(json['tag']),
      mastery: serializer.fromJson<int>(json['mastery']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      reviewDueAt: serializer.fromJson<DateTime?>(json['reviewDueAt']),
      syncRevision: serializer.fromJson<int>(json['syncRevision']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'term': serializer.toJson<String>(term),
      'definition': serializer.toJson<String>(definition),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'source': serializer.toJson<String>(source),
      'sourceContext': serializer.toJson<String?>(sourceContext),
      'tag': serializer.toJson<String>(tag),
      'mastery': serializer.toJson<int>(mastery),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'reviewDueAt': serializer.toJson<DateTime?>(reviewDueAt),
      'syncRevision': serializer.toJson<int>(syncRevision),
      'isDirty': serializer.toJson<bool>(isDirty),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  VocabularyEntry copyWith({
    String? id,
    String? term,
    String? definition,
    Value<String?> partOfSpeech = const Value.absent(),
    String? source,
    Value<String?> sourceContext = const Value.absent(),
    String? tag,
    int? mastery,
    bool? isFavorite,
    Value<DateTime?> reviewDueAt = const Value.absent(),
    int? syncRevision,
    bool? isDirty,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => VocabularyEntry(
    id: id ?? this.id,
    term: term ?? this.term,
    definition: definition ?? this.definition,
    partOfSpeech: partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
    source: source ?? this.source,
    sourceContext: sourceContext.present
        ? sourceContext.value
        : this.sourceContext,
    tag: tag ?? this.tag,
    mastery: mastery ?? this.mastery,
    isFavorite: isFavorite ?? this.isFavorite,
    reviewDueAt: reviewDueAt.present ? reviewDueAt.value : this.reviewDueAt,
    syncRevision: syncRevision ?? this.syncRevision,
    isDirty: isDirty ?? this.isDirty,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  VocabularyEntry copyWithCompanion(VocabularyEntriesCompanion data) {
    return VocabularyEntry(
      id: data.id.present ? data.id.value : this.id,
      term: data.term.present ? data.term.value : this.term,
      definition: data.definition.present
          ? data.definition.value
          : this.definition,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      source: data.source.present ? data.source.value : this.source,
      sourceContext: data.sourceContext.present
          ? data.sourceContext.value
          : this.sourceContext,
      tag: data.tag.present ? data.tag.value : this.tag,
      mastery: data.mastery.present ? data.mastery.value : this.mastery,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      reviewDueAt: data.reviewDueAt.present
          ? data.reviewDueAt.value
          : this.reviewDueAt,
      syncRevision: data.syncRevision.present
          ? data.syncRevision.value
          : this.syncRevision,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyEntry(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('definition: $definition, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('source: $source, ')
          ..write('sourceContext: $sourceContext, ')
          ..write('tag: $tag, ')
          ..write('mastery: $mastery, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('reviewDueAt: $reviewDueAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('isDirty: $isDirty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    term,
    definition,
    partOfSpeech,
    source,
    sourceContext,
    tag,
    mastery,
    isFavorite,
    reviewDueAt,
    syncRevision,
    isDirty,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyEntry &&
          other.id == this.id &&
          other.term == this.term &&
          other.definition == this.definition &&
          other.partOfSpeech == this.partOfSpeech &&
          other.source == this.source &&
          other.sourceContext == this.sourceContext &&
          other.tag == this.tag &&
          other.mastery == this.mastery &&
          other.isFavorite == this.isFavorite &&
          other.reviewDueAt == this.reviewDueAt &&
          other.syncRevision == this.syncRevision &&
          other.isDirty == this.isDirty &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class VocabularyEntriesCompanion extends UpdateCompanion<VocabularyEntry> {
  final Value<String> id;
  final Value<String> term;
  final Value<String> definition;
  final Value<String?> partOfSpeech;
  final Value<String> source;
  final Value<String?> sourceContext;
  final Value<String> tag;
  final Value<int> mastery;
  final Value<bool> isFavorite;
  final Value<DateTime?> reviewDueAt;
  final Value<int> syncRevision;
  final Value<bool> isDirty;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const VocabularyEntriesCompanion({
    this.id = const Value.absent(),
    this.term = const Value.absent(),
    this.definition = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceContext = const Value.absent(),
    this.tag = const Value.absent(),
    this.mastery = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.reviewDueAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyEntriesCompanion.insert({
    required String id,
    required String term,
    required String definition,
    this.partOfSpeech = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceContext = const Value.absent(),
    this.tag = const Value.absent(),
    this.mastery = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.reviewDueAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.isDirty = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       term = Value(term),
       definition = Value(definition),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VocabularyEntry> custom({
    Expression<String>? id,
    Expression<String>? term,
    Expression<String>? definition,
    Expression<String>? partOfSpeech,
    Expression<String>? source,
    Expression<String>? sourceContext,
    Expression<String>? tag,
    Expression<int>? mastery,
    Expression<bool>? isFavorite,
    Expression<DateTime>? reviewDueAt,
    Expression<int>? syncRevision,
    Expression<bool>? isDirty,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (term != null) 'term': term,
      if (definition != null) 'definition': definition,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (source != null) 'source': source,
      if (sourceContext != null) 'source_context': sourceContext,
      if (tag != null) 'tag': tag,
      if (mastery != null) 'mastery': mastery,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (reviewDueAt != null) 'review_due_at': reviewDueAt,
      if (syncRevision != null) 'sync_revision': syncRevision,
      if (isDirty != null) 'is_dirty': isDirty,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? term,
    Value<String>? definition,
    Value<String?>? partOfSpeech,
    Value<String>? source,
    Value<String?>? sourceContext,
    Value<String>? tag,
    Value<int>? mastery,
    Value<bool>? isFavorite,
    Value<DateTime?>? reviewDueAt,
    Value<int>? syncRevision,
    Value<bool>? isDirty,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return VocabularyEntriesCompanion(
      id: id ?? this.id,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      source: source ?? this.source,
      sourceContext: sourceContext ?? this.sourceContext,
      tag: tag ?? this.tag,
      mastery: mastery ?? this.mastery,
      isFavorite: isFavorite ?? this.isFavorite,
      reviewDueAt: reviewDueAt ?? this.reviewDueAt,
      syncRevision: syncRevision ?? this.syncRevision,
      isDirty: isDirty ?? this.isDirty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (definition.present) {
      map['definition'] = Variable<String>(definition.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceContext.present) {
      map['source_context'] = Variable<String>(sourceContext.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (mastery.present) {
      map['mastery'] = Variable<int>(mastery.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (reviewDueAt.present) {
      map['review_due_at'] = Variable<DateTime>(reviewDueAt.value);
    }
    if (syncRevision.present) {
      map['sync_revision'] = Variable<int>(syncRevision.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyEntriesCompanion(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('definition: $definition, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('source: $source, ')
          ..write('sourceContext: $sourceContext, ')
          ..write('tag: $tag, ')
          ..write('mastery: $mastery, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('reviewDueAt: $reviewDueAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('isDirty: $isDirty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SentencePatternsTable extends SentencePatterns
    with TableInfo<$SentencePatternsTable, SentencePattern> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SentencePatternsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternMeta = const VerificationMeta(
    'pattern',
  );
  @override
  late final GeneratedColumn<String> pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 800,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('日常表达'),
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _masteryMeta = const VerificationMeta(
    'mastery',
  );
  @override
  late final GeneratedColumn<int> mastery = GeneratedColumn<int>(
    'mastery',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reviewDueAtMeta = const VerificationMeta(
    'reviewDueAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewDueAt = GeneratedColumn<DateTime>(
    'review_due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncRevisionMeta = const VerificationMeta(
    'syncRevision',
  );
  @override
  late final GeneratedColumn<int> syncRevision = GeneratedColumn<int>(
    'sync_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pattern,
    meaning,
    category,
    example,
    mastery,
    isFavorite,
    reviewDueAt,
    syncRevision,
    isDirty,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sentence_patterns';
  @override
  VerificationContext validateIntegrity(
    Insertable<SentencePattern> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pattern')) {
      context.handle(
        _patternMeta,
        pattern.isAcceptableOrUnknown(data['pattern']!, _patternMeta),
      );
    } else if (isInserting) {
      context.missing(_patternMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('mastery')) {
      context.handle(
        _masteryMeta,
        mastery.isAcceptableOrUnknown(data['mastery']!, _masteryMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('review_due_at')) {
      context.handle(
        _reviewDueAtMeta,
        reviewDueAt.isAcceptableOrUnknown(
          data['review_due_at']!,
          _reviewDueAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_revision')) {
      context.handle(
        _syncRevisionMeta,
        syncRevision.isAcceptableOrUnknown(
          data['sync_revision']!,
          _syncRevisionMeta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SentencePattern map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SentencePattern(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      ),
      mastery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      reviewDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}review_due_at'],
      ),
      syncRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_revision'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SentencePatternsTable createAlias(String alias) {
    return $SentencePatternsTable(attachedDatabase, alias);
  }
}

class SentencePattern extends DataClass implements Insertable<SentencePattern> {
  final String id;
  final String pattern;
  final String meaning;
  final String category;
  final String? example;
  final int mastery;
  final bool isFavorite;
  final DateTime? reviewDueAt;
  final int syncRevision;
  final bool isDirty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SentencePattern({
    required this.id,
    required this.pattern,
    required this.meaning,
    required this.category,
    this.example,
    required this.mastery,
    required this.isFavorite,
    this.reviewDueAt,
    required this.syncRevision,
    required this.isDirty,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pattern'] = Variable<String>(pattern);
    map['meaning'] = Variable<String>(meaning);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    map['mastery'] = Variable<int>(mastery);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || reviewDueAt != null) {
      map['review_due_at'] = Variable<DateTime>(reviewDueAt);
    }
    map['sync_revision'] = Variable<int>(syncRevision);
    map['is_dirty'] = Variable<bool>(isDirty);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SentencePatternsCompanion toCompanion(bool nullToAbsent) {
    return SentencePatternsCompanion(
      id: Value(id),
      pattern: Value(pattern),
      meaning: Value(meaning),
      category: Value(category),
      example: example == null && nullToAbsent
          ? const Value.absent()
          : Value(example),
      mastery: Value(mastery),
      isFavorite: Value(isFavorite),
      reviewDueAt: reviewDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewDueAt),
      syncRevision: Value(syncRevision),
      isDirty: Value(isDirty),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SentencePattern.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SentencePattern(
      id: serializer.fromJson<String>(json['id']),
      pattern: serializer.fromJson<String>(json['pattern']),
      meaning: serializer.fromJson<String>(json['meaning']),
      category: serializer.fromJson<String>(json['category']),
      example: serializer.fromJson<String?>(json['example']),
      mastery: serializer.fromJson<int>(json['mastery']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      reviewDueAt: serializer.fromJson<DateTime?>(json['reviewDueAt']),
      syncRevision: serializer.fromJson<int>(json['syncRevision']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pattern': serializer.toJson<String>(pattern),
      'meaning': serializer.toJson<String>(meaning),
      'category': serializer.toJson<String>(category),
      'example': serializer.toJson<String?>(example),
      'mastery': serializer.toJson<int>(mastery),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'reviewDueAt': serializer.toJson<DateTime?>(reviewDueAt),
      'syncRevision': serializer.toJson<int>(syncRevision),
      'isDirty': serializer.toJson<bool>(isDirty),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SentencePattern copyWith({
    String? id,
    String? pattern,
    String? meaning,
    String? category,
    Value<String?> example = const Value.absent(),
    int? mastery,
    bool? isFavorite,
    Value<DateTime?> reviewDueAt = const Value.absent(),
    int? syncRevision,
    bool? isDirty,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SentencePattern(
    id: id ?? this.id,
    pattern: pattern ?? this.pattern,
    meaning: meaning ?? this.meaning,
    category: category ?? this.category,
    example: example.present ? example.value : this.example,
    mastery: mastery ?? this.mastery,
    isFavorite: isFavorite ?? this.isFavorite,
    reviewDueAt: reviewDueAt.present ? reviewDueAt.value : this.reviewDueAt,
    syncRevision: syncRevision ?? this.syncRevision,
    isDirty: isDirty ?? this.isDirty,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SentencePattern copyWithCompanion(SentencePatternsCompanion data) {
    return SentencePattern(
      id: data.id.present ? data.id.value : this.id,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      category: data.category.present ? data.category.value : this.category,
      example: data.example.present ? data.example.value : this.example,
      mastery: data.mastery.present ? data.mastery.value : this.mastery,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      reviewDueAt: data.reviewDueAt.present
          ? data.reviewDueAt.value
          : this.reviewDueAt,
      syncRevision: data.syncRevision.present
          ? data.syncRevision.value
          : this.syncRevision,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SentencePattern(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('meaning: $meaning, ')
          ..write('category: $category, ')
          ..write('example: $example, ')
          ..write('mastery: $mastery, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('reviewDueAt: $reviewDueAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('isDirty: $isDirty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pattern,
    meaning,
    category,
    example,
    mastery,
    isFavorite,
    reviewDueAt,
    syncRevision,
    isDirty,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SentencePattern &&
          other.id == this.id &&
          other.pattern == this.pattern &&
          other.meaning == this.meaning &&
          other.category == this.category &&
          other.example == this.example &&
          other.mastery == this.mastery &&
          other.isFavorite == this.isFavorite &&
          other.reviewDueAt == this.reviewDueAt &&
          other.syncRevision == this.syncRevision &&
          other.isDirty == this.isDirty &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SentencePatternsCompanion extends UpdateCompanion<SentencePattern> {
  final Value<String> id;
  final Value<String> pattern;
  final Value<String> meaning;
  final Value<String> category;
  final Value<String?> example;
  final Value<int> mastery;
  final Value<bool> isFavorite;
  final Value<DateTime?> reviewDueAt;
  final Value<int> syncRevision;
  final Value<bool> isDirty;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SentencePatternsCompanion({
    this.id = const Value.absent(),
    this.pattern = const Value.absent(),
    this.meaning = const Value.absent(),
    this.category = const Value.absent(),
    this.example = const Value.absent(),
    this.mastery = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.reviewDueAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SentencePatternsCompanion.insert({
    required String id,
    required String pattern,
    required String meaning,
    this.category = const Value.absent(),
    this.example = const Value.absent(),
    this.mastery = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.reviewDueAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.isDirty = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pattern = Value(pattern),
       meaning = Value(meaning),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SentencePattern> custom({
    Expression<String>? id,
    Expression<String>? pattern,
    Expression<String>? meaning,
    Expression<String>? category,
    Expression<String>? example,
    Expression<int>? mastery,
    Expression<bool>? isFavorite,
    Expression<DateTime>? reviewDueAt,
    Expression<int>? syncRevision,
    Expression<bool>? isDirty,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pattern != null) 'pattern': pattern,
      if (meaning != null) 'meaning': meaning,
      if (category != null) 'category': category,
      if (example != null) 'example': example,
      if (mastery != null) 'mastery': mastery,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (reviewDueAt != null) 'review_due_at': reviewDueAt,
      if (syncRevision != null) 'sync_revision': syncRevision,
      if (isDirty != null) 'is_dirty': isDirty,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SentencePatternsCompanion copyWith({
    Value<String>? id,
    Value<String>? pattern,
    Value<String>? meaning,
    Value<String>? category,
    Value<String?>? example,
    Value<int>? mastery,
    Value<bool>? isFavorite,
    Value<DateTime?>? reviewDueAt,
    Value<int>? syncRevision,
    Value<bool>? isDirty,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SentencePatternsCompanion(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      meaning: meaning ?? this.meaning,
      category: category ?? this.category,
      example: example ?? this.example,
      mastery: mastery ?? this.mastery,
      isFavorite: isFavorite ?? this.isFavorite,
      reviewDueAt: reviewDueAt ?? this.reviewDueAt,
      syncRevision: syncRevision ?? this.syncRevision,
      isDirty: isDirty ?? this.isDirty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(pattern.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (mastery.present) {
      map['mastery'] = Variable<int>(mastery.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (reviewDueAt.present) {
      map['review_due_at'] = Variable<DateTime>(reviewDueAt.value);
    }
    if (syncRevision.present) {
      map['sync_revision'] = Variable<int>(syncRevision.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SentencePatternsCompanion(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('meaning: $meaning, ')
          ..write('category: $category, ')
          ..write('example: $example, ')
          ..write('mastery: $mastery, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('reviewDueAt: $reviewDueAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('isDirty: $isDirty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewEventsTable extends ReviewEvents
    with TableInfo<$ReviewEventsTable, ReviewEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncRevisionMeta = const VerificationMeta(
    'syncRevision',
  );
  @override
  late final GeneratedColumn<int> syncRevision = GeneratedColumn<int>(
    'sync_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemType,
    itemId,
    rating,
    durationMs,
    reviewedAt,
    syncRevision,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('sync_revision')) {
      context.handle(
        _syncRevisionMeta,
        syncRevision.isAcceptableOrUnknown(
          data['sync_revision']!,
          _syncRevisionMeta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      syncRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_revision'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $ReviewEventsTable createAlias(String alias) {
    return $ReviewEventsTable(attachedDatabase, alias);
  }
}

class ReviewEvent extends DataClass implements Insertable<ReviewEvent> {
  final String id;
  final String itemType;
  final String itemId;
  final int rating;
  final int durationMs;
  final DateTime reviewedAt;
  final int syncRevision;
  final bool isDirty;
  const ReviewEvent({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.rating,
    required this.durationMs,
    required this.reviewedAt,
    required this.syncRevision,
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_type'] = Variable<String>(itemType);
    map['item_id'] = Variable<String>(itemId);
    map['rating'] = Variable<int>(rating);
    map['duration_ms'] = Variable<int>(durationMs);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['sync_revision'] = Variable<int>(syncRevision);
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  ReviewEventsCompanion toCompanion(bool nullToAbsent) {
    return ReviewEventsCompanion(
      id: Value(id),
      itemType: Value(itemType),
      itemId: Value(itemId),
      rating: Value(rating),
      durationMs: Value(durationMs),
      reviewedAt: Value(reviewedAt),
      syncRevision: Value(syncRevision),
      isDirty: Value(isDirty),
    );
  }

  factory ReviewEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewEvent(
      id: serializer.fromJson<String>(json['id']),
      itemType: serializer.fromJson<String>(json['itemType']),
      itemId: serializer.fromJson<String>(json['itemId']),
      rating: serializer.fromJson<int>(json['rating']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      syncRevision: serializer.fromJson<int>(json['syncRevision']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemType': serializer.toJson<String>(itemType),
      'itemId': serializer.toJson<String>(itemId),
      'rating': serializer.toJson<int>(rating),
      'durationMs': serializer.toJson<int>(durationMs),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'syncRevision': serializer.toJson<int>(syncRevision),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  ReviewEvent copyWith({
    String? id,
    String? itemType,
    String? itemId,
    int? rating,
    int? durationMs,
    DateTime? reviewedAt,
    int? syncRevision,
    bool? isDirty,
  }) => ReviewEvent(
    id: id ?? this.id,
    itemType: itemType ?? this.itemType,
    itemId: itemId ?? this.itemId,
    rating: rating ?? this.rating,
    durationMs: durationMs ?? this.durationMs,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    syncRevision: syncRevision ?? this.syncRevision,
    isDirty: isDirty ?? this.isDirty,
  );
  ReviewEvent copyWithCompanion(ReviewEventsCompanion data) {
    return ReviewEvent(
      id: data.id.present ? data.id.value : this.id,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      rating: data.rating.present ? data.rating.value : this.rating,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      syncRevision: data.syncRevision.present
          ? data.syncRevision.value
          : this.syncRevision,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEvent(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('rating: $rating, ')
          ..write('durationMs: $durationMs, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemType,
    itemId,
    rating,
    durationMs,
    reviewedAt,
    syncRevision,
    isDirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewEvent &&
          other.id == this.id &&
          other.itemType == this.itemType &&
          other.itemId == this.itemId &&
          other.rating == this.rating &&
          other.durationMs == this.durationMs &&
          other.reviewedAt == this.reviewedAt &&
          other.syncRevision == this.syncRevision &&
          other.isDirty == this.isDirty);
}

class ReviewEventsCompanion extends UpdateCompanion<ReviewEvent> {
  final Value<String> id;
  final Value<String> itemType;
  final Value<String> itemId;
  final Value<int> rating;
  final Value<int> durationMs;
  final Value<DateTime> reviewedAt;
  final Value<int> syncRevision;
  final Value<bool> isDirty;
  final Value<int> rowid;
  const ReviewEventsCompanion({
    this.id = const Value.absent(),
    this.itemType = const Value.absent(),
    this.itemId = const Value.absent(),
    this.rating = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewEventsCompanion.insert({
    required String id,
    required String itemType,
    required String itemId,
    required int rating,
    this.durationMs = const Value.absent(),
    required DateTime reviewedAt,
    this.syncRevision = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemType = Value(itemType),
       itemId = Value(itemId),
       rating = Value(rating),
       reviewedAt = Value(reviewedAt);
  static Insertable<ReviewEvent> custom({
    Expression<String>? id,
    Expression<String>? itemType,
    Expression<String>? itemId,
    Expression<int>? rating,
    Expression<int>? durationMs,
    Expression<DateTime>? reviewedAt,
    Expression<int>? syncRevision,
    Expression<bool>? isDirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemType != null) 'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
      if (rating != null) 'rating': rating,
      if (durationMs != null) 'duration_ms': durationMs,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (syncRevision != null) 'sync_revision': syncRevision,
      if (isDirty != null) 'is_dirty': isDirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemType,
    Value<String>? itemId,
    Value<int>? rating,
    Value<int>? durationMs,
    Value<DateTime>? reviewedAt,
    Value<int>? syncRevision,
    Value<bool>? isDirty,
    Value<int>? rowid,
  }) {
    return ReviewEventsCompanion(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      rating: rating ?? this.rating,
      durationMs: durationMs ?? this.durationMs,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      syncRevision: syncRevision ?? this.syncRevision,
      isDirty: isDirty ?? this.isDirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (syncRevision.present) {
      map['sync_revision'] = Variable<int>(syncRevision.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEventsCompanion(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('rating: $rating, ')
          ..write('durationMs: $durationMs, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('isDirty: $isDirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InboxEntriesTable extends InboxEntries
    with TableInfo<$InboxEntriesTable, InboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('手动添加'),
  );
  static const VerificationMeta _isProcessedMeta = const VerificationMeta(
    'isProcessed',
  );
  @override
  late final GeneratedColumn<bool> isProcessed = GeneratedColumn<bool>(
    'is_processed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_processed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncRevisionMeta = const VerificationMeta(
    'syncRevision',
  );
  @override
  late final GeneratedColumn<int> syncRevision = GeneratedColumn<int>(
    'sync_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    content,
    source,
    isProcessed,
    createdAt,
    updatedAt,
    syncRevision,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<InboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('is_processed')) {
      context.handle(
        _isProcessedMeta,
        isProcessed.isAcceptableOrUnknown(
          data['is_processed']!,
          _isProcessedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_revision')) {
      context.handle(
        _syncRevisionMeta,
        syncRevision.isAcceptableOrUnknown(
          data['sync_revision']!,
          _syncRevisionMeta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      isProcessed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_processed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_revision'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $InboxEntriesTable createAlias(String alias) {
    return $InboxEntriesTable(attachedDatabase, alias);
  }
}

class InboxEntry extends DataClass implements Insertable<InboxEntry> {
  final String id;
  final String kind;
  final String content;
  final String source;
  final bool isProcessed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncRevision;
  final bool isDirty;
  const InboxEntry({
    required this.id,
    required this.kind,
    required this.content,
    required this.source,
    required this.isProcessed,
    required this.createdAt,
    required this.updatedAt,
    required this.syncRevision,
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['content'] = Variable<String>(content);
    map['source'] = Variable<String>(source);
    map['is_processed'] = Variable<bool>(isProcessed);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_revision'] = Variable<int>(syncRevision);
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  InboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return InboxEntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      content: Value(content),
      source: Value(source),
      isProcessed: Value(isProcessed),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncRevision: Value(syncRevision),
      isDirty: Value(isDirty),
    );
  }

  factory InboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InboxEntry(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      content: serializer.fromJson<String>(json['content']),
      source: serializer.fromJson<String>(json['source']),
      isProcessed: serializer.fromJson<bool>(json['isProcessed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncRevision: serializer.fromJson<int>(json['syncRevision']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'content': serializer.toJson<String>(content),
      'source': serializer.toJson<String>(source),
      'isProcessed': serializer.toJson<bool>(isProcessed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncRevision': serializer.toJson<int>(syncRevision),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  InboxEntry copyWith({
    String? id,
    String? kind,
    String? content,
    String? source,
    bool? isProcessed,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncRevision,
    bool? isDirty,
  }) => InboxEntry(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    content: content ?? this.content,
    source: source ?? this.source,
    isProcessed: isProcessed ?? this.isProcessed,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncRevision: syncRevision ?? this.syncRevision,
    isDirty: isDirty ?? this.isDirty,
  );
  InboxEntry copyWithCompanion(InboxEntriesCompanion data) {
    return InboxEntry(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      content: data.content.present ? data.content.value : this.content,
      source: data.source.present ? data.source.value : this.source,
      isProcessed: data.isProcessed.present
          ? data.isProcessed.value
          : this.isProcessed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncRevision: data.syncRevision.present
          ? data.syncRevision.value
          : this.syncRevision,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InboxEntry(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('source: $source, ')
          ..write('isProcessed: $isProcessed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    content,
    source,
    isProcessed,
    createdAt,
    updatedAt,
    syncRevision,
    isDirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InboxEntry &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.content == this.content &&
          other.source == this.source &&
          other.isProcessed == this.isProcessed &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncRevision == this.syncRevision &&
          other.isDirty == this.isDirty);
}

class InboxEntriesCompanion extends UpdateCompanion<InboxEntry> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> content;
  final Value<String> source;
  final Value<bool> isProcessed;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> syncRevision;
  final Value<bool> isDirty;
  final Value<int> rowid;
  const InboxEntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.content = const Value.absent(),
    this.source = const Value.absent(),
    this.isProcessed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InboxEntriesCompanion.insert({
    required String id,
    required String kind,
    required String content,
    this.source = const Value.absent(),
    this.isProcessed = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncRevision = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InboxEntry> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? content,
    Expression<String>? source,
    Expression<bool>? isProcessed,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncRevision,
    Expression<bool>? isDirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (content != null) 'content': content,
      if (source != null) 'source': source,
      if (isProcessed != null) 'is_processed': isProcessed,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncRevision != null) 'sync_revision': syncRevision,
      if (isDirty != null) 'is_dirty': isDirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InboxEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? content,
    Value<String>? source,
    Value<bool>? isProcessed,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? syncRevision,
    Value<bool>? isDirty,
    Value<int>? rowid,
  }) {
    return InboxEntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      source: source ?? this.source,
      isProcessed: isProcessed ?? this.isProcessed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncRevision: syncRevision ?? this.syncRevision,
      isDirty: isDirty ?? this.isDirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (isProcessed.present) {
      map['is_processed'] = Variable<bool>(isProcessed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncRevision.present) {
      map['sync_revision'] = Variable<int>(syncRevision.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('source: $source, ')
          ..write('isProcessed: $isProcessed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('isDirty: $isDirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VocabularyEntriesTable vocabularyEntries =
      $VocabularyEntriesTable(this);
  late final $SentencePatternsTable sentencePatterns = $SentencePatternsTable(
    this,
  );
  late final $ReviewEventsTable reviewEvents = $ReviewEventsTable(this);
  late final $InboxEntriesTable inboxEntries = $InboxEntriesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vocabularyEntries,
    sentencePatterns,
    reviewEvents,
    inboxEntries,
    appSettings,
  ];
}

typedef $$VocabularyEntriesTableCreateCompanionBuilder =
    VocabularyEntriesCompanion Function({
      required String id,
      required String term,
      required String definition,
      Value<String?> partOfSpeech,
      Value<String> source,
      Value<String?> sourceContext,
      Value<String> tag,
      Value<int> mastery,
      Value<bool> isFavorite,
      Value<DateTime?> reviewDueAt,
      Value<int> syncRevision,
      Value<bool> isDirty,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$VocabularyEntriesTableUpdateCompanionBuilder =
    VocabularyEntriesCompanion Function({
      Value<String> id,
      Value<String> term,
      Value<String> definition,
      Value<String?> partOfSpeech,
      Value<String> source,
      Value<String?> sourceContext,
      Value<String> tag,
      Value<int> mastery,
      Value<bool> isFavorite,
      Value<DateTime?> reviewDueAt,
      Value<int> syncRevision,
      Value<bool> isDirty,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$VocabularyEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyEntriesTable> {
  $$VocabularyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mastery => $composableBuilder(
    column: $table.mastery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewDueAt => $composableBuilder(
    column: $table.reviewDueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VocabularyEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyEntriesTable> {
  $$VocabularyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mastery => $composableBuilder(
    column: $table.mastery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewDueAt => $composableBuilder(
    column: $table.reviewDueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VocabularyEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyEntriesTable> {
  $$VocabularyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<int> get mastery =>
      $composableBuilder(column: $table.mastery, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewDueAt => $composableBuilder(
    column: $table.reviewDueAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$VocabularyEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabularyEntriesTable,
          VocabularyEntry,
          $$VocabularyEntriesTableFilterComposer,
          $$VocabularyEntriesTableOrderingComposer,
          $$VocabularyEntriesTableAnnotationComposer,
          $$VocabularyEntriesTableCreateCompanionBuilder,
          $$VocabularyEntriesTableUpdateCompanionBuilder,
          (
            VocabularyEntry,
            BaseReferences<
              _$AppDatabase,
              $VocabularyEntriesTable,
              VocabularyEntry
            >,
          ),
          VocabularyEntry,
          PrefetchHooks Function()
        > {
  $$VocabularyEntriesTableTableManager(
    _$AppDatabase db,
    $VocabularyEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<String> definition = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceContext = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<int> mastery = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> reviewDueAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyEntriesCompanion(
                id: id,
                term: term,
                definition: definition,
                partOfSpeech: partOfSpeech,
                source: source,
                sourceContext: sourceContext,
                tag: tag,
                mastery: mastery,
                isFavorite: isFavorite,
                reviewDueAt: reviewDueAt,
                syncRevision: syncRevision,
                isDirty: isDirty,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String term,
                required String definition,
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceContext = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<int> mastery = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> reviewDueAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyEntriesCompanion.insert(
                id: id,
                term: term,
                definition: definition,
                partOfSpeech: partOfSpeech,
                source: source,
                sourceContext: sourceContext,
                tag: tag,
                mastery: mastery,
                isFavorite: isFavorite,
                reviewDueAt: reviewDueAt,
                syncRevision: syncRevision,
                isDirty: isDirty,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VocabularyEntriesTable, VocabularyEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $VocabularyEntriesTable,
                    VocabularyEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VocabularyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabularyEntriesTable,
      VocabularyEntry,
      $$VocabularyEntriesTableFilterComposer,
      $$VocabularyEntriesTableOrderingComposer,
      $$VocabularyEntriesTableAnnotationComposer,
      $$VocabularyEntriesTableCreateCompanionBuilder,
      $$VocabularyEntriesTableUpdateCompanionBuilder,
      (
        VocabularyEntry,
        BaseReferences<_$AppDatabase, $VocabularyEntriesTable, VocabularyEntry>,
      ),
      VocabularyEntry,
      PrefetchHooks Function()
    >;
typedef $$SentencePatternsTableCreateCompanionBuilder =
    SentencePatternsCompanion Function({
      required String id,
      required String pattern,
      required String meaning,
      Value<String> category,
      Value<String?> example,
      Value<int> mastery,
      Value<bool> isFavorite,
      Value<DateTime?> reviewDueAt,
      Value<int> syncRevision,
      Value<bool> isDirty,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$SentencePatternsTableUpdateCompanionBuilder =
    SentencePatternsCompanion Function({
      Value<String> id,
      Value<String> pattern,
      Value<String> meaning,
      Value<String> category,
      Value<String?> example,
      Value<int> mastery,
      Value<bool> isFavorite,
      Value<DateTime?> reviewDueAt,
      Value<int> syncRevision,
      Value<bool> isDirty,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$SentencePatternsTableFilterComposer
    extends Composer<_$AppDatabase, $SentencePatternsTable> {
  $$SentencePatternsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mastery => $composableBuilder(
    column: $table.mastery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewDueAt => $composableBuilder(
    column: $table.reviewDueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SentencePatternsTableOrderingComposer
    extends Composer<_$AppDatabase, $SentencePatternsTable> {
  $$SentencePatternsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mastery => $composableBuilder(
    column: $table.mastery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewDueAt => $composableBuilder(
    column: $table.reviewDueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SentencePatternsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SentencePatternsTable> {
  $$SentencePatternsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<int> get mastery =>
      $composableBuilder(column: $table.mastery, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewDueAt => $composableBuilder(
    column: $table.reviewDueAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SentencePatternsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SentencePatternsTable,
          SentencePattern,
          $$SentencePatternsTableFilterComposer,
          $$SentencePatternsTableOrderingComposer,
          $$SentencePatternsTableAnnotationComposer,
          $$SentencePatternsTableCreateCompanionBuilder,
          $$SentencePatternsTableUpdateCompanionBuilder,
          (
            SentencePattern,
            BaseReferences<
              _$AppDatabase,
              $SentencePatternsTable,
              SentencePattern
            >,
          ),
          SentencePattern,
          PrefetchHooks Function()
        > {
  $$SentencePatternsTableTableManager(
    _$AppDatabase db,
    $SentencePatternsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SentencePatternsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SentencePatternsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SentencePatternsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pattern = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<int> mastery = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> reviewDueAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SentencePatternsCompanion(
                id: id,
                pattern: pattern,
                meaning: meaning,
                category: category,
                example: example,
                mastery: mastery,
                isFavorite: isFavorite,
                reviewDueAt: reviewDueAt,
                syncRevision: syncRevision,
                isDirty: isDirty,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pattern,
                required String meaning,
                Value<String> category = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<int> mastery = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> reviewDueAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SentencePatternsCompanion.insert(
                id: id,
                pattern: pattern,
                meaning: meaning,
                category: category,
                example: example,
                mastery: mastery,
                isFavorite: isFavorite,
                reviewDueAt: reviewDueAt,
                syncRevision: syncRevision,
                isDirty: isDirty,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SentencePatternsTable, SentencePattern>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SentencePatternsTable,
                    SentencePattern
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SentencePatternsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SentencePatternsTable,
      SentencePattern,
      $$SentencePatternsTableFilterComposer,
      $$SentencePatternsTableOrderingComposer,
      $$SentencePatternsTableAnnotationComposer,
      $$SentencePatternsTableCreateCompanionBuilder,
      $$SentencePatternsTableUpdateCompanionBuilder,
      (
        SentencePattern,
        BaseReferences<_$AppDatabase, $SentencePatternsTable, SentencePattern>,
      ),
      SentencePattern,
      PrefetchHooks Function()
    >;
typedef $$ReviewEventsTableCreateCompanionBuilder =
    ReviewEventsCompanion Function({
      required String id,
      required String itemType,
      required String itemId,
      required int rating,
      Value<int> durationMs,
      required DateTime reviewedAt,
      Value<int> syncRevision,
      Value<bool> isDirty,
      Value<int> rowid,
    });
typedef $$ReviewEventsTableUpdateCompanionBuilder =
    ReviewEventsCompanion Function({
      Value<String> id,
      Value<String> itemType,
      Value<String> itemId,
      Value<int> rating,
      Value<int> durationMs,
      Value<DateTime> reviewedAt,
      Value<int> syncRevision,
      Value<bool> isDirty,
      Value<int> rowid,
    });

class $$ReviewEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);
}

class $$ReviewEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewEventsTable,
          ReviewEvent,
          $$ReviewEventsTableFilterComposer,
          $$ReviewEventsTableOrderingComposer,
          $$ReviewEventsTableAnnotationComposer,
          $$ReviewEventsTableCreateCompanionBuilder,
          $$ReviewEventsTableUpdateCompanionBuilder,
          (
            ReviewEvent,
            BaseReferences<_$AppDatabase, $ReviewEventsTable, ReviewEvent>,
          ),
          ReviewEvent,
          PrefetchHooks Function()
        > {
  $$ReviewEventsTableTableManager(_$AppDatabase db, $ReviewEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewEventsCompanion(
                id: id,
                itemType: itemType,
                itemId: itemId,
                rating: rating,
                durationMs: durationMs,
                reviewedAt: reviewedAt,
                syncRevision: syncRevision,
                isDirty: isDirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemType,
                required String itemId,
                required int rating,
                Value<int> durationMs = const Value.absent(),
                required DateTime reviewedAt,
                Value<int> syncRevision = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewEventsCompanion.insert(
                id: id,
                itemType: itemType,
                itemId: itemId,
                rating: rating,
                durationMs: durationMs,
                reviewedAt: reviewedAt,
                syncRevision: syncRevision,
                isDirty: isDirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewEventsTable, ReviewEvent>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReviewEventsTable,
                    ReviewEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewEventsTable,
      ReviewEvent,
      $$ReviewEventsTableFilterComposer,
      $$ReviewEventsTableOrderingComposer,
      $$ReviewEventsTableAnnotationComposer,
      $$ReviewEventsTableCreateCompanionBuilder,
      $$ReviewEventsTableUpdateCompanionBuilder,
      (
        ReviewEvent,
        BaseReferences<_$AppDatabase, $ReviewEventsTable, ReviewEvent>,
      ),
      ReviewEvent,
      PrefetchHooks Function()
    >;
typedef $$InboxEntriesTableCreateCompanionBuilder =
    InboxEntriesCompanion Function({
      required String id,
      required String kind,
      required String content,
      Value<String> source,
      Value<bool> isProcessed,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> syncRevision,
      Value<bool> isDirty,
      Value<int> rowid,
    });
typedef $$InboxEntriesTableUpdateCompanionBuilder =
    InboxEntriesCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> content,
      Value<String> source,
      Value<bool> isProcessed,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> syncRevision,
      Value<bool> isDirty,
      Value<int> rowid,
    });

class $$InboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $InboxEntriesTable> {
  $$InboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isProcessed => $composableBuilder(
    column: $table.isProcessed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $InboxEntriesTable> {
  $$InboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isProcessed => $composableBuilder(
    column: $table.isProcessed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InboxEntriesTable> {
  $$InboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get isProcessed => $composableBuilder(
    column: $table.isProcessed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);
}

class $$InboxEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InboxEntriesTable,
          InboxEntry,
          $$InboxEntriesTableFilterComposer,
          $$InboxEntriesTableOrderingComposer,
          $$InboxEntriesTableAnnotationComposer,
          $$InboxEntriesTableCreateCompanionBuilder,
          $$InboxEntriesTableUpdateCompanionBuilder,
          (
            InboxEntry,
            BaseReferences<_$AppDatabase, $InboxEntriesTable, InboxEntry>,
          ),
          InboxEntry,
          PrefetchHooks Function()
        > {
  $$InboxEntriesTableTableManager(_$AppDatabase db, $InboxEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<bool> isProcessed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboxEntriesCompanion(
                id: id,
                kind: kind,
                content: content,
                source: source,
                isProcessed: isProcessed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncRevision: syncRevision,
                isDirty: isDirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String content,
                Value<String> source = const Value.absent(),
                Value<bool> isProcessed = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> syncRevision = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboxEntriesCompanion.insert(
                id: id,
                kind: kind,
                content: content,
                source: source,
                isProcessed: isProcessed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncRevision: syncRevision,
                isDirty: isDirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InboxEntriesTable, InboxEntry>(table),
                  BaseReferences<_$AppDatabase, $InboxEntriesTable, InboxEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InboxEntriesTable,
      InboxEntry,
      $$InboxEntriesTableFilterComposer,
      $$InboxEntriesTableOrderingComposer,
      $$InboxEntriesTableAnnotationComposer,
      $$InboxEntriesTableCreateCompanionBuilder,
      $$InboxEntriesTableUpdateCompanionBuilder,
      (
        InboxEntry,
        BaseReferences<_$AppDatabase, $InboxEntriesTable, InboxEntry>,
      ),
      InboxEntry,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VocabularyEntriesTableTableManager get vocabularyEntries =>
      $$VocabularyEntriesTableTableManager(_db, _db.vocabularyEntries);
  $$SentencePatternsTableTableManager get sentencePatterns =>
      $$SentencePatternsTableTableManager(_db, _db.sentencePatterns);
  $$ReviewEventsTableTableManager get reviewEvents =>
      $$ReviewEventsTableTableManager(_db, _db.reviewEvents);
  $$InboxEntriesTableTableManager get inboxEntries =>
      $$InboxEntriesTableTableManager(_db, _db.inboxEntries);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
