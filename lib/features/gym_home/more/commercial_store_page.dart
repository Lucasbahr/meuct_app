import 'package:flutter/material.dart';

import '../../admin/screens/admin_store_tab.dart';
import 'quick_sale_page.dart';

/// Loja / produtos (equipe): lista existente + venda rápida.
class CommercialStorePage extends StatelessWidget {
  const CommercialStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loja e produtos'),
        actions: [
          IconButton(
            tooltip: 'Venda rápida',
            icon: const Icon(Icons.point_of_sale_rounded),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const QuickSalePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: const AdminStoreTab(),
    );
  }
}
