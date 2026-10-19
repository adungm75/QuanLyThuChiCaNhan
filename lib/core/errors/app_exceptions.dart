/// Lớp cơ sở (Base Class) cho tất cả ngoại lệ trong ứng dụng (Custom Exception Hierarchy)
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final DateTime timestamp;
  final dynamic details;

  AppException(
    this.message, {
    this.code,
    this.details,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final codeStr = code != null ? '[$code] ' : '';
    return '$codeStr$message';
  }
}

/// Ngoại lệ khi nhập số tiền âm hoặc không hợp lệ (<= 0)
class NegativeAmountException extends AppException {
  final double providedAmount;

  NegativeAmountException(this.providedAmount)
      : super(
          'Số tiền không thể âm hoặc bằng 0: ${providedAmount.toStringAsFixed(0)} đ. Vui lòng nhập số dương!',
          code: 'ERR_NEGATIVE_AMOUNT',
          details: {'providedAmount': providedAmount},
        );
}

/// Ngoại lệ dữ liệu giao dịch không hợp lệ (thiếu tiêu đề, danh mục rỗng, ...)
class InvalidTransactionException extends AppException {
  final String fieldName;

  InvalidTransactionException(this.fieldName, String message)
      : super(
          'Dữ liệu giao dịch không hợp lệ ở trường "$fieldName": $message',
          code: 'ERR_INVALID_TRANSACTION',
          details: {'field': fieldName},
        );
}

/// Ngoại lệ khi thao tác Database (đọc/ghi thất bại, lỗi kết nối, ...)
class DatabaseException extends AppException {
  final String operation; // 'READ', 'WRITE', 'DELETE', 'QUERY'

  DatabaseException(this.operation, String message, {dynamic cause})
      : super(
          'Lỗi cơ sở dữ liệu khi thực hiện [$operation]: $message',
          code: 'ERR_DATABASE_$operation',
          details: cause,
        );
}

/// Ngoại lệ khi chi tiêu vượt ngân sách tháng đã đặt ra
class BudgetExceededException extends AppException {
  final double currentTotal;
  final double budgetLimit;
  final double attemptedAmount;

  BudgetExceededException({
    required this.currentTotal,
    required this.budgetLimit,
    required this.attemptedAmount,
  }) : super(
          'Cảnh báo: Giao dịch này (${attemptedAmount.toStringAsFixed(0)} đ) làm tổng chi vượt ngân sách ${(budgetLimit).toStringAsFixed(0)} đ (Tổng sau khi thêm: ${(currentTotal + attemptedAmount).toStringAsFixed(0)} đ)!',
          code: 'WARN_BUDGET_EXCEEDED',
          details: {
            'currentTotal': currentTotal,
            'budgetLimit': budgetLimit,
            'attemptedAmount': attemptedAmount,
          },
        );
}

/// Ngoại lệ khi không tìm thấy mục cần tìm
class ItemNotFoundException extends AppException {
  final String id;

  ItemNotFoundException(this.id, [String entity = 'Mục'])
      : super(
          '$entity với ID "$id" không tồn tại trong hệ thống.',
          code: 'ERR_NOT_FOUND',
        );
}

/// Ngoại lệ lỗi validation chung
class ValidationException extends AppException {
  final Map<String, String> errors;

  ValidationException(this.errors)
      : super(
          'Phát hiện ${errors.length} lỗi khi kiểm tra dữ liệu: ${errors.values.join(", ")}',
          code: 'ERR_VALIDATION_FAILED',
          details: errors,
        );
}
