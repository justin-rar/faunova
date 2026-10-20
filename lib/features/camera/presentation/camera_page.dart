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
        loadingMessage: 'Menginisialisasi lensa kamera dan sensor arah...',
        emptyTitle: 'Sensor Kamera Tidak Terdeteksi',
        emptyMessage: 'Perangkat ini tidak memiliki modul kamera yang kompatibel.',
        errorMessage: 'Izin kamera ditolak. Berikan izin di Pengaturan HP untuk memotret satwa.',
        offlineMessage: 'Mode luring. Identifikasi AI memerlukan sambungan internet aktif.',
        onRetry: () {
          setState(() {
            _currentStatus = AppViewStatus.content;
          });
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            _buildStateSwitcherCard(),
            const SizedBox(height: 14),

            // Tactical Field Viewfinder HUD
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1B261A), // Deep jungle dark tone
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.sage.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Stack(
                children: [
                  // 1. Grid lines overlay
                  CustomPaint(
                    size: Size.infinite,
                    painter: _ViewfinderGridPainter(),
                  ),

                  // 2. Compass & GPS HUD Header
                  Positioned(
                    top: 14,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.sageTua, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.explore_rounded, size: 14, color: AppColors.emas),
                              SizedBox(width: 6),
                              Text(
                                'HEADING 148° SE',
                                style: TextStyle(
                                  color: AppColors.teksPutih,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.gps_fixed_rounded, size: 13, color: Color(0xFF81C784)),
                              SizedBox(width: 5),
                              Text(
                                'GPS SIAP',
                                style: TextStyle(
                                  color: AppColors.teksPutih,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Center Optical Crosshair & Warning
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.emas.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.filter_center_focus_rounded,
                                size: 50,
                                color: AppColors.emas.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Arahkan kamera ke satwa liar',
                            style: TextStyle(
                              color: AppColors.teksPutih,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Shutter Action Bar
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kamera siap diintegrasikan pada Sesi S5'),
                              backgroundColor: AppColors.sageTua,
                            ),
                          );
                        },
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emas,
                            border: Border.all(color: AppColors.teksPutih, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.teksGelap,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pipeline Specifications Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sageMuda,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 18, color: AppColors.sageTua),
                      SizedBox(width: 8),
                      Text(
                        'Kontrak Validasi Lapangan (Plan 5.3)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildPipelineStep(
                    number: '1',
                    title: 'Hanya Kamera Langsung (Tanpa Galeri)',
                    description: 'Mencegah manipulasi foto unduhan untuk menjaga orisinalitas koleksi.',
                  ),
                  const SizedBox(height: 8),
                  _buildPipelineStep(
                    number: '2',
                    title: 'Kompresi & Penghapusan EXIF di Klien',
                    description: 'Menghemat bandwidth dan membuang metadata gambar sebelum ke server.',
                  ),
                  const SizedBox(height: 8),
                  _buildPipelineStep(
                    number: '3',
                    title: 'Validasi ai-gateway (Gemini API)',
                    description: 'Objek bukan hewan (isAnimal: false) ditolak otomatis di sisi server.',
                  ),
                  const SizedBox(height: 8),
                  _buildPipelineStep(
                    number: '4',
                    title: 'Pencatatan Rantai Hash Kanonis',
                    description: 'SHA-256 kanonis dihitung dan disimpan di Postgres dengan advisory lock.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSwitcherCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: AppColors.teksGelap),
              SizedBox(width: 8),
              Text(
                'Simulasi State (AGENTS.md)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
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
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPipelineStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: AppColors.sageTua,
          child: Text(
            number,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.teksPutih),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.teksGelap),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    // Rule of thirds
    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), paint);
    canvas.drawLine(Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), paint);
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), paint);
    canvas.drawLine(Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
