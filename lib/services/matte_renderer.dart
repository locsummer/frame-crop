import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/matte_config.dart';

class MatteRenderer {
  /// Render trực tiếp khung ảnh nghệ thuật 4K chuẩn 3840x2160 (hoặc 2160x3840)
  static Future<Uint8List> renderArtTo4KBytes({
    required ui.Image image,
    required MatteConfig config,
  }) async {
    final int width = config.orientation.targetWidth;
    final int height = config.orientation.targetHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    paintMatteOnCanvas(
      canvas: canvas,
      size: Size(width.toDouble(), height.toDouble()),
      image: image,
      config: config,
      isHighRes: true,
    );

    final picture = recorder.endRecording();
    final ui.Image renderedImage = await picture.toImage(width, height);
    final ByteData? byteData = await renderedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Không thể xuất dữ liệu ảnh từ Canvas');
    }

    return byteData.buffer.asUint8List();
  }

  /// Hàm vẽ chung cho cả Widget Preview lẫn lúc Xuất ảnh 4K
  static void paintMatteOnCanvas({
    required Canvas canvas,
    required Size size,
    required ui.Image image,
    required MatteConfig config,
    bool isHighRes = false,
  }) {
    final canvasRect = Offset.zero & size;

    // 1. Nếu Không viền (None) -> Vẽ tranh lấp đầy khung 16:9
    if (config.style == MatteStyle.none) {
      _drawImageCover(
        canvas: canvas,
        destRect: canvasRect,
        image: image,
        scale: config.imageScale,
        offset: config.imageOffset,
      );
      return;
    }

    // 2. Vẽ nền viền giấy Passe-partout (Matte Background)
    final bgPaint = Paint()..color = config.presetColor.color;
    canvas.drawRect(canvasRect, bgPaint);

    // Tính toán kích thước ô mở (Opening Window) của khung viền
    final double minDim = size.shortestSide;
    final double inset = minDim * config.style.insetFraction;

    // Tỉ lệ cửa sổ trong: giữ cân đối
    final double windowWidth = size.width - (inset * 2);
    final double windowHeight = size.height - (inset * 2);

    final innerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: windowWidth,
      height: windowHeight,
    );

    // 3. Hiệu ứng viền vát cạnh 45 độ (Bevel / Shadow Box)
    final double bevelWidth = isHighRes ? 16.0 : 4.0;

    // Bóng đổ phía trên và bên trái (mặt khuất sáng)
    final darkBevelPaint = Paint()
      ..color = config.presetColor.bevelColor.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = bevelWidth;

    // Viền sáng phía dưới và bên phải (mặt phản quang mép cắt giấy)
    final lightBevelPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = bevelWidth / 2;

    if (config.style == MatteStyle.shadowBox) {
      // Đổ bóng sâu đa tầng cho Shadow box
      final shadowRect = innerRect.inflate(bevelWidth);
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isHighRes ? 24.0 : 6.0);
      canvas.drawRect(shadowRect, shadowPaint);
    }

    // 4. Vẽ tranh nghệ thuật bên trong ô viền
    canvas.save();
    canvas.clipRect(innerRect);

    _drawImageCover(
      canvas: canvas,
      destRect: innerRect,
      image: image,
      scale: config.imageScale,
      offset: config.imageOffset,
    );

    // Đổ bóng mép trong đè nhẹ lên ảnh tạo chiều sâu chân thật
    final innerShadowPaint = Paint()
      ..shader = ui.Gradient.radial(
        innerRect.center,
        innerRect.width / 1.5,
        [
          Colors.transparent,
          Colors.black.withOpacity(0.18),
        ],
        [0.85, 1.0],
      );
    canvas.drawRect(innerRect, innerShadowPaint);

    canvas.restore();

    // 5. Vẽ mép cắt bìa giấy nghệ thuật (Bevel Edge)
    canvas.drawRect(innerRect, darkBevelPaint);
    canvas.drawRect(innerRect.deflate(bevelWidth / 2), lightBevelPaint);
  }

  /// Thuật toán vẽ ảnh lấp đầy (Aspect Fill / Cover) có pan và zoom
  static void _drawImageCover({
    required Canvas canvas,
    required Rect destRect,
    required ui.Image image,
    required double scale,
    required Offset offset,
  }) {
    final double imgWidth = image.width.toDouble();
    final double imgHeight = image.height.toDouble();

    final double scaleX = destRect.width / imgWidth;
    final double scaleY = destRect.height / imgHeight;
    final double baseScale = (scaleX > scaleY ? scaleX : scaleY) * scale;

    final double scaledW = imgWidth * baseScale;
    final double scaledH = imgHeight * baseScale;

    // Tính độ lệch Pan (từ -1 đến 1 chuyển sang pixel giới hạn)
    final double maxOffsetX = (scaledW - destRect.width) / 2;
    final double maxOffsetY = (scaledH - destRect.height) / 2;

    final double panX = maxOffsetX > 0 ? offset.dx * maxOffsetX : 0;
    final double panY = maxOffsetY > 0 ? offset.dy * maxOffsetY : 0;

    final double drawLeft = destRect.center.dx - (scaledW / 2) + panX;
    final double drawTop = destRect.center.dy - (scaledH / 2) + panY;

    final srcRect = Rect.fromLTWH(0, 0, imgWidth, imgHeight);
    final targetRect = Rect.fromLTWH(drawLeft, drawTop, scaledW, scaledH);

    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(image, srcRect, targetRect, paint);
  }

  /// Chuyển đổi Uint8List ảnh (JPG, PNG) thành ui.Image
  static Future<ui.Image> decodeImageFromBytes(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  /// Tạo tác phẩm tranh mẫu chất lượng cao ngay trên Canvas (offline-ready)
  static Future<ui.Image> createSampleArtImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1920, 1080));

    // Bầu trời hoàng hôn hoàng gia
    final skyGradient = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(0, 750),
      [
        const Color(0xFF16222F),
        const Color(0xFF2C3E50),
        const Color(0xFF8E44AD),
        const Color(0xFFD35400),
        const Color(0xFFF39C12),
      ],
      [0.0, 0.35, 0.65, 0.85, 1.0],
    );
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1920, 750), Paint()..shader = skyGradient);

    // Mặt trăng / mặt trời vàng
    final sunPaint = Paint()..color = const Color(0xFFFFF3D1);
    canvas.drawCircle(const Offset(1100, 480), 90, sunPaint);

    // Biển phản quang
    final seaGradient = ui.Gradient.linear(
      const Offset(0, 750),
      const Offset(0, 1080),
      [
        const Color(0xFF2C3E50),
        const Color(0xFF1B2631),
        const Color(0xFF0E141B),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(const Rect.fromLTWH(0, 750, 1920, 330), Paint()..shader = seaGradient);

    // Vệt sáng mặt trời trên mặt nước
    final reflectionPaint = Paint()
      ..color = const Color(0xFFF39C12).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(const Rect.fromLTWH(950, 750, 300, 330), reflectionPaint);

    // Dãy núi hoàng hôn (Mountain silhouette)
    final mountainPath = Path()
      ..moveTo(0, 750)
      ..lineTo(280, 520)
      ..lineTo(560, 640)
      ..lineTo(920, 420)
      ..lineTo(1280, 610)
      ..lineTo(1600, 490)
      ..lineTo(1920, 590)
      ..lineTo(1920, 750)
      ..close();
    canvas.drawPath(mountainPath, Paint()..color = const Color(0xFF1A1F26));

    final picture = recorder.endRecording();
    return await picture.toImage(1920, 1080);
  }
}
