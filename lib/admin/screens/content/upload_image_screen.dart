import 'dart:typed_data';
import '../../../core/theme/app_theme.dart';
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
  Uint8List? _fileBytes;
  String? _fileName;
  int _fileSize = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes!;
        _fileName = result.files.single.name;
        _fileSize = result.files.single.size;
        if (_titleCtrl.text.isEmpty) {
          _titleCtrl.text =
              result.files.single.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    }
  }

  Future<void> _upload() async {
    if (_fileBytes == null || _titleCtrl.text.isEmpty) return;
    await ref.read(uploadNotifierProvider.notifier).uploadImage(
          bytes: _fileBytes!,
          fileName: _fileName!,
          title: _titleCtrl.text.trim(),
          fileSizeBytes: _fileSize,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uploadNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper2,
        title: const Text('Görsel Yükle', style: TextStyle(color: AppColors.ink)),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: AppColors.ink),
              decoration: _inputDecoration('Başlık'),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: state.isUploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kraft, width: 1.5),
                  image: _fileBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_fileBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _fileBytes == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image,
                                color: AppColors.kraft, size: 48),
                            SizedBox(height: 8),
                            Text('Görsel dosyası seç',
                                style: TextStyle(color: AppColors.ink2)),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            if (state.isUploading) ...[
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: state.isCompressing ? null : (state.progress > 0 ? state.progress : null),
                backgroundColor: AppColors.paper2,
                color: AppColors.kraft,
              ),
              const SizedBox(height: 8),
              Text(
                state.isCompressing
                    ? 'Sıkıştırılıyor...'
                    : state.progress > 0
                        ? '${(state.progress * 100).toStringAsFixed(0)}% yükleniyor...'
                        : 'Başlatılıyor...',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kraft.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.kraft, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(state.error!,
                          style: const TextStyle(
                              color: AppColors.kraft, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_fileBytes != null && !state.isUploading)
                    ? _upload
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kraft,
                  disabledBackgroundColor:
                      AppColors.kraft.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: state.isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: AppColors.ink, strokeWidth: 2),
                      )
                    : const Text('Yükle',
                        style: TextStyle(fontSize: 16, color: AppColors.ink)),
              ),
            ),
          ],
        ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.paper2,
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
