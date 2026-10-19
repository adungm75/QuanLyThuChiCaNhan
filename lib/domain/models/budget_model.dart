import '../../core/errors/app_exceptions.dart';

/// Thực thể Ngân sách hàng tháng (Monthly Budget)
class Budget {
  final String id;
  final int month;
  final int year;
  final double limitAmount;

  const Budget({
    required this.id,
    required this.month,
    required this.year,
    required this.limitAmount,
  });

  /// Named constructor
  Budget.create({
    required this.month,
    required this.year,
    required this.limitAmount,
  }) : id = '${year}_${month.toString().padLeft(2, '0')}' {
    if (limitAmount <= 0) {
      throw NegativeAmountException(limitAmount);
    }
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      limitAmount: (json['limitAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'limitAmount': limitAmount,
    };
  }

  Budget copyWith({
    String? id,
    int? month,
    int? year,
    double? limitAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }
}
