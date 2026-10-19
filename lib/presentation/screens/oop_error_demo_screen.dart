import 'package:flutter/material.dart';
import '../../core/errors/centralized_error_handler.dart';
import '../../core/mixins/logging_mixin.dart';
import '../../data/datasources/in_memory_database.dart';
import '../../domain/factories/transaction_factory.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/transaction_model.dart';
import '../controllers/transaction_controller.dart';
import '../widgets/error_log_sheet.dart';

class OopErrorDemoScreen extends StatefulWidget {
  final TransactionController controller;

  const OopErrorDemoScreen({super.key, required this.controller});

  @override
  State<OopErrorDemoScreen> createState() => _OopErrorDemoScreenState();
}

class _OopErrorDemoScreenState extends State<OopErrorDemoScreen> with LoggingMixin {
  bool _causeRenderError = false;

  @override
  Widget build(BuildContext context) {
    if (_causeRenderError) {
      // Cố tình gây lỗi trong quá trình build để ErrorBoundary bắt được
      throw StateError('Mô phỏng lỗi giao diện (Widget Render Error) để kiểm thử Error Boundary!');
    }

    final db = InMemoryDatabase.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo OOP & Xử Lý Ngoại Lệ'),
        actions: [
          IconButton(
            tooltip: 'Nhật Ký Lỗi Tập Trung',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => ErrorLogSheet.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner giới thiệu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade800, Colors.teal.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Kiến Trúc OOP & Error Pipeline',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ứng dụng được thiết kế phân tầng chuẩn (Clean Architecture) với Domain Layer độc lập, áp dụng Factory Pattern, Repository<T>, LoggingMixin và cơ chế xử lý ngoại lệ tập trung.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tóm tắt các thành phần OOP đã áp dụng
          const Text('1. CÁC MẪU OOP & DESIGN PATTERNS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),

          _buildConceptTile(
            title: 'Factory Pattern (TransactionFactory)',
            subtitle: 'Đóng gói khởi tạo giao dịch, kiểm tra nghiệp vụ và trả về Transaction.expense/income tương ứng.',
            icon: Icons.precision_manufacturing_rounded,
            color: Colors.blue,
          ),
          _buildConceptTile(
            title: 'Generics & Repository Pattern (Repository<T>)',
            subtitle: 'Khuôn mẫu generic CRUD trừu tượng. ExpenseRepositoryImpl triển khai và kế thừa.',
            icon: Icons.account_tree_rounded,
            color: Colors.indigo,
          ),
          _buildConceptTile(
            title: 'Mixins (LoggingMixin)',
            subtitle: 'Cung cấp khả năng log tự động (INFO, WARN, ERROR, DEBUG) cho bất kỳ class nào with LoggingMixin.',
            icon: Icons.layers_rounded,
            color: Colors.deepPurple,
          ),
          _buildConceptTile(
            title: 'Custom Exceptions Hierarchy',
            subtitle: 'Kế thừa AppException: NegativeAmountException, InvalidTransactionException, DatabaseException, BudgetExceededException.',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          _buildConceptTile(
            title: 'Centralized Error Handling Pipeline',
            subtitle: 'Tất cả ngoại lệ đi qua một pipeline duy nhất: phân loại -> log -> chuẩn hóa thông báo UI.',
            icon: Icons.hub_rounded,
            color: Colors.teal,
          ),

          const SizedBox(height: 24),

          // PHẦN DEMO NGOẠI LỆ TRỰC QUAN (INTERACTIVE PLAYGROUND)
          const Text('2. PHÒNG THỬ NGHIỆM NGOẠI LỆ (ERROR PLAYGROUND)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 10),

          // Case 1: Nhập số tiền âm
          _buildDemoCard(
            title: 'Test 1: Nhập số tiền âm',
            description: 'Kích hoạt NegativeAmountException khi truyền amount <= 0 vào TransactionFactory',
            icon: Icons.remove_circle_outline_rounded,
            color: Colors.red,
            buttonText: 'Kích hoạt lỗi số tiền âm (-500.000 đ)',
            onPressed: () {
              try {
                logInfo('Bắt đầu thử nghiệm tạo giao dịch số tiền âm...');
                TransactionFactory.createExpense(
                  title: 'Mua quà sinh nhật',
                  amount: -500000, // Cố tình truyền số âm
                  category: TransactionCategory.findById('shopping'),
                );
              } catch (e, stackTrace) {
                CentralizedErrorHandler.instance.showErrorSnackBar(context, e, stackTrace);
              }
            },
          ),

          // Case 2: Dữ liệu không hợp lệ (tiêu đề rỗng)
          _buildDemoCard(
            title: 'Test 2: Dữ liệu không hợp lệ',
            description: 'Kích hoạt InvalidTransactionException khi tiêu đề bị bỏ trống',
            icon: Icons.edit_off_rounded,
            color: Colors.orange,
            buttonText: 'Kích hoạt lỗi tiêu đề rỗng',
            onPressed: () {
              try {
                logInfo('Bắt đầu thử nghiệm tạo giao dịch không có tiêu đề...');
                TransactionFactory.createExpense(
                  title: '   ', // Tiêu đề rỗng
                  amount: 150000,
                  category: TransactionCategory.findById('food'),
                );
              } catch (e, stackTrace) {
                CentralizedErrorHandler.instance.showErrorSnackBar(context, e, stackTrace);
              }
            },
          ),

          // Case 3: Giả lập lỗi Đọc Database
          _buildDemoCard(
            title: 'Test 3: Mô phỏng lỗi Đọc Database',
            description: 'Bật cờ mô phỏng lỗi READ trong InMemoryDatabase và thử tải danh sách',
            icon: Icons.storage_rounded,
            color: Colors.deepOrange,
            buttonText: db.simulateReadError ? 'ĐANG BẬT LỖI ĐỌC (Bấm để tắt)' : 'Thử tải khi có lỗi Đọc DB',
            onPressed: () async {
              setState(() {
                db.simulateReadError = !db.simulateReadError;
              });
              await widget.controller.loadTransactions(context: context);
            },
          ),

          // Case 4: Giả lập lỗi Ghi Database
          _buildDemoCard(
            title: 'Test 4: Mô phỏng lỗi Ghi Database',
            description: 'Bật cờ mô phỏng lỗi WRITE trong InMemoryDatabase và thử thêm giao dịch mới',
            icon: Icons.save_alt_rounded,
            color: Colors.purple,
            buttonText: db.simulateWriteError ? 'ĐANG BẬT LỖI GHI (Bấm để tắt)' : 'Thử thêm giao dịch khi có lỗi Ghi DB',
            onPressed: () async {
              setState(() {
                db.simulateWriteError = !db.simulateWriteError;
              });
              if (db.simulateWriteError) {
                final dummyTx = Transaction(
                  id: 'err_tx_${DateTime.now().millisecondsSinceEpoch}',
                  title: 'Test Ghi Database',
                  amount: 100000,
                  date: DateTime.now(),
                  category: TransactionCategory.findById('bills'),
                  type: TransactionType.expense,
                );
                await widget.controller.addTransaction(dummyTx, context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã tắt mô phỏng lỗi Ghi Database.')),
                );
              }
            },
          ),

          // Case 5: Cảnh báo chi tiêu vượt ngân sách
          _buildDemoCard(
            title: 'Test 5: Cảnh báo vượt ngân sách',
            description: 'Kích hoạt BudgetExceededException khi giao dịch chi tiêu vượt quá hạn mức tháng',
            icon: Icons.crisis_alert_rounded,
            color: Colors.brown,
            buttonText: 'Thử thêm chi tiêu vượt hạn mức (100.000.000 đ)',
            onPressed: () async {
              final bigTx = Transaction(
                id: 'big_tx_${DateTime.now().millisecondsSinceEpoch}',
                title: 'Mua xe phân khối lớn',
                amount: 100000000,
                date: DateTime.now(),
                category: TransactionCategory.findById('shopping'),
                type: TransactionType.expense,
              );
              await widget.controller.addTransaction(bigTx, context);
            },
          ),

          // Case 6: Test Error Boundary
          _buildDemoCard(
            title: 'Test 6: Kiểm thử Error Boundary (UI Fallback)',
            description: 'Cố tình ném lỗi render để ErrorBoundary bắt và hiển thị màn hình cứu hộ thân thiện',
            icon: Icons.healing_rounded,
            color: Colors.pink,
            buttonText: 'Kích hoạt lỗi Render Widget',
            onPressed: () {
              setState(() {
                _causeRenderError = true;
              });
            },
          ),

          const SizedBox(height: 16),

          // Nút mở Log Sheet
          ElevatedButton.icon(
            onPressed: () => ErrorLogSheet.show(context),
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('Mở Hộp Nhật Ký Lỗi Tập Trung (Log Viewer)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildConceptTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ),
    );
  }

  Widget _buildDemoCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
