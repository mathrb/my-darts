import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/constants.dart';
import '../providers/statistics_provider.dart';
import '../state/player_stats_page_state.dart';

class PracticeGameTypeChipSelectorWidget extends ConsumerWidget {
  final String playerId;

  const PracticeGameTypeChipSelectorWidget({super.key, required this.playerId});

  static const _practiceTypes = [
    GameType.aroundTheClock,
    GameType.bobs27,
    GameType.shanghai,
    GameType.catch40,
    GameType.checkoutPractice,
  ];

  static String _label(GameType type) => switch (type) {
        GameType.aroundTheClock => 'Around the Clock',
        GameType.bobs27 => "Bob's 27",
        GameType.shanghai => 'Shanghai',
        GameType.catch40 => 'Catch-40',
        GameType.checkoutPractice => 'Checkout',
        _ => type.name,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);

    if (pageState.activeTab != StatsTabIndex.practice) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _practiceTypes.map((type) {
          final isSelected = pageState.selectedPracticeGameType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_label(type)),
              selected: isSelected,
              selectedColor: cs.primaryContainer,
              checkmarkColor: cs.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
              backgroundColor: cs.surfaceContainerHighest,
              onSelected: (_) => notifier.setPracticeGameType(type),
            ),
          );
        }).toList(),
      ),
    );
  }
}
