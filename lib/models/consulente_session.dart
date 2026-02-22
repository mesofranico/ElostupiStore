import 'dart:convert';

class ConsulenteSession {
  static List<int>? _parseAcompanhantesIds(dynamic acompanhantesIds) {
    if (acompanhantesIds == null) return null;

    // Se já é uma lista, converter para List<int>
    if (acompanhantesIds is List) {
      return acompanhantesIds
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .toList();
    }

    // Se é uma string JSON, fazer parse
    if (acompanhantesIds is String) {
      try {
        final List<dynamic> parsed = json.decode(acompanhantesIds);
        return parsed
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .toList();
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  final int? id;
  final int consulenteId;
  final DateTime sessionDate;
  final String description;
  final String? notes;
  final List<int>? acompanhantesIds; // IDs dos consulentes acompanhantes
  final int extraAcompanhantes; // Número de acompanhantes não registados
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConsulenteSession({
    this.id,
    required this.consulenteId,
    required this.sessionDate,
    required this.description,
    this.notes,
    this.acompanhantesIds,
    this.extraAcompanhantes = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ConsulenteSession.fromJson(Map<String, dynamic> json) {
    return ConsulenteSession(
      id: json['id'],
      consulenteId: json['consulente_id'] ?? 0,
      sessionDate: DateTime.parse(json['session_date']),
      description: json['description'] ?? '',
      notes: json['notes'],
      acompanhantesIds: json['acompanhantes_ids'] != null
          ? _parseAcompanhantesIds(json['acompanhantes_ids'])
          : null,
      extraAcompanhantes: json['extra_acompanhantes'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consulente_id': consulenteId,
      'session_date': sessionDate.toIso8601String(),
      'description': description,
      'notes': notes,
      'acompanhantes_ids': acompanhantesIds,
      'extra_acompanhantes': extraAcompanhantes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ConsulenteSession copyWith({
    int? id,
    int? consulenteId,
    DateTime? sessionDate,
    String? description,
    String? notes,
    List<int>? acompanhantesIds,
    int? extraAcompanhantes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsulenteSession(
      id: id ?? this.id,
      consulenteId: consulenteId ?? this.consulenteId,
      sessionDate: sessionDate ?? this.sessionDate,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      acompanhantesIds: acompanhantesIds ?? this.acompanhantesIds,
      extraAcompanhantes: extraAcompanhantes ?? this.extraAcompanhantes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ConsulenteSession(id: $id, consulenteId: $consulenteId, sessionDate: $sessionDate, description: $description, extraAcompanhantes: $extraAcompanhantes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsulenteSession &&
        other.id == id &&
        other.consulenteId == consulenteId &&
        other.sessionDate == sessionDate &&
        other.description == description &&
        other.notes == notes &&
        other.acompanhantesIds == acompanhantesIds &&
        other.extraAcompanhantes == extraAcompanhantes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        consulenteId.hashCode ^
        sessionDate.hashCode ^
        description.hashCode ^
        notes.hashCode ^
        acompanhantesIds.hashCode ^
        extraAcompanhantes.hashCode;
  }
}
