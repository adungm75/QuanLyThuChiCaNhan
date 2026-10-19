import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../../core/errors/app_exceptions.dart';

/// [TransactionFactory] - Triển khai Factory Pattern trong OOP Dart
/// Đóng gói logic khởi tạo và kiểm tra tính hợp lệ trước khi tạo thực thể Transaction
class TransactionFactory {
  // Private constructor để biến class thành Factory thuần túy
  TransactionFactory._();

  /// Tạo giao dịch mới dựa vào loại (Type)
  static Transaction create({
    String? id,
    required String title,
    required double amount,
    DateTime? date,
    required TransactionCategory category,
    required TransactionType type,
    String? note,
  }) {
    // 1. Kiểm tra nghiệp vụ số tiền
    if (amount <= 0) {
      throw NegativeAmountException(amount);
    }

    // 2. Kiểm tra nghiệp vụ tiêu đề
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw InvalidTransactionException('title', 'Tên giao dịch không được bỏ trống.');
    }

    // 3. Tự sinh id nếu chưa có
    final finalId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final finalDate = date ?? DateTime.now();

    // 4. Khởi tạo theo đúng loại
    if (type == TransactionType.income) {
      return Transaction.income(
        id: finalId,
        title: cleanTitle,
        amount: amount,
        date: finalDate,
        category: category,
        note: note,
      );
    } else {
      return Transaction.expense(
        id: finalId,
        title: cleanTitle,
        amount: amount,
        date: finalDate,
        category: category,
        note: note,
      );
    }
  }

  /// Factory helper: Tạo nhanh Chi tiêu
  static Transaction createExpense({
    String? id,
    required String title,
    required double amount,
    DateTime? date,
    required TransactionCategory category,
    String? note,
  }) {
    return create(
      id: id,
      title: title,
      amount: amount,
      date: date,
      category: category,
      type: TransactionType.expense,
      note: note,
    );
  }

  /// Factory helper: Tạo nhanh Thu nhập
  static Transaction createIncome({
    String? id,
    required String title,
    required double amount,
    DateTime? date,
    required TransactionCategory category,
    String? note,
  }) {
    return create(
      id: id,
      title: title,
      amount: amount,
      date: date,
      category: category,
      type: TransactionType.income,
      note: note,
    );
  }

  /// Tạo dữ liệu mẫu đa dạng cho demo
  static List<Transaction> createDemoSamples() {
    final now = DateTime.now();
    return [
      createIncome(
        title: 'Nhận lương tháng này',
        amount: 25000000,
        date: DateTime(now.year, now.month, 5, 9, 30),
        category: TransactionCategory.findById('salary'),
        note: 'Lương chuyển khoản công ty',
      ),
      createIncome(
        title: 'Thưởng dự án hoàn thành',
        amount: 5000000,
        date: DateTime(now.year, now.month, 10, 15, 00),
        category: TransactionCategory.findById('bonus'),
        note: 'Thưởng KPI quý',
      ),
      createExpense(
        title: 'Đi siêu thị VinMart',
        amount: 850000,
        date: DateTime(now.year, now.month, 6, 18, 20),
        category: TransactionCategory.findById('food'),
        note: 'Mua thực phẩm tuần',
      ),
      createExpense(
        title: 'Tiền điện nước & Internet',
        amount: 1450000,
        date: DateTime(now.year, now.month, 8, 10, 15),
        category: TransactionCategory.findById('bills'),
        note: 'Hóa đơn định kỳ',
      ),
      createExpense(
        title: 'Đổ xăng xe máy & Bảo dưỡng',
        amount: 320000,
        date: DateTime(now.year, now.month, 12, 14, 00),
        category: TransactionCategory.findById('transport'),
        note: 'Xăng RON 95',
      ),
      createExpense(
        title: 'Mua tai nghe bluetooth',
        amount: 1200000,
        date: DateTime(now.year, now.month, 14, 20, 45),
        category: TransactionCategory.findById('shopping'),
        note: 'Khuyến mãi Shopee',
      ),
      createExpense(
        title: 'Xem phim cuối tuần',
        amount: 250000,
        date: DateTime(now.year, now.month, 16, 19, 30),
        category: TransactionCategory.findById('entertainment'),
        note: 'Vé CGV + bắp nước',
      ),
    ];
  }
}
