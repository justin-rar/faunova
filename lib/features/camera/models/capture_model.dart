// ==============================================================================
// FAUNOVA MODEL: CaptureModel
// Mewakili rekaman satwa yang tersimpan dalam koleksi dan rantai kanonis SHA-256
// Sesuai Plan 5.2, 5.3 & AGENTS.md (Sesi S7)
// ==============================================================================

class CaptureModel {
  final String id;
  final String? scanId;
  final String userId;
  final String photoObjectPath;
  final String speciesName;
  final String? category;
  final String description;
  final double? latitude;
  final double? longitude;
  final double? cameraHeading;
  final DateTime receivedAt;
  final int seq;
  final String previousHash;
  final String blockHash;
  final String photoSha256;
  final DateTime createdAt;

  const CaptureModel({
    required this.id,
    this.scanId,
    required this.userId,
    required this.photoObjectPath,
    required this.speciesName,
    this.category,
    this.description = '',
    this.latitude,
    this.longitude,
    this.cameraHeading,
    required this.receivedAt,
    required this.seq,
    required this.previousHash,
    required this.blockHash,
    required this.photoSha256,
    required this.createdAt,
  });

  factory CaptureModel.fromJson(Map<String, dynamic> json) {
    return CaptureModel(
      id: json['id']?.toString() ?? json['capture_id']?.toString() ?? '',
      scanId: json['scan_id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      photoObjectPath: json['photo_object_path']?.toString() ?? '',
      speciesName: json['species_name']?.toString() ?? 'Satwa Terverifikasi',
      category: json['category']?.toString(),
      description: json['description']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cameraHeading: (json['camera_heading'] as num?)?.toDouble(),
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      seq: (json['seq'] as num?)?.toInt() ?? 1,
      previousHash: json['previous_hash']?.toString() ?? '',
      blockHash: json['block_hash']?.toString() ?? '',
      photoSha256: json['photo_sha256']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scan_id': scanId,
      'user_id': userId,
      'photo_object_path': photoObjectPath,
      'species_name': speciesName,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'camera_heading': cameraHeading,
      'received_at': receivedAt.toIso8601String(),
      'seq': seq,
      'previous_hash': previousHash,
      'block_hash': blockHash,
      'photo_sha256': photoSha256,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Format potongan hash ramah UI (misal: "a1b2c3d4...9e0f")
  String get shortBlockHash {
    if (blockHash.length < 12) return blockHash;
    return '${blockHash.substring(0, 8)}...${blockHash.substring(blockHash.length - 4)}';
  }

  /// Format potongan previous hash ramah UI
  String get shortPreviousHash {
    if (previousHash.length < 12) return previousHash;
    return '${previousHash.substring(0, 8)}...${previousHash.substring(previousHash.length - 4)}';
  }
}
