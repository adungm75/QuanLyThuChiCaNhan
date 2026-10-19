import 'package:flutter/material.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/errors/centralized_error_handler.dart';
import '../../core/mixins/logging_mixin.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'budget_controller.dart';

class TransactionController with ChangeNotifier, LoggingMixin {
  final TransactionRepository _repository;
  final BudgetController _budgetController;

  TransactionController(this._repository, this._budgetController) {
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  List<Transaction> _transactions = [];
  bool _isLoading = false;

  late int _selectedMonth;
  late int _selectedYear;

  String _searchQuery = '';
  TransactionType? _filterType;
  String? _filterCategoryId;

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  String get searchQuery => _searchQuery;
  TransactionType? get filterType => _filterType;
  String? get filterCategoryId => _filterCategoryId;

  // Thống kê nhanh theo tháng được chọn
  double get totalIncome {
    return _transactions
        .where((t) =>
            t.date.month == _selectedMonth &&
            t.date.year == _selectedYear &&
            t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) =>
            t.date.month == _selectedMonth &&
            t.date.year == _selectedYear &&
            t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get netBalance => totalIncome - totalExpense;

  void changeMonth(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    _budgetController.loadBudget(month, year);
    loadTransactions();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadTransactions();
  }

  void setFilterType(TransactionType? type) {
    _filterType = type;
    loadTransactions();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    loadTransactions();
  }

  /// Tải danh sách giao dịch có xử lý lỗi tập trung
  Future<void> loadTransactions({BuildContext? context}) async {
    _isLoading = true;
    notifyListeners();
    logInfo('Tải dữ liệu giao dịch cho tháng $_selectedMonth/$_selectedYear...');

    try {
      if (_searchQuery.trim().isNotEmpty || _filterType != null || _filterCategoryId != null) {
        _transactions = await _repository.search(
          query: _searchQuery,
          type: _filterType,
          categoryId: _filterCategoryId,
          month: _selectedMonth,
          year: _selectedYear,
        );
      } else {
        _transactions = await _repository.getByMonth(_selectedMonth, _selectedYear);
      }
      logInfo('Tải thành công: ${_transactions.length} giao dịch');
    } catch (e, stackTrace) {
      logError('Thất bại khi nạp danh sách giao dịch', e, stackTrace);
      if (context != null && context.mounted) {
        CentralizedErrorHandler.instance.showErrorSnackBar(context, e, stackTrace);
      } else {
        CentralizedErrorHandler.instance.process(e, stackTrace);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm giao dịch với kiểm tra ngân sách và xử lý ngoại lệ
  Future<bool> addTransaction(Transaction transaction, BuildContext context) async {
    try {
      logInfo('Bắt đầu thêm giao dịch mới: ${transaction.title}');

      // Kiểm tra xem giao dịch này có khiến chi tiêu vượt hạn mức ngân sách tháng không
      if (transaction.type == TransactionType.expense) {
        final budget = _budgetController.currentBudget;
        if (budget != null && budget.limitAmount > 0) {
          final currentExpense = totalExpense;
          if (currentExpense + transaction.amount > budget.limitAmount) {
            // Ném ngoại lệ cảnh báo vượt ngân sách
            final warningEx = BudgetExceededException(
              currentTotal: currentExpense,
              budgetLimit: budget.limitAmount,
              attemptedAmount: transaction.amount,
            );
            // Gửi cảnh báo qua Centralized Error Handler
            CentralizedErrorHandler.instance.showErrorSnackBar(context, warningEx);
          }
        }
      }

      await _repository.add(transaction);
      await loadTransactions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm "${transaction.title}" thành công!'),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (e, stackTrace) {
      logError('Lỗi trong quá trình thêm giao dịch', e, stackTrace);
      if (context.mounted) {
        CentralizedErrorHandler.instance.showErrorSnackBar(context, e, stackTrace);
      }
      return false;
    }
  }

  /// Cập nhật giao dịch
  Future<bool> updateTransaction(Transaction transaction, BuildContext context) async {
    try {
      logInfo('Cập nhật giao dịch: ${transaction.id}');
      await _repository.update(transaction);
      await loadTransactions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật "${transaction.title}"!'),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (e, stackTrace) {
      logError('Lỗi trong quá trình cập nhật giao dịch', e, stackTrace);
      if (context.mounted) {
        CentralizedErrorHandler.instance.showErrorSnackBar(context, e, stackTrace);
      }
      return false;
    }
  }

  /// Xóa giao dịch
  Future<bool> deleteTransaction(String id, BuildContext context) async {
    try {
      logInfo('Yêu cầu xóa giao dịch ID: $id');
      await _repository.delete(id);
      await loadTransactions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giao dịch thành công.'),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (e, stackTrace) {
      logError('Lỗi khi xóa giao dịch', e, stackTrace);
      if (context.mounted) {
        CentralizedErrorHandler.instance.showErrorSnackBar(context, e, stackTrace);
      }
      return false;
    }
  }
}
