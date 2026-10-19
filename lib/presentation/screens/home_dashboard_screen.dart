import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/budget_controller.dart';
import '../widgets/transaction_card.dart';
import '../widgets/error_log_sheet.dart';
import 'add_edit_transaction_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  final TransactionController transactionController;
  final BudgetController budgetController;
  final VoidCallback onSeeAllTransactions;

  const HomeDashboardScreen({
    super.key,
    required this.transactionController,
    required this.budgetController,
    required this.onSeeAllTransactions,
  });

  void _showMonthPicker(BuildContext context) async {
    final currentMonth = transactionController.selectedMonth;
    final currentYear = transactionController.selectedYear;

    int tempMonth = currentMonth;
    int tempYear = currentYear;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Chọn thời gian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tháng:'),
                  DropdownButton<int>(
                    value: tempMonth,
                    items: List.generate(12, (i) => i + 1).map((m) {
                      return DropdownMenuItem(value: m, child: Text('Tháng $m'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempMonth = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Năm:'),
                  DropdownButton<int>(
                    value: tempYear,
                    items: [2024, 2025, 2026, 2027].map((y) {
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempYear = val);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                transactionController.changeMonth(tempMonth, tempYear);
                Navigator.pop(ctx);
              },
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([transactionController, budgetController]),
      builder: (context, _) {
        final totalIncome = transactionController.totalIncome;
        final totalExpense = transactionController.totalExpense;
        final netBalance = transactionController.netBalance;

        final budget = budgetController.currentBudget;
        final budgetLimit = budget?.limitAmount ?? 0.0;
        final double budgetPercent = budgetLimit > 0 ? (totalExpense / budgetLimit).clamp(0.0, 1.0) : 0.0;
        final bool isOverBudget = budgetLimit > 0 && totalExpense > budgetLimit;

        final recentList = transactionController.transactions.take(5).toList();

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () => _showMonthPicker(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tháng ${transactionController.selectedMonth}/${transactionController.selectedYear}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Xem Nhật Ký Lỗi Tập Trung',
                icon: const Icon(Icons.bug_report_outlined),
                onPressed: () => ErrorLogSheet.show(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await transactionController.loadTransactions(context: context);
              await budgetController.loadBudget(
                transactionController.selectedMonth,
                transactionController.selectedYear,
              );
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Số dư ròng (Net Balance)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade800, Colors.teal.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Số dư ròng tháng này',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.formatVND(netBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.white24,
                                      child: Icon(Icons.arrow_upward, size: 14, color: Colors.greenAccent),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tổng thu', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          Text(
                                            CurrencyFormatter.formatVND(totalIncome),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(height: 24, width: 1, color: Colors.white24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.white24,
                                      child: Icon(Icons.arrow_downward, size: 14, color: Colors.redAccent),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tổng chi', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          Text(
                                            CurrencyFormatter.formatVND(totalExpense),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ngân sách tháng Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isOverBudget ? Colors.red.shade300 : Colors.grey.shade200,
                        width: isOverBudget ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isOverBudget ? Icons.warning_amber_rounded : Icons.pie_chart_rounded,
                                color: isOverBudget ? Colors.red : Colors.teal,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ngân sách chi tiêu tháng',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                budgetLimit > 0
                                    ? '${(budgetPercent * 100).toStringAsFixed(0)}%'
                                    : 'Chưa cài đặt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOverBudget ? Colors.red : Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: budgetPercent,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOverBudget
                                    ? Colors.red
                                    : (budgetPercent > 0.8 ? Colors.amber.shade700 : Colors.teal),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đã chi: ${CurrencyFormatter.formatVND(totalExpense)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              Text(
                                budgetLimit > 0
                                    ? 'Hạn mức: ${CurrencyFormatter.formatVND(budgetLimit)}'
                                    : 'Chưa đặt hạn mức',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isOverBudget ? Colors.red : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Danh sách giao dịch gần đây
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giao dịch gần đây',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: onSeeAllTransactions,
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                ),

                if (transactionController.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (recentList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('Chưa có giao dịch nào trong tháng này', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentList.map((tx) => TransactionCard(
                        transaction: tx,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditTransactionScreen(
                                controller: transactionController,
                                initialTransaction: tx,
                              ),
                            ),
                          );
                        },
                        onDelete: () {
                          transactionController.deleteTransaction(tx.id, context);
                        },
                      )),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_add_tx',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTransactionScreen(
                    controller: transactionController,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Giao dịch'),
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}
