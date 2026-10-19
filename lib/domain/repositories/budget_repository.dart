import 'repository.dart';
import '../models/budget_model.dart';

abstract class BudgetRepository extends Repository<Budget> {
  /// Lấy ngân sách đã thiết lập cho một tháng cụ thể
  Future<Budget?> getBudgetForMonth(int month, int year);

  /// Lưu hoặc cập nhật hạn mức ngân sách
  Future<void> saveBudget(int month, int year, double limitAmount);
}
