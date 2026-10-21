// ==============================================================================
// FAUNOVA WIDGET: CurrencyConverterCard
// Menampilkan estimasi harga langganan Centang Biru dalam 3 mata uang (IDR, USD, JPY)
// dengan cache Hive terenkripsi (Plan 78, 127, 418, 562 & AGENTS.md Sesi S12)
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/app_colors.dart';

class CurrencyConverterCard extends StatefulWidget {
  final int baseAmountIdr;

  const CurrencyConverterCard({
    super.key,
    this.baseAmountIdr = CurrencyService.blueBadgePriceIdr,
  });

  @override
  State<CurrencyConverterCard> createState() => _CurrencyConverterCardState();
}

class _CurrencyConverterCardState extends State<CurrencyConverterCard> {
  bool _isLoading = false;

  Future<void> _refreshRates() async {
    setState(() => _isLoading = true);
    try {
      await CurrencyService.instance.fetchRates(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CurrencyService.instance.isUsingCachedRates
                        ? 'Gagal menghubungi server kurs. Menggunakan data tersimpan di Hive.'
                        : 'Kurs mata uang berhasil diperbarui dan disimpan ke Hive terenkripsi.',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: CurrencyService.instance.isUsingCachedRates
                ? AppColors.emasTua
                : AppColors.sageTua,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Galat memuat kurs: $e'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySvc = CurrencyService.instance;
    final priceIdr = currencySvc.formatPrice(widget.baseAmountIdr, 'IDR');
    final priceUsd = currencySvc.formatPrice(widget.baseAmountIdr, 'USD');
    final priceJpy = currencySvc.formatPrice(widget.baseAmountIdr, 'JPY');
    final lastUpdated = currencySvc.getLastUpdatedLabel();
    final isCached = currencySvc.isUsingCachedRates;

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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.emas,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.currency_exchange_rounded, color: AppColors.teksGelap, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimasi Kurs Centang Biru',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Harga tampil dalam 3 mata uang (IDR, USD, JPY)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _isLoading ? null : _refreshRates,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageTua),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 14, color: AppColors.sageTua),
                            SizedBox(width: 4),
                            Text(
                              'Perbarui',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sageTua,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Kartu Mata Uang
          Row(
            children: [
              // 1. IDR (Resmi)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.sageTua.withValues(alpha: 0.5), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sageTua.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.sageTua.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'IDR (Resmi)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.sageTua,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        priceIdr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '/ 30 Hari',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. USD (Estimasi)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gading,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.sage.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.sageMuda.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'USD (Est.)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teksGelap,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        priceUsd,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '/ 30 Hari',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. JPY (Estimasi)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gading,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.sage.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.sageMuda.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'JPY (Est.)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teksGelap,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        priceJpy,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '/ 30 Hari',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer info status enkripsi & Midtrans rule
          Row(
            children: [
              Icon(
                isCached ? Icons.offline_pin_rounded : Icons.lock_outline_rounded,
                size: 13,
                color: AppColors.sageTua,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Cache Hive Terenkripsi • Diperbarui: $lastUpdated',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teksGelap.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '* Aturan Transaksi: Transaksi pembayaran Midtrans selalu diproses dalam IDR. Nilai USD dan JPY adalah estimasi kurs real-time.',
            style: TextStyle(
              fontSize: 9.5,
              fontStyle: FontStyle.italic,
              color: AppColors.teksGelap.withValues(alpha: 0.65),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
