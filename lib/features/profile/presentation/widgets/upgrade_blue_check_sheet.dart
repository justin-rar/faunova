// ==============================================================================
// FAUNOVA WIDGET: UpgradeBlueCheckSheet
// Lembar langganan Centang Biru bulanan via Midtrans Sandbox (Plan 5.4, Plan 118-133)
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../midtrans_snap_webview_page.dart';
import '../../models/payment_transaction_model.dart';

class UpgradeBlueCheckSheet extends StatefulWidget {
  final VoidCallback? onSubscriptionUpdated;

  const UpgradeBlueCheckSheet({
    super.key,
    this.onSubscriptionUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSubscriptionUpdated,
    VoidCallback? onUpdated,
  }) async {
    final callback = onSubscriptionUpdated ?? onUpdated;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradeBlueCheckSheet(onSubscriptionUpdated: callback),
    );
  }

  @override
  State<UpgradeBlueCheckSheet> createState() => _UpgradeBlueCheckSheetState();
}

class _UpgradeBlueCheckSheetState extends State<UpgradeBlueCheckSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingPayment = false;
  List<PaymentTransactionModel> _transactions = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await PaymentService.instance.getMyTransactions();
    if (mounted) {
      setState(() {
        _transactions = history;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _handleProceedPayment() async {
    if (_isLoadingPayment) return;

    setState(() => _isLoadingPayment = true);

    try {
      final result = await PaymentService.instance.createBlueCheckPayment();

      if (!mounted) return;
      setState(() => _isLoadingPayment = false);

      if (result.success && result.redirectUrl != null && result.orderId != null) {
        if (!mounted) return;
        final paymentSuccess = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => MidtransSnapWebViewPage(
              orderId: result.orderId!,
              redirectUrl: result.redirectUrl!,
              amountIdr: result.amountIdr,
            ),
          ),
        );

        if (paymentSuccess == true && mounted) {
          // Refresh profil
          await ProfileService.instance.getMyProfile();
          if (!mounted) return;
          widget.onSubscriptionUpdated?.call();
          _loadHistory();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil dikirim! Menunggu konfirmasi webhook server.'),
              backgroundColor: AppColors.sageTua,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Gagal membuat tagihan pembayaran.'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kendala transaksi: $e'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header Tab
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.sageTua,
                    unselectedLabelColor: AppColors.teksGelap.withValues(alpha: 0.6),
                    indicatorColor: AppColors.sageTua,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Langganan Centang Biru'),
                      Tab(text: 'Riwayat Pembayaran'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.teksGelap),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2DDD3)),

          // Body Tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubscriptionTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    final currencyService = CurrencyService.instance;
    final idrFormatted = currencyService.formatPrice(15000, 'IDR');
    final usdFormatted = currencyService.formatPrice(15000, 'USD');
    final jpyFormatted = currencyService.formatPrice(15000, 'JPY');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Banner Centang Biru
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E4A2C), Color(0xFF4A6E42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFF64B5F6), size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kolektor Terverifikasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Langganan Bulanan (Midtrans Sandbox)',
                          style: TextStyle(color: Color(0xFFC7D3C0), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 14),
              // Harga 3 Mata Uang (Plan 127)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    idrFormatted,
                    style: const TextStyle(
                      color: AppColors.emas,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    ' / bulan',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Estimasi Kurs: ≈ $usdFormatted  •  ≈ $jpyFormatted',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Keuntungan
        const Text(
          'Keuntungan Akun Centang Biru (Plan 5.4)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.teksGelap,
          ),
        ),
        const SizedBox(height: 12),
        _buildBenefitItem(
          icon: Icons.verified_rounded,
          iconColor: const Color(0xFF1976D2),
          title: 'Lencana Centang Biru Resmi',
          description: 'Tampil terverifikasi di samping nama akun Anda di Profil, Feed, dan komentar.',
        ),
        const SizedBox(height: 10),
        _buildBenefitItem(
          icon: Icons.chat_rounded,
          iconColor: AppColors.sageTua,
          title: 'Kuota Chat AI 10 Pertanyaan (Plan 124)',
          description: 'Dua kali lipat kapasitas tanya-jawab analitik taksonomi per hasil tangkapan satwa.',
        ),
        const SizedBox(height: 10),
        _buildBenefitItem(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFFE65100),
          title: 'Prioritas Pencarian Kolektor Teratas',
          description: 'Profil Anda diprioritaskan di barisan teratas direktori pencarian akun Faunova.',
        ),
        const SizedBox(height: 24),

        // Tombol Bayar
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoadingPayment ? null : _handleProceedPayment,
            icon: _isLoadingPayment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teksGelap),
                  )
                : const Icon(Icons.payment_rounded, size: 20),
            label: Text(
              _isLoadingPayment ? 'Membuat Transaksi...' : 'Bayar Rp 15.000 (Midtrans Sandbox)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emas,
              foregroundColor: AppColors.teksGelap,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Pembayaran sekali bayar perpanjangan manual. Tanpa auto-charge.',
            style: TextStyle(fontSize: 10.5, color: AppColors.teksGelap.withValues(alpha: 0.6)),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleUi(
                    fontSize: 12.5,
                    color: AppColors.teksGelap,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodyCompact(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.sageTua));
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.sage.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Belum ada riwayat pembayaran.',
              style: AppTypography.bodyMedium(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isSuccess = tx.isSuccess;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tx.orderId,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleUi(
                        fontSize: 12,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? AppColors.sageTua.withValues(alpha: 0.15)
                          : const Color(0xFFFF8A80).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tx.statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? AppColors.sageTua : AppColors.merahStatus,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rp ${tx.amountIdr.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teksGelap,
                    ),
                  ),
                  Text(
                    tx.createdAt != null
                        ? '${tx.createdAt!.day}/${tx.createdAt!.month}/${tx.createdAt!.year}'
                        : '-',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.teksGelap.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
