import 'package:flutter/material.dart';

/// Camada semitransparente + [CircularProgressIndicator] + mensagem.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.visible,
    required this.message,
    required this.child,
  });

  final bool visible;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = cs.brightness == Brightness.light;
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: AbsorbPointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isLight
                      ? cs.inverseSurface.withValues(alpha: 0.72)
                      : cs.scrim.withValues(alpha: 0.65),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: cs.tertiary),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: isLight
                                ? cs.onInverseSurface
                                : cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
