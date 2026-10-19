import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cd1/core/errors/app_exceptions.dart';
import 'package:cd1/core/errors/centralized_error_handler.dart';
import 'package:cd1/domain/factories/transaction_factory.dart';
import 'package:cd1/domain/models/category_model.dart';
import 'package:cd1/domain/models/transaction_model.dart';
import 'package:cd1/data/datasources/in_memory_database.dart';
import 'package:cd1/data/repositories/expense_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. OOP Factory Pattern & Validation Tests', () {
    test('TransactionFactory tạo thành công chi tiêu hợp lệ', () {
      final tx = TransactionFactory.createExpense(
        title: 'Cà phê sáng',
        amount: 35000,
        category: TransactionCategory.findById('food'),
      );

      expect(tx.title, equals('Cà phê sáng'));
      expect(tx.amount, equals(35000));
      expect(tx.type, equals(TransactionType.expense));
    });

    test('TransactionFactory ném NegativeAmountException khi số tiền <= 0', () {
      expect(
        () => TransactionFactory.createExpense(
          title: 'Ăn trưa',
          amount: -50000,
          category: TransactionCategory.findById('food'),
        ),
        throwsA(isA<NegativeAmountException>()),
      );
    });

    test('TransactionFactory ném InvalidTransactionException khi tiêu đề rỗng', () {
      expect(
        () => TransactionFactory.createExpense(
          title: '   ',
          amount: 50000,
          category: TransactionCategory.findById('food'),
        ),
        throwsA(isA<InvalidTransactionException>()),
      );
    });
  });

  group('2. Generic Repository & Data Layer Tests', () {
    late ExpenseRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await InMemoryDatabase.instance.init();
      repository = ExpenseRepositoryImpl(database: InMemoryDatabase.instance);
      InMemoryDatabase.instance.simulateReadError = false;
      InMemoryDatabase.instance.simulateWriteError = false;
    });

    tearDown(() {
      InMemoryDatabase.instance.simulateReadError = false;
      InMemoryDatabase.instance.simulateWriteError = false;
    });

    test('Repository lấy danh sách giao dịch thành công', () async {
      final list = await repository.getAll();
      expect(list.isNotEmpty, isTrue);
    });

    test('Repository ném DatabaseException khi bật cờ mô phỏng lỗi đọc', () async {
      InMemoryDatabase.instance.simulateReadError = true;
      await expectLater(
        repository.getAll(),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('Repository ném DatabaseException khi bật cờ mô phỏng lỗi ghi', () async {
      InMemoryDatabase.instance.simulateWriteError = true;
      final newTx = Transaction(
        id: 'test_tx',
        title: 'Test Ghi',
        amount: 100000,
        date: DateTime.now(),
        category: TransactionCategory.findById('bills'),
        type: TransactionType.expense,
      );

      await expectLater(
        repository.add(newTx),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('Thêm giao dịch mới và kiểm tra lưu trữ bền vững', () async {
      final newTx = TransactionFactory.createExpense(
        id: 'persistent_test_id',
        title: 'Trà sữa trân châu',
        amount: 45000,
        category: TransactionCategory.findById('food'),
      );

      await repository.add(newTx);
      final found = await repository.getById('persistent_test_id');
      expect(found, isNotNull);
      expect(found?.title, equals('Trà sữa trân châu'));
      expect(found?.amount, equals(45000));
    });
  });

  group('3. Centralized Error Pipeline Tests', () {
    test('CentralizedErrorHandler chuẩn hóa NegativeAmountException', () {
      final ex = NegativeAmountException(-20000);
      final processed = CentralizedErrorHandler.instance.process(ex);

      expect(processed.errorCode, equals('ERR_NEGATIVE_AMOUNT'));
      expect(processed.isWarning, isTrue);
      expect(processed.userMessage.contains('-20000'), isTrue);
    });

    test('CentralizedErrorHandler chuẩn hóa DatabaseException', () {
      final ex = DatabaseException('READ', 'Mất kết nối');
      final processed = CentralizedErrorHandler.instance.process(ex);

      expect(processed.errorCode, equals('ERR_DATABASE_READ'));
      expect(processed.isWarning, isFalse);
    });
  });
}
