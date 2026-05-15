import 'package:flutter/material.dart';

import '../utils/app_spacing.dart';

class FilterChipRowWidget<T> extends StatelessWidget {
  const FilterChipRowWidget({
    required this.items,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.allLabel,
    super.key,
  });

  final List<T> items;
  final T? selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onSelected;
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget chip({
      required String label,
      required bool isSelected,
      required VoidCallback onTap,
    }) =>
        FilterChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: cs.primaryContainer,
          checkmarkColor: cs.onPrimaryContainer,
          backgroundColor: cs.surfaceContainerHighest,
          labelStyle: TextStyle(
            color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
          onSelected: (_) => onTap(),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          if (allLabel != null) ...[
            chip(
              label: allLabel!,
              isSelected: selected == null,
              onTap: () => onSelected(null),
            ),
            const SizedBox(width: AppSpacing.space2),
          ],
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space2),
              child: chip(
                label: labelBuilder(item),
                isSelected: selected == item,
                onTap: () => onSelected(selected == item ? null : item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
