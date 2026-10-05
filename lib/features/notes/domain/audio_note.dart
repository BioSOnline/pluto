import '../../categories/domain/category.dart';

enum PlutoSyncStatus {
  synced,
  uploading,
  offline,
  failed,
}

enum PlutoRecordingSaveState {
  unsaved,
  saving,
  saved,
  failed,
}

class PlutoAudioNote {
  const PlutoAudioNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.categoryId,
    required this.tags,
    required this.durationMs,
    required this.fileSizeBytes,
    required this.localFilePath,
    required this.cloudFileUrl,
    required this.transcript,
    required this.isFavorite,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String categoryId;
  final List<String> tags;
  final int durationMs;
  final int fileSizeBytes;
  final String localFilePath;
  final String? cloudFileUrl;
  final String? transcript;
  final bool isFavorite;
  final PlutoSyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get canRetrySync {
    return syncStatus == PlutoSyncStatus.failed ||
        syncStatus == PlutoSyncStatus.offline;
  }

  PlutoAudioNote rename(String nextTitle) {
    final trimmedTitle = nextTitle.trim();

    return copyWith(
      title: trimmedTitle.isEmpty ? title : trimmedTitle,
      updatedAt: DateTime.now(),
      syncStatus: PlutoSyncStatus.offline,
    );
  }

  PlutoAudioNote moveToCategory(String nextCategoryId) {
    return copyWith(
      categoryId: nextCategoryId,
      updatedAt: DateTime.now(),
      syncStatus: PlutoSyncStatus.offline,
    );
  }

  PlutoAudioNote retag(List<String> nextTags) {
    return copyWith(
      tags: _cleanTags(nextTags),
      updatedAt: DateTime.now(),
      syncStatus: PlutoSyncStatus.offline,
    );
  }

  PlutoAudioNote toggleFavorite() {
    return copyWith(
      isFavorite: !isFavorite,
      updatedAt: DateTime.now(),
      syncStatus: PlutoSyncStatus.offline,
    );
  }

  PlutoAudioNote softDelete() {
    return copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: PlutoSyncStatus.offline,
    );
  }

  PlutoAudioNote restore() {
    return copyWith(
      deletedAt: null,
      forceDeletedAt: true,
      updatedAt: DateTime.now(),
      syncStatus: PlutoSyncStatus.offline,
    );
  }

  PlutoAudioNote markUploading() {
    return copyWith(syncStatus: PlutoSyncStatus.uploading);
  }

  PlutoAudioNote markSynced({String? cloudFileUrl}) {
    return copyWith(
      cloudFileUrl: cloudFileUrl ?? this.cloudFileUrl,
      syncStatus: PlutoSyncStatus.synced,
    );
  }

  PlutoAudioNote markSyncFailed() {
    return copyWith(syncStatus: PlutoSyncStatus.failed);
  }

  bool matchesSearch(String query, PlutoCategory? category) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchableParts = [
      title,
      category?.name ?? '',
      ...tags,
      transcript ?? '',
      createdAt.toIso8601String(),
    ].join(' ').toLowerCase();

    return searchableParts.contains(normalizedQuery);
  }

  PlutoAudioNote copyWith({
    String? id,
    String? userId,
    String? title,
    String? categoryId,
    List<String>? tags,
    int? durationMs,
    int? fileSizeBytes,
    String? localFilePath,
    String? cloudFileUrl,
    String? transcript,
    bool? isFavorite,
    PlutoSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool forceDeletedAt = false,
  }) {
    return PlutoAudioNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      durationMs: durationMs ?? this.durationMs,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      localFilePath: localFilePath ?? this.localFilePath,
      cloudFileUrl: cloudFileUrl ?? this.cloudFileUrl,
      transcript: transcript ?? this.transcript,
      isFavorite: isFavorite ?? this.isFavorite,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: forceDeletedAt ? deletedAt : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'categoryId': categoryId,
      'tags': tags,
      'durationMs': durationMs,
      'fileSizeBytes': fileSizeBytes,
      'localFilePath': localFilePath,
      'cloudFileUrl': cloudFileUrl,
      'transcript': transcript,
      'isFavorite': isFavorite,
      'syncStatus': syncStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory PlutoAudioNote.fromJson(Map<String, Object?> json) {
    return PlutoAudioNote(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String,
      categoryId: json['categoryId'] as String,
      tags: _readStringList(json['tags']),
      durationMs: json['durationMs'] as int? ?? 0,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      localFilePath: json['localFilePath'] as String? ?? '',
      cloudFileUrl: json['cloudFileUrl'] as String?,
      transcript: json['transcript'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      syncStatus: _readSyncStatus(json['syncStatus']),
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
      deletedAt: _readNullableDate(json['deletedAt']),
    );
  }
}

String createFallbackNoteTitle(DateTime recordedAt) {
  final hour = recordedAt.hour.toString().padLeft(2, '0');
  final minute = recordedAt.minute.toString().padLeft(2, '0');
  final month = recordedAt.month.toString().padLeft(2, '0');
  final day = recordedAt.day.toString().padLeft(2, '0');

  return 'Voice note $month/$day $hour:$minute';
}

String suggestPlutoCategoryId({
  required String title,
  required List<String> tags,
  String? transcript,
}) {
  final text = [title, ...tags, transcript ?? ''].join(' ').toLowerCase();

  if (_containsAny(text, ['meeting', 'client', 'project', 'deadline'])) {
    return 'work';
  }
  if (_containsAny(text, ['lecture', 'exam', 'class', 'assignment'])) {
    return 'study';
  }
  if (_containsAny(text, ['idea', 'script', 'draft', 'hook'])) {
    return 'ideas';
  }
  if (_containsAny(text, ['buy', 'call', 'todo', 'remind'])) {
    return 'reminders';
  }
  if (_containsAny(text, ['family', 'journal', 'home', 'personal'])) {
    return 'personal';
  }

  return plutoUncategorizedCategoryId;
}

List<String> _cleanTags(List<String> tags) {
  final cleanedTags = tags
      .map((tag) => tag.trim().toLowerCase())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();
  cleanedTags.sort();
  return cleanedTags;
}

bool _containsAny(String text, List<String> needles) {
  return needles.any(text.contains);
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}

PlutoSyncStatus _readSyncStatus(Object? value) {
  if (value is String) {
    return PlutoSyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PlutoSyncStatus.offline,
    );
  }
  return PlutoSyncStatus.offline;
}

DateTime _readDate(Object? value) {
  return _readNullableDate(value) ?? DateTime.now();
}

DateTime? _readNullableDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
