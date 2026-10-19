import 'package:flutter/material.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/errors/centralized_error_handler.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/factories/transaction_factory.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/transaction_model.dart';
import '../controllers/transaction_controller.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionController controller;
  final Transaction? initialTransaction;

  const AddEditTransactionScreen({
    super.key,
    required this.controller,
    this.initialTransaction,
  });

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late TransactionType _selectedType;
  late TransactionCategory _selectedCategory;
  late DateTime _selectedDate;

  bool get isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTransaction;
    if (init != null) {
      _titleController = TextEditingController(text: init.title);
      _amountController = TextEditingController(text: init.amount.toStringAsFixed(0));
      _noteController = TextEditingController(text: init.note ?? '');
      _selectedType = init.type;
      _selectedCategory = init.category;
      _selectedDate = init.date;
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedType = TransactionType.expense;
      _selectedCategory = TransactionCategory.defaultCategories.firstWhere(
        (c) => c.type == TransactionType.expense,
      );
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    // 1. Phân tích số tiền nhập vào
    final rawAmountText = _amountController.text.trim();
    double amount;
    try {
      amount = double.parse(rawAmountText);
    } catch (_) {
      CentralizedErrorHandler.instance.showErrorSnackBar(
        context,
        FormatException('Số tiền "$rawAmountText" không phải là số hợp lệ!'),
      );
      return;
    }

    try {
      // 2. ỨNG DỤNG FACTORY PATTERN (TransactionFactory):
      // Đóng gói logic khởi tạo và kiểm tra nghiệp vụ tự động ném ra Custom Exceptions:
      // - NegativeAmountException nếu amount <= 0
      // - InvalidTransactionException nếu tiêu đề rỗng
      final transaction = TransactionFactory.create(
        id: widget.initialTransaction?.id,
        title: _titleController.text,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        type: _selectedType,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      bool success = false;
      if (isEditing) {
        success = await widget.controller.updateTransaction(transaction, context);
      } else {
        success = await widget.controller.addTransaction(transaction, context);
      }

      if (success && mounted) {
        Navigator.pop(context);
      }
    } on AppException catch (e, stackTrace) {
      // Bắt ngoại lệ nghiệp vụ bằng khối try-catch và chuyển cho CentralizedErrorHandler
      if (mounted) {
        CentralizedErrorHandler.instance.showErrorSnackBar(context, e, stackTrace);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        CentralizedErrorHandler.instance.showErrorSnackBar(context, e, stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = TransactionCategory.defaultCategories
        .where((c) => c.type == _selectedType)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa giao dịch' : 'Thêm giao dịch mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Button: Chọn Thu / Chi
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment<TransactionType>(
                    value: TransactionType.expense,
                    label: Text('Chi tiêu'),
                    icon: Icon(Icons.arrow_downward_rounded, color: Colors.red),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.income,
                    label: Text('Thu nhập'),
                    icon: Icon(Icons.arrow_upward_rounded, color: Colors.green),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategory = TransactionCategory.defaultCategories.firstWhere(
                      (c) => c.type == _selectedType,
                    );
                  });
                },
              ),
              const SizedBox(height: 20),

              // Số tiền
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: 'Số tiền (VNĐ) *',
                  hintText: 'Nhập số tiền (hoặc thử gõ số âm để test lỗi)',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  suffixText: '₫',
                  helperText: 'Gợi ý: Thử nhập số âm (ví dụ: -50000) để test NegativeAmountException',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Tên giao dịch
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên giao dịch *',
                  hintText: 'Ví dụ: Cơm trưa, Đổ xăng, Lương tháng...',
                  prefixIcon: Icon(Icons.title_rounded),
                  helperText: 'Gợi ý: Bỏ trống tiêu đề để test InvalidTransactionException',
                ),
              ),
              const SizedBox(height: 16),

              // Danh mục
              DropdownButtonFormField<TransactionCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: availableCategories.map((cat) {
                  return DropdownMenuItem<TransactionCategory>(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.color, size: 20),
                        const SizedBox(width: 10),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (cat) {
                  if (cat != null) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Chọn ngày
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày thực hiện',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(CurrencyFormatter.formatDate(_selectedDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ghi chú
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (Tùy chọn)',
                  hintText: 'Chi tiết thêm về giao dịch này...',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 28),

              // Nút Lưu giao dịch
              ElevatedButton.icon(
                onPressed: _saveTransaction,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  isEditing ? 'Cập nhật giao dịch' : 'Lưu giao dịch',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
