import 'package:flutter/material.dart';
import '../../core/errors/error_boundary.dart';
import '../controllers/budget_controller.dart';
import '../controllers/transaction_controller.dart';
import 'home_dashboard_screen.dart';
import 'transaction_list_screen.dart';
import 'statistics_screen.dart';
import 'budget_screen.dart';
import 'oop_error_demo_screen.dart';

class MainScreen extends StatefulWidget {
  final TransactionController transactionController;
  final BudgetController budgetController;

  const MainScreen({
    super.key,
    required this.transactionController,
    required this.budgetController,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Khởi động nạp dữ liệu ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.transactionController.loadTransactions();
      widget.budgetController.loadBudget(
        widget.transactionController.selectedMonth,
        widget.transactionController.selectedYear,
      );
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeDashboardScreen(
        transactionController: widget.transactionController,
        budgetController: widget.budgetController,
        onSeeAllTransactions: () => _onTabSelected(1),
      ),
      TransactionListScreen(controller: widget.transactionController),
      StatisticsScreen(controller: widget.transactionController),
      BudgetScreen(
        budgetController: widget.budgetController,
        transactionController: widget.transactionController,
      ),
      OopErrorDemoScreen(controller: widget.transactionController),
    ];

    return Scaffold(
      body: ErrorBoundary(
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz_rounded),
            label: 'Giao dịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
            label: 'Ngân sách',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science_rounded),
            label: 'Demo OOP',
          ),
        ],
      ),
    );
  }
}
