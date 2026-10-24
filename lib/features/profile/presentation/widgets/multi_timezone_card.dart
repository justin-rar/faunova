// ==============================================================================
// FAUNOVA WIDGET: MultiTimeZoneCard
// Menampilkan konversi waktu simultan dalam 4 zona: WIB, WITA, WIT, dan London
// Sesuai Plan 40, 136, 318 & AGENTS.md (Sesi S12)
// ==============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/timezone_service.dart';
import '../../../../core/theme/app_colors.dart';

class MultiTimeZoneCard extends StatefulWidget {
  /// Waktu spesifik yang akan dikonversi (misal `received_at` server).
  /// Jika null, kartu akan menampilkan jam hidup (real-time clock) saat ini.
  final DateTime? targetTime;
  final String title;
  final String subtitle;

  const MultiTimeZoneCard({
    super.key,
    this.targetTime,
    this.title = 'Waktu Observasi 4 Zona',
    this.subtitle = 'Konversi otomatis WIB, WITA, WIT, dan London (BST/GMT)',
  });

  @override
  State<MultiTimeZoneCard> createState() => _MultiTimeZoneCardState();
}

class _MultiTimeZoneCardState extends State<MultiTimeZoneCard> {
  Timer? _liveTimer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.targetTime ?? DateTime.now();
    if (widget.targetTime == null) {
      _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _currentTime = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MultiTimeZoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetTime != oldWidget.targetTime) {
      _currentTime = widget.targetTime ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zones = TimeZoneService.getAllZones(_currentTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageMuda.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.sageTua,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.teksGelap.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.targetTime == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.sageTua.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sageTua.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: AppColors.sageTua, size: 7),
                      SizedBox(width: 5),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sageTua,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Grid 2x2 kartu zona waktu (tanpa padding implisit status bar)
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: zones.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final zone = zones[index];
              final isPrimaryWib = zone.code == TimeZoneCode.wib;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPrimaryWib ? Colors.white : AppColors.gading,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPrimaryWib
                        ? AppColors.sageTua.withValues(alpha: 0.45)
                        : AppColors.sage.withValues(alpha: 0.2),
                    width: isPrimaryWib ? 1.4 : 1.0,
                  ),
                  boxShadow: isPrimaryWib
                      ? [
                          BoxShadow(
                            color: AppColors.sageTua.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          zone.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isPrimaryWib ? AppColors.sageTua : AppColors.teksGelap,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isPrimaryWib
                                ? AppColors.sageTua.withValues(alpha: 0.12)
                                : AppColors.sageMuda.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            zone.offsetLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isPrimaryWib ? AppColors.sageTua : AppColors.teksGelap,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      zone.formattedTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isPrimaryWib ? AppColors.sageTua : AppColors.teksGelap,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            zone.formattedDate,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.teksGelap.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (zone.isDaylightSaving)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.emas.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DST',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emasTua,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
