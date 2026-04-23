import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/menu_item_model.dart';
import '../../providers/content_provider.dart';

class CreateMenuScreen extends ConsumerStatefulWidget {
  final MenuItemModel? existing;
  const CreateMenuScreen({super.key, this.existing});

  @override
  ConsumerState<CreateMenuScreen> createState() => _CreateMenuScreenState();
}

class _CreateMenuScreenState extends ConsumerState<CreateMenuScreen> {
  final _uuid = const Uuid();
  final _titleCtrl = TextEditingController();
  String _bgColor = '#1A1A2E';
  String _accentColor = '#E94560';
  List<MenuCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _bgColor = widget.existing!.backgroundColor;
      _accentColor = widget.existing!.accentColor;
      _categories = widget.existing!.categories.toList();
    }
  }

  void _addCategory() {
    setState(() {
      _categories.add(MenuCategory(id: _uuid.v4(), name: '', items: []));
    });
  }

  void _removeCategory(int i) {
    setState(() => _categories.removeAt(i));
  }

  void _updateCategoryName(int i, String name) {
    setState(() {
      final cat = _categories[i];
      _categories[i] = MenuCategory(id: cat.id, name: name, items: cat.items);
    });
  }

  void _addItem(int catIndex) {
    setState(() {
      final cat = _categories[catIndex];
      _categories[catIndex] = MenuCategory(
        id: cat.id,
        name: cat.name,
        items: [...cat.items, const MenuEntry(name: '', description: '', price: '')],
      );
    });
  }

  void _removeItem(int catIndex, int itemIndex) {
    setState(() {
      final cat = _categories[catIndex];
      final items = cat.items.toList()..removeAt(itemIndex);
      _categories[catIndex] =
          MenuCategory(id: cat.id, name: cat.name, items: items);
    });
  }

  void _updateItem(int catIndex, int itemIndex, MenuEntry entry) {
    setState(() {
      final cat = _categories[catIndex];
      final items = cat.items.toList()..[itemIndex] = entry;
      _categories[catIndex] =
          MenuCategory(id: cat.id, name: cat.name, items: items);
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    final menu = MenuItemModel(
      id: widget.existing?.id ?? _uuid.v4(),
      title: _titleCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      backgroundColor: _bgColor,
      accentColor: _accentColor,
      categories: _categories,
    );
    await ref.read(uploadNotifierProvider.notifier).saveMenu(menu);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Menü Oluştur', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Kaydet',
                style: TextStyle(
                    color: Color(0xFFE94560), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_titleCtrl, 'Menü Başlığı'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _colorTile('Arka Plan', _bgColor,
                  (v) => setState(() => _bgColor = v))),
              const SizedBox(width: 12),
              Expanded(child: _colorTile('Vurgu Rengi', _accentColor,
                  (v) => setState(() => _accentColor = v))),
            ],
          ),
          const SizedBox(height: 20),
          ..._categories.asMap().entries.map((e) => _CategoryCard(
                index: e.key,
                category: e.value,
                onRemove: () => _removeCategory(e.key),
                onNameChanged: (n) => _updateCategoryName(e.key, n),
                onAddItem: () => _addItem(e.key),
                onRemoveItem: (i) => _removeItem(e.key, i),
                onUpdateItem: (i, entry) => _updateItem(e.key, i, entry),
              )),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(Icons.add, color: Color(0xFFE94560)),
            label: const Text('Kategori Ekle',
                style: TextStyle(color: Color(0xFFE94560))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE94560)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) => TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF0F3460),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
        ),
      );

  Widget _colorTile(String label, String value, ValueChanged<String> onChange) {
    return GestureDetector(
      onTap: () => _showColorPicker(label, value, onChange),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _parseColor(value),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white70))),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(
      String label, String current, ValueChanged<String> onChange) {
    final presets = [
      '#1A1A2E', '#16213E', '#0F3460', '#E94560',
      '#000000', '#FFFFFF', '#FF6B6B', '#4ECDC4',
      '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: presets
                  .map((hex) => GestureDetector(
                        onTap: () {
                          onChange(hex);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _parseColor(hex),
                            borderRadius: BorderRadius.circular(8),
                            border: hex == current
                                ? Border.all(
                                    color: const Color(0xFFE94560), width: 2)
                                : null,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(
          int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }
}

class _CategoryCard extends StatelessWidget {
  final int index;
  final MenuCategory category;
  final VoidCallback onRemove;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;
  final void Function(int, MenuEntry) onUpdateItem;

  const _CategoryCard({
    required this.index,
    required this.category,
    required this.onRemove,
    required this.onNameChanged,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onUpdateItem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: category.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Kategori adı',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onChanged: onNameChanged,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFE94560)),
                  onPressed: onRemove,
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            ...category.items.asMap().entries.map((e) => _ItemRow(
                  index: e.key,
                  entry: e.value,
                  onRemove: () => onRemoveItem(e.key),
                  onUpdate: (entry) => onUpdateItem(e.key, entry),
                )),
            TextButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add, color: Colors.white54, size: 16),
              label: const Text('Ürün Ekle',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatefulWidget {
  final int index;
  final MenuEntry entry;
  final VoidCallback onRemove;
  final ValueChanged<MenuEntry> onUpdate;

  const _ItemRow({
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.entry.name);
    _desc = TextEditingController(text: widget.entry.description);
    _price = TextEditingController(text: widget.entry.price);
  }

  void _notify() {
    widget.onUpdate(MenuEntry(
      name: _name.text,
      description: _desc.text,
      price: _price.text,
    ));
  }

  InputDecoration _dec(String h) => InputDecoration(
        hintText: h,
        hintStyle: const TextStyle(color: Colors.white24),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _dec('Ürün adı'),
              onChanged: (_) => _notify(),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _desc,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              decoration: _dec('Açıklama'),
              onChanged: (_) => _notify(),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _price,
              style: const TextStyle(color: Color(0xFFE94560), fontSize: 13),
              decoration: _dec('Fiyat'),
              onChanged: (_) => _notify(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 16),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }
}
