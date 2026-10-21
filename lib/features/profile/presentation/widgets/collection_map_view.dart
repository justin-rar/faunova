// ==============================================================================
// FAUNOVA WIDGET: CollectionMapView
// Peta persebaran koleksi satwa pengguna berbasis OpenStreetMap (flutter_map)
// Sesuai Plan 5.7 & AGENTS.md (Sesi S8)
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../camera/models/capture_model.dart';
import '../capture_detail_page.dart';

class CollectionMapView extends StatefulWidget {
  final List<CaptureModel> captures;
  final double height;

  const CollectionMapView({
    super.key,
    required this.captures,
    this.height = 380,
  });

  @override
  State<CollectionMapView> createState() => _CollectionMapViewState();
}

class _CollectionMapViewState extends State<CollectionMapView> {
  final MapController _mapController = MapController();
  CaptureModel? _selectedCapture;

  List<CaptureModel> get _validCaptures => widget.captures
      .where((c) => c.latitude != null && c.longitude != null)
      .toList();

  LatLng _calculateInitialCenter() {
    final valid = _validCaptures;
    if (valid.isEmpty) {
      // Titik tengah kepulauan Indonesia (Nusantara)
      return const LatLng(-0.7893, 113.9213);
    }
    // Titik tangkapan terbaru
    return LatLng(valid.first.latitude!, valid.first.longitude!);
  }

  double _calculateInitialZoom() {
    final valid = _validCaptures;
    if (valid.isEmpty) return 4.5;
    if (valid.length == 1) return 13.0;
    return 6.0;
  }

  Future<void> _openGoogleMaps(CaptureModel capture) async {
    if (capture.latitude == null || capture.longitude == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${capture.latitude},${capture.longitude}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka Google Maps: $e'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = _validCaptures;

    if (valid.isEmpty) {
      return Container(
        height: 220,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sageMuda.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_rounded, size: 36, color: AppColors.sageTua),
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum Ada Titik Koordinat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tangkapan Anda belum memiliki metadata GPS. Aktifkan izin lokasi saat memotret satwa.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.teksGelap.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Map OpenStreetMap via flutter_map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _calculateInitialCenter(),
                initialZoom: _calculateInitialZoom(),
                minZoom: 3,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.faunova.app',
                ),
                MarkerLayer(
                  markers: valid.map((capture) {
                    final isSelected = _selectedCapture?.id == capture.id;
                    return Marker(
                      point: LatLng(capture.latitude!, capture.longitude!),
                      width: isSelected ? 48 : 40,
                      height: isSelected ? 48 : 40,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCapture = capture;
                          });
                          _mapController.move(
                            LatLng(capture.latitude!, capture.longitude!),
                            14.0,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.emas : AppColors.sageTua,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 2.5 : 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '#${capture.seq}',
                              style: TextStyle(
                                fontSize: isSelected ? 12 : 10.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? AppColors.teksGelap : AppColors.teksPutih,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Top-left badge: Total Spot
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.sageTua.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_rounded, color: AppColors.emas, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '${valid.length} Lokasi Terpetakan',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Zoom & Control buttons (Top Right)
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  _buildMapCircleButton(
                    icon: Icons.add_rounded,
                    onTap: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom + 1);
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildMapCircleButton(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom - 1);
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildMapCircleButton(
                    icon: Icons.my_location_rounded,
                    onTap: () {
                      _mapController.move(_calculateInitialCenter(), _calculateInitialZoom());
                    },
                  ),
                ],
              ),
            ),

            // Selected Marker Floating Popup Card (Bottom)
            if (_selectedCapture != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: _buildSelectedCard(_selectedCapture!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.teksGelap, size: 18),
        ),
      ),
    );
  }

  Widget _buildSelectedCard(CaptureModel capture) {
    Widget imageThumbnail;
    if (capture.photoObjectPath.isNotEmpty && File(capture.photoObjectPath).existsSync()) {
      imageThumbnail = Image.file(
        File(capture.photoObjectPath),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
      );
    } else {
      imageThumbnail = Container(
        width: 56,
        height: 56,
        color: AppColors.sageMuda,
        child: const Icon(Icons.pets_rounded, color: AppColors.sageTua, size: 28),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageThumbnail,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.emas,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${capture.seq}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        capture.speciesName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teksGelap,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (capture.category != null && capture.category!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    capture.category!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.emasTua,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.pin_drop_rounded, size: 12, color: AppColors.sageTua),
                    const SizedBox(width: 3),
                    Text(
                      '${capture.latitude!.toStringAsFixed(4)}, ${capture.longitude!.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.teksGelap.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.teksGelap),
                onPressed: () {
                  setState(() {
                    _selectedCapture = null;
                  });
                },
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _openGoogleMaps(capture),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.sageMuda.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.map_rounded, size: 16, color: AppColors.sageTua),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CaptureDetailPage(capture: capture),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.sageTua,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Detail',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teksPutih,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
