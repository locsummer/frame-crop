import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../models/matte_config.dart';
import '../services/matte_renderer.dart';
import '../services/museum_service.dart';
import '../services/samsung_tv_service.dart';
import '../widgets/matte_selector.dart';
import '../widgets/tv_frame_preview.dart';

class StudioScreen extends StatefulWidget {
  final Artwork? initialArtwork;

  const StudioScreen({super.key, this.initialArtwork});

  @override
  State<StudioScreen> createState() => StudioScreenState();
}

class StudioScreenState extends State<StudioScreen> {
  Artwork? _currentArtwork;
  ui.Image? _loadedImage;
  bool _isLoading = false;
  bool _isRendering4K = false;
  bool _isSendingToTv = false;

  MatteConfig _config = const MatteConfig();
  BezelStyle _bezelStyle = BezelStyle.modernTeak;

  final _tvService = SamsungTvService();

  @override
  void initState() {
    super.initState();
    if (widget.initialArtwork != null) {
      loadArtwork(widget.initialArtwork!);
    } else {
      // Tải kiệt tác mặc định để người dùng trải nghiệm ngay
      final defaultArt = MuseumService.getCuratedArtworks().first;
      loadArtwork(defaultArt);
    }
  }

  Future<void> loadArtwork(Artwork art) async {
    setState(() {
      _currentArtwork = art;
      _isLoading = true;
    });

    try {
      Uint8List imageBytes;
      if (art.localFilePath != null) {
        imageBytes = await File(art.localFilePath!).readAsBytes();
      } else {
        // Tải qua mạng
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
        final urlToFetch = art.highResUrl ?? art.imageUrl;
        final request = await client.getUrl(Uri.parse(urlToFetch));
        request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Mobile; Android) FrameCrop/1.0');
        final response = await request.close();
        if (response.statusCode != 200) {
          throw HttpException('HTTP status ${response.statusCode}');
        }
        final bytesBuilder = BytesBuilder();
        await for (var chunk in response) {
          bytesBuilder.add(chunk);
        }
        imageBytes = bytesBuilder.toBytes();
      }

      if (imageBytes.isEmpty) {
        throw Exception('Dữ liệu ảnh rỗng');
      }

      final uiImage = await MatteRenderer.decodeImageFromBytes(imageBytes);
      if (mounted) {
        setState(() {
          _loadedImage = uiImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Không tải được ảnh từ mạng ($e), chuyển sang tranh hoàng hôn mẫu');
      final fallbackImage = await MatteRenderer.createSampleArtImage();
      if (mounted) {
        setState(() {
          _loadedImage = fallbackImage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _export4K() async {
    if (_loadedImage == null) return;

    setState(() => _isRendering4K = true);
    try {
      final bytes = await MatteRenderer.renderArtTo4KBytes(
        image: _loadedImage!,
        config: _config,
      );

      if (mounted) {
        setState(() => _isRendering4K = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Render 4K Thành Công!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Độ phân giải: ${_config.orientation.targetWidth} × ${_config.orientation.targetHeight} pixels'),
                Text('Tỉ lệ: ${_config.orientation.label}'),
                Text('Dung lượng: ${(bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB'),
                const SizedBox(height: 12),
                const Text(
                  'Ảnh đã được xử lý chuẩn xác 16:9 với viền Passe-partout hoàn mỹ, sẵn sàng để đồng bộ lên TV The Frame.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRendering4K = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất 4K: $e')),
        );
      }
    }
  }

  Future<void> _sendToFrameTv() async {
    if (_loadedImage == null) return;

    if (!_tvService.isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chưa kết nối TV'),
          content: const Text(
            'Vui lòng chuyển sang tab "TV The Frame" để quét hoặc nhập địa chỉ IP của TV trước khi gửi tranh.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSendingToTv = true);
    try {
      final bytes = await MatteRenderer.renderArtTo4KBytes(
        image: _loadedImage!,
        config: _config,
      );

      final fileName = 'frame_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final success = await _tvService.sendArtImage(
        imageBytes: bytes,
        fileName: fileName,
      );

      if (mounted) {
        setState(() => _isSendingToTv = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã truyền tranh 4K thành công lên Samsung The Frame!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể gửi tranh lên TV. Hãy kiểm tra kết nối trong tab TV.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingToTv = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Art Studio & Matte 4K',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            if (_currentArtwork != null)
              Text(
                '${_currentArtwork!.title} • ${_currentArtwork!.artist}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          // Nút xuất ảnh 4K
          IconButton(
            icon: _isRendering4K
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Xuất file 4K (3840x2160)',
            onPressed: (_loadedImage == null || _isRendering4K) ? null : _export4K,
          ),
          // Nút gửi thẳng lên TV
          FilledButton.tonalIcon(
            onPressed: (_loadedImage == null || _isSendingToTv) ? null : _sendToFrameTv,
            icon: _isSendingToTv
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.tv, size: 18),
            label: const Text('Gửi TV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Khung TV Live Preview trực quan
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFF121212),
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TvFramePreview(
                      image: _loadedImage,
                      config: _config,
                      bezelStyle: _bezelStyle,
                      onTransformChanged: (offset, scale) {
                        setState(() {
                          _config = _config.copyWith(
                            imageOffset: offset,
                            imageScale: scale,
                          );
                        });
                      },
                    ),
            ),
          ),

          // Thanh điều khiển Matte & Tùy biến
          Expanded(
            flex: 6,
            child: Container(
              color: Theme.of(context).cardColor,
              child: MatteSelectorSheet(
                config: _config,
                bezelStyle: _bezelStyle,
                onConfigChanged: (newConfig) {
                  setState(() => _config = newConfig);
                },
                onBezelChanged: (newBezel) {
                  setState(() => _bezelStyle = newBezel);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
