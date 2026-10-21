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
  });

  int get quotaRemaining => (quotaMax - quotaUsed).clamp(0, quotaMax);

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

    final isAnimalValue = json['isAnimal'] == true || resultObj['isAnimal'] == true;

    return ScanResultModel(
      scanId: json['scanId']?.toString() ?? '',
      requestId: requestId ?? json['requestId']?.toString() ?? '',
      status: json['status']?.toString() ?? (isAnimalValue ? 'completed' : 'rejected_not_animal'),
      isAnimal: isAnimalValue,
      name: resultObj['name']?.toString() ?? json['name']?.toString(),
      categoryOrSpecies: resultObj['categoryOrSpecies']?.toString() ?? json['categoryOrSpecies']?.toString(),
      description: resultObj['description']?.toString() ?? json['description']?.toString(),
      additionalFact: resultObj['additionalFact']?.toString() ?? json['additionalFact']?.toString(),
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scanId': scanId,
      'requestId': requestId,
      'status': status,
      'isAnimal': isAnimal,
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
    };
  }
}
