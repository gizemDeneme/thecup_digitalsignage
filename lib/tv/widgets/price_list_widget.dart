import 'package:flutter/material.dart';
import '../../data/models/price_list_model.dart';

class PriceListWidget extends StatelessWidget {
  final PriceListModel item;

  const PriceListWidget({super.key, required this.item});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF0F3460);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(item.backgroundColor);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFFE94560),
              fontSize: 44,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 3, width: 100, color: const Color(0xFFE94560)),
          const SizedBox(height: 32),
          Expanded(
            child: item.entries.length <= 15
                ? _singleColumn()
                : _twoColumns(),
          ),
        ],
      ),
    );
  }

  Widget _singleColumn() {
    return ListView.separated(
      itemCount: item.entries.length,
      separatorBuilder: (_, _) =>
          const Divider(color: Colors.white12, height: 1),
      itemBuilder: (_, i) => _EntryRow(entry: item.entries[i]),
    );
  }

  Widget _twoColumns() {
    final half = (item.entries.length / 2).ceil();
    final left = item.entries.take(half).toList();
    final right = item.entries.skip(half).toList();
    return Row(
      children: [
        Expanded(child: _listView(left)),
        const SizedBox(width: 40),
        Expanded(child: _listView(right)),
      ],
    );
  }

  Widget _listView(List<PriceEntry> entries) {
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) =>
          const Divider(color: Colors.white12, height: 1),
      itemBuilder: (_, i) => _EntryRow(entry: entries[i]),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final PriceEntry entry;

  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (entry.isHighlighted)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.star, color: Color(0xFFE94560), size: 16),
            ),
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(
                color: entry.isHighlighted ? Colors.white : Colors.white70,
                fontSize: entry.isHighlighted ? 24 : 20,
                fontWeight: entry.isHighlighted
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (entry.unit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                entry.unit,
                style: const TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ),
          Text(
            entry.price,
            style: TextStyle(
              color: const Color(0xFFE94560),
              fontSize: entry.isHighlighted ? 28 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
