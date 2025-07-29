class ElectricitySettings {
  final int id;
  final double defaultPricePerKw;
  final double vatRate;
  final DateTime updatedAt;

  ElectricitySettings({
    required this.id,
    required this.defaultPricePerKw,
    required this.vatRate,
    required this.updatedAt,
  });

  factory ElectricitySettings.fromJson(Map<String, dynamic> json) {
    return ElectricitySettings(
      id: json['id'],
      defaultPricePerKw: double.parse(json['default_price_per_kw'].toString()),
      vatRate: double.parse(json['vat_rate'].toString()),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'default_price_per_kw': defaultPricePerKw,
      'vat_rate': vatRate,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Criar configurações padrão
  factory ElectricitySettings.defaultSettings() {
    return ElectricitySettings(
      id: 1,
      defaultPricePerKw: 0.15,
      vatRate: 23.0,
      updatedAt: DateTime.now(),
    );
  }
} 