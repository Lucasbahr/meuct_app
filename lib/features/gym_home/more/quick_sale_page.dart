import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/payment/checkout_payment_urls.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/components/product_card.dart';
import '../../../shared/components/student_card.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../admin/services/admin_service.dart';
import '../../marketplace/services/marketplace_service.dart';

/// Venda rápida: aluno → produto → quantidade → pedido + checkout (mesma API do carrinho).
class QuickSalePage extends StatefulWidget {
  const QuickSalePage({super.key});

  @override
  State<QuickSalePage> createState() => _QuickSalePageState();
}

class _QuickSalePageState extends State<QuickSalePage> {
  final _admin = AdminService();
  final _marketplace = MarketplaceService();
  final _qtyCtrl = TextEditingController(text: '1');

  int _step = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _activeProducts = [];
  Map<String, dynamic>? _student;
  Map<String, dynamic>? _product;
  bool _submitting = false;
  String _provider = 'mercado_pago';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await _admin.getStudents();
      final prods = await _marketplace.listProducts(order: 'desc');
      if (!mounted) return;
      setState(() {
        _students = students;
        _activeProducts = prods.where((p) => p['is_active'] != false).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  int? _productId(Map<String, dynamic> p) {
    final id = p['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse(id?.toString() ?? '');
  }

  Future<void> _confirm() async {
    final sid = _student;
    final prod = _product;
    final pid = prod == null ? null : _productId(prod);
    final q = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (sid == null || pid == null || q < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione aluno, produto e quantidade válida.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final order = await _marketplace.createOrder([
        {'product_id': pid, 'quantity': q},
      ]);
      final orderIdRaw = order['id'] ?? order['order_id'];
      final orderId = orderIdRaw is int
          ? orderIdRaw
          : int.tryParse(orderIdRaw?.toString() ?? '');
      if (orderId == null) {
        throw Exception('Pedido criado sem id na resposta.');
      }
      final checkoutData = await _marketplace.checkout(
        orderId,
        provider: _provider,
        returnUrl: CheckoutPaymentUrls.returnUrl(),
        cancelUrl: CheckoutPaymentUrls.cancelUrl(),
      );
      final payUrl = MarketplaceService.extractPaymentUrl(checkoutData);
      if (!mounted) return;
      if (payUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Pedido criado. URL de pagamento não reconhecida — confira o painel ou a API.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
        return;
      }
      final uri = Uri.parse(payUrl);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (launched) {
        final nome = (sid['nome'] ?? 'Aluno').toString();
        final itemName = (prod!['name'] ?? 'item').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pagamento aberto. Pedido para $nome ($q× $itemName).',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venda rápida'),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.tertiary,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(label: 'Tentar de novo', onPressed: _load),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          _stepChip(0, 'Aluno'),
                          const SizedBox(width: AppSpacing.sm),
                          _stepChip(1, 'Produto'),
                          const SizedBox(width: AppSpacing.sm),
                          _stepChip(2, 'Confirmar'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _step,
                        children: [
                          _studentStep(),
                          _productStep(),
                          _confirmStep(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _stepChip(int i, String label) {
    final sel = _step == i;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: sel
              ? cs.primary.withValues(alpha: 0.15)
              : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: sel
                ? cs.primary
                : cs.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: sel ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _studentStep() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: _students.length,
      itemBuilder: (context, i) {
        final s = _students[i];
        return StudentCard(
          student: s,
          onTap: () => setState(() {
            _student = s;
            _step = 1;
          }),
        );
      },
    );
  }

  Widget _productStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextButton.icon(
            onPressed: () => setState(() => _step = 0),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Trocar aluno'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            itemCount: _activeProducts.length,
            itemBuilder: (context, i) {
              final p = _activeProducts[i];
              return ProductCard(
                product: p,
                compact: true,
                onTap: () => setState(() {
                  _product = p;
                  _step = 2;
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _confirmStep() {
    final nome = (_student?['nome'] ?? '—').toString();
    final pnome = (_product?['name'] ?? '—').toString();
    final price = _product == null
        ? '—'
        : MarketplaceService.formatPrice(_product!['price']);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _step = 1),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Trocar produto'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Resumo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        _summaryRow('Aluno', nome),
        _summaryRow('Produto', pnome),
        _summaryRow('Preço unit.', 'R\$ $price'),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'O pedido é criado na API como na loja. O aluno escolhido fica registrado neste fluxo para sua operação; associe ao pedido no back-end se necessário.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Gateway de pagamento',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Mercado Pago'),
              selected: _provider == 'mercado_pago',
              onSelected: _submitting
                  ? null
                  : (_) => setState(() => _provider = 'mercado_pago'),
            ),
            ChoiceChip(
              label: const Text('PayPal'),
              selected: _provider == 'paypal',
              onSelected: _submitting
                  ? null
                  : (_) => setState(() => _provider = 'paypal'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Gerar pedido e abrir pagamento',
          loading: _submitting,
          onPressed: _submitting ? null : _confirm,
        ),
      ],
    );
  }

  Widget _summaryRow(String k, String v) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
