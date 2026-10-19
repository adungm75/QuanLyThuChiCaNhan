import 'package:flutter/material.dart';
import '../../core/errors/centralized_error_handler.dart';
import '../../core/mixins/logging_mixin.dart';
import '../../domain/models/budget_model.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetController with ChangeNotifier, LoggingMixin {
  final BudgetRepository _budgetRepository;

  BudgetController(this._budgetRepository);

  Budget? _currentBudget;
  bool _isLoading = false;

  Budget? get currentBudget => _currentBudget;
  bool get isLoading => _isLoading;

  Future<void> loadBudget(int month, int year) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentBudget = await _budgetRepository.getBudgetForMonth(month, year);
      logInfo('Đã tải ngân sách tháng $month/$year: ${_currentBudget?.limitAmount ?? "Chưa thiết lập"}');
    } catch (e, stackTrace) {
      logError('Lỗi khi tải ngân sách', e, stackTrace);
      CentralizedErrorHandler.instance.process(e, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setBudget(BuildContext context, int month, int year, double limitAmount) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _budgetRepository.saveBudget(month, year, limitAmount);
      await loadBudget(month, year);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật hạn mức ngân sách thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (e, stackTrace) {
      logError('Thất bại khi cập nhật ngân sách', e, stackTrace);
      if (context.mounted) {
        CentralizedErrorHandler.instance.showErrorSnackBar(context, e, stackTrace);
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
