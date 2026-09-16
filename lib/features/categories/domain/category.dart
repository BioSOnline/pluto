const String plutoUncategorizedCategoryId = 'uncategorized';

class PlutoCategory {
  const PlutoCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.colorValue,
    required this.isSystemDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final int colorValue;
  final bool isSystemDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlutoCategory rename(String nextName) {
    return copyWith(name: nextName.trim(), updatedAt: DateTime.now());
  }

  PlutoCategory copyWith({
    String? id,
    String? userId,
    String? name,
    int? colorValue,
    bool? isSystemDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlutoCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'colorValue': colorValue,
      'isSystemDefault': isSystemDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PlutoCategory.fromJson(Map<String, Object?> json) {
    return PlutoCategory(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      isSystemDefault: json['isSystemDefault'] as bool? ?? false,
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }
}

List<PlutoCategory> createDefaultPlutoCategories(String userId) {
  final now = DateTime.now();

  return [
    PlutoCategory(
      id: plutoUncategorizedCategoryId,
      userId: userId,
      name: 'Uncategorized',
      colorValue: 0xFF64748B,
      isSystemDefault: true,
      createdAt: now,
      updatedAt: now,
    ),
    PlutoCategory(
      id: 'personal',
      userId: userId,
      name: 'Personal',
      colorValue: 0xFF10B981,
      isSystemDefault: true,
      createdAt: now,
      updatedAt: now,
    ),
    PlutoCategory(
      id: 'work',
      userId: userId,
      name: 'Work',
      colorValue: 0xFF6366F1,
      isSystemDefault: true,
      createdAt: now,
      updatedAt: now,
    ),
    PlutoCategory(
      id: 'study',
      userId: userId,
      name: 'Study',
      colorValue: 0xFF8B5CF6,
      isSystemDefault: true,
      createdAt: now,
      updatedAt: now,
    ),
    PlutoCategory(
      id: 'ideas',
      userId: userId,
      name: 'Ideas',
      colorValue: 0xFFF59E0B,
      isSystemDefault: true,
      createdAt: now,
      updatedAt: now,
    ),
    PlutoCategory(
      id: 'reminders',
      userId: userId,
      name: 'Reminders',
      colorValue: 0xFFF43F5E,
      isSystemDefault: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

DateTime _readDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
