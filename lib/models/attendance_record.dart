import 'package:intl/intl.dart';

class AttendanceRecord {
  int? id;
  int consulenteId;
  DateTime attendanceDate;
  String status; // 'present', 'absent', 'pending'
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Campos adicionais para exibição
  String? consulenteName;
  String? consulentePhone;
  String? consulenteEmail;

  AttendanceRecord({
    this.id,
    required this.consulenteId,
    required this.attendanceDate,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.consulenteName,
    this.consulentePhone,
    this.consulenteEmail,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      consulenteId: json['consulente_id'],
      attendanceDate: DateTime.parse(json['attendance_date']),
      status: json['status'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      consulenteName: json['consulente_name'],
      consulentePhone: json['consulente_phone'],
      consulenteEmail: json['consulente_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consulente_id': consulenteId,
      'attendance_date': DateFormat('yyyy-MM-dd').format(attendanceDate),
      'status': status,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'consulente_id': consulenteId,
      'attendance_date': DateFormat('yyyy-MM-dd').format(attendanceDate),
      'status': status,
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'status': status,
      'notes': notes,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'present':
        return 'Presente';
      case 'absent':
        return 'Faltou';
      case 'pending':
        return 'Pendente';
      default:
        return 'Desconhecido';
    }
  }

  String get statusIcon {
    switch (status) {
      case 'present':
        return '✓';
      case 'absent':
        return '✗';
      case 'pending':
        return '?';
      default:
        return '?';
    }
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(attendanceDate);
  }

  String get formattedDateTime {
    return DateFormat('dd/MM/yyyy HH:mm').format(attendanceDate);
  }

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isPending => status == 'pending';

  AttendanceRecord copyWith({
    int? id,
    int? consulenteId,
    DateTime? attendanceDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? consulenteName,
    String? consulentePhone,
    String? consulenteEmail,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      consulenteId: consulenteId ?? this.consulenteId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      consulenteName: consulenteName ?? this.consulenteName,
      consulentePhone: consulentePhone ?? this.consulentePhone,
      consulenteEmail: consulenteEmail ?? this.consulenteEmail,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord(id: $id, consulenteId: $consulenteId, attendanceDate: $attendanceDate, status: $status, consulenteName: $consulenteName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceRecord &&
        other.id == id &&
        other.consulenteId == consulenteId &&
        other.attendanceDate == attendanceDate &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        consulenteId.hashCode ^
        attendanceDate.hashCode ^
        status.hashCode;
  }
}
