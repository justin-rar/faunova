import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'compass_heading_service.dart';

class LocationReadingResult {
  final double? latitude;
  final double? longitude;
  final bool? isMock;
  final String statusDescription;

  const LocationReadingResult({
    this.latitude,
    this.longitude,
    this.isMock,
    required this.statusDescription,
  });

  bool get hasValidCoordinates => latitude != null && longitude != null;
}

class SensorLocationService {
  static final SensorLocationService instance = SensorLocationService._internal();
  SensorLocationService._internal();

  StreamSubscription<CompassEvent>? _compassSubscription;
  double? _latestHeading;

  /// Inisialisasi pendengar sensor kompas
  void startCompassListener() {
    try {
      if (FlutterCompass.events != null) {
        _compassSubscription?.cancel();
        _compassSubscription = FlutterCompass.events!.listen((event) {
          if (event.heading != null) {
            _latestHeading = CompassHeadingService.normalizeHeading(event.heading!);
          }
        }, onError: (e) {
          debugPrint('Compass listener error: $e');
        });
      }
    } catch (e) {
      debugPrint('Compass hardware not available: $e');
    }
  }

  /// Berhenti mendengarkan kompas
  void stopCompassListener() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  /// Dapatkan heading kompas saat ini (atau fallback null jika sensor tidak tersedia)
  double? get currentHeading => _latestHeading;

  /// Membaca koordinat lokasi terkini secara aman
  /// Sesuai aturan Plan 5.10: jika izin ditolak / GPS mati, kembalikan NULL
  /// Jangan pernah mengganti NULL dengan (0,0)
  Future<LocationReadingResult> readCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationReadingResult(
          latitude: null,
          longitude: null,
          isMock: null,
          statusDescription: 'Layanan lokasi (GPS) nonaktif',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationReadingResult(
            latitude: null,
            longitude: null,
            isMock: null,
            statusDescription: 'Izin lokasi ditolak oleh pengguna',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationReadingResult(
          latitude: null,
          longitude: null,
          isMock: null,
          statusDescription: 'Izin lokasi ditolak permanen di pengaturan',
        );
      }

      // Ambil posisi dengan batas waktu 5 detik agar tidak memblokir UI rana
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      // Validasi rentang koordinat bumi
      final lat = position.latitude;
      final lng = position.longitude;
      if (lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) {
        return const LocationReadingResult(
          latitude: null,
          longitude: null,
          isMock: null,
          statusDescription: 'Koordinat di luar batas valid bumi',
        );
      }

      final isMock = position.isMocked;

      return LocationReadingResult(
        latitude: lat,
        longitude: lng,
        isMock: isMock,
        statusDescription: isMock
            ? 'Lokasi palsu (Mock Location) terdeteksi'
            : 'GPS Terkunci Presisi',
      );
    } catch (e) {
      debugPrint('SensorLocationService read error: $e');
      return LocationReadingResult(
        latitude: null,
        longitude: null,
        isMock: null,
        statusDescription: 'Gagal membaca sensor lokasi: $e',
      );
    }
  }
}
