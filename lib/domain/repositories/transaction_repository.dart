import 'repository.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

/// [TransactionRepository] - Kế thừa Generic `Repository<Transaction>`
/// Bổ sung các phương thức nghiệp vụ đặc thù cho Quản lý chi tiêu
abstract class TransactionRepository extends Repository<Transaction> {
  /// Lấy danh sách giao dịch theo tháng và năm
  Future<List<Transaction>> getByMonth(int month, int year);

  /// Tìm kiếm và lọc giao dịch
  Future<List<Transaction>> search({
    String? query,
    TransactionType? type,
    String? categoryId,
    int? month,
    int? year,
  });

  /// Tính tổng thu nhập theo tháng
  Future<double> getTotalIncome(int month, int year);

  /// Tính tổng chi tiêu theo tháng
  Future<double> getTotalExpense(int month, int year);
}
