import 'package:flutter/material.dart';

import '../../admin/screens/admin_plans_tab.dart';

class PlansModulePage extends StatelessWidget {
  const PlansModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos e mensalidades'),
      ),
      body: const AdminPlansTab(),
    );
  }
}
