import 'package:flutter/foundation.dart';

/// Enum phân loại mức độ ghi log
enum LogLevel { info, warning, error, debug }

/// Model lưu thông tin log để có thể hiển thị trong Error Log Inspector
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String sender;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.sender,
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    return '[$timeStr] [${level.name.toUpperCase()}] [$sender]: $message';
  }
}

/// Singleton lưu trữ bộ nhớ đệm các log trong phiên làm việc
class LogStore {
  LogStore._();
  static final LogStore instance = LogStore._();

  final List<LogEntry> _logs = [];
  final ValueNotifier<int> logCountNotifier = ValueNotifier<int>(0);

  List<LogEntry> get logs => List.unmodifiable(_logs.reversed);

  void add(LogEntry entry) {
    _logs.add(entry);
    logCountNotifier.value = _logs.length;
    if (kDebugMode) {
      debugPrint(entry.toString());
      if (entry.error != null) {
        debugPrint('   => Detail Error: ${entry.error}');
      }
    }
  }

  void clear() {
    _logs.clear();
    logCountNotifier.value = 0;
  }
}

/// [LoggingMixin] - Demo tính năng Mixin trong OOP Dart
/// Cung cấp khả năng ghi log chuẩn hóa cho bất kỳ class nào `with LoggingMixin`.
/// Tự động đính kèm tên class (runtimeType) và thời gian thực.
mixin LoggingMixin {
  String get logTag => runtimeType.toString();

  void logInfo(String message) {
    _log(LogLevel.info, message);
  }

  void logWarning(String message) {
    _log(LogLevel.warning, message);
  }

  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  void logDebug(String message) {
    _log(LogLevel.debug, message);
  }

  void _log(LogLevel level, String message, {Object? error, StackTrace? stackTrace}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      sender: logTag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    LogStore.instance.add(entry);
  }
}
