import 'dart:ui';
import 'package:flutter/material.dart';
import 'core/config/env_config.dart';
import 'core/errors/centralized_error_handler.dart';
import 'core/errors/error_boundary.dart';
import 'core/utils/app_theme.dart';
import 'data/datasources/in_memory_database.dart';
import 'data/repositories/budget_repository_impl.dart';
import 'data/repositories/expense_repository_impl.dart';
import 'presentation/controllers/budget_controller.dart';
import 'presentation/controllers/transaction_controller.dart';
import 'presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cài đặt cơ chế bắt lỗi Flutter Framework tập trung
  FlutterError.onError = (FlutterErrorDetails details) {
    CentralizedErrorHandler.instance.process(details.exception, details.stack);
    FlutterError.presentError(details);
  };

  // 2. Bắt lỗi không đồng bộ ở tầng Platform / Engine (Async unhandled errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    CentralizedErrorHandler.instance.process(error, stack);
    return true;
  };

  // 3. Khởi tạo và nạp an toàn cấu hình biến môi trường từ .env
  await EnvConfig.init();

  // 4. Khởi tạo cơ sở dữ liệu lưu trữ vĩnh viễn (được bọc an toàn trong try-catch)
  try {
    await InMemoryDatabase.instance.init();
  } catch (e, stack) {
    debugPrint('Cảnh báo nạp bộ nhớ lưu trữ: $e\n$stack');
  }

  // 5. Khởi tạo các Dependencies theo Repository Pattern
  final expenseRepository = ExpenseRepositoryImpl();
  final budgetRepository = BudgetRepositoryImpl();

  // 6. Khởi tạo Controllers
  final budgetController = BudgetController(budgetRepository);
  final transactionController = TransactionController(expenseRepository, budgetController);

  runApp(ExpenseTrackerApp(
    transactionController: transactionController,
    budgetController: budgetController,
  ));
}

class ExpenseTrackerApp extends StatelessWidget {
  final TransactionController transactionController;
  final BudgetController budgetController;

  const ExpenseTrackerApp({
    super.key,
    required this.transactionController,
    required this.budgetController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EnvConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Bọc ứng dụng trong ErrorBoundary để ngăn chặn crash toàn màn hình
      builder: (context, child) {
        return ErrorBoundary(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: MainScreen(
        transactionController: transactionController,
        budgetController: budgetController,
      ),
    );
  }
}
