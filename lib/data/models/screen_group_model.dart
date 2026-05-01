import 'package:cloud_firestore/cloud_firestore.dart';
import 'playlist_model.dart';

/// "Ekran 1" veya "Ekran 2" gibi bir grup.
/// Tüm aynı gruptaki TV'ler bu dokümanı dinler.
class ScreenGroupModel {
  final String id;         // "ekran_1" | "ekran_2"
  final String name;       // "Ekran 1"
  final PlaylistModel? playlist;

  const ScreenGroupModel({
    required this.id,
    required this.name,
    this.playlist,
  });

  factory ScreenGroupModel.fromFirestore(String id, Map<String, dynamic> data) {
    PlaylistModel? playlist;
    final raw = data['playlist'];
    if (raw != null) {
      try {
        playlist = PlaylistModel.fromMap(raw as Map<String, dynamic>);
      } catch (_) {}
    }
    return ScreenGroupModel(
      id: id,
      name: data['name'] as String? ?? id,
      playlist: playlist,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        if (playlist != null) 'playlist': playlist!.toMap(),
      };
}
