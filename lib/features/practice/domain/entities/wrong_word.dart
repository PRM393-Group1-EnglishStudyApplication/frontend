class WrongWord {
  final String word;
  final String level;
  final String definition;
  final String mistakeExplanation;

  const WrongWord({
    required this.word,
    required this.level,
    required this.definition,
    required this.mistakeExplanation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WrongWord &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          level == other.level &&
          definition == other.definition &&
          mistakeExplanation == other.mistakeExplanation;

  @override
  int get hashCode =>
      word.hashCode ^
      level.hashCode ^
      definition.hashCode ^
      mistakeExplanation.hashCode;
}
