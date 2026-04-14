import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/entities/event_card.dart';

/// Exit condition HUD - top bar display
/// Shows 4 types of conditions with progress bars and warning banner
class ExitConditionHUD extends StatelessWidget {
  final List<ExitCondition> conditions;
  final int drawnCount;
  final VoidCallback? onBannerTap;

  const ExitConditionHUD({
    super.key,
    required this.conditions,
    required this.drawnCount,
    this.onBannerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Warning banner if any condition triggered
        _buildWarningBanner(),

        // Main HUD bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF252A34).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF393E46),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Condition indicators
              Expanded(
                child: Row(
                  children: conditions.map((cond) {
                    return Expanded(
                      child: _ConditionIndicator(condition: cond),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 12),

              // Drawn count
              _DrawnCountBadge(count: drawnCount),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    final triggered = conditions.where((c) => c.isTriggered).toList();
    if (triggered.isEmpty) return const SizedBox.shrink();

    final cond = triggered.first;

    return GestureDetector(
      onTap: onBannerTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF8B2020),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B2020).withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '⚠ 退出条件已触发：【${cond.type.label}】—— 本章事件卡循环即将结束',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.02, 1.02),
            duration: 500.ms,
          )
          .then()
          .scale(
            begin: const Offset(1.02, 1.02),
            end: const Offset(1, 1),
            duration: 500.ms,
          ),
    );
  }
}

class _ConditionIndicator extends StatelessWidget {
  final ExitCondition condition;

  const _ConditionIndicator({required this.condition});

  @override
  Widget build(BuildContext context) {
    final color = condition.isTriggered
        ? const Color(0xFF4A7A6A)
        : condition.type.activeColor;
    final isTurnLimit = condition.type == ExitConditionType.turnLimit;
    final isOverLimit =
        isTurnLimit && condition.current >= condition.target - 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status dot + label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: condition.isTriggered
                    ? const Color(0xFF4A7A6A)
                    : condition.type.activeColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              condition.type.label,
              style: TextStyle(
                color: condition.isTriggered
                    ? const Color(0xFF4A7A6A)
                    : const Color(0xFFE0E0E0),
                fontSize: 10,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Progress bar
        if (isTurnLimit)
          Text(
            '${condition.current}/${condition.target}',
            style: TextStyle(
              color: isOverLimit
                  ? const Color(0xFFC94A4A)
                  : const Color(0xFFD4A843),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          SizedBox(
            width: 50,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: condition.progress,
                backgroundColor: const Color(0xFF393E46),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
      ],
    );
  }
}

class _DrawnCountBadge extends StatelessWidget {
  final int count;

  const _DrawnCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (count > 8) {
      textColor = const Color(0xFFC94A4A);
    } else if (count > 6) {
      textColor = const Color(0xFFD4A843);
    } else {
      textColor = const Color(0xFFE0E0E0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF393E46)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '已抽',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '张',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    ).animate(target: count > 8 ? 1 : 0).shake(
          hz: 2,
          duration: 300.ms,
        );
  }
}
