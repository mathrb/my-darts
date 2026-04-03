import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class TrendChartShellWidget extends StatelessWidget {
  final bool hasEnoughData;
  final Widget child;

  const TrendChartShellWidget({
    super.key,
    required this.hasEnoughData,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: hasEnoughData
          ? Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: child,
            )
          : Center(
              child: Text(
                'Not enough data yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
    );
  }
}
