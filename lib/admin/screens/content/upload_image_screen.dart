import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/content_provider.dart';

class UploadImageScreen extends ConsumerStatefulWidget {
  const UploadImageScreen({super.key});

  @override
  ConsumerState<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends ConsumerState<UploadImageScreen> {
  final _titleCtrl = TextEditingController();
  File? _selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        if (_titleCtrl.text.isEmpty) {
          _titleCtrl.text =
              result.files.single.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null || _titleCtrl.text.isEmpty) return;
    await ref
        .read(uploadNotifierProvider.notifier)
        .uploadImage(_selectedFile!, _titleCtrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uploadNotifierProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Görsel Yükle', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Başlık'),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE94560), width: 1.5),
                  image: _selectedFile != null
                      ? DecorationImage(
                          image: FileImage(_selectedFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedFile == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image,
                                color: Color(0xFFE94560), size: 48),
                            SizedBox(height: 8),
                            Text('Görsel dosyası seç',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            if (state.isUploading) ...[
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: state.progress,
                backgroundColor: const Color(0xFF0F3460),
                color: const Color(0xFFE94560),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!,
                  style: const TextStyle(color: Color(0xFFE94560))),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_selectedFile != null && !state.isUploading)
                    ? _upload
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Yükle',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0F3460),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      );

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }
}
