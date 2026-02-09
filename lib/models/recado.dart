class Recado {
  final String id;
  final String titulo;
  final String pessoa;
  final String instrucao;
  final DateTime? dataLimite;
  final bool alerta;

  Recado({
    required this.id,
    required this.titulo,
    required this.pessoa,
    required this.instrucao,
    this.dataLimite,
    this.alerta = false,
  });

  factory Recado.fromJson(Map<String, dynamic> json) {
    return Recado(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      pessoa: json['pessoa']?.toString() ?? '',
      instrucao: json['instrucao']?.toString() ?? '',
      dataLimite: json['dataLimite'] != null ? DateTime.tryParse(json['dataLimite'].toString()) : null,
      alerta: json['alerta'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'pessoa': pessoa,
      'instrucao': instrucao,
      'dataLimite': dataLimite?.toIso8601String(),
      'alerta': alerta,
    };
  }

  int? get diasRestantes {
    if (dataLimite == null) return null;
    final now = DateTime.now();
    final limit = DateTime(dataLimite!.year, dataLimite!.month, dataLimite!.day);
    final today = DateTime(now.year, now.month, now.day);
    return limit.difference(today).inDays;
  }

  Recado copyWith({
    String? id,
    String? titulo,
    String? pessoa,
    String? instrucao,
    DateTime? dataLimite,
    bool? alerta,
  }) {
    return Recado(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      pessoa: pessoa ?? this.pessoa,
      instrucao: instrucao ?? this.instrucao,
      dataLimite: dataLimite ?? this.dataLimite,
      alerta: alerta ?? this.alerta,
    );
  }
}
