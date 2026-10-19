import '../../core/errors/app_exceptions.dart';
import '../../core/mixins/logging_mixin.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/in_memory_database.dart';

/// [ExpenseRepositoryImpl] - Triển khai TransactionRepository
/// Áp dụng:
/// - Repository Pattern (kết nối Domain với Data)
/// - LoggingMixin (tự động ghi log nghiệp vụ và lỗi)
/// - Khối try-catch-finally chặt chẽ để xử lý ngoại lệ
class ExpenseRepositoryImpl with LoggingMixin implements TransactionRepository {
  final InMemoryDatabase _database;

  ExpenseRepositoryImpl({InMemoryDatabase? database})
      : _database = database ?? InMemoryDatabase.instance;

  @override
  Future<List<Transaction>> getAll() async {
    logInfo('Bắt đầu tải toàn bộ danh sách giao dịch...');
    try {
      final list = await _database.queryTransactions();
      list.sort((a, b) => b.date.compareTo(a.date));
      logInfo('Tải thành công ${list.length} giao dịch.');
      return list;
    } catch (e, stackTrace) {
      logError('Thất bại khi lấy danh sách giao dịch', e, stackTrace);
      rethrow;
    } finally {
      logDebug('Kết thúc quá trình getAll()');
    }
  }

  @override
  Future<Transaction?> getById(String id) async {
    logInfo('Tìm kiếm giao dịch theo ID: $id');
    try {
      return await _database.findTransactionById(id);
    } catch (e, stackTrace) {
      logError('Thất bại khi tìm giao dịch $id', e, stackTrace);
      rethrow;
    } finally {
      logDebug('Kết thúc quá trình getById($id)');
    }
  }

  @override
  Future<void> add(Transaction item) async {
    logInfo('Bắt đầu thêm mới giao dịch: "${item.title}" - ${item.amount} đ');
    try {
      // Xác minh lại nghiệp vụ một lần nữa trước khi lưu xuống DB
      item.validate();
      await _database.insertTransaction(item);
      logInfo('Ghi thành công giao dịch "${item.title}" vào cơ sở dữ liệu.');
    } on AppException {
      // Bắt các ngoại lệ nghiệp vụ chuyên biệt
      rethrow;
    } catch (e, stackTrace) {
      logError('Ngoại lệ không mong muốn khi thêm giao dịch', e, stackTrace);
      throw DatabaseException('WRITE', 'Không thể hoàn tất thêm mới: ${e.toString()}');
    } finally {
      logDebug('Hoàn tất lệnh gọi add()');
    }
  }

  @override
  Future<void> update(Transaction item) async {
    logInfo('Bắt đầu cập nhật giao dịch ID: ${item.id}');
    try {
      item.validate();
      await _database.updateTransaction(item);
      logInfo('Cập nhật thành công giao dịch ID: ${item.id}');
    } catch (e, stackTrace) {
      logError('Thất bại khi cập nhật giao dịch ${item.id}', e, stackTrace);
      rethrow;
    } finally {
      logDebug('Hoàn tất lệnh gọi update()');
    }
  }

  @override
  Future<void> delete(String id) async {
    logInfo('Bắt đầu xóa giao dịch ID: $id');
    try {
      await _database.deleteTransaction(id);
      logInfo('Đã xóa thành công giao dịch ID: $id');
    } catch (e, stackTrace) {
      logError('Thất bại khi xóa giao dịch $id', e, stackTrace);
      rethrow;
    } finally {
      logDebug('Hoàn tất lệnh gọi delete()');
    }
  }

  @override
  Future<List<Transaction>> getByMonth(int month, int year) async {
    logInfo('Lấy danh sách giao dịch tháng $month/$year');
    try {
      final all = await getAll();
      return all.where((t) => t.date.month == month && t.date.year == year).toList();
    } catch (e, stackTrace) {
      logError('Lỗi khi lọc giao dịch theo tháng', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Transaction>> search({
    String? query,
    TransactionType? type,
    String? categoryId,
    int? month,
    int? year,
  }) async {
    logInfo('Thực hiện tìm kiếm với bộ lọc: query="$query", type=$type, cat=$categoryId');
    try {
      final all = await getAll();
      return all.where((t) {
        if (query != null && query.trim().isNotEmpty) {
          final q = query.toLowerCase().trim();
          final titleMatch = t.title.toLowerCase().contains(q);
          final noteMatch = t.note?.toLowerCase().contains(q) ?? false;
          if (!titleMatch && !noteMatch) return false;
        }

        if (type != null && t.type != type) {
          return false;
        }

        if (categoryId != null && categoryId.isNotEmpty && t.category.id != categoryId) {
          return false;
        }

        if (month != null && t.date.month != month) {
          return false;
        }

        if (year != null && t.date.year != year) {
          return false;
        }

        return true;
      }).toList();
    } catch (e, stackTrace) {
      logError('Lỗi trong quá trình tìm kiếm giao dịch', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<double> getTotalIncome(int month, int year) async {
    final list = await getByMonth(month, year);
    return list
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<double> getTotalExpense(int month, int year) async {
    final list = await getByMonth(month, year);
    return list
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }
}
