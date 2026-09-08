import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/tv_device.dart';

class SamsungTvService {
  static final SamsungTvService _instance = SamsungTvService._internal();
  factory SamsungTvService() => _instance;
  SamsungTvService._internal();

  WebSocket? _socket;
  TvDevice? _currentTv;
  bool _isArtModeOn = false;
  final _connectionStateController = StreamController<bool>.broadcast();
  final _artModeStateController = StreamController<bool>.broadcast();
  final _logController = StreamController<String>.broadcast();

  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<bool> get artModeStateStream => _artModeStateController.stream;
  Stream<String> get logStream => _logController.stream;
  TvDevice? get currentTv => _currentTv;
  bool get isArtModeOn => _isArtModeOn;
  bool get isConnected => _socket != null;

  void _log(String message) {
    debugPrint('[SamsungTV] $message');
    _logController.add(message);
  }

  /// Quét TV Samsung trong mạng nội bộ (SSDP Multicast)
  Future<List<TvDevice>> discoverTvs({Duration timeout = const Duration(seconds: 4)}) async {
    final List<TvDevice> foundDevices = [];
    final seenIps = <String>{};

    try {
      _log('Bắt đầu quét TV qua SSDP (239.255.255.250:1900)...');
      final RawDatagramSocket socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: false,
      );
      socket.broadcastEnabled = true;
      socket.multicastLoopback = false;

      final multicastAddress = InternetAddress('239.255.255.250');
      const searchMessage =
          'M-SEARCH * HTTP/1.1\r\n'
          'HOST: 239.255.255.250:1900\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: 2\r\n'
          'ST: urn:samsung.com:device:RemoteControlReceiver:1\r\n'
          '\r\n';

      socket.send(utf8.encode(searchMessage), multicastAddress, 1900);

      // Cũng tìm kiếm mục tiêu chung
      const genericSearch =
          'M-SEARCH * HTTP/1.1\r\n'
          'HOST: 239.255.255.250:1900\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: 2\r\n'
          'ST: ssdp:all\r\n'
          '\r\n';
      socket.send(utf8.encode(genericSearch), multicastAddress, 1900);

      final completer = Completer<List<TvDevice>>();

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final response = utf8.decode(datagram.data, allowMalformed: true);
            final ip = datagram.address.address;

            if (!seenIps.contains(ip) &&
                (response.toLowerCase().contains('samsung') ||
                    response.contains('RemoteControlReceiver') ||
                    response.contains('SEC_HHP_'))) {
              seenIps.add(ip);
              final device = TvDevice(
                id: 'samsung_$ip',
                name: 'Samsung The Frame ($ip)',
                ip: ip,
                port: 8002,
                isArtModeSupported: true,
              );
              foundDevices.add(device);
              _log('Tìm thấy TV: ${device.name}');
            }
          }
        }
      });

      Timer(timeout, () {
        socket.close();
        if (!completer.isCompleted) {
          completer.complete(foundDevices);
        }
      });

      return await completer.future;
    } catch (e) {
      _log('Lỗi quét SSDP: $e');
      return foundDevices;
    }
  }

  /// Kết nối và Ghép đôi (Pairing) với Samsung The Frame
  Future<bool> connect(TvDevice device) async {
    await disconnect();
    _currentTv = device;
    _log('Đang kết nối tới TV tại ${device.ip}:${device.port}...');

    final appNameBase64 = base64Encode(utf8.encode('FrameCrop'));
    String url = 'wss://${device.ip}:${device.port}/api/v2/channels/samsung.remote.control?name=$appNameBase64';
    if (device.token != null && device.token!.isNotEmpty) {
      url += '&token=${device.token}';
    }

    try {
      final customClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Bỏ qua chứng chỉ SSL tự ký của TV nội bộ
          return true;
        }
        ..connectionTimeout = const Duration(seconds: 5);

      final wsUri = Uri.parse(url);
      _socket = await WebSocket.connect(
        wsUri.toString(),
        customClient: customClient,
      );

      _log('Kết nối WebSocket thành công!');
      _connectionStateController.add(true);

      _socket!.listen(
        (data) {
          _handleTvMessage(data);
        },
        onError: (error) {
          _log('Lỗi socket TV: $error');
          disconnect();
        },
        onDone: () {
          _log('Đã ngắt kết nối với TV');
          disconnect();
        },
      );

      // Kết nối tiếp vào Art Mode Channel
      _connectArtChannel();
      return true;
    } catch (e) {
      _log('Không thể kết nối tới TV: $e');
      disconnect();
      return false;
    }
  }

  void _connectArtChannel() {
    if (_socket == null) return;
    _log('Đăng ký kênh Art Mode (com.samsung.art-app)...');
    final message = jsonEncode({
      'method': 'ms.channel.connect',
      'params': {
        'channel': 'com.samsung.art-app',
      }
    });
    _socket!.add(message);
  }

  void _handleTvMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final event = json['event'];

      if (event == 'ms.channel.connect') {
        final token = json['data']?['token'] as String?;
        if (token != null && _currentTv != null) {
          _currentTv = _currentTv!.copyWith(token: token, isPaired: true);
          _log('Đã nhận và lưu Pairing Token: $token');
        }
      } else if (event == 'art_app_request' || event == 'art_app_response' || event == 'artmode_status') {
        _log('Nhận tín hiệu Art Mode: $data');
        if (data.toString().contains('"value":"on"') || data.toString().contains('"status":"on"')) {
          _isArtModeOn = true;
          _artModeStateController.add(true);
        } else if (data.toString().contains('"value":"off"') || data.toString().contains('"status":"off"')) {
          _isArtModeOn = false;
          _artModeStateController.add(false);
        }
      }
    } catch (_) {}
  }

  /// Bật hoặc Tắt chế độ tranh (Art Mode)
  Future<void> toggleArtMode(bool enable) async {
    if (_socket == null) {
      _log('Chưa kết nối với TV!');
      return;
    }
    _log('Chuyển Art Mode sang: ${enable ? "BẬT" : "TẮT"}');
    final payload = {
      'method': 'ms.channel.emit',
      'params': {
        'event': 'art_app_request',
        'to': 'host',
        'data': jsonEncode({
          'request': 'set_artmode_status',
          'value': enable ? 'on' : 'off',
        }),
      }
    };
    _socket!.add(jsonEncode(payload));
    _isArtModeOn = enable;
    _artModeStateController.add(enable);
  }

  /// Gửi ảnh 4K sang TV Samsung The Frame
  Future<bool> sendArtImage({
    required Uint8List imageBytes,
    required String fileName,
    String matteId = 'none',
  }) async {
    if (_socket == null || _currentTv == null) {
      _log('Lỗi: TV chưa kết nối!');
      return false;
    }

    try {
      _log('Chuẩn bị gửi ảnh $fileName (${(imageBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB) lên TV...');

      // 1. Tải ảnh qua REST upload endpoint cục bộ của TV Tizen (cổng 8001 / 8002)
      final uploadUri = Uri.parse('http://${_currentTv!.ip}:8001/api/v2/channels/com.samsung.art-app/file');
      final client = HttpClient()..badCertificateCallback = ((_, __, ___) => true);
      
      try {
        final request = await client.postUrl(uploadUri);
        request.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
        request.headers.set('file-name', fileName);
        request.headers.set('matte-id', matteId);
        request.add(imageBytes);
        final response = await request.close();
        _log('Tải file lên TV hoàn tất: mã phản hồi ${response.statusCode}');
      } catch (uploadError) {
        _log('Thử phương thức truyền binary qua WebSocket: $uploadError');
        // Fallback: Gửi binary payload trực tiếp qua socket
        _socket!.add(imageBytes);
      }

      // 2. Kích hoạt chọn và hiển thị ảnh vừa gửi
      final selectPayload = {
        'method': 'ms.channel.emit',
        'params': {
          'event': 'art_app_request',
          'to': 'host',
          'data': jsonEncode({
            'request': 'select_image',
            'image_id': fileName,
            'show': true,
          }),
        }
      };
      _socket!.add(jsonEncode(selectPayload));
      _log('Đã gửi lệnh hiển thị ảnh lên Art Mode của The Frame!');
      return true;
    } catch (e) {
      _log('Lỗi khi gửi ảnh lên TV: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
      _connectionStateController.add(false);
      _log('Đã đóng kết nối TV.');
    }
  }
}
