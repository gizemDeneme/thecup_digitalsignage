import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audit_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/screen_provider.dart';
import '../../../data/models/audit_log_model.dart';

class PublishScreen extends ConsumerWidget {
  const PublishScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(playlistEditorProvider);
    final totalSecs = items.fold(0, (a, b) => a + b.durationSeconds);
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper2,
        title: const Text('Yayınla', style: TextStyle(color: AppColors.ink)),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yayın Özeti',
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _summaryRow(Icons.play_circle, 'İçerik sayısı', '${items.length}'),
            _summaryRow(Icons.timer, 'Toplam süre', '${mins}d ${secs}s'),
            _summaryRow(Icons.tv, 'Hedef', 'Ekran 1 + Ekran 2'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.kraft),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Yayınlandıktan sonra tüm ekranlara 1-2 saniye içinde iletilir.',
                      style: TextStyle(color: AppColors.ink2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _publish(context, ref),
                icon: const Icon(Icons.broadcast_on_personal,
                    color: AppColors.ink),
                label: const Text(
                  'Tüm Ekranlara Yayınla',
                  style: TextStyle(fontSize: 16, color: AppColors.ink),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kraft,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.kraft, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.ink2)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.ink, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.kraft),
      ),
    );

    try {
      final items = ref.read(playlistEditorProvider);
      final screenRepo = ref.read(screenRepositoryProvider);
      await Future.wait([
        screenRepo.publishToGroup('ekran_1', items, source: 'playlist'),
        screenRepo.publishToGroup('ekran_2', items, source: 'playlist'),
        screenRepo.setGroupPaused('ekran_1', false),
        screenRepo.setGroupPaused('ekran_2', false),
      ]);
      await ref.read(auditServiceProvider).log(
            AuditAction.playlistPublish,
            metadata: {
              'itemCount': items.length,
              'totalSeconds':
                  items.fold<int>(0, (a, b) => a + b.durationSeconds),
              'targets': ['ekran_1', 'ekran_2'],
            },
          );
      if (context.mounted) {
        Navigator.of(context).pop(); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ekran 1 ve Ekran 2\'ye yayınlandı!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.of(context).pop(); // go back to editor
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.kraft,
          ),
        );
      }
    }
  }
}
