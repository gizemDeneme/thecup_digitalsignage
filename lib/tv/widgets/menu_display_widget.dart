import 'package:flutter/material.dart';
import '../../data/models/menu_item_model.dart';

class MenuDisplayWidget extends StatelessWidget {
  final MenuItemModel item;

  const MenuDisplayWidget({super.key, required this.item});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF1A1A2E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(item.backgroundColor);
    final accent = _parseColor(item.accentColor);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                item.title,
                style: TextStyle(
                  color: accent,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 3, width: 120, color: accent),
          const SizedBox(height: 32),
          // Categories
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildColumns(accent),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildColumns(Color accent) {
    final cats = item.categories;
    if (cats.isEmpty) return [];

    final mid = (cats.length / 2).ceil();
    final left = cats.take(mid).toList();
    final right = cats.skip(mid).toList();

    return [
      Expanded(child: _column(left, accent)),
      if (right.isNotEmpty) ...[
        const SizedBox(width: 60),
        Expanded(child: _column(right, accent)),
      ],
    ];
  }

  Widget _column(List<MenuCategory> cats, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cats
          .map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name.toUpperCase(),
                      style: TextStyle(
                        color: accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...cat.items.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                            if (e.description.isNotEmpty)
                              Expanded(
                                child: Text(
                                  e.description,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 14),
                                ),
                              ),
                            Text(
                              e.price,
                              style: TextStyle(
                                color: accent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
