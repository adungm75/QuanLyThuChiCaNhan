import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/mixins/logging_mixin.dart';
import '../../domain/factories/transaction_factory.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/budget_model.dart';

/// [InMemoryDatabase] - Cơ sở dữ liệu lưu trữ cục bộ (Local Persistent Storage)
/// Tích hợp SharedPreferences để lưu vĩnh viễn dữ liệu trên thiết bị Android/iOS/Desktop.
/// Dữ liệu sẽ KHÔNG bị mất kể cả khi tắt hẳn app hoặc xóa khỏi ứng dụng chạy ngầm.
class InMemoryDatabase with LoggingMixin {
  InMemoryDatabase._() {
    _initSampleData();
  }
  static final InMemoryDatabase instance = InMemoryDatabase._();

  static const String _transactionsKey = 'expense_tracker_transactions_v1';
  static const String _budgetsKey = 'expense_tracker_budgets_v1';

  final Map<String, Transaction> _transactionsTable = {};
  final Map<String, Budget> _budgetsTable = {};
  bool _isInitialized = false;

  // Các cờ cấu hình giả lập lỗi Database phục vụ mục đích kiểm thử và demo
  bool simulateReadError = false;
  bool simulateWriteError = false;
  bool simulateDeleteError = false;

  /// Khởi tạo và nạp dữ liệu đã lưu từ bộ nhớ vĩnh viễn (Persistent Storage)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Nạp danh sách Giao dịch
      final txJsonString = prefs.getString(_transactionsKey);
      if (txJsonString != null && txJsonString.isNotEmpty) {
        final List<dynamic> rawList = jsonDecode(txJsonString);
        _transactionsTable.clear();
        for (var item in rawList) {
          final tx = Transaction.fromJson(Map<String, dynamic>.from(item as Map));
          _transactionsTable[tx.id] = tx;
        }
        logInfo('Đã khôi phục ${_transactionsTable.length} giao dịch từ bộ nhớ máy.');
      } else {
        // Lần đầu mở app: khởi tạo dữ liệu mẫu và lưu vào bộ nhớ máy
        _initSampleData();
        await _persistTransactions(prefs);
      }

      // 2. Nạp danh sách Ngân sách
      final budgetJsonString = prefs.getString(_budgetsKey);
      if (budgetJsonString != null && budgetJsonString.isNotEmpty) {
        final List<dynamic> rawList = jsonDecode(budgetJsonString);
        _budgetsTable.clear();
        for (var item in rawList) {
          final budget = Budget.fromJson(Map<String, dynamic>.from(item as Map));
          _budgetsTable[budget.id] = budget;
        }
        logInfo('Đã khôi phục ${_budgetsTable.length} hạn mức ngân sách từ bộ nhớ máy.');
      } else {
        final now = DateTime.now();
        final sampleBudget = Budget.create(month: now.month, year: now.year, limitAmount: 10000000);
        _budgetsTable[sampleBudget.id] = sampleBudget;
        await _persistBudgets(prefs);
      }

      _isInitialized = true;
    } catch (e, stackTrace) {
      logError('Lỗi khởi tạo bộ nhớ lưu trữ', e, stackTrace);
      // Fallback về sample data nếu đọc file gặp lỗi
      _initSampleData();
      _isInitialized = true;
    }
  }

  void _initSampleData() {
    final samples = TransactionFactory.createDemoSamples();
    for (var tx in samples) {
      _transactionsTable[tx.id] = tx;
    }
    final now = DateTime.now();
    final sampleBudget = Budget.create(month: now.month, year: now.year, limitAmount: 10000000);
    _budgetsTable[sampleBudget.id] = sampleBudget;
    logInfo('Khởi tạo cơ sở dữ liệu mẫu ban đầu: ${_transactionsTable.length} giao dịch');
  }

  /// Ghi đè danh sách giao dịch xuống bộ nhớ vĩnh viễn (Disk / SharedPreferences)
  Future<void> _persistTransactions([SharedPreferences? existingPrefs]) async {
    try {
      final prefs = existingPrefs ?? await SharedPreferences.getInstance();
      final list = _transactionsTable.values.map((t) => t.toJson()).toList();
      await prefs.setString(_transactionsKey, jsonEncode(list));
      logDebug('Đã ghi vĩnh viễn ${list.length} giao dịch xuống ổ đĩa.');
    } catch (e, stackTrace) {
      logError('Không thể lưu giao dịch xuống ổ đĩa', e, stackTrace);
      throw DatabaseException('WRITE', 'Lỗi I/O khi lưu trữ dữ liệu vĩnh viễn: $e');
    }
  }

  /// Ghi đè danh sách ngân sách xuống bộ nhớ vĩnh viễn
  Future<void> _persistBudgets([SharedPreferences? existingPrefs]) async {
    try {
      final prefs = existingPrefs ?? await SharedPreferences.getInstance();
      final list = _budgetsTable.values.map((b) => b.toJson()).toList();
      await prefs.setString(_budgetsKey, jsonEncode(list));
      logDebug('Đã ghi vĩnh viễn ${list.length} hạn mức ngân sách xuống ổ đĩa.');
    } catch (e, stackTrace) {
      logError('Không thể lưu ngân sách xuống ổ đĩa', e, stackTrace);
      throw DatabaseException('WRITE', 'Lỗi I/O khi lưu trữ ngân sách: $e');
    }
  }

  // --- Transactions Operations ---

  Future<List<Transaction>> queryTransactions() async {
    if (!_isInitialized) await init();
    await Future.delayed(const Duration(milliseconds: 80));

    if (simulateReadError) {
      logError('Mô phỏng lỗi: Không thể kết nối hoặc đọc bảng Transactions');
      throw DatabaseException('READ', 'Mất kết nối tới cơ sở dữ liệu hoặc phân vùng lưu trữ bị khóa.');
    }

    return _transactionsTable.values.toList();
  }

  Future<Transaction?> findTransactionById(String id) async {
    if (!_isInitialized) await init();
    await Future.delayed(const Duration(milliseconds: 30));
    if (simulateReadError) {
      throw DatabaseException('READ', 'Lỗi truy vấn bản ghi $id từ bộ nhớ.');
    }
    return _transactionsTable[id];
  }

  Future<void> insertTransaction(Transaction transaction) async {
    if (!_isInitialized) await init();
    await Future.delayed(const Duration(milliseconds: 80));
    if (simulateWriteError) {
      logError('Mô phỏng lỗi: Không thể ghi dữ liệu giao dịch [${transaction.id}]');
      throw DatabaseException('WRITE', 'Dung lượng bộ nhớ đầy hoặc không có quyền ghi dữ liệu.');
    }
    _transactionsTable[transaction.id] = transaction;
    await _persistTransactions();
    logInfo('Thêm mới thành công và đã lưu vĩnh viễn giao dịch ID: ${transaction.id}');
  }

  Future<void> updateTransaction(Transaction transaction) async {
    if (!_isInitialized) await init();
    await Future.delayed(const Duration(milliseconds: 80));
    if (simulateWriteError) {
      logError('Mô phỏng lỗi: Cập nhật giao dịch [${transaction.id}] thất bại');
      throw DatabaseException('WRITE', 'Lỗi xung đột phiên bản dữ liệu khi cập nhật.');
    }
    if (!_transactionsTable.containsKey(transaction.id)) {
      throw ItemNotFoundException(transaction.id, 'Giao dịch');
    }
    _transactionsTable[transaction.id] = transaction;
    await _persistTransactions();
    logInfo('Cập nhật thành công và đã lưu vĩnh viễn giao dịch ID: ${transaction.id}');
  }

  Future<void> deleteTransaction(String id) async {
    if (!_isInitialized) await init();
    await Future.delayed(const Duration(milliseconds: 60));
    if (simulateDeleteError) {
      logError('Mô phỏng lỗi: Xóa giao dịch [$id] thất bại');
      throw DatabaseException('DELETE', 'Không thể xóa do ràng buộc toàn vẹn khóa ngoại.');
    }
    if (!_transactionsTable.containsKey(id)) {
      throw ItemNotFoundException(id, 'Giao dịch');
    }
    _transactionsTable.remove(id);
    await _persistTransactions();
    logInfo('Đã xóa và cập nhật bộ nhớ vĩnh viễn cho giao dịch ID: $id');
  }

  // --- Budgets Operations ---

  Future<Budget?> findBudget(String budgetId) async {
    if (!_isInitialized) await init();
    await Future.delayed(const Duration(milliseconds: 30));
    if (simulateReadError) {
      throw DatabaseException('READ', 'Lỗi đọc thông tin ngân sách từ cơ sở dữ liệu.');
    }
    return _budgetsTable[budgetId];
  }

  Future<void> saveBudget(Budget budget) async {
    if (!_isInitialized) await init();
    await Future.delayed(const Duration(milliseconds: 80));
    if (simulateWriteError) {
      throw DatabaseException('WRITE', 'Lỗi lưu thông tin hạn mức ngân sách.');
    }
    _budgetsTable[budget.id] = budget;
    await _persistBudgets();
    logInfo('Đã lưu vĩnh viễn hạn mức ngân sách [${budget.id}]: ${budget.limitAmount}');
  }
}
