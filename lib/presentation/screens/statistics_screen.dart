import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/category_model.dart';
import '../controllers/transaction_controller.dart';
import '../widgets/error_log_sheet.dart';

class StatisticsScreen extends StatelessWidget {
  final TransactionController controller;

  const StatisticsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final totalIncome = controller.totalIncome;
        final totalExpense = controller.totalExpense;
        final netBalance = controller.netBalance;

        // Nhóm chi tiêu theo từng danh mục
        final expenseTransactions = controller.transactions.where((t) => t.type == TransactionType.expense).toList();
        final Map<String, double> categoryExpenseMap = {};
        for (var tx in expenseTransactions) {
          categoryExpenseMap[tx.category.id] = (categoryExpenseMap[tx.category.id] ?? 0.0) + tx.amount;
        }

        final sortedExpenseCategories = categoryExpenseMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          appBar: AppBar(
            title: Text('Thống Kê Tháng ${controller.selectedMonth}/${controller.selectedYear}'),
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
              // Thẻ tổng quan tài chính
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cân đối thu chi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem('Thu nhập', totalIncome, Colors.green),
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          _buildSummaryItem('Chi tiêu', totalExpense, Colors.red),
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          _buildSummaryItem(
                            'Số dư',
                            netBalance,
                            netBalance >= 0 ? Colors.teal : Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phân bổ chi tiêu theo danh mục
              const Text(
                'Phân bổ chi tiêu theo danh mục',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (sortedExpenseCategories.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Không có khoản chi tiêu nào trong tháng này.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                )
              else
                ...sortedExpenseCategories.map((entry) {
                  final cat = TransactionCategory.findById(entry.key);
                  final amount = entry.value;
                  final percent = totalExpense > 0 ? (amount / totalExpense) : 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(cat.icon, color: cat.color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatVND(amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(percent * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cat.color),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatVND(amount),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
