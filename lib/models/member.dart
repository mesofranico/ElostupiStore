class Member {
  final int? id;
  final String name;
  final String? email;
  final String phone;
  final String membershipType;
  final double monthlyFee;
  final DateTime joinDate;
  final bool isActive;
  final DateTime? lastPaymentDate;
  final DateTime? nextPaymentDate;
  final String? paymentStatus;

  final int? overdueMonths;
  final double? totalOverdue;

  Member({
    this.id,
    required this.name,
    this.email,
    required this.phone,
    required this.membershipType,
    required this.monthlyFee,
    required this.joinDate,
    this.isActive = true,
    this.lastPaymentDate,
    this.nextPaymentDate,
    this.paymentStatus,

    this.overdueMonths,
    this.totalOverdue,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'],
      membershipType: json['membership_type'],
      monthlyFee: double.parse(json['monthly_fee'].toString()),
      joinDate: _parseDateAsLocal(json['join_date']),
      isActive: json['is_active'] == 1,
      lastPaymentDate: json['last_payment_date'] != null 
          ? _parseDateAsLocal(json['last_payment_date']) 
          : null,
      nextPaymentDate: json['next_payment_date'] != null 
          ? _parseDateAsLocal(json['next_payment_date']) 
          : null,
      paymentStatus: json['payment_status'],

      overdueMonths: json['overdue_months'],
      totalOverdue: json['total_overdue'] != null ? double.parse(json['total_overdue'].toString()) : null,
    );
  }

  // Função para parsear data da API (já vem no timezone correto)
  static DateTime _parseDateAsLocal(String dateString) {
    // A API já retorna a data no timezone de Lisboa, então apenas parsear
    return DateTime.parse(dateString);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email ?? '',
      'phone': phone,
      'membership_type': membershipType,
      'monthly_fee': monthlyFee,
      'join_date': joinDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'next_payment_date': nextPaymentDate?.toIso8601String(),
      'payment_status': paymentStatus,

      'overdue_months': overdueMonths,
      'total_overdue': totalOverdue,
    };
  }

  Member copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? membershipType,
    double? monthlyFee,
    DateTime? joinDate,
    bool? isActive,
    DateTime? lastPaymentDate,
    DateTime? nextPaymentDate,
    String? paymentStatus,

    int? overdueMonths,
    double? totalOverdue,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      membershipType: membershipType ?? this.membershipType,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      
      overdueMonths: overdueMonths ?? this.overdueMonths,
      totalOverdue: totalOverdue ?? this.totalOverdue,
    );
  }
} 