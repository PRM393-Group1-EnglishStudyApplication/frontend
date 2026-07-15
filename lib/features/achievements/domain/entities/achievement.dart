class Achievement {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int requiredXp;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.requiredXp,
    required this.isUnlocked,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    int? requiredXp,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      requiredXp: requiredXp ?? this.requiredXp,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          iconUrl == other.iconUrl &&
          requiredXp == other.requiredXp &&
          isUnlocked == other.isUnlocked &&
          unlockedAt == other.unlockedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      iconUrl.hashCode ^
      requiredXp.hashCode ^
      isUnlocked.hashCode ^
      unlockedAt.hashCode;
}
