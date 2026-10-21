import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/compass_heading_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../models/scan_result_model.dart';
import 'scan_chat_page.dart';

class ScanResultPage extends StatelessWidget {
  final ScanResultModel scanResult;

  const ScanResultPage({
    super.key,
    required this.scanResult,
  });

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
          style: const TextStyle(
            fontWeight: FontWeight.w700,
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
          // 1. Kartu Foto Satwa
          _buildPhotoCard(),
          const SizedBox(height: 16),

          // 2. Banner Status & Detail Taksonomi
          if (scanResult.isAnimal) ...[
            _buildAnimalHeaderCard(),
            const SizedBox(height: 14),
            _buildDescriptionCard(),
            const SizedBox(height: 14),
            if (scanResult.additionalFact != null &&
                scanResult.additionalFact!.isNotEmpty) ...[
              _buildFactCard(),
              const SizedBox(height: 14),
            ],
            _buildMetadataVerificationCard(),
            const SizedBox(height: 24),
            _buildAnimalActions(context),
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
        height: 260,
      );
    } else if (scanResult.imageBase64 != null &&
        scanResult.imageBase64!.isNotEmpty) {
      imageWidget = Image.memory(
        base64Decode(scanResult.imageBase64!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 260,
      );
    } else {
      imageWidget = Container(
        height: 260,
        color: AppColors.sageMuda,
        child: const Center(
          child: Icon(Icons.pets_rounded, size: 64, color: AppColors.sageTua),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scanResult.isAnimal
              ? AppColors.sage.withValues(alpha: 0.5)
              : AppColors.merahStatus.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            imageWidget,
            // Tag Status di atas foto
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scanResult.isAnimal
                      ? AppColors.sageTua.withValues(alpha: 0.92)
                      : AppColors.merahStatus.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
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
                      size: 14,
                      color: AppColors.teksPutih,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      scanResult.isAnimal ? 'TERVERIFIKASI SATWA' : 'BUKAN SATWA',
                      style: const TextStyle(
                        color: AppColors.teksPutih,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emas,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FAUNA TERDETEKSI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teksGelap,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.emasTua),
              const SizedBox(width: 4),
              const Text(
                'Gemini AI',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emasTua,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            scanResult.name ?? 'Satwa Tidak Dikenal',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.teksGelap,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scanResult.categoryOrSpecies ?? 'Spesies belum terklasifikasi',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.teksGelap.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, size: 18, color: AppColors.sageTua),
              SizedBox(width: 8),
              Text(
                'Karakteristik & Ciri Lapangan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scanResult.description ?? 'Deskripsi tidak tersedia.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.teksGelap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageMuda.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.emasTua),
              SizedBox(width: 8),
              Text(
                'Fakta Unik Lapangan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scanResult.additionalFact!,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.teksGelap,
            ),
          ),
        ],
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
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.sageTua),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Metadata Verifikasi Lapangan (Server)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.teksGelap.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
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
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.teksGelap),
            label: const Text(
              'Tanya AI Seputar Satwa',
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
        const SizedBox(height: 10),

        // Tombol Simpan ke Koleksi (Disiapkan untuk S7)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur Simpan ke Koleksi & Hash-Chain akan aktif pada Sesi S7'),
                  backgroundColor: AppColors.sageTua,
                ),
              );
            },
            icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.sageTua),
            label: const Text(
              'Simpan ke Koleksi Kanonis (Sesi S7)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.teksGelap,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.sageTua, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Tombol Pindai Ulang
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Pindai Satwa Lain',
            style: TextStyle(
              color: AppColors.teksGelap,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
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
