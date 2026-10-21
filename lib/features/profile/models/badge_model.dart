// ==============================================================================
// FAUNOVA MODEL: BadgeModel
// Model data Lencana Gelar Pencapaian (Plan 5.8: 202-217)
// ==============================================================================

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final int targetCount;
  final int currentProgress;
  final int actualProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String iconName;
  final String category;
  final bool isNewlyUnlocked;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.targetCount,
    required this.currentProgress,
    required this.actualProgress,
    required this.isUnlocked,
    this.unlockedAt,
    required this.iconName,
    required this.category,
    this.isNewlyUnlocked = false,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['unlocked_at'] != null) {
      try {
        parsedDate = DateTime.parse(json['unlocked_at'].toString());
      } catch (_) {}
    }

    return BadgeModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetCount: (json['target_count'] as num?)?.toInt() ?? 1,
      currentProgress: (json['current_progress'] as num?)?.toInt() ?? 0,
      actualProgress: (json['actual_progress'] as num?)?.toInt() ?? 0,
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      unlockedAt: parsedDate,
      iconName: json['icon_name'] as String? ?? 'military_tech',
      category: json['category'] as String? ?? 'Umum',
      isNewlyUnlocked: json['is_newly_unlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target_count': targetCount,
      'current_progress': currentProgress,
      'actual_progress': actualProgress,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'icon_name': iconName,
      'category': category,
      'is_newly_unlocked': isNewlyUnlocked,
    };
  }
}
