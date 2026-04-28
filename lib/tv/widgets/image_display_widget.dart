import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/image_item_model.dart';

class ImageDisplayWidget extends StatelessWidget {
  final ImageItemModel item;

  const ImageDisplayWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Bulanık arka plan — portre görsellerde yan boşlukları doldurur
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: CachedNetworkImage(
            imageUrl: item.downloadUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Karartma katmanı — bulanık görseli bastırır, net görseli öne çıkarır
        Container(color: Colors.black.withValues(alpha: 0.45)),
        // Net görsel — tam sığdır, kırpma yok
        CachedNetworkImage(
          imageUrl: item.downloadUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, _) => const Center(
              child: CircularProgressIndicator(color: Colors.white24)),
          errorWidget: (_, _, _) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white24, size: 80)),
        ),
      ],
    );
  }
}
