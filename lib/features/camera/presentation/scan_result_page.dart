import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/services/compass_heading_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/theme/app_typography.dart';
import '../models/capture_model.dart';
import '../models/scan_result_model.dart';
import 'scan_chat_page.dart';

class ScanResultPage extends StatefulWidget {
  final ScanResultModel scanResult;

  const ScanResultPage({
    super.key,
    required this.scanResult,
  });

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  bool _isSaving = false;
  CaptureModel? _savedCapture;

  ScanResultModel get scanResult => widget.scanResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gading,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksPutih),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          scanResult.isAnimal ? 'Hasil Identifikasi Satwa' : 'Verifikasi AI Ditolak',
          style: AppTypography.titleUi(
            fontSize: 16,
            color: AppColors.teksPutih,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + kToolbarHeight + 14,
          16,
          40,
        ),
        children: [
          // 1. Kartu Foto Satwa (Aspect Ratio 4:3 Field Journal)
          _buildPhotoCard(),
          const SizedBox(height: 16),

          // 2. Banner Status & Detail Taksonomi
          if (scanResult.isAnimal) ...[
            _buildAnimalHeaderCard(),
            const SizedBox(height: 14),
            _buildQuickAiInquiryCard(context),
            const SizedBox(height: 16),
            _buildAnimalActions(context),
            const SizedBox(height: 16),
            _buildMetadataVerificationCard(),
          ] else ...[
            _buildNonAnimalRejectionCard(),
            const SizedBox(height: 24),
            _buildNonAnimalActions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
    Widget imageWidget;
    if (scanResult.localPhotoPath != null &&
        File(scanResult.localPhotoPath!).existsSync()) {
      imageWidget = Image.file(
        File(scanResult.localPhotoPath!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else if (scanResult.imageBase64 != null &&
        scanResult.imageBase64!.isNotEmpty) {
      imageWidget = Image.memory(
        base64Decode(scanResult.imageBase64!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else {
      imageWidget = Container(
        color: AppColors.sageMuda,
        child: const Center(
          child: Icon(Icons.pets_rounded, size: 64, color: AppColors.sageTua),
        ),
      );
    }

    final logId = scanResult.scanId.length >= 8
        ? scanResult.scanId.substring(0, 8).toUpperCase()
        : (scanResult.scanId.isNotEmpty ? scanResult.scanId.toUpperCase() : '804-JAV');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scanResult.isAnimal
              ? AppColors.surfaceContainerHighest
              : AppColors.merahStatus.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageWidget,
              // Pinned Taxonomy Index Badge (Top Left Corner of Photo)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.center_focus_strong,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Log #$logId',
                        style: AppTypography.labelCaption(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Status Badge (Top Right Corner of Photo)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scanResult.isAnimal
                        ? AppColors.sageTua.withValues(alpha: 0.92)
                        : AppColors.merahStatus.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        scanResult.isAnimal
                            ? Icons.verified_rounded
                            : Icons.cancel_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        scanResult.isAnimal ? 'TERVERIFIKASI SATWA' : 'BUKAN SATWA',
                        style: AppTypography.labelCaption(
                          fontSize: 10.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating Tag: AI Detection Badge (Bottom Right Corner)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: scanResult.isAnimal
                              ? AppColors.sageTua
                              : AppColors.merahStatus,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        scanResult.isAnimal
                            ? 'Terdeteksi AI Faunova'
                            : 'AI: Bukan Satwa',
                        style: AppTypography.labelCaption(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scanResult.isAnimal
                              ? AppColors.sageTua
                              : AppColors.merahStatus,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildAnimalHeaderCard() {
    final name = scanResult.name ?? 'Satwa Ditemukan';
    final species = scanResult.categoryOrSpecies ?? 'Fauna Tropis';
    final desc = scanResult.description ?? 'Belum ada catatan deskripsi lapangan.';
    final isDangerous = desc.toLowerCase().contains('bisa') ||
        desc.toLowerCase().contains('racun') ||
        desc.toLowerCase().contains('gigit') ||
        desc.toLowerCase().contains('bahaya') ||
        name.toLowerCase().contains('kelabang') ||
        name.toLowerCase().contains('ular');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Spesies: Common & Scientific Name with Confidence Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.headlineSpecies(
                        fontSize: 22,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      species,
                      style: AppTypography.subheadSpecies(
                        fontSize: 15,
                        color: AppColors.sageTua,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Cukup yakin (94%)',
                  style: AppTypography.labelCaption(
                    fontSize: 11,
                    color: AppColors.onTertiaryFixed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Alert / Safety Warning Chip
          if (isDangerous) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: AppColors.onErrorContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Waspada: Memiliki bisa/pertahanan menyengat',
                    style: AppTypography.labelCaption(
                      fontSize: 11,
                      color: AppColors.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Divider Bar
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: AppColors.surfaceContainerHighest),
          ),

          // Deskripsi Spesies
          Text(
            desc,
            style: AppTypography.bodyCompact(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),

          if (scanResult.additionalFact != null &&
              scanResult.additionalFact!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.emasTua),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scanResult.additionalFact!,
                      style: AppTypography.bodyCompact(
                        fontSize: 12,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Micro-Telemetry Badges
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMicroTelemetryBadge(
                Icons.explore_outlined,
                'Hutan Dataran Rendah',
              ),
              _buildMicroTelemetryBadge(
                desc.toLowerCase().contains('malam') || isDangerous
                    ? Icons.nights_stay_outlined
                    : Icons.wb_sunny_outlined,
                desc.toLowerCase().contains('malam') ? 'Nokturnal' : 'Spesimen Lapangan',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroTelemetryBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.emasTua),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelCaption(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAiInquiryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScanChatPage(scanResult: scanResult),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const Icon(Icons.forum_outlined, size: 18, color: AppColors.sageTua),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tanya Soal Satwa Ini',
                    style: AppTypography.titleUi(
                      fontSize: 14.5,
                      color: AppColors.teksGelap,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Model Taksonomi',
                  style: AppTypography.labelCaption(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.sageTua),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Pill Prompt Suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInquiryPill(
                context,
                'Apakah beracun?',
              ),
              _buildInquiryPill(
                context,
                'Di mana habitatnya?',
              ),
              _buildInquiryPill(
                context,
                'Status kelestarian?',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Interactive Tap Target Input Field
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScanChatPage(scanResult: scanResult),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ketik pertanyaanmu seputar satwa...',
                      style: AppTypography.bodyCompact(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.sageTua,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_upward_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryPill(BuildContext context, String question) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ScanChatPage(
              scanResult: scanResult,
              initialQuery: question,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              question,
              style: AppTypography.bodyCompact(
                fontSize: 12,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.north_east_rounded, size: 13, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataVerificationCard() {
    final headingText = scanResult.cameraHeading != null
        ? CompassHeadingService.formatDetailed(scanResult.cameraHeading!)
        : 'Sensor kompas tidak tersedia';

    final coordText = scanResult.latitude != null && scanResult.longitude != null
        ? '${scanResult.latitude!.toStringAsFixed(4)}°, ${scanResult.longitude!.toStringAsFixed(4)}°'
        : 'Lokasi tidak tersedia (GPS mati/ditolak)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: AppColors.sageTua),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Metadata Verifikasi Lapangan (Server)',
                  style: AppTypography.titleUi(
                    fontSize: 13,
                    color: AppColors.teksGelap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetaRow(Icons.place_outlined, 'Koordinat', coordText),
          const SizedBox(height: 8),
          _buildMetaRow(Icons.explore_outlined, 'Arah Kompas', headingText),
          const SizedBox(height: 8),
          _buildMetaRow(
            Icons.fingerprint_rounded,
            'Hash SHA-256',
            scanResult.photoSha256 != null
                ? '${scanResult.photoSha256!.substring(0, 16)}...'
                : '-',
          ),
          const SizedBox(height: 8),
          _buildMetaRow(
            Icons.speed_rounded,
            'Kuota Hari Ini',
            'Sisa ${scanResult.quotaRemaining} dari ${scanResult.quotaMax} scan (WIB)',
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.sageTua),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTypography.bodyCompact(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyCompact(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.teksGelap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalActions(BuildContext context) {
    return Column(
      children: [
        // Tombol Tanya AI Seputar Satwa (Sesi S6)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScanChatPage(scanResult: scanResult),
                ),
              );
            },
            icon: const Icon(Icons.forum_outlined, color: AppColors.teksGelap, size: 18),
            label: Text(
              'Tanya AI Seputar Satwa',
              style: AppTypography.titleUi(
                fontSize: 14,
                color: AppColors.teksGelap,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Tombol Simpan ke Koleksi Kanonis (Primary CTA)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: _savedCapture != null
              ? ElevatedButton.icon(
                  onPressed: () => _showSaveSuccessDialog(_savedCapture!),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    'Tersimpan di Koleksi (Blok #${_savedCapture!.seq})',
                    style: AppTypography.titleUi(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageTua,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _isSaving ? null : _onSaveToCollectionPressed,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teksGelap),
                        )
                      : const Icon(Icons.library_add_outlined, color: AppColors.teksGelap),
                  label: Text(
                    _isSaving ? 'Menghubungkan ke Rantai Kanonis...' : 'Simpan ke Koleksi Kanonis',
                    style: AppTypography.titleUi(
                      fontSize: 14,
                      color: AppColors.teksGelap,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emas,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
        ),
        const SizedBox(height: 12),

        // Tombol Sekunder: Foto Ulang / Pindai Satwa Lain
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Pindai Satwa Lain',
            style: AppTypography.bodyMedium(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.teksGelap,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onSaveToCollectionPressed() async {
    if (_isSaving || _savedCapture != null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final capture = await CaptureService.instance.saveCapture(
        scanId: scanResult.scanId,
        photoPath: scanResult.localPhotoPath,
        demoSpeciesName: scanResult.name,
        demoCategory: scanResult.categoryOrSpecies,
        demoPhotoSha256: scanResult.photoSha256,
        demoLatitude: scanResult.latitude,
        demoLongitude: scanResult.longitude,
        demoHeading: scanResult.cameraHeading,
      );

      if (!mounted) return;

      setState(() {
        _savedCapture = capture;
        _isSaving = false;
      });

      _showSaveSuccessDialog(capture);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.merahStatus,
        ),
      );
    }
  }

  void _showSaveSuccessDialog(CaptureModel capture) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.gading,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.sageTua,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tersimpan di Koleksi!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teksGelap,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spesies "${capture.speciesName}" telah berhasil diverifikasi dan dicatat ke dalam hash-chain kanonis SHA-256.',
                style: const TextStyle(fontSize: 13, color: AppColors.teksGelap, height: 1.45),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _buildDialogRow('Nomor Blok', '#${capture.seq}'),
                    const Divider(height: 12),
                    _buildDialogRow('Prev Hash', capture.shortPreviousHash),
                    const Divider(height: 12),
                    _buildDialogRow('Block Hash', capture.shortBlockHash),
                    const Divider(height: 12),
                    _buildDialogRow('Integritas', 'Sah & Tamper-Evident'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emas,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(
                  color: AppColors.teksGelap,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.teksGelap.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.teksGelap,
          ),
        ),
      ],
    );
  }

  Widget _buildNonAnimalRejectionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.merahStatus.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.merahStatus.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.merahStatus.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: AppColors.merahStatus,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objek Bukan Satwa',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.merahStatus,
                      ),
                    ),
                    Text(
                      'Verifikasi orisinalitas fauna ditolak AI',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            scanResult.additionalFact ??
                scanResult.description ??
                'Foto yang Anda ambil terdeteksi bukan merupakan satwa/hewan nyata.',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.teksGelap),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sesuai aturan kurasi Faunova, foto bukan hewan tidak dapat disimpan ke koleksi atau diajak tanya jawab.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.teksGelap.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonAnimalActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.teksGelap),
            label: const Text(
              'Ambil Foto Satwa Ulang',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.teksGelap,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emas,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
