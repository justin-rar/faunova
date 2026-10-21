import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/services/chat_service.dart';
import '../models/scan_chat_message_model.dart';
import '../models/scan_result_model.dart';

class ScanChatPage extends StatefulWidget {
  final ScanResultModel scanResult;

  const ScanChatPage({
    super.key,
    required this.scanResult,
  });

  @override
  State<ScanChatPage> createState() => _ScanChatPageState();
}

class _ScanChatPageState extends State<ScanChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService.instance;

  List<ScanChatMessageModel> _messages = [];
  bool _isLoadingHistory = true;
  bool _isSending = false;
  String? _errorMessage;

  // Kuota
  int _chatCount = 0;
  int _chatLimit = 5;

  // Pertanyaan cepat yang disarankan
  final List<String> _quickSuggestions = const [
    'Apa makanan utama satwa ini?',
    'Di mana habitat alami satwa ini?',
    'Apakah satwa ini termasuk dilindungi?',
    'Bagaimana siklus hidup satwa ini?',
    'Apa keunikan adaptasi satwa ini?',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _errorMessage = null;
    });

    try {
      final history = await _chatService.fetchChatHistory(widget.scanResult.scanId);
      if (mounted) {
        setState(() {
          _messages = history;
          // Hitung pertanyaan user yang sudah diajukan
          _chatCount = history.where((m) => m.isUser).length;
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? predefinedText]) async {
    final text = (predefinedText ?? _textController.text).trim();
    if (text.isEmpty || _isSending) return;

    if (_chatCount >= _chatLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Batas $_chatLimit pertanyaan telah tercapai untuk scan ini.',
          ),
          backgroundColor: AppColors.merahStatus,
        ),
      );
      return;
    }

    _textController.clear();
    FocusScope.of(context).unfocus();

    final userMsg = ScanChatMessageModel(
      id: 'local-user-${DateTime.now().millisecondsSinceEpoch}',
      scanId: widget.scanResult.scanId,
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final result = await _chatService.sendMessage(
        scanId: widget.scanResult.scanId,
        message: text,
        scanContext: widget.scanResult,
      );

      final assistantMsg = ScanChatMessageModel(
        id: 'local-assistant-${DateTime.now().millisecondsSinceEpoch}',
        scanId: widget.scanResult.scanId,
        role: 'assistant',
        content: result.reply,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(assistantMsg);
          _chatCount = result.chatCount;
          _chatLimit = result.chatLimit;
          _isSending = false;
        });
        _scrollToBottom();
      }
    } on ChatQuotaExceededException catch (e) {
      if (mounted) {
        setState(() {
          _chatCount = e.chatCount;
          _chatLimit = e.chatLimit;
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final animalName = widget.scanResult.name ?? 'Satwa Observasi';
    final species = widget.scanResult.categoryOrSpecies ?? '';
    final remainingQuestions = (_chatLimit - _chatCount).clamp(0, _chatLimit);
    final isQuotaFull = _chatCount >= _chatLimit;

    return Scaffold(
      backgroundColor: AppColors.gading,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksPutih),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Tanya AI: $animalName',
          style: const TextStyle(
            color: AppColors.teksPutih,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isQuotaFull
                      ? AppColors.merahStatus.withValues(alpha: 0.15)
                      : AppColors.emas.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isQuotaFull ? AppColors.merahStatus : AppColors.emasTua,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isQuotaFull ? Icons.lock_clock_rounded : Icons.bolt_rounded,
                      size: 13,
                      color: isQuotaFull ? AppColors.merahStatus : AppColors.emasTua,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$remainingQuestions/$_chatLimit Sisa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isQuotaFull ? AppColors.merahStatus : AppColors.emasTua,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner Ringkasan Konteks Satwa Lapangan
            _buildContextBanner(animalName, species, remainingQuestions, isQuotaFull),

            // Konten Percakapan (Loading, Error, Empty, atau Daftar Pesan)
            Expanded(
              child: _buildChatBody(),
            ),

            // Suggestion Chips (Tampil jika belum melampaui kuota)
            if (!isQuotaFull) _buildQuickSuggestions(),

            // Bilah Input Teks & Tombol Kirim
            _buildInputBar(isQuotaFull),
          ],
        ),
      ),
    );
  }

  Widget _buildContextBanner(
    String name,
    String species,
    int remaining,
    bool isFull,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sageMuda.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.sageTua.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: AppColors.sageTua,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teksGelap,
                  ),
                ),
                if (species.isNotEmpty)
                  Text(
                    species,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.teksGelap.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isFull
                  ? AppColors.merahStatus.withValues(alpha: 0.12)
                  : AppColors.sageTua.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isFull ? 'Kuota Habis' : 'AI Terkalibrasi',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isFull ? AppColors.merahStatus : AppColors.sageTua,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody() {
    if (_isLoadingHistory) {
      return const Center(
        child: AppStateView(
          status: AppViewStatus.loading,
          loadingMessage: 'Memuat riwayat percakapan...',
          child: SizedBox.shrink(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: AppStateView(
          status: AppViewStatus.error,
          errorMessage: 'Gagal memuat riwayat: $_errorMessage',
          onRetry: _loadHistory,
          retryLabel: 'Coba Lagi',
          child: SizedBox.shrink(),
        ),
      );
    }

    if (_messages.isEmpty && !_isSending) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return _buildThinkingBubble();
        }
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.sageMuda.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 38,
                color: AppColors.sageTua,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tanya Naturalis AI Faunova',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajukan pertanyaan ilmiah seputar ciri fisik, kebiasaan hidup, atau status konservasi satwa hasil observasi ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.teksGelap.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickSuggestions.take(3).map((suggestion) {
                return ActionChip(
                  label: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teksGelap,
                    ),
                  ),
                  backgroundColor: AppColors.sageMuda,
                  side: BorderSide(
                    color: AppColors.sageTua.withValues(alpha: 0.3),
                  ),
                  onPressed: () => _handleSendMessage(suggestion),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ScanChatMessageModel message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.sageTua,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? AppColors.sageTua : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: AppColors.sageTua.withValues(alpha: 0.15),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: isUser ? Colors.white : AppColors.teksGelap,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.teksGelap.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 4),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.sageTua,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: AppColors.sageTua.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.sageTua),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Asisten AI sedang menyusun jawaban...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.teksGelap.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _quickSuggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              visualDensity: VisualDensity.compact,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              label: Text(
                suggestion,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teksGelap,
                ),
              ),
              backgroundColor: AppColors.sageMuda.withValues(alpha: 0.7),
              side: BorderSide(
                color: AppColors.sageTua.withValues(alpha: 0.25),
              ),
              onPressed: _isSending ? null : () => _handleSendMessage(suggestion),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(bool isQuotaFull) {
    if (isQuotaFull) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.sageTua.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 18,
              color: AppColors.merahStatus,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Batas $_chatLimit pertanyaan telah tercapai untuk hasil scan ini.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.merahStatus,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.sageTua.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSendMessage(),
              decoration: InputDecoration(
                hintText: 'Tanyakan sesuatu tentang satwa ini...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.teksGelap.withValues(alpha: 0.5),
                ),
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: AppColors.gading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: AppColors.sageTua.withValues(alpha: 0.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: AppColors.sageTua,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.emas,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.teksGelap),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: AppColors.teksGelap,
                      size: 20,
                    ),
              onPressed: _isSending ? null : () => _handleSendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }
}
