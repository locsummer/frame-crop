import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/matte_config.dart';
import '../services/matte_renderer.dart';

enum BezelStyle {
  modernTeak('Gỗ Teak (Sáng)', Color(0xFFC19A6B), Color(0xFF8B6538)),
  walnut('Gỗ Óc Chó (Trầm)', Color(0xFF5C4033), Color(0xFF382418)),
  modernWhite('Trắng Tinh Tế', Color(0xFFF0F0F0), Color(0xFFD8D8D8)),
  blackMetal('Kim Loại Đen', Color(0xFF1F1F1F), Color(0xFF101010));

  final String label;
  final Color color;
  final Color shadowColor;
  const BezelStyle(this.label, this.color, this.shadowColor);
}

class TvFramePreview extends StatelessWidget {
  final ui.Image? image;
  final MatteConfig config;
  final BezelStyle bezelStyle;
  final Function(Offset offset, double scale)? onTransformChanged;

  const TvFramePreview({
    super.key,
    required this.image,
    required this.config,
    this.bezelStyle = BezelStyle.modernTeak,
    this.onTransformChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight;

        // Tính toán kích thước vừa vặn theo tỉ lệ 16:9 hoặc 9:16
        final double targetAspect = config.orientation.aspectRatio;
        double frameW = maxW;
        double frameH = frameW / targetAspect;

        if (frameH > maxH) {
          frameH = maxH;
          frameW = frameH * targetAspect;
        }

        const double bezelWidth = 8.0;

        return Center(
          child: Container(
            width: frameW,
            height: frameH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: bezelStyle.color,
                width: bezelWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: bezelStyle.shadowColor.withOpacity(0.8),
                  blurRadius: 1,
                  offset: const Offset(0, 0),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    GestureDetector(
                      onScaleUpdate: (details) {
                        if (onTransformChanged != null) {
                          // Điều chỉnh scale & pan offset
                          final newScale = (config.imageScale * details.scale).clamp(1.0, 3.0);
                          final panDelta = details.focalPointDelta;
                          final newOffset = config.imageOffset +
                              Offset(
                                panDelta.dx / (frameW / 2),
                                panDelta.dy / (frameH / 2),
                              );
                          onTransformChanged!(newOffset, newScale);
                        }
                      },
                      child: CustomPaint(
                        painter: _MatteCanvasPainter(
                          image: image!,
                          config: config,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF1E1E1E),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tv, size: 48, color: Colors.grey.shade600),
                            const SizedBox(height: 8),
                            Text(
                              'Chưa chọn tranh',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Huy hiệu tỉ lệ & độ phân giải ở góc
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        config.orientation == TvOrientation.landscape
                            ? '16:9 • 4K UHD'
                            : '9:16 • 4K UHD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MatteCanvasPainter extends CustomPainter {
  final ui.Image image;
  final MatteConfig config;

  _MatteCanvasPainter({
    required this.image,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    MatteRenderer.paintMatteOnCanvas(
      canvas: canvas,
      size: size,
      image: image,
      config: config,
      isHighRes: false,
    );
  }

  @override
  bool shouldRepaint(covariant _MatteCanvasPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.config.style != config.style ||
        oldDelegate.config.presetColor != config.presetColor ||
        oldDelegate.config.orientation != config.orientation ||
        oldDelegate.config.imageScale != config.imageScale ||
        oldDelegate.config.imageOffset != config.imageOffset;
  }
}
