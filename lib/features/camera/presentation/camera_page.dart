import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/data/sample_images.dart';
import '../../../core/services/compass_heading_service.dart';
import '../../../core/services/image_processing_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/scan_service.dart';
import '../../../core/services/sensor_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_app_bar.dart';
import 'scan_result_page.dart';

enum TargetSampleType {
  hardwareCamera,
  butterflyAnimal,
  komodoAnimal,
  coffeeNonAnimal,
}

class CameraPage extends StatefulWidget {
  final bool isActive;
  const CameraPage({super.key, this.isActive = true});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  AppViewStatus _currentStatus = AppViewStatus.content;
  double _cameraHeading = 148.0;
  String _gpsStatus = 'GPS SIAP';
  bool _isGpsLocked = true;

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessingScan = false;
  String _processingStageMessage = 'Menyiapkan pemindaian...';
  TargetSampleType _selectedTarget = TargetSampleType.butterflyAnimal;

  // Flash mode state
  FlashMode _currentFlashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      _initSensorsAndCamera();
    }
  }

  @override
  void didUpdateWidget(CameraPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // Masuk ke tab kamera -> aktifkan sensor
      _initSensorsAndCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      // Keluar dari tab kamera -> matikan kamera agar tidak membebani emulator/HP
      _disposeCamera();
    }
  }

  void _disposeCamera({bool notify = true}) {
    final controller = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;
    if (controller != null) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    SensorLocationService.instance.stopCompassListener();
    if (notify && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera(notify: false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && _selectedTarget == TargetSampleType.hardwareCamera) {
      _initCamera();
    }
  }

  Future<void> _initSensorsAndCamera() async {
    if (!mounted) return;

    // ── Minta izin runtime sebelum akses hardware ──────────────────────────
    final cameraGranted = await PermissionService.instance.requestCamera(context);
    if (!mounted) return;
    final locationGranted = await PermissionService.instance.requestLocation(context);
    if (!mounted) return;

    if (!cameraGranted || !locationGranted) {
      // Izin ditolak — tampilkan status error agar tidak gagal diam-diam
      setState(() {
        _currentStatus = AppViewStatus.error;
        _gpsStatus = !locationGranted ? 'LOKASI DITOLAK' : 'GPS SIAP';
        _isGpsLocked = locationGranted;
      });
      return;
    }

    // 1. Kompas & Lokasi
    SensorLocationService.instance.startCompassListener();
    _checkGpsStatus();

    // 2. Hardware Camera (hanya jika target adalah kamera fisik)
    if (_selectedTarget == TargetSampleType.hardwareCamera) {
      await _initCamera();
    }
  }

  Future<void> _checkGpsStatus() async {
    final locationResult = await SensorLocationService.instance.readCurrentLocation();
    if (mounted) {
      setState(() {
        if (locationResult.hasValidCoordinates) {
          _gpsStatus = locationResult.isMock == true ? 'MOCK GPS' : 'GPS SIAP';
          _isGpsLocked = locationResult.isMock != true;
        } else {
          _gpsStatus = 'LOKASI NONAKTIF';
          _isGpsLocked = false;
        }
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        final backCamera = _availableCameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _availableCameras.first,
        );

        final controller = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await controller.initialize();
        if (mounted && widget.isActive) {
          setState(() {
            _cameraController = controller;
            _isCameraInitialized = true;
          });
        } else {
          controller.dispose();
        }
      }
    } catch (e) {
      debugPrint('Hardware camera init exception: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    FlashMode nextMode;
    switch (_currentFlashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      case FlashMode.off:
      default:
        nextMode = FlashMode.auto;
        break;
    }

    try {
      await _cameraController!.setFlashMode(nextMode);
      setState(() {
        _currentFlashMode = nextMode;
      });
    } catch (e) {
      debugPrint('Failed to set flash mode: $e');
    }
  }

  Future<void> _onShutterPressed() async {
    if (_isProcessingScan) return;

    setState(() {
      _isProcessingScan = true;
      _processingStageMessage = 'Menangkap citra satwa...';
    });

    try {
      Uint8List rawBytes;
      String? localPath;

      // 1. Ambil byte gambar (dari hardware kamera atau target uji terpilih)
      if (_selectedTarget == TargetSampleType.hardwareCamera) {
        if (!_isCameraInitialized || _cameraController == null) {
          setState(() {
            _isProcessingScan = false;
          });
          _showErrorDialog(
            'Lensa kamera fisik belum aktif di perangkat/emulator ini.\n\n'
            'Silakan pilih salah satu chip mode bidikan di atas:\n'
            '• "Kupu-kupu (Satwa)" untuk uji identifikasi satwa AI\n'
            '• "Cangkir Kopi (Non-Satwa)" untuk uji penolakan non-satwa AI\n\n'
            'Jika di HP fisik, pastikan izin kamera diizinkan di Pengaturan HP.',
          );
          return;
        }
        final photo = await _cameraController!.takePicture();
        localPath = photo.path;
        rawBytes = await photo.readAsBytes();
      } else {
        // Mode target uji yang valid
        rawBytes = _getSampleTargetBytes(_selectedTarget);
      }

      // 2. Baca GPS & Heading
      setState(() {
        _processingStageMessage = 'Membaca GPS & arah kompas...';
      });

      final locationResult = await SensorLocationService.instance.readCurrentLocation();
      final currentSensorHeading = SensorLocationService.instance.currentHeading ?? _cameraHeading;

      // 3. Kompresi & buang EXIF di klien (Plan 5.2)
      setState(() {
        _processingStageMessage = 'Kompresi & pembersihan metadata EXIF...';
      });

      final processedImage = await ImageProcessingService.processCameraImage(rawBytes);

      // 4. Kirim ke Edge Function `ai-gateway`
      setState(() {
        _processingStageMessage = 'Menganalisis satwa via DeepSeek AI...';
      });

      final scanResult = await ScanService.instance.scanAnimal(
        imageBase64: processedImage.base64String,
        photoSha256: processedImage.sha256Hash,
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
        heading: currentSensorHeading,
        isMock: locationResult.isMock,
        localPhotoPath: localPath,
      );

      if (mounted) {
        setState(() {
          _isProcessingScan = false;
        });

        // Buka halaman hasil identifikasi
        Navigator.of(context).push(
          MaterialAppPageRoute(
            builder: (_) => ScanResultPage(scanResult: scanResult),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingScan = false;
        });

        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.gading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.merahStatus),
            SizedBox(width: 8),
            Text(
              'Identifikasi Gagal',
              style: TextStyle(
                color: AppColors.teksGelap,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.teksGelap, fontSize: 13.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emas,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Tutup',
              style: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 14;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        centerTitle: true,
        title: Text(
          'Kamera Identifikasi AI',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: Stack(
        children: [
          AppStateView(
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
              padding: EdgeInsets.fromLTRB(16, topPadding, 16, 110),
              children: [
                _buildTargetSelectorCard(),
                const SizedBox(height: 12),

                // Tactical Field Viewfinder HUD
                Container(
                  height: 420,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B261A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.sage.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // 1. Kamera Langsung atau Preview Viewfinder
                        _buildCameraPreviewOrFallback(),

                        // 2. Garis Grid Rule of Thirds
                        CustomPaint(
                          size: Size.infinite,
                          painter: _ViewfinderGridPainter(),
                        ),

                        // 3. Top HUD: Kompas & Status GPS
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 14,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _cameraHeading = (_cameraHeading + 45.0) % 360.0;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.sageTua, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.explore_rounded, size: 14, color: AppColors.emas),
                                      const SizedBox(width: 6),
                                      Text(
                                        'HEADING ${CompassHeadingService.formatHud(_cameraHeading)}',
                                        style: const TextStyle(
                                          color: AppColors.teksPutih,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isGpsLocked ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                                      size: 13,
                                      color: _isGpsLocked ? const Color(0xFF81C784) : AppColors.emas,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _gpsStatus,
                                      style: const TextStyle(
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

                        // 4. Optical Crosshair Reticle Tengah (tampil saat lensa aktif atau saat memilih target sampel)
                        if (_isCameraInitialized || _selectedTarget != TargetSampleType.hardwareCamera)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.emas.withValues(alpha: 0.7),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.filter_center_focus_rounded,
                                        size: 48,
                                        color: AppColors.emas,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    _getTargetSubtitle(),
                                    style: const TextStyle(
                                      color: AppColors.teksPutih,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 5. Tombol Flash di Sisi Kanan Atas
                        if (_isCameraInitialized)
                          Positioned(
                            top: 54,
                            right: 14,
                            child: GestureDetector(
                              onTap: _toggleFlash,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _currentFlashMode == FlashMode.always
                                      ? Icons.flash_on_rounded
                                      : _currentFlashMode == FlashMode.off
                                          ? Icons.flash_off_rounded
                                          : Icons.flash_auto_rounded,
                                  color: AppColors.emas,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),

                        // 6. Tombol Rana (Shutter Action Bar)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: _onShutterPressed,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.emas,
                                  border: Border.all(color: AppColors.teksPutih, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
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
                ),

                const SizedBox(height: 14),

                // Pipeline Specifications Card
                _buildValidationContractCard(),
              ],
            ),
          ),

          // Loading Overlay saat proses scan berlangsung
          if (_isProcessingScan)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.gading,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.sageTua),
                      const SizedBox(height: 18),
                      const Text(
                        'Mengidentifikasi Satwa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _processingStageMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreviewOrFallback() {
    if (_selectedTarget == TargetSampleType.hardwareCamera) {
      if (_isCameraInitialized && _cameraController != null) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1,
              height: _cameraController!.value.previewSize?.width ?? 1,
              child: CameraPreview(_cameraController!),
            ),
          ),
        );
      }

      // Kamera fisik belum aktif / di emulator
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF1B261A),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_outlined,
                size: 52,
                color: AppColors.sage.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lensa Fisik Belum Aktif',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.teksPutih,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Di Emulator, silakan pilih chip sampel di atas:\n"Kupu-kupu (Satwa)" atau "Cangkir Kopi (Non-Satwa)"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.teksPutih.withValues(alpha: 0.75),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilan sampel optik nyata
    if (_selectedTarget == TargetSampleType.coffeeNonAnimal) {
      return SizedBox.expand(
        child: Image.memory(
          SampleImages.chessboardBytes,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return SizedBox.expand(
        child: Image.memory(
          SampleImages.butterflyBytes,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  String _getTargetSubtitle() {
    switch (_selectedTarget) {
      case TargetSampleType.hardwareCamera:
        return _isCameraInitialized
            ? 'Lensa Lapangan Aktif'
            : 'Arahkan kamera ke satwa liar';
      case TargetSampleType.butterflyAnimal:
        return 'Sampel Uji: Kupu-kupu (Satwa)';
      case TargetSampleType.komodoAnimal:
        return 'Sampel Uji: Komodo (Satwa)';
      case TargetSampleType.coffeeNonAnimal:
        return 'Sampel Uji: Kopi (Non-Satwa)';
    }
  }

  Widget _buildTargetSelectorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 16, color: AppColors.teksGelap),
              const SizedBox(width: 8),
              const Text(
                'Mode Bidikan Kamera (Sesi S5)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.teksGelap,
                ),
              ),
              const Spacer(),
              if (_isCameraInitialized)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.sageTua,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LENSA AKTIF',
                    style: TextStyle(fontSize: 9, color: AppColors.teksPutih, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildTargetChip('Kamera Fisik', TargetSampleType.hardwareCamera),
              _buildTargetChip('Kupu-kupu (Satwa)', TargetSampleType.butterflyAnimal),
              _buildTargetChip('Komodo (Satwa)', TargetSampleType.komodoAnimal),
              _buildTargetChip('Cangkir Kopi (Non-Satwa)', TargetSampleType.coffeeNonAnimal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChip(String label, TargetSampleType type) {
    final isSelected = _selectedTarget == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedTarget = type;
        });
        if (type == TargetSampleType.hardwareCamera && !_isCameraInitialized) {
          _initCamera();
        } else if (type != TargetSampleType.hardwareCamera && _isCameraInitialized) {
          _disposeCamera();
        }
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

  Widget _buildValidationContractCard() {
    return Container(
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
            title: 'Validasi ai-gateway (DeepSeek Vision API)',
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

  Uint8List _getSampleTargetBytes(TargetSampleType sample) {
    switch (sample) {
      case TargetSampleType.coffeeNonAnimal:
        return SampleImages.chessboardBytes;
      case TargetSampleType.komodoAnimal:
      case TargetSampleType.butterflyAnimal:
      default:
        return SampleImages.butterflyBytes;
    }
  }
}

class MaterialAppPageRoute<T> extends MaterialPageRoute<T> {
  MaterialAppPageRoute({required super.builder});
}

class _ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

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
