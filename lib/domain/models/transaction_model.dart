import 'category_model.dart';
import '../../core/errors/app_exceptions.dart';

/// Lớp thực thể (Entity) đại diện cho một Giao dịch tài chính
/// Thể hiện tính đóng gói (Encapsulation), Named Constructors và Validation logic
class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionCategory category;
  final TransactionType type;
  final String? note;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.note,
  });

  /// Named Constructor: Tạo giao dịch Chi tiêu (Expense)
  Transaction.expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
  }) : type = TransactionType.expense {
    validate();
  }

  /// Named Constructor: Tạo giao dịch Thu nhập (Income)
  Transaction.income({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
  }) : type = TransactionType.income {
    validate();
  }

  /// Kiểm tra tính toàn vẹn của dữ liệu giao dịch
  /// Ném ra các Custom Exception nếu vi phạm nghiệp vụ
  void validate() {
    if (amount <= 0) {
      throw NegativeAmountException(amount);
    }
    if (title.trim().isEmpty) {
      throw InvalidTransactionException('title', 'Tiêu đề giao dịch không được để trống.');
    }
  }

  /// Factory constructor parse từ JSON / Map
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: TransactionCategory.findById(json['categoryId'] as String),
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': category.id,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'note': note,
    };
  }

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    TransactionCategory? category,
    TransactionType? type,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, title: $title, amount: $amount, type: ${type.name}, date: $date)';
  }
}
