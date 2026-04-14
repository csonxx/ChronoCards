import 'package:flutter/material.dart';
import '../../../domain/entities/event_card.dart';

/// Deck distributor HUD - bottom bar showing distributor busy status
/// 5 density levels: idle / normal / busy / full / overloaded
class DeckDistributorHUD extends StatelessWidget {
  final DeckDistributorStatus status;

  const DeckDistributorHUD({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final level = status.densityLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252A34).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: level.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Density indicator
          _DensityIndicator(status: status),

          const SizedBox(width: 12),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  level.label,
                  style: TextStyle(
                    color: level.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (level == DeckDensityLevel.overloaded && status.queueLength > 0)
                  Text(
                    '⏳预计等待：${status.queueLength}回合',
                    style: const TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // Count display
          _CountDisplay(status: status),
        ],
      ),
    );
  }
}

class _DensityIndicator extends StatelessWidget {
  final DeckDistributorStatus status;

  const _DensityIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final level = status.densityLevel;
    final bars = 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(bars, (index) {
        final isActive = index < (status.busyCount * bars / status.totalCount).ceil();
        return Container(
          width: 16,
          height: 12 + (index * 3),
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: isActive ? level.color : const Color(0xFF393E46),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _CountDisplay extends StatelessWidget {
  final DeckDistributorStatus status;

  const _CountDisplay({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${status.busyCount}',
            style: TextStyle(
              color: status.densityLevel.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' / ${status.totalCount} ',
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 14,
            ),
          ),
          const Text(
            '发牌员忙碌',
            style: TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
