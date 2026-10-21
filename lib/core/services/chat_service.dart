import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'encrypted_storage_service.dart';
import '../../features/camera/models/scan_chat_message_model.dart';
import '../../features/camera/models/scan_result_model.dart';

class ChatException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  const ChatException(this.message, {this.code = 'CHAT_ERROR', this.statusCode});

  @override
  String toString() => message;
}

class ChatQuotaExceededException extends ChatException {
  final int chatCount;
  final int chatLimit;

  const ChatQuotaExceededException(
    super.message, {
    this.chatCount = 5,
    this.chatLimit = 5,
  }) : super(code: 'QUOTA_EXCEEDED', statusCode: 429);
}

class ChatAuthException extends ChatException {
  const ChatAuthException([super.message = 'Autentikasi diperlukan untuk percakapan AI.'])
      : super(code: 'AUTH_REQUIRED', statusCode: 401);
}

class ChatReplyResult {
  final String reply;
  final int chatCount;
  final int chatLimit;

  const ChatReplyResult({
    required this.reply,
    required this.chatCount,
    required this.chatLimit,
  });

  int get remaining => (chatLimit - chatCount).clamp(0, chatLimit);
  bool get isQuotaExceeded => chatCount >= chatLimit;
}

class ChatService {
  static final ChatService instance = ChatService._internal();
  ChatService._internal();

  final _uuid = const Uuid();

  // Cache lokal demo percakapan per scanId
  final Map<String, List<ScanChatMessageModel>> _demoChats = {};
  final Map<String, int> _demoChatCounts = {};

  bool? _mockIsVerified;

  @visibleForTesting
  void setMockVerified(bool? verified) {
    _mockIsVerified = verified;
  }

  bool get isUserVerified {
    if (_mockIsVerified != null) return _mockIsVerified!;
    try {
      final demoSetting = EncryptedStorageService.instance.getSetting('demo_verified_active');
      if (demoSetting == true) return true;
    } catch (_) {}
    return false;
  }

  /// Mengambil riwayat percakapan untuk sebuah scan satwa
  Future<List<ScanChatMessageModel>> fetchChatHistory(String scanId) async {
    if (AppConfig.isDemoMode) {
      return _demoChats[scanId] ?? [];
    }

    try {
      String? accessToken;
      try {
        accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        accessToken = null;
      }

      if (accessToken == null) {
        return _demoChats[scanId] ?? [];
      }

      final response = await Supabase.instance.client
          .from('scan_chats')
          .select('*')
          .eq('scan_id', scanId)
          .order('created_at', ascending: true);

      final List<dynamic> list = response as List<dynamic>;
      final messages = list
          .map((item) => ScanChatMessageModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return messages;
    } catch (_) {
      return _demoChats[scanId] ?? [];
    }
  }

  /// Mengirim pertanyaan pengguna ke Edge Function `ai-gateway` (mode: chat)
  Future<ChatReplyResult> sendMessage({
    required String scanId,
    required String message,
    ScanResultModel? scanContext,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw const ChatException('Pertanyaan tidak boleh kosong.');
    }
    if (trimmedMessage.length > 500) {
      throw const ChatException('Pertanyaan maksimal 500 karakter.');
    }

    if (AppConfig.isDemoMode) {
      return _generateDemoChatReply(
        scanId: scanId,
        message: trimmedMessage,
        scanContext: scanContext,
      );
    }

    String? accessToken;
    try {
      accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      accessToken = null;
    }

    // Mode demo / offline tanpa kredensial Supabase
    if (accessToken == null) {
      return _generateDemoChatReply(
        scanId: scanId,
        message: trimmedMessage,
        scanContext: scanContext,
      );
    }

    final endpoint = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/ai-gateway');
    final payload = {
      'mode': 'chat',
      'scanId': scanId,
      'message': trimmedMessage,
    };

    try {
      final response = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'apikey': AppConfig.supabaseAnonKey,
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          throw const ChatException(
            'Asisten AI membutuhkan waktu terlalu lama. Silakan coba kirim kembali.',
            code: 'TIMEOUT',
            statusCode: 504,
          );
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final replyText = responseData['reply']?.toString() ?? '';
        final chatCount = (responseData['chatCount'] as num?)?.toInt() ?? 1;
        final chatLimit = (responseData['chatLimit'] as num?)?.toInt() ?? 5;

        return ChatReplyResult(
          reply: replyText,
          chatCount: chatCount,
          chatLimit: chatLimit,
        );
      } else if (response.statusCode == 429) {
        final chatCount = (responseData['chatCount'] as num?)?.toInt() ?? 5;
        final chatLimit = (responseData['chatLimit'] as num?)?.toInt() ?? 5;
        throw ChatQuotaExceededException(
          responseData['message']?.toString() ??
              'Batas kuota pertanyaan untuk scan ini telah tercapai.',
          chatCount: chatCount,
          chatLimit: chatLimit,
        );
      } else if (response.statusCode == 401) {
        throw ChatAuthException(
          responseData['message']?.toString() ??
              'Sesi autentikasi telah berakhir. Silakan masuk kembali.',
        );
      } else {
        final errorMsg = responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            'Gagal mengirim pertanyaan ke server (${response.statusCode}).';
        throw ChatException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ChatException) rethrow;
      debugPrint('ChatService network error: $e');
      throw const ChatException(
        'Sambungan ke asisten AI gagal: Periksa koneksi internet Anda.',
      );
    }
  }

  /// Simulasi balasan chat lokal cerdas untuk mode demo/luring
  ChatReplyResult _generateDemoChatReply({
    required String scanId,
    required String message,
    ScanResultModel? scanContext,
  }) {
    final currentCount = _demoChatCounts[scanId] ?? 0;
    final isVerified = isUserVerified;
    final limit = isVerified ? 10 : 5;

    if (currentCount >= limit) {
      throw ChatQuotaExceededException(
        isVerified
            ? 'Batas 10 pertanyaan (Centang Biru) untuk scan ini telah tercapai.'
            : 'Batas 5 pertanyaan demo untuk scan ini telah tercapai. Aktifkan Centang Biru untuk 10 pertanyaan.',
        chatCount: currentCount,
        chatLimit: limit,
      );
    }

    final animalName = scanContext?.name ?? 'Satwa Ini';
    final species = scanContext?.categoryOrSpecies ?? 'Fauna Tropis';
    final lowerMsg = message.toLowerCase();

    String reply;
    if (lowerMsg.contains('makan') || lowerMsg.contains('pangan') || lowerMsg.contains('diet')) {
      reply = '$animalName ($species) umumnya mengonsumsi nektar bunga, getah tanaman, atau buah-buahan yang jatuh di sekitarnya. Pola makannya mendukung proses penyerbukan vegetasi hutan tropis.';
    } else if (lowerMsg.contains('habitat') || lowerMsg.contains('tinggal') || lowerMsg.contains('wilayah')) {
      reply = 'Habitat alami $animalName mencakup kanopi hutan dataran rendah, semak belukar terbuka, hingga kebun warga yang kaya akan vegetasi berbunga dan sumber air tawar.';
    } else if (lowerMsg.contains('lindung') || lowerMsg.contains('punah') || lowerMsg.contains('iucn') || lowerMsg.contains('status')) {
      reply = 'Populasi $animalName saat ini dipantau oleh badan konservasi. Meskipun sebagian besar masih berstatus Least Concern (LC), fragmentasi habitat dan alih fungsi lahan menjadi ancaman serius bagi kelestariannya.';
    } else if (lowerMsg.contains('umur') || lowerMsg.contains('hidup') || lowerMsg.contains('siklus')) {
      reply = 'Siklus hidup $animalName melibatkan metamorfosis atau tahapan adaptasi yang ketat. Masa hidup individu dewasa di alam liar berkisar antara beberapa minggu hingga beberapa bulan tergantung ketersediaan pakan dan suhu udara.';
    } else {
      reply = 'Mengenai "$message", satwa $animalName ($species) memiliki adaptasi morfologi yang unik untuk bertahan dari predator di alam liar. Observasi lapangan Anda mencatat spesimen yang sangat menarik!';
    }

    // Catat ke demo chat
    final newCount = currentCount + 1;
    _demoChatCounts[scanId] = newCount;

    final history = _demoChats.putIfAbsent(scanId, () => []);
    history.add(ScanChatMessageModel(
      id: _uuid.v4(),
      scanId: scanId,
      role: 'user',
      content: message,
      createdAt: DateTime.now(),
    ));
    history.add(ScanChatMessageModel(
      id: _uuid.v4(),
      scanId: scanId,
      role: 'assistant',
      content: reply,
      createdAt: DateTime.now(),
    ));

    return ChatReplyResult(
      reply: reply,
      chatCount: newCount,
      chatLimit: limit,
    );
  }

  /// Reset demo chat untuk pengujian
  @visibleForTesting
  void resetDemoState() {
    _demoChats.clear();
    _demoChatCounts.clear();
    _mockIsVerified = null;
  }
}
