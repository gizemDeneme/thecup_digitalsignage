import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/price_list_model.dart';
import '../../providers/content_provider.dart';

class CreatePriceListScreen extends ConsumerStatefulWidget {
  final PriceListModel? existing;
  const CreatePriceListScreen({super.key, this.existing});

  @override
  ConsumerState<CreatePriceListScreen> createState() =>
      _CreatePriceListScreenState();
}

class _CreatePriceListScreenState extends ConsumerState<CreatePriceListScreen> {
  final _uuid = const Uuid();
  final _titleCtrl = TextEditingController();
  String _bgColor = '#0F3460';
  List<PriceEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _bgColor = widget.existing!.backgroundColor;
      _entries = widget.existing!.entries.toList();
    }
  }

  void _addEntry() {
    setState(() {
      _entries.add(
          const PriceEntry(name: '', price: '', unit: '', isHighlighted: false));
    });
  }

  void _removeEntry(int i) => setState(() => _entries.removeAt(i));

  void _updateEntry(int i, PriceEntry e) =>
      setState(() => _entries[i] = e);

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    final list = PriceListModel(
      id: widget.existing?.id ?? _uuid.v4(),
      title: _titleCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      backgroundColor: _bgColor,
      entries: _entries,
    );
    await ref.read(uploadNotifierProvider.notifier).savePriceList(list);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper2,
        title: const Text('Fiyat Listesi', style: TextStyle(color: AppColors.ink)),
        iconTheme: const IconThemeData(color: AppColors.ink),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Kaydet',
                style: TextStyle(
                    color: AppColors.kraft, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: AppColors.ink),
              decoration: InputDecoration(
                labelText: 'Liste Başlığı',
                labelStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.paper2,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _entries.length,
              onReorder: (o, n) {
                setState(() {
                  final item = _entries.removeAt(o);
                  _entries.insert(n > o ? n - 1 : n, item);
                });
              },
              itemBuilder: (_, i) => _EntryRow(
                key: ValueKey(i),
                entry: _entries[i],
                onRemove: () => _removeEntry(i),
                onUpdate: (e) => _updateEntry(i, e),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add, color: AppColors.kraft),
              label: const Text('Satır Ekle',
                  style: TextStyle(color: AppColors.kraft)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.kraft),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }
}

class _EntryRow extends StatefulWidget {
  final PriceEntry entry;
  final VoidCallback onRemove;
  final ValueChanged<PriceEntry> onUpdate;

  const _EntryRow({
    super.key,
    required this.entry,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  late TextEditingController _name;
  late TextEditingController _price;
  late TextEditingController _unit;
  late bool _highlighted;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.entry.name);
    _price = TextEditingController(text: widget.entry.price);
    _unit = TextEditingController(text: widget.entry.unit);
    _highlighted = widget.entry.isHighlighted;
  }

  void _notify() {
    widget.onUpdate(PriceEntry(
      name: _name.text,
      price: _price.text,
      unit: _unit.text,
      isHighlighted: _highlighted,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(8),
        border: _highlighted
            ? Border.all(color: AppColors.kraft, width: 1)
            : null,
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: AppColors.muted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _name,
              style: const TextStyle(color: AppColors.ink, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ürün adı',
                hintStyle: TextStyle(color: AppColors.line.withValues(alpha: 0.2)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _unit,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Birim',
                hintStyle: TextStyle(color: AppColors.line.withValues(alpha: 0.2)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _price,
              style: const TextStyle(color: AppColors.kraft, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Fiyat',
                hintStyle: TextStyle(color: AppColors.line.withValues(alpha: 0.2)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.star,
              color: _highlighted ? AppColors.kraft : AppColors.line.withValues(alpha: 0.2),
              size: 18,
            ),
            onPressed: () {
              setState(() => _highlighted = !_highlighted);
              _notify();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.muted, size: 18),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _unit.dispose();
    super.dispose();
  }
}
