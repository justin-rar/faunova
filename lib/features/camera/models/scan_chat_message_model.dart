class ScanChatMessageModel {
  final String id;
  final String scanId;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  const ScanChatMessageModel({
    required this.id,
    required this.scanId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ScanChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ScanChatMessageModel(
      id: json['id']?.toString() ?? '',
      scanId: json['scan_id']?.toString() ?? json['scanId']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scan_id': scanId,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
