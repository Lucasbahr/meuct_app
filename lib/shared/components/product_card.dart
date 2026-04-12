import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/marketplace/services/marketplace_service.dart';
import 'app_card.dart';
import '../themes/app_tokens.dart';

/// Card de produto para listas (loja admin / venda rápida).
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.compact = false,
  });

  final Map<String, dynamic> product;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = (product['name'] ?? '').toString();
    final price = MarketplaceService.formatPrice(product['price']);
    final active = product['is_active'] != false;
    final stock = product['stock'];
    final img = MarketplaceService.productPrimaryImageUrl(product);

    final cs = Theme.of(context).colorScheme;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: SizedBox(
            width: compact ? 52 : 64,
            height: compact ? 52 : 64,
            child: img != null
                ? CachedNetworkImage(
                    imageUrl: img,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _placeholder(context),
                  )
                : _placeholder(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Produto' : name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'R\$ $price',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 14 : 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _badge(
                    'Estoque: ${stock ?? "—"}',
                    cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _badge(
                    active ? 'Ativo' : 'Inativo',
                    active ? AppColors.success : cs.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ],
    );

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: content,
    );
  }

  Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      child: Icon(
        Icons.inventory_2_outlined,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
