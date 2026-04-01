class Plant {
  final String id;
  final String name;
  final String hint;
  final String scientificName;
  final String commonUses;
  final String localNames;
  final String description;
  final String uses;
  final String primaryImageUrl;
  final String detailImageUrl;
  final List<String> helpsWith;
  final Map<String, dynamic> rawData;

  const Plant({
    required this.id,
    required this.name,
    required this.hint,
    required this.scientificName,
    required this.commonUses,
    required this.localNames,
    required this.description,
    required this.uses,
    required this.primaryImageUrl,
    required this.detailImageUrl,
    required this.helpsWith,
    required this.rawData,
  });

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  factory Plant.fromMap(String id, Map<String, dynamic> data) {
    final helpsWith = _asStringList(data['helps_with']);
    final primaryName = (data['name'] ??
            data['plant_name'] ??
            data['plantName'] ??
            data['title'] ??
            data['common_name'] ??
            '')
        .toString()
        .trim();

    return Plant(
      id: id,
      name: primaryName.isEmpty ? id : primaryName,
      hint: (data['hint'] ?? data['summary'] ?? '').toString(),
      scientificName:
          (data['scientificName'] ?? data['scientific_name'] ?? '').toString(),
      commonUses: (data['commonUses'] ?? data['common_uses'] ?? '').toString(),
      localNames: _asStringList(
  data['localNames'] ?? data['local_names'] ?? data['local_name'] ?? [],
).join(', '),
uses: () {
  final raw = data['uses'] ?? data['plant_uses'] ?? data['medicinal_uses'] ?? '';
  if (raw is List) {
    return raw.map((e) => e is Map
        ? '${e['category'] ?? ''}: ${e['description'] ?? ''}'
        : e.toString()).join('\n');
  }
  return raw.toString();
}(),
      description: (data['description'] ?? '').toString(),
      primaryImageUrl: (data['primary_url'] ??
              data['primary_image_url'] ??
              data['image_url'] ??
              data['image'] ??
              '')
          .toString(),
      detailImageUrl: (data['detail_url'] ??
              data['detail_image_url'] ??
              data['secondary_image_url'] ??
              data['detail_image'] ??
              '')
          .toString(),
      helpsWith: helpsWith,
      rawData: Map<String, dynamic>.from(data),
    );
  }
}
