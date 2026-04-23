import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/image_item_model.dart';

class ImageDisplayWidget extends StatelessWidget {
  final ImageItemModel item;

  const ImageDisplayWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: item.downloadUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, _) =>
          const Center(child: CircularProgressIndicator(color: Colors.white24)),
      errorWidget: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 80)),
    );
  }
}
