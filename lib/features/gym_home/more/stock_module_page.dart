import 'package:flutter/material.dart';

import '../../admin/screens/admin_stock_tab.dart';

class StockModulePage extends StatelessWidget {
  const StockModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
      ),
      body: const AdminStockTab(),
    );
  }
}
