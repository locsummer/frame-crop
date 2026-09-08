import 'dart:convert';
import 'dart:io';
import '../models/artwork.dart';

class MuseumService {
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  // Famous curated public domain artworks for quick offline/instant loading
  static const List<Map<String, String>> curatedMasterpieces = [
    {
      'id': 'curated_vangogh_starry',
      'title': 'The Starry Night',
      'artist': 'Vincent van Gogh',
      'date': '1889',
      'medium': 'Oil on canvas',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/1280px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg',
      'highResUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/2560px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg',
      'source': 'Museum of Modern Art',
    },
    {
      'id': 'curated_monet_waterlilies',
      'title': 'Water Lilies and the Japanese Bridge',
      'artist': 'Claude Monet',
      'date': '1899',
      'medium': 'Oil on canvas',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Claude_Monet_-_Water_Lilies_and_the_Japanese_Bridge_-_Google_Art_Project.jpg/1280px-Claude_Monet_-_Water_Lilies_and_the_Japanese_Bridge_-_Google_Art_Project.jpg',
      'highResUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Claude_Monet_-_Water_Lilies_and_the_Japanese_Bridge_-_Google_Art_Project.jpg/2560px-Claude_Monet_-_Water_Lilies_and_the_Japanese_Bridge_-_Google_Art_Project.jpg',
      'source': 'Princeton University Art Museum',
    },
    {
      'id': 'curated_hokusai_wave',
      'title': 'The Great Wave off Kanagawa',
      'artist': 'Katsushika Hokusai',
      'date': 'ca. 1830–1832',
      'medium': 'Woodblock print',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Great_Wave_off_Kanagawa2.jpg/1280px-Great_Wave_off_Kanagawa2.jpg',
      'highResUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Great_Wave_off_Kanagawa2.jpg/2560px-Great_Wave_off_Kanagawa2.jpg',
      'source': 'The Met Museum',
    },
    {
      'id': 'curated_klimt_the_kiss',
      'title': 'The Kiss (Der Kuss)',
      'artist': 'Gustav Klimt',
      'date': '1907–1908',
      'medium': 'Oil and gold leaf on canvas',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/The_Kiss_-_Gustav_Klimt_-_Google_Cultural_Institute.jpg/1280px-The_Kiss_-_Gustav_Klimt_-_Google_Cultural_Institute.jpg',
      'highResUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/The_Kiss_-_Gustav_Klimt_-_Google_Cultural_Institute.jpg/2560px-The_Kiss_-_Gustav_Klimt_-_Google_Cultural_Institute.jpg',
      'source': 'Österreichische Galerie Belvedere',
    },
    {
      'id': 'curated_vermeer_pearl',
      'title': 'Girl with a Pearl Earring',
      'artist': 'Johannes Vermeer',
      'date': 'ca. 1665',
      'medium': 'Oil on canvas',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/1665_Girl_with_a_Pearl_Earring.jpg/1280px-1665_Girl_with_a_Pearl_Earring.jpg',
      'highResUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/1665_Girl_with_a_Pearl_Earring.jpg/2560px-1665_Girl_with_a_Pearl_Earring.jpg',
      'source': 'Mauritshuis, The Hague',
    },
    {
      'id': 'curated_caspar_wanderer',
      'title': 'Wanderer above the Sea of Fog',
      'artist': 'Caspar David Friedrich',
      'date': '1818',
      'medium': 'Oil on canvas',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Caspar_David_Friedrich_-_Wanderer_above_the_sea_of_fog.jpg/1280px-Caspar_David_Friedrich_-_Wanderer_above_the_sea_of_fog.jpg',
      'highResUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Caspar_David_Friedrich_-_Wanderer_above_the_sea_of_fog.jpg/2560px-Caspar_David_Friedrich_-_Wanderer_above_the_sea_of_fog.jpg',
      'source': 'Hamburger Kunsthalle',
    },
  ];

  static List<Artwork> getCuratedArtworks() {
    return curatedMasterpieces
        .map((map) => Artwork(
              id: map['id']!,
              title: map['title']!,
              artist: map['artist']!,
              date: map['date']!,
              medium: map['medium']!,
              imageUrl: map['imageUrl']!,
              highResUrl: map['highResUrl'],
              source: map['source']!,
            ))
        .toList();
  }

  /// Fetch from Art Institute of Chicago API
  static Future<List<Artwork>> fetchChicagoArtworks({
    int page = 1,
    int limit = 15,
    String? query,
  }) async {
    try {
      final Uri uri;
      if (query != null && query.trim().isNotEmpty) {
        uri = Uri.parse(
          'https://api.artic.edu/api/v1/artworks/search?q=${Uri.encodeComponent(query)}&page=$page&limit=$limit&fields=id,title,artist_title,date_display,medium_display,image_id',
        );
      } else {
        uri = Uri.parse(
          'https://api.artic.edu/api/v1/artworks?page=$page&limit=$limit&fields=id,title,artist_title,date_display,medium_display,image_id',
        );
      }

      final request = await _client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(body);
        final config = json['config'] as Map<String, dynamic>?;
        final imageBaseUrl = config?['iiif_url'] as String? ?? 'https://www.artic.edu/iiif/2';
        final List<dynamic> data = json['data'] ?? [];

        final List<Artwork> artworks = [];
        for (final item in data) {
          if (item['image_id'] != null) {
            artworks.add(Artwork.fromChicagoJson(item, imageBaseUrl));
          }
        }
        return artworks;
      }
    } catch (e) {
      // Fallback gracefully on network error
    }
    return [];
  }

  /// Fetch from The Met Museum API
  static Future<List<Artwork>> fetchMetHighlights() async {
    try {
      // Curated Met Object IDs of famous landscape & oil paintings
      final metObjectIds = [436535, 438012, 436532, 435882, 437984, 437658];
      final List<Artwork> artworks = [];

      for (final id in metObjectIds) {
        try {
          final uri = Uri.parse('https://collectionapi.metmuseum.org/public/collection/v1/objects/$id');
          final request = await _client.getUrl(uri);
          final response = await request.close();
          if (response.statusCode == 200) {
            final body = await response.transform(utf8.decoder).join();
            final Map<String, dynamic> json = jsonDecode(body);
            if (json['primaryImageSmall'] != null && json['primaryImageSmall'].toString().isNotEmpty) {
              artworks.add(Artwork.fromMetJson(json));
            }
          }
        } catch (_) {}
      }
      return artworks;
    } catch (_) {
      return [];
    }
  }
}
