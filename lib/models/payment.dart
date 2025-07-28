class Payment {
  final int? id;
  final int memberId;
  final double amount;
  final DateTime paymentDate;
  final String status;
  final String paymentType;
  final String? memberName;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.memberId,
    required this.amount,
    required this.paymentDate,
    required this.status,
    required this.paymentType,
    this.memberName,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      memberId: json['member_id'],
      amount: double.parse(json['amount'].toString()),
      paymentDate: DateTime.parse(json['payment_date']),
      status: json['status'],
      paymentType: json['payment_type'] ?? 'regular',
      memberName: json['member_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'status': status,
      'payment_type': paymentType,
      'member_name': memberName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Payment copyWith({
    int? id,
    int? memberId,
    double? amount,
    DateTime? paymentDate,
    String? status,
    String? paymentType,
    String? memberName,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      paymentType: paymentType ?? this.paymentType,
      memberName: memberName ?? this.memberName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 