import 'package:flutter/material.dart';
import '../models/matte_config.dart';
import 'tv_frame_preview.dart';

class MatteSelectorSheet extends StatelessWidget {
  final MatteConfig config;
  final BezelStyle bezelStyle;
  final Function(MatteConfig) onConfigChanged;
  final Function(BezelStyle) onBezelChanged;

  const MatteSelectorSheet({
    super.key,
    required this.config,
    required this.bezelStyle,
    required this.onConfigChanged,
    required this.onBezelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tỉ lệ hiển thị (Orientation)
          Row(
            children: [
              Text(
                'TỈ LỆ MÀN HÌNH',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey.shade400,
                ),
              ),
              const Spacer(),
              SegmentedButton<TvOrientation>(
                segments: const [
                  ButtonSegment(
                    value: TvOrientation.landscape,
                    icon: Icon(Icons.crop_16_9, size: 18),
                    label: Text('16:9 Ngang'),
                  ),
                  ButtonSegment(
                    value: TvOrientation.portrait,
                    icon: Icon(Icons.stay_current_portrait, size: 18),
                    label: Text('9:16 Dọc'),
                  ),
                ],
                selected: {config.orientation},
                onSelectionChanged: (newSelection) {
                  onConfigChanged(config.copyWith(orientation: newSelection.first));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Kiểu viền Matte (Passe-partout Style)
          Text(
            'KIỂU VIỀN TRANH (MATTE)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MatteStyle.values.map((style) {
                final isSelected = config.style == style;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(style.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onConfigChanged(config.copyWith(style: style));
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Màu sắc viền giấy (chỉ hiện khi có viền)
          if (config.style != MatteStyle.none) ...[
            Text(
              'MÀU GIẤY VIỀN (PASSE-PARTOUT)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: MattePresetColor.presets.map((preset) {
                final isSelected = config.presetColor.name == preset.name;
                return GestureDetector(
                  onTap: () => onConfigChanged(config.copyWith(presetColor: preset)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12.0),
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: preset.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Khung viền ngoài TV (Bezel / Frame)
          Text(
            'KHUNG NGOÀI THE FRAME',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BezelStyle.values.map((bezel) {
                final isSelected = bezelStyle == bezel;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    avatar: CircleAvatar(backgroundColor: bezel.color),
                    label: Text(bezel.label),
                    selected: isSelected,
                    onSelected: (_) => onBezelChanged(bezel),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Thu phóng ảnh bên trong khung
          Row(
            children: [
              Text(
                'THU PHÓNG TRANH',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey.shade400,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  onConfigChanged(config.copyWith(
                    imageScale: 1.0,
                    imageOffset: Offset.zero,
                  ));
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Đặt lại'),
              ),
            ],
          ),
          Slider(
            value: config.imageScale,
            min: 1.0,
            max: 2.5,
            divisions: 15,
            label: '${(config.imageScale * 100).toInt()}%',
            onChanged: (val) {
              onConfigChanged(config.copyWith(imageScale: val));
            },
          ),
        ],
      ),
    );
  }
}
