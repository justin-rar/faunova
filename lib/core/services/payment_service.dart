// ==============================================================================
// FAUNOVA SERVICE: PaymentService
// Integrasi Midtrans Sandbox untuk langganan Centang Biru bulanan (Rp 15.000)
// Sesuai Plan 5.4 (118-133), Plan 304, Plan 444, Plan 550 & AGENTS.md (Aturan Keras 1, 2, 6)
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/payment_transaction_model.dart';
import '../config/app_config.dart';
import 'encrypted_storage_service.dart';

class PaymentCreationResult {
  final bool success;
  final String? orderId;
  final String? token;
  final String? redirectUrl;
  final int amountIdr;
  final String? errorMessage;

  const PaymentCreationResult({
    required this.success,
    this.orderId,
    this.token,
    this.redirectUrl,
    this.amountIdr = 15000,
    this.errorMessage,
  });

  String? get snapToken => token;
}

class PaymentService {
  static final PaymentService instance = PaymentService._internal();
  PaymentService._internal();

  static const int blueCheckPriceIdr = 15000;

  SupabaseClient? _client;

  @visibleForTesting
  void setMockClient(SupabaseClient client) {
    _client = client;
  }

  SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory transaction records for demo/test mode
  final List<PaymentTransactionModel> _demoTransactions = [];

  @visibleForTesting
  void resetDemoTransactions() {
    _demoTransactions.clear();
  }

  /// Membuat transaksi baru dan meminta Snap Token dari Edge Function create-payment
  Future<PaymentCreationResult> createBlueCheckPayment() async {
    final client = _supabase;

    // Jika Supabase terkonfigurasi dan user sudah login
    if (client != null &&
        AppConfig.isSupabaseConfigured &&
        AppConfig.isSupabaseInitialized &&
        client.auth.currentSession != null) {
      try {
        final res = await client.functions.invoke(
          'create-payment',
          headers: {
            'Authorization': 'Bearer ${client.auth.currentSession?.accessToken}',
          },
        );

        if (res.status == 200 && res.data is Map<String, dynamic>) {
          final data = res.data as Map<String, dynamic>;
          final orderId = data['orderId'] as String?;
          final token = data['token'] as String?;
          final redirectUrl = data['redirectUrl'] as String?;

          return PaymentCreationResult(
            success: true,
            orderId: orderId,
            token: token,
            redirectUrl: redirectUrl,
            amountIdr: (data['amountIdr'] as num?)?.toInt() ?? blueCheckPriceIdr,
          );
        } else {
          final errMsg = res.data is Map ? res.data['message'] ?? res.data['error'] : 'Gagal membuat transaksi.';
          return PaymentCreationResult(
            success: false,
            errorMessage: errMsg?.toString() ?? 'Gagal membuat token pembayaran.',
          );
        }
      } catch (e) {
        debugPrint('PaymentService createBlueCheckPayment error: $e');
        return PaymentCreationResult(
          success: false,
          errorMessage: 'Terjadi kendala jaringan saat menghubungi payment gateway: $e',
        );
      }
    }

    // Fallback mode demo / testing deterministik
    final demoOrderId = 'FAUNOVA-CB-DEMO-${DateTime.now().millisecondsSinceEpoch}';
    const demoToken = 'mock_snap_token_sandbox_faunova_123';
    const demoRedirectUrl = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/mock_snap_token_sandbox_faunova_123';

    final demoTx = PaymentTransactionModel(
      id: demoOrderId,
      orderId: demoOrderId,
      amountIdr: blueCheckPriceIdr,
      status: 'pending',
      snapToken: demoToken,
      redirectUrl: demoRedirectUrl,
      createdAt: DateTime.now(),
    );

    _demoTransactions.insert(0, demoTx);

    return PaymentCreationResult(
      success: true,
      orderId: demoOrderId,
      token: demoToken,
      redirectUrl: demoRedirectUrl,
      amountIdr: blueCheckPriceIdr,
    );
  }

  /// Mengambil riwayat transaksi pembayaran pengguna
  Future<List<PaymentTransactionModel>> getMyTransactions() async {
    final client = _supabase;

    if (client != null &&
        AppConfig.isSupabaseConfigured &&
        AppConfig.isSupabaseInitialized &&
        client.auth.currentSession != null) {
      try {
        final res = await client.rpc('get_my_transactions');
        if (res is List) {
          final list = res
              .map((item) => PaymentTransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          return list;
        }
      } catch (e) {
        debugPrint('PaymentService getMyTransactions error: $e');
      }
    }

    // Fallback demo/luring
    if (_demoTransactions.isEmpty) {
      _demoTransactions.add(
        PaymentTransactionModel(
          id: 'FAUNOVA-CB-PREV-001',
          orderId: 'FAUNOVA-CB-PREV-001',
          amountIdr: 15000,
          status: 'settlement',
          createdAt: DateTime.now().subtract(const Duration(days: 32)),
          processedAt: DateTime.now().subtract(const Duration(days: 32)),
          entitlementDays: 30,
        ),
      );
    }

    return List.unmodifiable(_demoTransactions);
  }

  /// Memeriksa status transaksi terkini dari server
  Future<PaymentTransactionModel?> checkTransactionStatus(String orderId) async {
    final client = _supabase;

    if (client != null &&
        AppConfig.isSupabaseConfigured &&
        AppConfig.isSupabaseInitialized) {
      try {
        final res = await client
            .from('transactions')
            .select()
            .eq('order_id', orderId)
            .maybeSingle();

        if (res != null) {
          return PaymentTransactionModel.fromJson(Map<String, dynamic>.from(res));
        }
      } catch (e) {
        debugPrint('PaymentService checkTransactionStatus error: $e');
      }
    }

    // Fallback mode demo
    try {
      return _demoTransactions.firstWhere((tx) => tx.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  /// Simulasi verifikasi sukses webhook (berguna untuk demo & testing)
  Future<bool> simulateWebhookSettlement(String orderId) async {
    final client = _supabase;

    if (client != null &&
        AppConfig.isSupabaseConfigured &&
        AppConfig.isSupabaseInitialized) {
      try {
        final res = await client.rpc('process_midtrans_settlement', params: {
          'p_order_id': orderId,
          'p_provider_tx_id': 'sandbox_tx_${DateTime.now().millisecondsSinceEpoch}',
          'p_provider_status': 'settlement',
          'p_gross_amount': blueCheckPriceIdr,
        });

        if (res is Map && res['success'] == true) {
          return true;
        }
      } catch (e) {
        debugPrint('simulateWebhookSettlement RPC error: $e');
      }
    }

    // Demo update
    final index = _demoTransactions.indexWhere((tx) => tx.orderId == orderId);
    if (index != -1) {
      final old = _demoTransactions[index];
      _demoTransactions[index] = PaymentTransactionModel(
        id: old.id,
        orderId: old.orderId,
        amountIdr: old.amountIdr,
        status: 'settlement',
        snapToken: old.snapToken,
        redirectUrl: old.redirectUrl,
        createdAt: old.createdAt,
        processedAt: DateTime.now(),
        entitlementDays: old.entitlementDays,
      );
      // Simpan status verified lokal di storage
      await EncryptedStorageService.instance.saveSetting('demo_verified_active', true);
      return true;
    }

    return false;
  }
}
