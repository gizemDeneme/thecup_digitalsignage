import 'package:cloud_firestore/cloud_firestore.dart';
import 'content_item_model.dart';

class PlaylistModel {
  final String id;
  final DateTime publishedAt;
  final List<PlaylistItem> items;

  const PlaylistModel({
    required this.id,
    required this.publishedAt,
    required this.items,
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as String? ?? 'active',
      publishedAt: map['publishedAt'] != null
          ? (map['publishedAt'] as Timestamp).toDate()
          : DateTime.now(),
      items: (map['items'] as List<dynamic>? ?? [])
          .map((e) => PlaylistItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'publishedAt': Timestamp.fromDate(publishedAt),
        'items': items.map((i) => i.toMap()).toList(),
      };

  PlaylistModel copyWith({List<PlaylistItem>? items}) {
    return PlaylistModel(
      id: id,
      publishedAt: publishedAt,
      items: items ?? this.items,
    );
  }
}
