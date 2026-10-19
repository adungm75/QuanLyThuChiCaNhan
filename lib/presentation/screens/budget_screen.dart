import 'package:flutter/material.dart';
import '../../core/errors/centralized_error_handler.dart';
import '../../core/utils/currency_formatter.dart';
import '../controllers/budget_controller.dart';
import '../controllers/transaction_controller.dart';
import '../widgets/error_log_sheet.dart';

class BudgetScreen extends StatefulWidget {
  final BudgetController budgetController;
  final TransactionController transactionController;

  const BudgetScreen({
    super.key,
    required this.budgetController,
    required this.transactionController,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentBudget();
  }

  void _loadCurrentBudget() {
    final budget = widget.budgetController.currentBudget;
    if (budget != null) {
      _amountController.text = budget.limitAmount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final rawText = _amountController.text.trim();
    double amount;
    try {
      amount = double.parse(rawText);
    } catch (_) {
      CentralizedErrorHandler.instance.showErrorSnackBar(
        context,
        FormatException('Số tiền ngân sách "$rawText" không hợp lệ!'),
      );
      return;
    }

    final success = await widget.budgetController.setBudget(
      context,
      widget.transactionController.selectedMonth,
      widget.transactionController.selectedYear,
      amount,
    );

    if (success && mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.budgetController, widget.transactionController]),
      builder: (context, _) {
        final totalExpense = widget.transactionController.totalExpense;
        final budget = widget.budgetController.currentBudget;
        final limit = budget?.limitAmount ?? 0.0;
        final double percent = limit > 0 ? (totalExpense / limit).clamp(0.0, 1.0) : 0.0;
        final isOver = limit > 0 && totalExpense > limit;
        final remaining = limit - totalExpense;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Quản Lý Ngân Sách'),
            actions: [
              IconButton(
                tooltip: 'Nhật Ký Lỗi Tập Trung',
                icon: const Icon(Icons.bug_report_outlined),
                onPressed: () => ErrorLogSheet.show(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
              // Trạng thái ngân sách Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tháng ${widget.transactionController.selectedMonth}/${widget.transactionController.selectedYear}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOver ? Colors.red.shade100 : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOver ? 'VƯỢT NGÂN SÁCH' : 'TRONG HẠN MỨC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOver ? Colors.red.shade800 : Colors.teal.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Circle / Progress Indicator
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 14,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOver ? Colors.red : (percent > 0.8 ? Colors.amber.shade800 : Colors.teal),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đã tiêu: ${(percent * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            isOver
                                ? 'Vượt quá: ${CurrencyFormatter.formatVND(-remaining)}'
                                : 'Còn lại: ${CurrencyFormatter.formatVND(remaining)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isOver ? Colors.red.shade700 : Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniInfo('Đã chi', totalExpense, Colors.red.shade700),
                          _buildMiniInfo(
                            'Hạn mức',
                            limit,
                            limit > 0 ? Colors.teal.shade800 : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Thiết lập hạn mức mới
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Thiết lập hạn mức ngân sách tháng',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cài đặt số tiền tối đa bạn muốn chi tiêu trong tháng này.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Hạn mức ngân sách (VNĐ)',
                          hintText: 'Nhập số tiền ngân sách',
                          prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                          suffixText: '₫',
                          helperText: 'Thử nhập số âm (ví dụ: -2000000) để test NegativeAmountException',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _saveBudget,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Lưu hạn mức ngân sách'),
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
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildMiniInfo(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatVND(amount),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
