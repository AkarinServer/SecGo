class Kiosk {
  final int? id;
  final String ip;
  final int port;
  final String pin;
  final String? name;
  final int? lastSynced;
  final String? deviceId;

  Kiosk({
    this.id,
    required this.ip,
    required this.port,
    required this.pin,
    this.name,
    this.lastSynced,
    this.deviceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ip': ip,
      'port': port,
      'pin': pin,
      'name': name,
      'last_synced': lastSynced,
      'device_id': deviceId,
    };
  }

  factory Kiosk.fromMap(Map<String, dynamic> map) {
    return Kiosk(
      id: map['id'],
      ip: map['ip'],
      port: map['port'],
      pin: map['pin'],
      name: map['name'],
      lastSynced: map['last_synced'],
      deviceId: map['device_id'],
    );
  }
}
