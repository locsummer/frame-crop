import 'package:flutter_test/flutter_test.dart';
import 'package:frame_crop/models/matte_config.dart';
import 'package:frame_crop/services/museum_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MatteConfig & TvOrientation Tests', () {
    test('Landscape orientation has 16:9 aspect ratio and 3840x2160 resolution', () {
      const config = MatteConfig(orientation: TvOrientation.landscape);
      expect(config.orientation.targetWidth, 3840);
      expect(config.orientation.targetHeight, 2160);
      expect((config.orientation.aspectRatio - (16 / 9)).abs(), lessThan(0.001));
    });

    test('Portrait orientation has 9:16 aspect ratio and 2160x3840 resolution', () {
      const config = MatteConfig(orientation: TvOrientation.portrait);
      expect(config.orientation.targetWidth, 2160);
      expect(config.orientation.targetHeight, 3840);
      expect((config.orientation.aspectRatio - (9 / 16)).abs(), lessThan(0.001));
    });

    test('Matte preset colors provide contrast bevel colors', () {
      for (final preset in MattePresetColor.presets) {
        expect(preset.name, isNotEmpty);
        expect(preset.color, isNotNull);
        expect(preset.bevelColor, isNotNull);
      }
    });

    test('Matte styles have positive insets except none', () {
      expect(MatteStyle.none.insetFraction, 0.0);
      expect(MatteStyle.thin.insetFraction, greaterThan(0.0));
      expect(MatteStyle.modern.insetFraction, greaterThan(MatteStyle.thin.insetFraction));
      expect(MatteStyle.wide.insetFraction, greaterThan(MatteStyle.modern.insetFraction));
    });
  });

  group('MuseumService Tests', () {
    test('Curated artworks return non-empty list of masterpieces', () {
      final artworks = MuseumService.getCuratedArtworks();
      expect(artworks, isNotEmpty);
      expect(artworks.first.title, 'The Starry Night');
      expect(artworks.first.artist, 'Vincent van Gogh');
      expect(artworks.first.imageUrl, contains('http'));
    });
  });
}
