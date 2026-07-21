enum FlashcardSource { due, favorites, lesson }

extension FlashcardSourceApi on FlashcardSource {
  String get apiValue => switch (this) {
    FlashcardSource.due => 'due',
    FlashcardSource.favorites => 'favorites',
    FlashcardSource.lesson => 'lesson',
  };
}

class FlashcardModel {
  final String vocabularyId;
  final String word;
  final String? pronunciation;
  final String meaning;
  final String? exampleSentence;
  final int box;
  final bool isNew;

  const FlashcardModel({
    required this.vocabularyId,
    required this.word,
    this.pronunciation,
    required this.meaning,
    this.exampleSentence,
    required this.box,
    required this.isNew,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      vocabularyId: json['vocabulary_id'] as String? ?? '',
      word: json['word'] as String? ?? '',
      pronunciation: json['pronunciation'] as String?,
      meaning: json['meaning'] as String? ?? '',
      exampleSentence: json['example_sentence'] as String?,
      box: json['box'] as int? ?? 1,
      isNew: json['is_new'] as bool? ?? false,
    );
  }
}

class FlashcardCountsModel {
  final int due;
  final int newCount;
  final Map<String, int> boxes;

  const FlashcardCountsModel({
    required this.due,
    required this.newCount,
    required this.boxes,
  });

  factory FlashcardCountsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> boxesJson = json['boxes'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return FlashcardCountsModel(
      due: json['due'] as int? ?? 0,
      newCount: json['new'] as int? ?? 0,
      boxes: boxesJson.map((key, value) => MapEntry(key, value as int? ?? 0)),
    );
  }
}

class FlashcardSessionModel {
  final String source;
  final List<FlashcardModel> cards;
  final FlashcardCountsModel counts;

  const FlashcardSessionModel({
    required this.source,
    required this.cards,
    required this.counts,
  });

  factory FlashcardSessionModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> cardsJson = json['cards'] as List<dynamic>? ?? const <dynamic>[];
    return FlashcardSessionModel(
      source: json['source'] as String? ?? '',
      cards: cardsJson.map((item) => FlashcardModel.fromJson(item as Map<String, dynamic>)).toList(),
      counts: FlashcardCountsModel.fromJson(json['counts'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
    );
  }
}
