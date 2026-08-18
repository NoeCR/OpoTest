import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppDecorations {
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A65), AppTheme.primary, Color(0xFF7E57C2)],
  );

  static const darkHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D4852), AppTheme.cardDark],
  );

  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static TextStyle sectionLabel(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Colors.black.withValues(alpha: 0.45),
      );
}

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.showBack,
    this.height = 120,
    this.gradient = AppDecorations.headerGradient,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  /// Si es null, muestra botón atrás cuando la ruta actual se puede cerrar.
  final bool? showBack;
  final double height;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final shouldShowBack = showBack ?? canPop;
    final backAction = onBack ?? (canPop ? () => Navigator.maybePop(context) : null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height - 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (shouldShowBack && backAction != null)
                IconButton(
                  onPressed: backAction,
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppDecorations.sectionLabel(context)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class OptionChipRow<T> extends StatelessWidget {
  const OptionChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labelBuilder,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final on = opt == selected;
        return FilterChip(
          label: Text(labelBuilder?.call(opt) ?? opt.toString()),
          selected: on,
          onSelected: (_) => onSelected(opt),
          selectedColor: AppTheme.primary.withValues(alpha: 0.15),
          checkmarkColor: AppTheme.primary,
          labelStyle: TextStyle(
            color: on ? AppTheme.primary : Colors.black87,
            fontWeight: on ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
          side: BorderSide(color: on ? AppTheme.primary : Colors.black12),
        );
      }).toList(),
    );
  }
}
