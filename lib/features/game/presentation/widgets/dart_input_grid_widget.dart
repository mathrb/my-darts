import 'package:flutter/material.dart';

const _dartboardOrder = [
  20, 19, 18, 17, 16, 15, 14, 13, 12, 11,
  10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
];

class DartInputGridWidget extends StatelessWidget {
  const DartInputGridWidget({
    required this.onSegmentTapped,
    this.enabled = true,
    super.key,
  });

  final void Function(String segment) onSegmentTapped;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5E6D3),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSpecialRow(),
          const SizedBox(height: 8),
          _buildMultiplierRow('S', '', (n) => '$n'),
          const SizedBox(height: 8),
          _buildMultiplierRow('D', '··', (n) => 'D$n'),
          const SizedBox(height: 8),
          _buildMultiplierRow('T', '···', (n) => 'T$n'),
        ],
      ),
    );
  }

  Widget _buildSpecialRow() {
    return Row(
      children: [
        Expanded(
          child: _SegmentButton(
            label: 'MISS',
            dots: '',
            onTap: () => onSegmentTapped('MISS'),
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _SegmentButton(
            label: 'BULL\n25',
            dots: '',
            onTap: () => onSegmentTapped('SB'),
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _SegmentButton(
            label: 'BULL\n50',
            dots: '',
            onTap: () => onSegmentTapped('DB'),
            enabled: enabled,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplierRow(
    String header,
    String dots,
    String Function(int) segmentBuilder,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              header,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _dartboardOrder.map((n) {
              return SizedBox(
                width: 48,
                height: 56,
                child: _SegmentButton(
                  label: '$n',
                  dots: dots,
                  onTap: () => onSegmentTapped(segmentBuilder(n)),
                  enabled: enabled,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.dots,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final String dots;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (dots.isNotEmpty)
                  Text(
                    dots,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
