import '../../core/errors/app_exceptions.dart';
import '../../core/mixins/logging_mixin.dart';
import '../../domain/models/budget_model.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/in_memory_database.dart';

class BudgetRepositoryImpl with LoggingMixin implements BudgetRepository {
  final InMemoryDatabase _database;

  BudgetRepositoryImpl({InMemoryDatabase? database})
      : _database = database ?? InMemoryDatabase.instance;

  @override
  Future<List<Budget>> getAll() async {
    // Không dùng danh sách all cho budget nhưng cài đặt đầy đủ theo Repository<T>
    return [];
  }

  @override
  Future<Budget?> getById(String id) async {
    return _database.findBudget(id);
  }

  @override
  Future<void> add(Budget item) async {
    await _database.saveBudget(item);
  }

  @override
  Future<void> update(Budget item) async {
    await _database.saveBudget(item);
  }

  @override
  Future<void> delete(String id) async {
    // Không hỗ trợ xóa hẳn budget
  }

  @override
  Future<Budget?> getBudgetForMonth(int month, int year) async {
    final id = '${year}_${month.toString().padLeft(2, '0')}';
    logInfo('Lấy hạn mức ngân sách tháng $month/$year (ID: $id)');
    try {
      return await _database.findBudget(id);
    } catch (e, stackTrace) {
      logError('Lỗi lấy hạn mức ngân sách', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> saveBudget(int month, int year, double limitAmount) async {
    logInfo('Thiết lập hạn mức ngân sách tháng $month/$year: $limitAmount đ');
    try {
      if (limitAmount <= 0) {
        throw NegativeAmountException(limitAmount);
      }
      final budget = Budget.create(month: month, year: year, limitAmount: limitAmount);
      await _database.saveBudget(budget);
      logInfo('Lưu hạn mức ngân sách thành công.');
    } catch (e, stackTrace) {
      logError('Thất bại khi lưu ngân sách', e, stackTrace);
      rethrow;
    }
  }
}
