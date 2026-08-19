import 'package:flutter/material.dart';

/// Convierte un porcentaje (0–100) en valoración 0–5 (admite medios).
double starsFromPercent(double? percent) {
  if (percent == null) return 0;
  return (percent / 20.0).clamp(0, 5);
}

class ScoreStars extends StatelessWidget {
  const ScoreStars({
    super.key,
    required this.percent,
    this.size = 14,
    this.showLabel = false,
  });

  final double? percent;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final rating = starsFromPercent(percent);
    final label = percent == null ? '--' : '${percent!.round()}%';
    final stars = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final filled = rating - i;
          IconData icon;
          if (filled >= 0.75) {
            icon = Icons.star_rounded;
          } else if (filled >= 0.25) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }
          final active = filled >= 0.25;
          return Icon(
            icon,
            size: size,
            color: active ? const Color(0xFFE6A817) : const Color(0xFFCBD5E1),
          );
        }),
      ),
    );

    if (!showLabel) return stars;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        stars,
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
