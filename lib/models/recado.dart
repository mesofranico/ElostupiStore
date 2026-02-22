import 'dart:convert';

class Recado {
  final String id;
  final String titulo;
  final String pessoa;
  final String instrucao;
  final DateTime? dataLimite;
  final bool alerta;
  final List<int>? consulenteIds;
  final List<String>? consulenteNames;

  Recado({
    required this.id,
    required this.titulo,
    required this.pessoa,
    required this.instrucao,
    this.dataLimite,
    required this.alerta,
    this.consulenteIds,
    this.consulenteNames,
  });

  factory Recado.fromJson(Map<String, dynamic> json) {
    // Parsing consulenteIds (support JSON string or List)
    List<int>? ids;
    var rawIds = json['consulenteIds'] ?? json['consulente_ids'];
    if (rawIds != null) {
      if (rawIds is String) {
        try {
          ids = (jsonDecode(rawIds) as List)
              .map((e) => int.parse(e.toString()))
              .toList();
        } catch (_) {}
      } else if (rawIds is List) {
        ids = rawIds.map((e) => int.parse(e.toString())).toList();
      } else {
        ids = [int.parse(rawIds.toString())];
      }
    }

    // Parsing consulenteNames
    List<String>? names;
    var rawNames = json['consulenteNames'] ?? json['consulente_names'];
    if (rawNames != null) {
      if (rawNames is String) {
        try {
          names = (jsonDecode(rawNames) as List)
              .map((e) => e.toString())
              .toList();
        } catch (_) {
          names = [rawNames];
        }
      } else if (rawNames is List) {
        names = rawNames.map((e) => e.toString()).toList();
      } else {
        names = [rawNames.toString()];
      }
    }

    return Recado(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      pessoa: json['pessoa']?.toString() ?? '',
      instrucao: json['instrucao']?.toString() ?? '',
      dataLimite: json['dataLimite'] != null
          ? DateTime.tryParse(json['dataLimite'].toString())
          : (json['data_limite'] != null
                ? DateTime.tryParse(json['data_limite'].toString())
                : null),
      alerta: json['alerta'] == true || json['alerta'] == 1,
      consulenteIds: ids,
      consulenteNames: names,
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
      'consulenteIds': consulenteIds,
      'consulenteNames': consulenteNames,
    };
  }

  int? get diasRestantes {
    if (dataLimite == null) return null;
    final now = DateTime.now();
    final limit = DateTime(
      dataLimite!.year,
      dataLimite!.month,
      dataLimite!.day,
    );
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
    List<int>? consulenteIds,
    List<String>? consulenteNames,
  }) {
    return Recado(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      pessoa: pessoa ?? this.pessoa,
      instrucao: instrucao ?? this.instrucao,
      dataLimite: dataLimite ?? this.dataLimite,
      alerta: alerta ?? this.alerta,
      consulenteIds: consulenteIds ?? this.consulenteIds,
      consulenteNames: consulenteNames ?? this.consulenteNames,
    );
  }
}
