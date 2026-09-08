class Artwork {
  final String id;
  final String title;
  final String artist;
  final String date;
  final String medium;
  final String imageUrl;
  final String? highResUrl;
  final String source; // 'The Met Museum', 'Art Institute of Chicago', 'Local Photo'
  final String? localFilePath;

  const Artwork({
    required this.id,
    required this.title,
    required this.artist,
    required this.date,
    required this.medium,
    required this.imageUrl,
    this.highResUrl,
    required this.source,
    this.localFilePath,
  });

  factory Artwork.fromMetJson(Map<String, dynamic> json) {
    return Artwork(
      id: 'met_${json['objectID']}',
      title: (json['title'] as String?)?.isNotEmpty == true
          ? json['title']
          : 'Untitled',
      artist: (json['artistDisplayName'] as String?)?.isNotEmpty == true
          ? json['artistDisplayName']
          : 'Unknown Artist',
      date: json['objectDate'] ?? '',
      medium: json['medium'] ?? '',
      imageUrl: json['primaryImageSmall'] ?? json['primaryImage'] ?? '',
      highResUrl: json['primaryImage'],
      source: 'The Met Museum',
    );
  }

  factory Artwork.fromChicagoJson(Map<String, dynamic> json, String imageBaseUrl) {
    final imageId = json['image_id'] as String?;
    final imageUrl = imageId != null
        ? '$imageBaseUrl/$imageId/full/843,/0/default.jpg'
        : '';
    final highResUrl = imageId != null
        ? '$imageBaseUrl/$imageId/full/1686,/0/default.jpg'
        : null;

    return Artwork(
      id: 'aic_${json['id']}',
      title: json['title'] ?? 'Untitled',
      artist: json['artist_title'] ?? 'Unknown Artist',
      date: json['date_display'] ?? '',
      medium: json['medium_display'] ?? '',
      imageUrl: imageUrl,
      highResUrl: highResUrl,
      source: 'Art Institute of Chicago',
    );
  }

  Artwork copyWith({
    String? id,
    String? title,
    String? artist,
    String? date,
    String? medium,
    String? imageUrl,
    String? highResUrl,
    String? source,
    String? localFilePath,
  }) {
    return Artwork(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      date: date ?? this.date,
      medium: medium ?? this.medium,
      imageUrl: imageUrl ?? this.imageUrl,
      highResUrl: highResUrl ?? this.highResUrl,
      source: source ?? this.source,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
