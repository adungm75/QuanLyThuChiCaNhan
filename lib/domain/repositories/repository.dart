/// [Repository<T>] - Generic Repository Interface
/// Ứng dụng Generics trong Dart để định nghĩa khuôn mẫu CRUD chuẩn hóa cho mọi thực thể dữ liệu
abstract class Repository<T> {
  /// Lấy toàn bộ danh sách bản ghi
  Future<List<T>> getAll();

  /// Lấy bản ghi theo mã định danh (ID)
  Future<T?> getById(String id);

  /// Thêm mới một bản ghi
  Future<void> add(T item);

  /// Cập nhật thông tin bản ghi
  Future<void> update(T item);

  /// Xóa bản ghi theo ID
  Future<void> delete(String id);
}
