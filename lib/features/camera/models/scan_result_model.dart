class ScanResultModel {
  final String scanId;
  final String requestId;
  final String status;
  final bool isAnimal;
  final String? name;
  final String? categoryOrSpecies;
  final String? description;
  final String? additionalFact;
  final String? photoSha256;
  final double? latitude;
  final double? longitude;
  final double? cameraHeading;
  final bool? isMock;
  final int quotaUsed;
  final int quotaMax;
  final DateTime? receivedAt;
  final String? localPhotoPath;
  final String? imageBase64;
  final String? aiProvider;
  final double confidence;

  const ScanResultModel({
    required this.scanId,
    required this.requestId,
    required this.status,
    required this.isAnimal,
    this.name,
    this.categoryOrSpecies,
    this.description,
    this.additionalFact,
    this.photoSha256,
    this.latitude,
    this.longitude,
    this.cameraHeading,
    this.isMock,
    this.quotaUsed = 1,
    this.quotaMax = 20,
    this.receivedAt,
    this.localPhotoPath,
    this.imageBase64,
    this.aiProvider,
    this.confidence = 0.90,
  });

  int get quotaRemaining => (quotaMax - quotaUsed).clamp(0, quotaMax);

  String get confidencePercentText => '${(confidence * 100).toInt()}%';

  String get confidenceLabel =>
      confidence >= 0.85 ? 'Sangat yakin' : confidence >= 0.65 ? 'Cukup yakin' : 'Perkiraan';

  factory ScanResultModel.fromJson(
    Map<String, dynamic> json, {
    String? requestId,
    double? latitude,
    double? longitude,
    double? cameraHeading,
    bool? isMock,
    String? localPhotoPath,
    String? imageBase64,
  }) {
    final resultObj = json['result'] is Map<String, dynamic>
        ? json['result'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawFact = (resultObj['additionalFact'] ?? json['additionalFact'])
            ?.toString()
            .toLowerCase() ??
        '';
    final rawDesc = (resultObj['description'] ?? json['description'])
            ?.toString()
            .toLowerCase() ??
        '';
    final rawName = (resultObj['name'] ?? json['name'])
            ?.toString()
            .toLowerCase() ??
        '';
    final rawSpecies = (resultObj['categoryOrSpecies'] ?? json['categoryOrSpecies'])
            ?.toString()
            .toLowerCase() ??
        '';

    // Filter anti-salah klasifikasi:
    // 1. Manusia (Homo sapiens, orang, wajah manusia, selfie)
    final isHuman = rawSpecies.contains('homo sapiens') ||
        rawSpecies.contains('homo sapiens sapiens') ||
        rawSpecies.startsWith('homo ') ||
        rawName.contains('manusia') ||
        (rawName.contains('orang') && !rawName.contains('utan') && !rawName.contains('hutan')) ||
        rawDesc.contains('spesies manusia') ||
        rawDesc.contains('manusia modern') ||
        rawDesc.contains('homo sapiens');

    // 2. Tanaman / flora / makanan / minuman
    final isFloraOrItem = rawDesc.contains('tanaman') ||
        rawDesc.contains('tumbuhan') ||
        rawName.contains('kopi') ||
        rawName.contains('teh') ||
        rawSpecies.contains('coffea');

    // 3. Teks penolakan eksplisit dari AI
    final isExplicitlyRejected = rawFact.contains('tidak memuat satwa') ||
        rawFact.contains('bukan satwa') ||
        rawFact.contains('bukan hewan');

    final isExplicitlyNonAnimal = isHuman || isFloraOrItem || isExplicitlyRejected;

    final isAnimalValue = !isExplicitlyNonAnimal &&
        (json['isAnimal'] == true || resultObj['isAnimal'] == true);

    final statusValue = isAnimalValue
        ? (json['status']?.toString() ?? 'completed')
        : 'rejected_not_animal';

    String? finalFact = resultObj['additionalFact']?.toString() ?? json['additionalFact']?.toString();
    if (isHuman) {
      finalFact = 'Objek terdeteksi adalah manusia (Homo sapiens). Aplikasi Faunova khusus untuk katalog satwa dan fauna non-manusia.';
    } else if (isFloraOrItem && (finalFact == null || !finalFact.toLowerCase().contains('bukan satwa'))) {
      finalFact = 'Objek terdeteksi berupa flora, makanan/minuman, atau benda mati, bukan satwa/hewan nyata.';
    }

    return ScanResultModel(
      scanId: json['scanId']?.toString() ?? '',
      requestId: requestId ?? json['requestId']?.toString() ?? '',
      status: statusValue,
      isAnimal: isAnimalValue,
      name: isAnimalValue ? (resultObj['name']?.toString() ?? json['name']?.toString()) : null,
      categoryOrSpecies: isAnimalValue ? (resultObj['categoryOrSpecies']?.toString() ?? json['categoryOrSpecies']?.toString()) : null,
      description: isAnimalValue
          ? (resultObj['description']?.toString() ?? json['description']?.toString())
          : (isHuman ? 'Verifikasi ditolak: Objek foto adalah manusia. Silakan arahkan kamera ke satwa liar atau hewan peliharaan.' : (resultObj['description']?.toString() ?? 'Objek bukan satwa.')),
      additionalFact: finalFact,
      photoSha256: json['photoSha256']?.toString(),
      latitude: latitude ?? (json['latitude'] != null ? (json['latitude'] as num).toDouble() : null),
      longitude: longitude ?? (json['longitude'] != null ? (json['longitude'] as num).toDouble() : null),
      cameraHeading: cameraHeading ?? (json['cameraHeading'] != null ? (json['cameraHeading'] as num).toDouble() : null),
      isMock: isMock ?? (json['isMock'] as bool?),
      quotaUsed: (json['quotaUsed'] as num?)?.toInt() ?? 1,
      quotaMax: (json['quotaMax'] as num?)?.toInt() ?? 20,
      receivedAt: json['receivedAt'] != null
          ? DateTime.tryParse(json['receivedAt'].toString())
          : DateTime.now(),
      localPhotoPath: localPhotoPath,
      imageBase64: imageBase64,
      aiProvider: json['aiProvider']?.toString() ??
          resultObj['aiProvider']?.toString() ??
          (isAnimalValue ? 'DeepSeek Vision' : 'DeepSeek AI'),
      confidence: (resultObj['confidence'] as num?)?.toDouble() ??
          (json['confidence'] as num?)?.toDouble() ??
          0.90,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scanId': scanId,
      'requestId': requestId,
      'status': status,
      'isAnimal': isAnimal,
      'confidence': confidence,
      'name': name,
      'categoryOrSpecies': categoryOrSpecies,
      'description': description,
      'additionalFact': additionalFact,
      'photoSha256': photoSha256,
      'latitude': latitude,
      'longitude': longitude,
      'cameraHeading': cameraHeading,
      'isMock': isMock,
      'quotaUsed': quotaUsed,
      'quotaMax': quotaMax,
      'receivedAt': receivedAt?.toIso8601String(),
      'aiProvider': aiProvider,
    };
  }
}
