// ==============================================================================
// FAUNOVA PRESENTATION WIDGET: ReportPostSheet
// Lembar modal pelaporan postingan linimasa komunitas
// Sesuai Plan 53, 333 (Tahap 2 & Scope Tingkat 3) & Palet AGENTS.md
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/post_model.dart';

class ReportPostSheet extends StatefulWidget {
  final PostModel post;
  final void Function(String postId)? onReportSuccess;

  const ReportPostSheet({
    super.key,
    required this.post,
    this.onReportSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required PostModel post,
    void Function(String postId)? onReportSuccess,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportPostSheet(
        post: post,
        onReportSuccess: onReportSuccess,
      ),
    );
  }

  @override
  State<ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<ReportPostSheet> {
  String? _selectedReason;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<Map<String, String>> _reportCategories = [
    {
      'id': 'bukan_hewan',
      'title': 'Bukan Satwa / Objek Mati',
      'description': 'Foto tidak memuat hewan hidup atau fauna liar yang valid.',
      'icon': '🚫',
    },
    {
      'id': 'kekerasan_satwa',
      'title': 'Kekerasan atau Perburuan Liar',
      'description': 'Menampilkan penyiksaan satwa atau penangkapan ilegal.',
      'icon': '⚠️',
    },
    {
      'id': 'lokasi_palsu',
      'title': 'Lokasi Palsu / Manipulasi GPS',
      'description': 'Koordinat atau area observasi tidak sesuai fakta lapangan.',
      'icon': '📍',
    },
    {
      'id': 'spam',
      'title': 'Spam atau Promosi Ilegal',
      'description': 'Iklan komersial, tautan tidak relevan, atau spam massal.',
      'icon': '📢',
    },
    {
      'id': 'ujaran_kebencian',
      'title': 'Ujaran Kebencian / Konten Kasar',
      'description': 'Bahasa kasar, pelecehan, atau konten menyinggung SARA.',
      'icon': '💬',
    },
    {
      'id': 'lainnya',
      'title': 'Pelanggaran Lainnya',
      'description': 'Perilaku lain yang melanggar kode etik konservasi.',
      'icon': '📝',
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      setState(() {
        _errorMessage = 'Silakan pilih salah satu alasan laporan.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await PostService.instance.reportPost(
        postId: widget.post.id,
        reason: _selectedReason!,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      widget.onReportSuccess?.call(widget.post.id);

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] as String? ?? 'Laporan berhasil dikirim dan akan ditinjau.',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: AppColors.sageTua,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengirim laporan: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis handle atas
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.sageMuda,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header judul
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.merahStatus.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.merahStatus,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporkan Postingan',
                          style: AppTypography.titleUi(
                            fontSize: 17,
                            color: AppColors.teksGelap,
                          ),
                        ),
                        Text(
                          'Observasi @${widget.post.authorUsername} • ${widget.post.speciesName}',
                          style: AppTypography.bodyCompact(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.teksGelap),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'Bantu kurator menjaga etika sains dan keamanan komunitas Faunova. Pilih alasan yang paling sesuai:',
                style: AppTypography.bodyMedium(
                  fontSize: 12.5,
                  color: AppColors.teksGelap.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Banner error jika ada
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.merahStatus),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.merahStatus),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Daftar Alasan Pelanggaran
              ..._reportCategories.map((cat) {
                final isSelected = _selectedReason == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedReason = cat['id'];
                        _errorMessage = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.sageMuda.withValues(alpha: 0.4)
                            : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.sageTua : AppColors.sageMuda.withValues(alpha: 0.6),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(cat['icon']!, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat['title']!,
                                  style: AppTypography.labelProminent(
                                    fontSize: 13,
                                    color: AppColors.teksGelap,
                                  ),
                                ),
                                Text(
                                  cat['description']!,
                                  style: AppTypography.bodyCompact(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? AppColors.sageTua : AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Catatan tambahan opsional
              Text(
                'Catatan Tambahan (Opsional):',
                style: AppTypography.labelProminent(fontSize: 12, color: AppColors.teksGelap),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLength: 200,
                maxLines: 2,
                style: const TextStyle(fontSize: 12.5, color: AppColors.teksGelap),
                decoration: InputDecoration(
                  hintText: 'Jelaskan rincian atau bukti pelanggaran jika diperlukan...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant.withValues(alpha: 0.8)),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.sageMuda.withValues(alpha: 0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.teksGelap,
                        side: BorderSide(color: AppColors.sageMuda.withValues(alpha: 0.8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.merahStatus,
                        foregroundColor: AppColors.teksPutih,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        _isSubmitting ? 'Mengirim...' : 'Kirim Laporan',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
