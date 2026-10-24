// ==============================================================================
// FAUNOVA PRESENTATION: CaptureDetailPage
// Halaman detail tangkapan satwa koleksi kanonis dan audit hash blok SHA-256
// Sesuai Dokumen Desain Plan 5.2, 5.3 & AGENTS.md (Sesi S8)
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/services/compass_heading_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../camera/models/capture_model.dart';
import '../../camera/models/chain_verification_result.dart';
import '../../feed/presentation/widgets/create_post_sheet.dart';
import 'widgets/multi_timezone_card.dart';

class CaptureDetailPage extends StatefulWidget {
  final CaptureModel capture;

  const CaptureDetailPage({super.key, required this.capture});

  @override
  State<CaptureDetailPage> createState() => _CaptureDetailPageState();
}

class _CaptureDetailPageState extends State<CaptureDetailPage> {
  bool _isVerifyingBlock = false;
  ChainVerificationResult? _blockVerification;

  CaptureModel get capture => widget.capture;

  Future<void> _verifyCurrentBlock() async {
    setState(() {
      _isVerifyingBlock = true;
      _blockVerification = null;
    });

    try {
      final result = await CaptureService.instance.verifyBlock(capture.id);
      if (mounted) {
        setState(() {
          _blockVerification = result;
          _isVerifyingBlock = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingBlock = false;
          _blockVerification = ChainVerificationResult(
            isValid: false,
            totalBlocks: 1,
            message: 'Gagal memverifikasi: $e',
          );
        });
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    if (capture.latitude == null || capture.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat GPS tidak tersedia pada tangkapan ini.'),
          backgroundColor: AppColors.merahStatus,
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${capture.latitude},${capture.longitude}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Tidak dapat membuka aplikasi peta.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka peta: $e'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        backgroundColor: AppColors.sageTua,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 14;

    return Scaffold(
      backgroundColor: AppColors.gading,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Blok Koleksi #${capture.seq}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 40),
        children: [
          // 1. Foto Satwa & Badge Blok
          _buildHeroPhotoCard(),
          const SizedBox(height: 16),

          // 2. Header Spesies Satwa
          _buildSpeciesHeaderCard(),
          const SizedBox(height: 14),

          // 3. Panel Audit Hash-Chain Kanonis SHA-256 (Plan 5.2)
          _buildHashChainAuditCard(),
          const SizedBox(height: 14),

          // 4. Panel Metadata Sensor & Lapangan
          _buildSensorMetadataCard(),
          const SizedBox(height: 14),

          // 5. Panel Waktu Observasi Lapangan 4 Zona (Plan 40, 136, 318)
          MultiTimeZoneCard(
            targetTime: capture.receivedAt,
            title: 'Waktu Observasi 4 Zona',
            subtitle: 'Waktu resmi penerimaan server dalam WIB, WITA, WIT, dan London',
          ),
          const SizedBox(height: 20),

          // 6. Tombol Aksi Lapangan
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeroPhotoCard() {
    Widget imageWidget;
    final path = capture.photoObjectPath;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      imageWidget = Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 270,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 270,
            color: AppColors.sageMuda.withValues(alpha: 0.5),
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.sageTua),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 270,
          color: AppColors.sageTua,
          child: const Center(
            child: Icon(Icons.pets_rounded, size: 72, color: Colors.white54),
          ),
        ),
      );
    } else if (path.startsWith('assets/')) {
      imageWidget = Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 270,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 270,
          color: AppColors.sageTua,
          child: const Center(
            child: Icon(Icons.pets_rounded, size: 72, color: Colors.white54),
          ),
        ),
      );
    } else if (path.isNotEmpty && File(path).existsSync()) {
      imageWidget = Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 270,
      );
    } else {
      imageWidget = Container(
        height: 270,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E4A2C), AppColors.sageTua],
          ),
        ),
        child: const Center(
          child: Icon(Icons.pets_rounded, size: 72, color: Colors.white54),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        FullScreenImageViewer.open(
          context,
          imageUrl: capture.photoObjectPath,
          title: capture.speciesName,
          subtitle: '${capture.category} • Blok #${capture.seq}',
          description: capture.description,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.sage.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            imageWidget,
            // Badge Urutan Blok Kanonis
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sageTua.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.emas.withValues(alpha: 0.7), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: AppColors.emas),
                    const SizedBox(width: 6),
                    Text(
                      'BLOK RANTAI #${capture.seq}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Chip Genesis jika seq = 1
            if (capture.seq == 1)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.emas.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'GENESIS BLOCK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teksGelap,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSpeciesHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative Naturalist Strip
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sageTua, AppColors.emas, AppColors.sage],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            capture.speciesName,
                            style: AppTypography.headlineSpecies(
                              fontSize: 20,
                              color: AppColors.teksGelap,
                            ),
                          ),
                          if (capture.category != null && capture.category!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              capture.category!,
                              style: AppTypography.subheadSpecies(
                                fontSize: 13.5,
                                color: AppColors.sageTua,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.sageTua),
                          const SizedBox(width: 4),
                          Text(
                            'Terkunci',
                            style: AppTypography.labelCaption(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teksGelap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (capture.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    capture.description,
                    style: AppTypography.bodyMedium(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.teksGelap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashChainAuditCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 20, color: AppColors.sageTua),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Audit Rantai Kriptografis (SHA-256)',
                  style: AppTypography.titleUi(
                    fontSize: 14,
                    color: AppColors.teksGelap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Integritas data dijamin menggunakan hash bersambung deterministik per Plan 5.2.',
            style: AppTypography.bodyCompact(
              fontSize: 11.5,
              color: AppColors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Block Hash
          _buildHashRow(
            label: 'Block Hash (#${capture.seq})',
            hash: capture.blockHash,
            icon: Icons.tag_rounded,
          ),
          const Divider(height: 16),

          // Previous Hash
          _buildHashRow(
            label: capture.seq == 1 ? 'Previous Hash (Genesis: SHA-256(User))' : 'Previous Hash (Blok #${capture.seq - 1})',
            hash: capture.previousHash,
            icon: Icons.undo_rounded,
          ),
          const Divider(height: 16),

          // Photo SHA-256
          _buildHashRow(
            label: 'SHA-256 Byte Citra Asli',
            hash: capture.photoSha256,
            icon: Icons.camera_alt_outlined,
          ),
          const SizedBox(height: 16),

          // Banner Hasil Uji Blok
          if (_blockVerification != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _blockVerification!.isValid
                    ? AppColors.tertiaryFixed.withValues(alpha: 0.3)
                    : AppColors.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _blockVerification!.isValid
                      ? AppColors.sageTua.withValues(alpha: 0.4)
                      : AppColors.merahStatus.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _blockVerification!.isValid ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: _blockVerification!.isValid ? AppColors.sageTua : AppColors.merahStatus,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _blockVerification!.message,
                      style: AppTypography.labelProminent(
                        fontSize: 12,
                        color: _blockVerification!.isValid ? AppColors.sageTua : AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Tombol Uji Verifikasi Blok Ini
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isVerifyingBlock ? null : _verifyCurrentBlock,
              icon: _isVerifyingBlock
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageTua),
                    )
                  : const Icon(Icons.fingerprint_rounded, size: 18, color: AppColors.sageTua),
              label: Text(
                _isVerifyingBlock ? 'Memverifikasi Integritas Blok...' : 'Uji Integritas Blok Ini (verify_block)',
                style: AppTypography.labelProminent(
                  fontSize: 12.5,
                  color: AppColors.teksGelap,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.sageTua, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashRow({
    required String label,
    required String hash,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.sageTua),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelCaption(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            InkWell(
              onTap: () => _copyToClipboard(label, hash),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.copy_rounded, size: 13, color: AppColors.emasTua),
                    const SizedBox(width: 4),
                    Text(
                      'Salin',
                      style: AppTypography.labelCaption(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emasTua,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
          ),
          child: Text(
            hash.isNotEmpty ? hash : '-',
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: AppColors.teksGelap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorMetadataCard() {
    final headingStr = capture.cameraHeading != null
        ? CompassHeadingService.formatDetailed(capture.cameraHeading!)
        : 'Kompas tidak tersedia';

    final coordStr = capture.latitude != null && capture.longitude != null
        ? '${capture.latitude!.toStringAsFixed(6)}°, ${capture.longitude!.toStringAsFixed(6)}°'
        : 'Koordinat tidak tersedia';

    // Konversi WIB
    final wibTime = capture.receivedAt.toUtc().add(const Duration(hours: 7));
    final wibStr =
        '${wibTime.year}-${wibTime.month.toString().padLeft(2, '0')}-${wibTime.day.toString().padLeft(2, '0')} pk ${wibTime.hour.toString().padLeft(2, '0')}:${wibTime.minute.toString().padLeft(2, '0')} WIB';

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
          Text(
            'Metadata Sensor & Waktu Penerimaan',
            style: AppTypography.titleUi(
              fontSize: 13,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 12),
          _buildSensorRow(Icons.place_outlined, 'Koordinat GPS', coordStr),
          const SizedBox(height: 8),
          _buildSensorRow(Icons.explore_outlined, 'Arah Kompas', headingStr),
          const SizedBox(height: 8),
          _buildSensorRow(Icons.access_time_rounded, 'Waktu Server', wibStr),
        ],
      ),
    );
  }

  Widget _buildSensorRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.sageTua),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Tombol Bagikan ke Linimasa Komunitas
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              CreatePostSheet.show(context, capture: capture);
            },
            icon: const Icon(Icons.share_rounded, color: AppColors.teksPutih),
            label: Text(
              'Bagikan ke Linimasa (create_post)',
              style: AppTypography.labelProminent(
                fontSize: 14,
                color: AppColors.teksPutih,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageTua,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Tombol Buka di Google Maps
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _openGoogleMaps,
            icon: const Icon(Icons.map_rounded, color: AppColors.teksGelap),
            label: Text(
              'Buka Lokasi di Google Maps',
              style: AppTypography.labelProminent(
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
