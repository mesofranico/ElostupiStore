import 'dart:convert';

class FinancialRecord {
  final int? id;
  final String type; // 'income' or 'expense'
  final String category;
  final double amount;
  final String? description;
  final DateTime recordDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? details;

  FinancialRecord({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.description,
    required this.recordDate,
    this.createdAt,
    this.updatedAt,
    this.details,
  });

  factory FinancialRecord.fromJson(Map<String, dynamic> json) {
    return FinancialRecord(
      id: json['id'],
      type: json['type'],
      category: json['category'],
      amount: double.parse(json['amount'].toString()),
      description: json['description'],
      recordDate: DateTime.parse(json['record_date']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      details: json['details'] != null
          ? (json['details'] is String
                ? Map<String, dynamic>.from(jsonDecode(json['details']))
                : Map<String, dynamic>.from(json['details']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'record_date': recordDate.toIso8601String().split('T')[0],
      'details': details,
    };
  }

  FinancialRecord copyWith({
    int? id,
    String? type,
    String? category,
    double? amount,
    String? description,
    DateTime? recordDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? details,
  }) {
    return FinancialRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      details: details ?? this.details,
    );
  }
}
