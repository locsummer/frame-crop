class TvDevice {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String? token;
  final String? macAddress;
  final bool isArtModeSupported;
  final bool isPaired;
  final DateTime? lastConnectedAt;

  const TvDevice({
    required this.id,
    required this.name,
    required this.ip,
    this.port = 8002,
    this.token,
    this.macAddress,
    this.isArtModeSupported = true,
    this.isPaired = false,
    this.lastConnectedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'port': port,
      'token': token,
      'macAddress': macAddress,
      'isArtModeSupported': isArtModeSupported,
      'isPaired': isPaired,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  factory TvDevice.fromJson(Map<String, dynamic> json) {
    return TvDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      ip: json['ip'] as String,
      port: json['port'] as int? ?? 8002,
      token: json['token'] as String?,
      macAddress: json['macAddress'] as String?,
      isArtModeSupported: json['isArtModeSupported'] as bool? ?? true,
      isPaired: json['isPaired'] as bool? ?? false,
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.tryParse(json['lastConnectedAt'] as String)
          : null,
    );
  }

  TvDevice copyWith({
    String? id,
    String? name,
    String? ip,
    int? port,
    String? token,
    String? macAddress,
    bool? isArtModeSupported,
    bool? isPaired,
    DateTime? lastConnectedAt,
  }) {
    return TvDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      token: token ?? this.token,
      macAddress: macAddress ?? this.macAddress,
      isArtModeSupported: isArtModeSupported ?? this.isArtModeSupported,
      isPaired: isPaired ?? this.isPaired,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }
}
