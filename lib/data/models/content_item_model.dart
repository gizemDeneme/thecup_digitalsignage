import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { video, image, menu, priceList }

ContentType contentTypeFromString(String s) {
  return switch (s) {
    'video' => ContentType.video,
    'image' => ContentType.image,
    'menu' => ContentType.menu,
    'price_list' => ContentType.priceList,
    _ => throw ArgumentError('Unknown content type: $s'),
  };
}

String contentTypeToString(ContentType t) {
  return switch (t) {
    ContentType.video => 'video',
    ContentType.image => 'image',
    ContentType.menu => 'menu',
    ContentType.priceList => 'price_list',
  };
}

sealed class ContentItemModel {
  final String id;
  final ContentType type;
  final String title;
  final DateTime createdAt;

  const ContentItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
  });

  factory ContentItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = contentTypeFromString(data['type'] as String);
    return switch (type) {
      ContentType.video => VideoItemModel.fromMap(data),
      ContentType.image => ImageItemModel.fromMap(data),
      ContentType.menu => MenuItemModel.fromMap(data),
      ContentType.priceList => PriceListModel.fromMap(data),
    };
  }

  Map<String, dynamic> toMap();
}

// ─── Video ───────────────────────────────────────────────────────────────────

class VideoItemModel extends ContentItemModel {
  final String storageUrl;
  final String downloadUrl;
  final String? thumbnailUrl;
  final int fileSizeBytes;
  final int durationSeconds;

  const VideoItemModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required this.storageUrl,
    required this.downloadUrl,
    this.thumbnailUrl,
    required this.fileSizeBytes,
    required this.durationSeconds,
  }) : super(type: ContentType.video);

  factory VideoItemModel.fromMap(Map<String, dynamic> map) {
    return VideoItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      storageUrl: map['storageUrl'] as String,
      downloadUrl: map['downloadUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': 'video',
        'title': title,
        'storageUrl': storageUrl,
        'downloadUrl': downloadUrl,
        'thumbnailUrl': thumbnailUrl,
        'fileSizeBytes': fileSizeBytes,
        'durationSeconds': durationSeconds,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── Image ───────────────────────────────────────────────────────────────────

class ImageItemModel extends ContentItemModel {
  final String storageUrl;
  final String downloadUrl;
  final int fileSizeBytes;

  const ImageItemModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required this.storageUrl,
    required this.downloadUrl,
    required this.fileSizeBytes,
  }) : super(type: ContentType.image);

  factory ImageItemModel.fromMap(Map<String, dynamic> map) {
    return ImageItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      storageUrl: map['storageUrl'] as String,
      downloadUrl: map['downloadUrl'] as String,
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': 'image',
        'title': title,
        'storageUrl': storageUrl,
        'downloadUrl': downloadUrl,
        'fileSizeBytes': fileSizeBytes,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── Menu ────────────────────────────────────────────────────────────────────

class MenuEntry {
  final String name;
  final String description;
  final String price;

  const MenuEntry({
    required this.name,
    required this.description,
    required this.price,
  });

  factory MenuEntry.fromMap(Map<String, dynamic> map) => MenuEntry(
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        price: map['price'] as String,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
      };
}

class MenuCategory {
  final String id;
  final String name;
  final List<MenuEntry> items;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.items,
  });

  factory MenuCategory.fromMap(Map<String, dynamic> map) => MenuCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        items: (map['items'] as List<dynamic>)
            .map((e) => MenuEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toMap()).toList(),
      };
}

class MenuItemModel extends ContentItemModel {
  final String backgroundColor;
  final String accentColor;
  final String? logoUrl;
  final List<MenuCategory> categories;

  const MenuItemModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required this.backgroundColor,
    required this.accentColor,
    this.logoUrl,
    required this.categories,
  }) : super(type: ContentType.menu);

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      backgroundColor: map['backgroundColor'] as String? ?? '#1A1A2E',
      accentColor: map['accentColor'] as String? ?? '#E94560',
      logoUrl: map['logoUrl'] as String?,
      categories: (map['categories'] as List<dynamic>? ?? [])
          .map((e) => MenuCategory.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': 'menu',
        'title': title,
        'backgroundColor': backgroundColor,
        'accentColor': accentColor,
        'logoUrl': logoUrl,
        'categories': categories.map((c) => c.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── Price List ───────────────────────────────────────────────────────────────

class PriceEntry {
  final String name;
  final String price;
  final String unit;
  final bool isHighlighted;

  const PriceEntry({
    required this.name,
    required this.price,
    required this.unit,
    this.isHighlighted = false,
  });

  factory PriceEntry.fromMap(Map<String, dynamic> map) => PriceEntry(
        name: map['name'] as String,
        price: map['price'] as String,
        unit: map['unit'] as String? ?? '',
        isHighlighted: map['isHighlighted'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'unit': unit,
        'isHighlighted': isHighlighted,
      };
}

class PriceListModel extends ContentItemModel {
  final String backgroundColor;
  final List<PriceEntry> entries;

  const PriceListModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required this.backgroundColor,
    required this.entries,
  }) : super(type: ContentType.priceList);

  factory PriceListModel.fromMap(Map<String, dynamic> map) {
    return PriceListModel(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      backgroundColor: map['backgroundColor'] as String? ?? '#0F3460',
      entries: (map['entries'] as List<dynamic>? ?? [])
          .map((e) => PriceEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': 'price_list',
        'title': title,
        'backgroundColor': backgroundColor,
        'entries': entries.map((e) => e.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── Playlist Item ─────────────────────────────────────────────────────────────

class PlaylistItem {
  final String id;
  final ContentType type;
  final int durationSeconds;
  final String contentRef;

  /// Minutes from midnight (0–1439). null = always active.
  final int? startMinutes;
  final int? endMinutes;

  const PlaylistItem({
    required this.id,
    required this.type,
    required this.durationSeconds,
    required this.contentRef,
    this.startMinutes,
    this.endMinutes,
  });

  /// Returns true if this item should be shown at [time].
  bool isActiveAt(DateTime time) {
    if (startMinutes == null || endMinutes == null) return true;
    final current = time.hour * 60 + time.minute;
    if (startMinutes! <= endMinutes!) {
      // Same-day range e.g. 11:00–17:00
      return current >= startMinutes! && current < endMinutes!;
    } else {
      // Overnight range e.g. 22:00–02:00
      return current >= startMinutes! || current < endMinutes!;
    }
  }

  /// Human-readable label for the time range.
  String get timeRangeLabel {
    if (startMinutes == null || endMinutes == null) return 'Her Zaman';
    return '${_fmtMinutes(startMinutes!)} – ${_fmtMinutes(endMinutes!)}';
  }

  static String _fmtMinutes(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  factory PlaylistItem.fromMap(Map<String, dynamic> map) {
    return PlaylistItem(
      id: map['id'] as String,
      type: contentTypeFromString(map['type'] as String),
      durationSeconds: (map['durationSeconds'] as num).toInt(),
      contentRef: map['contentRef'] as String,
      startMinutes: (map['startMinutes'] as num?)?.toInt(),
      endMinutes: (map['endMinutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': contentTypeToString(type),
        'durationSeconds': durationSeconds,
        'contentRef': contentRef,
        if (startMinutes != null) 'startMinutes': startMinutes,
        if (endMinutes != null) 'endMinutes': endMinutes,
      };

  PlaylistItem copyWith({
    int? durationSeconds,
    Object? startMinutes = _sentinel,
    Object? endMinutes = _sentinel,
  }) {
    return PlaylistItem(
      id: id,
      type: type,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      contentRef: contentRef,
      startMinutes:
          startMinutes == _sentinel ? this.startMinutes : startMinutes as int?,
      endMinutes:
          endMinutes == _sentinel ? this.endMinutes : endMinutes as int?,
    );
  }
}

const _sentinel = Object();
