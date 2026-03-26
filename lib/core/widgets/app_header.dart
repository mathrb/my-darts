import 'package:flutter/material.dart';
import 'package:my_darts/core/utils/app_text_styles.dart';

/// App-wide top header row: logo, optional back button, and trailing action slot.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.showBack = false,
    this.onBack,
    this.trailing,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
      children: [
        if (showBack)
          IconButton(
            icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
            color: cs.onSurface,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
        Expanded(
          child: Text(
            'MYDARTS',
            style: AppTextStyles.headlineMedium.copyWith(
              color: cs.primaryFixed,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ?trailing,
      ],
      ),
    );
  }
}
