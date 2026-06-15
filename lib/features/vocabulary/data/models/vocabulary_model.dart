class VocabularyModel {
  final String id;
  final String word;
  final String meaning;
  final String? pronunciation;
  final String? exampleSentence;
  final String? audioUrl;
  final String? imageUrl;

  const VocabularyModel({
    required this.id,
    required this.word,
    required this.meaning,
    this.pronunciation,
    this.exampleSentence,
    this.audioUrl,
    this.imageUrl,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    return VocabularyModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      word: (json['word'] ?? '') as String,
      meaning: (json['meaning'] ?? json['definition'] ?? '') as String,
      pronunciation: json['pronunciation'] as String?,
      exampleSentence: (json['exampleSentence'] ?? json['example']) as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
