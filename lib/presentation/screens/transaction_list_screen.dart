import 'package:flutter/material.dart';
import '../../domain/models/category_model.dart';
import '../controllers/transaction_controller.dart';
import '../widgets/transaction_card.dart';
import '../widgets/error_log_sheet.dart';
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  final TransactionController controller;

  const TransactionListScreen({super.key, required this.controller});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final transactions = widget.controller.transactions;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Danh Sách Giao Dịch'),
            actions: [
              IconButton(
                tooltip: 'Nhật Ký Lỗi Tập Trung',
                icon: const Icon(Icons.bug_report_outlined),
                onPressed: () => ErrorLogSheet.show(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, ghi chú...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.controller.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    widget.controller.setSearchQuery(val);
                  },
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: widget.controller.filterType == null,
                      onSelected: (_) => widget.controller.setFilterType(null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Chi tiêu'),
                      selected: widget.controller.filterType == TransactionType.expense,
                      onSelected: (_) => widget.controller.setFilterType(
                        widget.controller.filterType == TransactionType.expense ? null : TransactionType.expense,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Thu nhập'),
                      selected: widget.controller.filterType == TransactionType.income,
                      onSelected: (_) => widget.controller.setFilterType(
                        widget.controller.filterType == TransactionType.income ? null : TransactionType.income,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dropdown chọn Danh mục lọc
                    PopupMenuButton<String?>(
                      initialValue: widget.controller.filterCategoryId,
                      tooltip: 'Lọc theo danh mục',
                      child: Chip(
                        avatar: const Icon(Icons.category, size: 16),
                        label: Text(
                          widget.controller.filterCategoryId == null
                              ? 'Danh mục'
                              : TransactionCategory.findById(widget.controller.filterCategoryId!).name,
                        ),
                      ),
                      onSelected: (catId) {
                        widget.controller.setFilterCategory(catId);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem<String?>(
                          value: null,
                          child: Text('Tất cả danh mục'),
                        ),
                        ...TransactionCategory.defaultCategories.map((c) {
                          return PopupMenuItem<String?>(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(c.icon, color: c.color, size: 18),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              // Count info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tìm thấy ${transactions.length} giao dịch',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Tháng ${widget.controller.selectedMonth}/${widget.controller.selectedYear}',
                      style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Transaction list
              Expanded(
                child: widget.controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text(
                                  'Không tìm thấy giao dịch nào phù hợp.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              return TransactionCard(
                                transaction: tx,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditTransactionScreen(
                                        controller: widget.controller,
                                        initialTransaction: tx,
                                      ),
                                    ),
                                  );
                                },
                                onDelete: () {
                                  widget.controller.deleteTransaction(tx.id, context);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_list_add',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTransactionScreen(controller: widget.controller),
                ),
              );
            },
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
