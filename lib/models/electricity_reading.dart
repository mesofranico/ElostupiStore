class ElectricityReading {
  final int id;
  final double counterValue; // Valor total do contador
  final double kwConsumed; // KW consumidos (calculado)
  final double pricePerKw;
  final double totalCost;
  final DateTime readingDate;
  final String notes;

  ElectricityReading({
    required this.id,
    required this.counterValue,
    required this.kwConsumed,
    required this.pricePerKw,
    required this.totalCost,
    required this.readingDate,
    this.notes = '',
  });

  factory ElectricityReading.fromJson(Map<String, dynamic> json) {
    return ElectricityReading(
      id: json['id'],
      counterValue: double.parse(json['counter_value'].toString()).toInt().toDouble(), // Garantir que seja inteiro
      kwConsumed: double.parse(json['kw_consumed'].toString()).toInt().toDouble(), // Garantir que seja inteiro
      pricePerKw: double.parse(json['price_per_kw'].toString()),
      totalCost: double.parse(json['total_cost'].toString()),
      readingDate: DateTime.parse(json['reading_date']),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'counter_value': counterValue,
      'kw_consumed': kwConsumed,
      'price_per_kw': pricePerKw,
      'total_cost': totalCost,
      'reading_date': readingDate.toIso8601String(),
      'notes': notes,
    };
  }

  // Calcula o custo total com IVA de 23%
  double calculateTotalWithVAT() {
    return totalCost * 1.23;
  }
} 