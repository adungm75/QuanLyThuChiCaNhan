import 'package:flutter/material.dart';
import '../mixins/logging_mixin.dart';
import 'app_exceptions.dart';

/// Kết quả đã chuẩn hóa sau khi đi qua Centralized Error Pipeline
class ProcessedError {
  final String title;
  final String userMessage;
  final String? errorCode;
  final bool isWarning;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  ProcessedError({
    required this.title,
    required this.userMessage,
    this.errorCode,
    this.isWarning = false,
    required this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();
}

/// [CentralizedErrorHandler] - Cơ chế bắt và xử lý ngoại lệ tập trung
/// Áp dụng LoggingMixin để tự động ghi log lỗi vào hệ thống.
class CentralizedErrorHandler with LoggingMixin {
  CentralizedErrorHandler._();
  static final CentralizedErrorHandler instance = CentralizedErrorHandler._();

  final ValueNotifier<ProcessedError?> lastErrorNotifier = ValueNotifier<ProcessedError?>(null);

  /// Xử lý ngoại lệ tập trung (Pipeline: Phân loại -> Log -> Chuẩn hóa thông báo)
  ProcessedError process(dynamic error, [StackTrace? stackTrace]) {
    ProcessedError processed;

    if (error is NegativeAmountException) {
      logWarning('Phát hiện nhập số tiền âm: ${error.providedAmount}');
      processed = ProcessedError(
        title: 'Số tiền không hợp lệ',
        userMessage: error.message,
        errorCode: error.code,
        isWarning: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is InvalidTransactionException) {
      logWarning('Phát hiện dữ liệu giao dịch sai: ${error.fieldName} - ${error.message}');
      processed = ProcessedError(
        title: 'Thông tin chưa đầy đủ',
        userMessage: error.message,
        errorCode: error.code,
        isWarning: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is BudgetExceededException) {
      logWarning('Cảnh báo vượt hạn mức ngân sách: ${error.message}');
      processed = ProcessedError(
        title: 'Cảnh báo vượt ngân sách',
        userMessage: error.message,
        errorCode: error.code,
        isWarning: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is DatabaseException) {
      logError('Lỗi cơ sở dữ liệu [${error.operation}]: ${error.message}', error, stackTrace);
      processed = ProcessedError(
        title: 'Lỗi Cơ sở dữ liệu (${error.operation})',
        userMessage: error.message,
        errorCode: error.code,
        isWarning: false,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is AppException) {
      logError('Lỗi ứng dụng [${error.code}]: ${error.message}', error, stackTrace);
      processed = ProcessedError(
        title: 'Lỗi hệ thống',
        userMessage: error.message,
        errorCode: error.code,
        isWarning: false,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is FormatException) {
      logError('Lỗi định dạng dữ liệu: ${error.message}', error, stackTrace);
      processed = ProcessedError(
        title: 'Sai định dạng',
        userMessage: 'Dữ liệu nhập vào không đúng định dạng: ${error.message}',
        errorCode: 'ERR_FORMAT',
        isWarning: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else {
      logError('Ngoại lệ chưa xác định: $error', error, stackTrace);
      processed = ProcessedError(
        title: 'Có lỗi xảy ra',
        userMessage: 'Đã xảy ra sự cố ngoài ý muốn: ${error.toString()}',
        errorCode: 'ERR_UNKNOWN',
        isWarning: false,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    lastErrorNotifier.value = processed;
    return processed;
  }

  /// Hiển thị SnackBar thông báo lỗi cho người dùng một cách nhất quán
  void showErrorSnackBar(BuildContext context, dynamic error, [StackTrace? stackTrace]) {
    final processed = process(error, stackTrace);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              processed.isWarning ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    processed.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    processed.userMessage,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: processed.isWarning ? Colors.orange.shade800 : Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Hiển thị Dialog chi tiết lỗi
  Future<void> showErrorDialog(BuildContext context, dynamic error, [StackTrace? stackTrace]) async {
    final processed = process(error, stackTrace);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          processed.isWarning ? Icons.warning_rounded : Icons.error_rounded,
          color: processed.isWarning ? Colors.orange : Colors.red,
          size: 40,
        ),
        title: Text(processed.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(processed.userMessage),
            if (processed.errorCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Mã lỗi: ${processed.errorCode}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black87),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
