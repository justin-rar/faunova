import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/services/compass_heading_service.dart';
import '../../../core/services/image_processing_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/scan_service.dart';
import '../../../core/services/sensor_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_app_bar.dart';
import 'scan_result_page.dart';

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

  // Flash mode state
  FlashMode _currentFlashMode = FlashMode.off;

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
      // Masuk ke tab kamera -> aktifkan sensor dan kamera
      _initSensorsAndCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      // Keluar dari tab kamera -> matikan kamera agar hemat baterai & resource
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
    } else if (state == AppLifecycleState.resumed) {
      _initSensorsAndCamera();
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

    // 2. Hardware Camera Fisik Langsung
    await _initCamera();
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
      case FlashMode.off:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
      case FlashMode.always:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await _cameraController!.setFlashMode(nextMode);
      if (mounted) {
        setState(() {
          _currentFlashMode = nextMode;
        });
      }
    } catch (e) {
      debugPrint('Failed to set flash mode $nextMode: $e');
      if (nextMode == FlashMode.torch) {
        try {
          await _cameraController!.setFlashMode(FlashMode.always);
          if (mounted) {
            setState(() {
              _currentFlashMode = FlashMode.always;
            });
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _onShutterPressed() async {
    if (_isProcessingScan) return;

    setState(() {
      _isProcessingScan = true;
      _processingStageMessage = 'Menangkap citra satwa...';
    });

    try {
      if (!_isCameraInitialized || _cameraController == null) {
        setState(() {
          _isProcessingScan = false;
        });
        _showErrorDialog(
          'Lensa kamera fisik belum aktif di perangkat ini.\n\n'
          'Pastikan izin kamera diizinkan di Pengaturan HP Anda dan lensa tidak sedang digunakan aplikasi lain.',
        );
        return;
      }

      // 1. Ambil foto langsung dari kamera fisik perangkat
      final photo = await _cameraController!.takePicture();
      final localPath = photo.path;
      final rawBytes = await photo.readAsBytes();

      // 2. Baca GPS & Heading
      setState(() {
        _processingStageMessage = 'Membaca GPS & arah kompas...';
      });

      final locationResult = await SensorLocationService.instance.readCurrentLocation();
      final currentSensorHeading = SensorLocationService.instance.currentHeading ?? _cameraHeading;

      // 3. Kompresi & buang EXIF di klien
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
    return Scaffold(
      backgroundColor: AppColors.gading,
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
              _initSensorsAndCamera();
            },
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B261A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.sage.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // 1. Kamera Fisik Langsung atau Pesan Status
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

                        // 4. Optical Crosshair Reticle Tengah
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.emas.withValues(alpha: 0.7),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.filter_center_focus_rounded,
                                      size: 52,
                                      color: AppColors.emas,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _isCameraInitialized ? 'Lensa Lapangan Aktif' : 'Arahkan kamera ke satwa liar',
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
                                  (_currentFlashMode == FlashMode.torch ||
                                          _currentFlashMode == FlashMode.always)
                                      ? Icons.flash_on_rounded
                                      : _currentFlashMode == FlashMode.auto
                                          ? Icons.flash_auto_rounded
                                          : Icons.flash_off_rounded,
                                  color: _currentFlashMode == FlashMode.off
                                      ? Colors.white70
                                      : AppColors.emas,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),

                        // 6. Tombol Rana (Shutter Action Bar)
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: _onShutterPressed,
                              child: Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.emas,
                                  border: Border.all(color: AppColors.teksPutih, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.teksGelap,
                                  size: 34,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

    // Kamera fisik belum aktif / di emulator tanpa modul kamera
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
              Icons.camera_alt_outlined,
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
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arahkan kamera HP ke satwa untuk menangkap citra langsung di lapangan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.teksPutih.withValues(alpha: 0.75),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
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
