// ==============================================================================
// FAUNOVA PRESENTATION: MidtransSnapWebViewPage
// Halaman WebView Snap Midtrans Sandbox untuk langganan Centang Biru (Plan 249, Hard Rule 6)
// ==============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_colors.dart';

class MidtransSnapWebViewPage extends StatefulWidget {
  final String orderId;
  final String redirectUrl;
  final int amountIdr;

  const MidtransSnapWebViewPage({
    super.key,
    required this.orderId,
    required this.redirectUrl,
    this.amountIdr = 15000,
  });

  @override
  State<MidtransSnapWebViewPage> createState() => _MidtransSnapWebViewPageState();
}

class _MidtransSnapWebViewPageState extends State<MidtransSnapWebViewPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String? _errorMessage;

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (!_isTestEnvironment && !kIsWeb) {
      _initWebView();
    }
  }

  void _initWebView() {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress / 100.0;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              final errUrl = error.url?.toLowerCase() ?? '';
              if (errUrl.startsWith('blob:') || errUrl.startsWith('data:')) {
                // Abaikan error dari navigasi blob saat mengunduh gambar QRIS di webview
                return;
              }

              // Jika error terjadi karena redirect URL Midtrans (misal http://example.com dengan status_code 200/settlement)
              if (errUrl.contains('transaction_status=settlement') ||
                  errUrl.contains('transaction_status=capture') ||
                  errUrl.contains('status_code=200') ||
                  errUrl.contains('success') ||
                  errUrl.contains('finish') ||
                  errUrl.contains('example.com')) {
                debugPrint('Intercepted settlement redirect in web error: $errUrl');
                _handlePaymentCompletion(true);
                return;
              }

              if (mounted) {
                setState(() {
                  _errorMessage = error.description;
                  _isLoading = false;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url.toLowerCase();
              debugPrint('Midtrans WebView navigating to: $url');

              // Cegah navigasi ke blob: URL (misal tombol Download QRIS) agar WebView tidak memicu net::ERR_FILE_NOT_FOUND
              if (url.startsWith('blob:') || url.startsWith('data:')) {
                return NavigationDecision.prevent;
              }

              // Intersep redirect status penyelesaian pembayaran dari Midtrans
              // Midtrans Sandbox sering me-redirect ke default http://example.com/?order_id=...&status_code=200&transaction_status=settlement
              if (url.contains('transaction_status=settlement') ||
                  url.contains('transaction_status=capture') ||
                  url.contains('status_code=200') ||
                  url.contains('finish') ||
                  url.contains('success') ||
                  url.contains('payment-success')) {
                debugPrint('Intercepted payment success navigation: $url');
                _handlePaymentCompletion(true);
                return NavigationDecision.prevent;
              } else if (url.contains('unfinish') ||
                         url.contains('transaction_status=deny') ||
                         url.contains('transaction_status=expire') ||
                         url.contains('transaction_status=cancel') ||
                         url.contains('cancel')) {
                _handlePaymentCompletion(false, reason: 'Pembayaran belum diselesaikan atau dibatalkan.');
                return NavigationDecision.prevent;
              } else if (url.contains('example.com')) {
                // Default callback sandbox Midtrans
                debugPrint('Intercepted example.com callback navigation: $url');
                _handlePaymentCompletion(true);
                return NavigationDecision.prevent;
              } else if (url.contains('error')) {
                _handlePaymentCompletion(false, reason: 'Terjadi kendala pada gateway pembayaran.');
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.redirectUrl));

      _controller = controller;
    } catch (e) {
      debugPrint('WebView initialization error: $e');
      _errorMessage = 'Tidak dapat memuat komponen webview: $e';
    }
  }

  /// Menangani penyelesaian di sisi klien.
  /// CATATAN KERAS ATURAN 6: Halaman redirect TIDAK BOLEH mengaktifkan Centang Biru langsung.
  /// Server webhook yang memverifikasi signature key adalah satu-satunya otoritas.
  void _handlePaymentCompletion(bool success, {String? reason}) {
    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.gading,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.sageTua, size: 26),
              SizedBox(width: 10),
              Text(
                'Pembayaran Terkirim',
                style: TextStyle(
                  color: AppColors.teksGelap,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaksi ${widget.orderId} sedang diverifikasi oleh server Faunova via Midtrans Webhook.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.teksGelap),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security_rounded, size: 16, color: AppColors.sageTua),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Masa aktif Centang Biru akan diperbarui otomatis setelah signature divalidasi server.',
                        style: TextStyle(fontSize: 10.5, color: AppColors.teksGelap),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emas,
                foregroundColor: AppColors.teksGelap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Kembali ke Profil', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason ?? 'Transaksi dibatalkan.'),
          backgroundColor: AppColors.merahStatus,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.sageTua,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Midtrans Sandbox Payment',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'Order: ${widget.orderId}',
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.gading,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: AppColors.emasTua, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Simulasi Bayar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Simulasikan pembayaran sukses untuk pesanan ${widget.orderId}? Server Supabase akan memproses transaksi ini via RPC settlement.',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.teksGelap),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emas,
                        foregroundColor: AppColors.teksGelap,
                      ),
                      child: const Text('Bayar Sukses'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await PaymentService.instance.simulateWebhookSettlement(widget.orderId);
                _handlePaymentCompletion(true);
              }
            },
            icon: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.emas),
            label: const Text(
              'Simulasi',
              style: TextStyle(
                color: AppColors.emas,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
        bottom: _isLoading && _loadingProgress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: AppColors.sage,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emas),
                ),
              )
            : null,
      ),
      body: _isTestEnvironment || kIsWeb || _controller == null
          ? _buildSandboxSimulator()
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.merahStatus),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat gateway pembayaran: $_errorMessage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.teksGelap),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _initWebView(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emas,
                              foregroundColor: AppColors.teksGelap,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSandboxSimulator() {
    return Container(
      color: AppColors.gading,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.sageMuda),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sageTua.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: AppColors.sageTua,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Simulator Midtrans Snap Sandbox',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teksGelap,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Order ID: ${widget.orderId}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.teksGelap.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran:', style: TextStyle(fontSize: 12)),
                    Text(
                      'Rp ${widget.amountIdr.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sageTua,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Simulasi pembayaran sukses di sandbox
                    await PaymentService.instance.simulateWebhookSettlement(widget.orderId);
                    _handlePaymentCompletion(true);
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text(
                    'Simulasi Bayar Berhasil (Sandbox)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emas,
                    foregroundColor: AppColors.teksGelap,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _handlePaymentCompletion(false, reason: 'Pembayaran dibatalkan.'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.merahStatus,
                  side: const BorderSide(color: AppColors.merahStatus),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Batalkan Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
