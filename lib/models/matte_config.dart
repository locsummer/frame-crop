import 'package:flutter/material.dart';

enum MatteStyle {
  none('Không viền (Full 16:9)', 0.0),
  thin('Viền mỏng (Thin)', 0.08),
  modern('Viền tiêu chuẩn (Modern)', 0.15),
  wide('Viền rộng (Wide)', 0.22),
  shadowBox('Hộp bóng sâu (Shadow Box)', 0.14);

  final String label;
  final double insetFraction; // Tỉ lệ thụt vào so với kích thước cạnh nhỏ nhất
  const MatteStyle(this.label, this.insetFraction);
}

enum TvOrientation {
  landscape('Ngang 16:9 (3840 × 2160)', 16 / 9, 3840, 2160),
  portrait('Dọc 9:16 (2160 × 3840)', 9 / 16, 2160, 3840);

  final String label;
  final double aspectRatio;
  final int targetWidth;
  final int targetHeight;
  const TvOrientation(this.label, this.aspectRatio, this.targetWidth, this.targetHeight);
}

class MattePresetColor {
  final String name;
  final Color color;
  final Color bevelColor;

  const MattePresetColor({
    required this.name,
    required this.color,
    required this.bevelColor,
  });

  static const MattePresetColor warmCream = MattePresetColor(
    name: 'Trắng Ngà (Warm Cream)',
    color: Color(0xFFF7F4EB),
    bevelColor: Color(0xFFD4CEBD),
  );
  static const MattePresetColor antique = MattePresetColor(
    name: 'Trắng Cổ Điển (Antique)',
    color: Color(0xFFEFEBD9),
    bevelColor: Color(0xFFCCC5B0),
  );
  static const MattePresetColor softLinen = MattePresetColor(
    name: 'Vải Linen (Soft Linen)',
    color: Color(0xFFE6E2D6),
    bevelColor: Color(0xFFC4BDAE),
  );
  static const MattePresetColor mutedSand = MattePresetColor(
    name: 'Cát Trầm (Muted Sand)',
    color: Color(0xFFD8CFBC),
    bevelColor: Color(0xFFB5AB95),
  );
  static const MattePresetColor charcoal = MattePresetColor(
    name: 'Xám Than (Charcoal)',
    color: Color(0xFF2B2D2F),
    bevelColor: Color(0xFF1B1C1E),
  );
  static const MattePresetColor jetBlack = MattePresetColor(
    name: 'Đen Tuyền (Jet Black)',
    color: Color(0xFF141414),
    bevelColor: Color(0xFF080808),
  );

  static const List<MattePresetColor> presets = [
    warmCream,
    antique,
    softLinen,
    mutedSand,
    charcoal,
    jetBlack,
  ];
}

class MatteConfig {
  final MatteStyle style;
  final MattePresetColor presetColor;
  final TvOrientation orientation;
  final double imageScale;
  final Offset imageOffset; // [-1.0, 1.0] pan offset

  const MatteConfig({
    this.style = MatteStyle.modern,
    this.presetColor = MattePresetColor.warmCream,
    this.orientation = TvOrientation.landscape,
    this.imageScale = 1.0,
    this.imageOffset = Offset.zero,
  });

  MatteConfig copyWith({
    MatteStyle? style,
    MattePresetColor? presetColor,
    TvOrientation? orientation,
    double? imageScale,
    Offset? imageOffset,
  }) {
    return MatteConfig(
      style: style ?? this.style,
      presetColor: presetColor ?? this.presetColor,
      orientation: orientation ?? this.orientation,
      imageScale: imageScale ?? this.imageScale,
      imageOffset: imageOffset ?? this.imageOffset,
    );
  }
}
