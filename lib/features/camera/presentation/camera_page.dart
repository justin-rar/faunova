import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  AppViewStatus _currentStatus = AppViewStatus.content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera Identifikasi AI'),
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Menyiapkan modul kamera...',
        emptyTitle: 'Kamera Tidak Tersedia',
        emptyMessage: 'Sensor kamera tidak ditemukan pada perangkat ini.',
        errorMessage: 'Izin akses kamera ditolak atau kamera sedang digunakan aplikasi lain.',
        offlineMessage: 'Mode luring. Identifikasi AI memerlukan koneksi internet aktif.',
        onRetry: () {
          setState(() {
            _currentStatus = AppViewStatus.content;
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStateSwitcherCard(),
              const SizedBox(height: 16),
              Container(
                height: 340,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.sageTua,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: AppColors.teksPutih, // Teks/ikon putih di atas sage tua
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Kamera Layar Penuh (Sesi S5)',
                          style: TextStyle(
                            color: AppColors.teksPutih,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 6),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Sesuai aturan plan: kamera langsung tanpa tombol galeri, GPS, dan sensor heading kompas.',
                            style: TextStyle(
                              color: AppColors.teksPutih,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 20,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.emas,
                          border: Border.all(color: AppColors.teksPutih, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera,
                          color: AppColors.teksGelap,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spesifikasi Alur Identifikasi (Plan 5.3):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1. Ambil foto hewan secara langsung (bukan dari galeri)\n'
                      '2. Kompresi gambar & hapus EXIF di klien\n'
                      '3. Verifikasi spesies via Edge Function (Gemini API)\n'
                      '4. Hash-chain kanonis disimpan di Postgres',
                      style: TextStyle(fontSize: 13, color: AppColors.teksGelap),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateSwitcherCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppColors.teksGelap),
              SizedBox(width: 8),
              Text(
                'Simulasi State (AGENTS.md)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildStateChip('Normal', AppViewStatus.content),
              _buildStateChip('Memuat', AppViewStatus.loading),
              _buildStateChip('Kosong', AppViewStatus.empty),
              _buildStateChip('Galat', AppViewStatus.error),
              _buildStateChip('Luring', AppViewStatus.offline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip(String label, AppViewStatus status) {
    final isSelected = _currentStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _currentStatus = status;
        });
      },
      selectedColor: AppColors.sageTua,
      backgroundColor: AppColors.gading,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
      ),
    );
  }
}
