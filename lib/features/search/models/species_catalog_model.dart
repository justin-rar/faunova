// ==============================================================================
// FAUNOVA MODEL: SpeciesCatalogModel
// Model katalog taksonomi satwa untuk pencarian dan filter taksonomi
// Sesuai Plan 5.2, 5.7 & AGENTS.md (Sesi S11)
// ==============================================================================

class SpeciesCatalogModel {
  final String speciesName;
  final String scientificName;
  final String taxonomyClass;
  final String conservationStatus;
  final String samplePhotoPath;
  final int observationsCount;
  final String description;

  const SpeciesCatalogModel({
    required this.speciesName,
    required this.scientificName,
    required this.taxonomyClass,
    required this.conservationStatus,
    required this.samplePhotoPath,
    required this.observationsCount,
    required this.description,
  });

  factory SpeciesCatalogModel.fromJson(Map<String, dynamic> json) {
    return SpeciesCatalogModel(
      speciesName: json['species_name'] as String? ?? 'Satwa Tidak Dikenal',
      scientificName: json['scientific_name'] as String? ?? json['category'] as String? ?? '',
      taxonomyClass: json['taxonomy_class'] as String? ?? 'Fauna',
      conservationStatus: json['conservation_status'] as String? ?? 'Terdata',
      samplePhotoPath: json['sample_photo_path'] as String? ?? '',
      observationsCount: (json['observations_count'] as num?)?.toInt() ?? 1,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species_name': speciesName,
      'scientific_name': scientificName,
      'taxonomy_class': taxonomyClass,
      'conservation_status': conservationStatus,
      'sample_photo_path': samplePhotoPath,
      'observations_count': observationsCount,
      'description': description,
    };
  }
}
