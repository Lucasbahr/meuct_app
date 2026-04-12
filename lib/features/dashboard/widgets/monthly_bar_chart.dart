import 'package:flutter/material.dart';

/// Gráfico de barras com grade de fundo e gradiente nas colunas (sem pacotes externos).
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.points,
    required this.color,
    this.maxBars = 12,
    this.valueLabel,
  });

  final List<({String label, double value})> points;
  final Color color;
  final int maxBars;
  final String Function(double value)? valueLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Sem série temporal no retorno da API.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }

    final slice = points.length > maxBars ? points.sublist(points.length - maxBars) : points;
    final maxV = slice.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final denom = maxV <= 0 ? 1.0 : maxV;

    String labelFor(double v) {
      if (valueLabel != null) return valueLabel!(v);
      return v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
    }

    const chartHeight = 196.0;

    return SizedBox(
      height: chartHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _MonthlyChartGridPainter(
              lineColor: cs.outline.withValues(alpha: 0.07),
              rows: 5,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < slice.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        labelFor(slice[i].value),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.62),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: (slice[i].value / denom).clamp(0.06, 1.0),
                            widthFactor: 0.78,
                            alignment: Alignment.bottomCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    color.withValues(alpha: 0.45),
                                    color.withValues(alpha: 0.95),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.22),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        slice[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyChartGridPainter extends CustomPainter {
  _MonthlyChartGridPainter({
    required this.lineColor,
    required this.rows,
  });

  final Color lineColor;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (var r = 1; r < rows; r++) {
      final y = size.height * (r / rows);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyChartGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.rows != rows;
  }
}
