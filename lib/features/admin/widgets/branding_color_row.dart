import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../core/branding/app_branding.dart';

/// Linha com amostra da cor, botão para abrir seletor visual e opcional limpar (API = padrão do app).
class BrandingColorRow extends StatelessWidget {
  const BrandingColorRow({
    super.key,
    required this.label,
    required this.helper,
    required this.controller,
    required this.fallbackColor,
    this.showClear = true,
  });

  final String label;
  final String helper;
  final TextEditingController controller;
  final Color fallbackColor;
  final bool showClear;

  Future<void> _openPicker(BuildContext context) async {
    final initial = parseHexColor(controller.text.trim()) ?? fallbackColor;
    final draft = <Color>[initial];

    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(label),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (ctx, setLocal) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ColorPicker(
                      pickerColor: draft[0],
                      onColorChanged: (c) {
                        draft[0] = c;
                        setLocal(() {});
                      },
                      paletteType: PaletteType.hueWheel,
                      enableAlpha: false,
                      hexInputBar: false,
                      labelTypes: const [],
                      displayThumbColor: true,
                      pickerAreaHeightPercent: 0.65,
                      pickerAreaBorderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in _quickSwatches)
                          InkWell(
                            onTap: () {
                              draft[0] = c;
                              setLocal(() {});
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, draft[0]),
              child: const Text("Usar esta cor"),
            ),
          ],
        );
      },
    );

    if (picked != null && context.mounted) {
      controller.text = formatBrandingHexRgb(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final preview = parseHexColor(controller.text.trim()) ?? fallbackColor;
        final hasCustom = controller.text.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              helper,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: preview.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openPicker(context),
                    icon: const Icon(Icons.color_lens_outlined, size: 20),
                    label: const Text("Escolher cor"),
                  ),
                ),
                if (showClear && hasCustom) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: "Voltar ao padrão do app",
                    onPressed: () => controller.clear(),
                    icon: const Icon(Icons.restart_alt),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

const List<Color> _quickSwatches = [
  Color(0xFFD32F2F),
  Color(0xFFE53935),
  Color(0xFFC62828),
  Color(0xFF1565C0),
  Color(0xFF1976D2),
  Color(0xFF00897B),
  Color(0xFF2E7D32),
  Color(0xFF6A1B9A),
  Color(0xFFAD1457),
  Color(0xFFEF6C00),
  Color(0xFFF9A825),
  Color(0xFF37474F),
  Color(0xFF000000),
  Color(0xFF1A1A1A),
  Color(0xFFFFFFFF),
];
