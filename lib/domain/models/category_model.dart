import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  static const List<TransactionCategory> defaultCategories = [
    // Chi tiêu
    TransactionCategory(
      id: 'food',
      name: 'Ăn uống',
      icon: Icons.restaurant_rounded,
      color: Colors.orange,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'shopping',
      name: 'Mua sắm',
      icon: Icons.shopping_bag_rounded,
      color: Colors.purple,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'transport',
      name: 'Di chuyển',
      icon: Icons.directions_car_rounded,
      color: Colors.blue,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'bills',
      name: 'Hóa đơn & Dịch vụ',
      icon: Icons.receipt_long_rounded,
      color: Colors.redAccent,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'entertainment',
      name: 'Giải trí',
      icon: Icons.movie_rounded,
      color: Colors.pink,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'health',
      name: 'Y tế & Sức khỏe',
      icon: Icons.medical_services_rounded,
      color: Colors.teal,
      type: TransactionType.expense,
    ),

    // Thu nhập
    TransactionCategory(
      id: 'salary',
      name: 'Tiền lương',
      icon: Icons.account_balance_wallet_rounded,
      color: Colors.green,
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'bonus',
      name: 'Tiền thưởng',
      icon: Icons.card_giftcard_rounded,
      color: Colors.amber,
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'investment',
      name: 'Đầu tư / Lãi',
      icon: Icons.trending_up_rounded,
      color: Colors.indigo,
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'other_income',
      name: 'Thu nhập khác',
      icon: Icons.attach_money_rounded,
      color: Colors.cyan,
      type: TransactionType.income,
    ),
  ];

  static TransactionCategory findById(String id) {
    return defaultCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => const TransactionCategory(
        id: 'other',
        name: 'Khác',
        icon: Icons.category_rounded,
        color: Colors.grey,
        type: TransactionType.expense,
      ),
    );
  }
}
