import 'package:flutter/material.dart';
import '../models/tv_device.dart';
import '../services/samsung_tv_service.dart';

class TvScreen extends StatefulWidget {
  const TvScreen({super.key});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  final _tvService = SamsungTvService();
  final _ipController = TextEditingController(text: '192.168.1.');
  final _portController = TextEditingController(text: '8002');
  final _tokenController = TextEditingController();

  List<TvDevice> _discoveredTvs = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _tvService.logStream.listen((msg) {
      if (mounted) {
        setState(() {
          _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} - $msg');
          if (_logs.length > 50) _logs.removeLast();
        });
      }
    });
  }

  Future<void> _scanNetwork() async {
    setState(() => _isScanning = true);
    final tvs = await _tvService.discoverTvs();
    if (mounted) {
      setState(() {
        _discoveredTvs = tvs;
        _isScanning = false;
      });
      if (tvs.isNotEmpty) {
        _selectTv(tvs.first);
      }
    }
  }

  void _selectTv(TvDevice tv) {
    _ipController.text = tv.ip;
    _portController.text = tv.port.toString();
    if (tv.token != null) {
      _tokenController.text = tv.token!;
    }
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8002;
    final token = _tokenController.text.trim().isNotEmpty ? _tokenController.text.trim() : null;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ IP của TV')),
      );
      return;
    }

    setState(() => _isConnecting = true);

    final device = TvDevice(
      id: 'manual_$ip',
      name: 'Samsung The Frame',
      ip: ip,
      port: port,
      token: token,
    );

    final success = await _tvService.connect(device);
    if (mounted) {
      setState(() => _isConnecting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kết nối TV thành công! Nhìn màn hình TV nếu có popup yêu cầu cấp quyền.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể kết nối. Hãy kiểm tra IP và đảm bảo điện thoại cùng mạng Wi-Fi với TV.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = _tvService.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kết Nối Samsung The Frame',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.radar),
            tooltip: 'Quét tự động trong Wi-Fi',
            onPressed: _isScanning ? null : _scanNetwork,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Trạng thái kết nối
          Card(
            color: isConnected ? Colors.teal.shade900.withOpacity(0.4) : theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isConnected ? Colors.tealAccent : Colors.grey.shade800,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? Colors.tealAccent : Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: isConnected ? Colors.tealAccent.withOpacity(0.6) : Colors.redAccent.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? 'Đã kết nối TV The Frame' : 'Chưa kết nối TV',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected
                              ? 'IP: ${_tvService.currentTv?.ip ?? ""} • Cổng: ${_tvService.currentTv?.port ?? 8002}'
                              : 'Hãy quét Wi-Fi hoặc nhập IP bên dưới',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  if (isConnected)
                    OutlinedButton(
                      onPressed: () async {
                        await _tvService.disconnect();
                        setState(() {});
                      },
                      child: const Text('Ngắt'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Điều khiển Art Mode (Nếu đã kết nối)
          if (isConnected) ...[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.art_track, color: Colors.amberAccent),
                        const SizedBox(width: 8),
                        const Text(
                          'Chế độ nghệ thuật (Art Mode)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Spacer(),
                        StreamBuilder<bool>(
                          stream: _tvService.artModeStateStream,
                          initialData: _tvService.isArtModeOn,
                          builder: (context, snapshot) {
                            final isOn = snapshot.data ?? false;
                            return Switch(
                              value: isOn,
                              onChanged: (val) {
                                _tvService.toggleArtMode(val);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bật/Tắt chế độ tranh nghệ thuật trên Samsung The Frame từ xa qua mạng Wi-Fi.',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Danh sách TV phát hiện được
          if (_discoveredTvs.isNotEmpty) ...[
            Text(
              'THIẾT BỊ PHÁT HIỆN QUA MẠNG NỘI BỘ (SSDP)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            ..._discoveredTvs.map((tv) => ListTile(
                  leading: const Icon(Icons.tv),
                  title: Text(tv.name),
                  subtitle: Text('IP: ${tv.ip} • Port: ${tv.port}'),
                  trailing: const Icon(Icons.chevron_right),
                  tileColor: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => _selectTv(tv),
                )),
            const SizedBox(height: 16),
          ],

          // Form nhập IP thủ công
          Text(
            'THÔNG TIN KẾT NỐI THỦ CÔNG',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ IP của TV (ví dụ: 192.168.1.50)',
              prefixIcon: Icon(Icons.network_wifi),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Cổng (8002)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Token ghép đôi (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isConnecting ? null : _connect,
            icon: _isConnecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.link),
            label: Text(_isConnecting ? 'Đang kết nối...' : 'Kết Nối Với TV'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
          ),
          const SizedBox(height: 24),

          // Nhật ký giao thức (Protocol Logs)
          Text(
            'NHẬT KÝ GIAO THỨC LAN / WEBSOCKET',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 140,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có hoạt động giao tiếp nào',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.greenAccent,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
