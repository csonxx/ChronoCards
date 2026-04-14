import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/entities/event_card.dart';

/// Card effect panel - shows card effects with conflict warnings
/// Handles exclusive/conflict hints and blank card special UI
class CardEffectPanel extends StatelessWidget {
  final EventCard card;
  final bool hasConflict;
  final String? conflictMessage;
  final Function(String optionId)? onOptionSelected;
  final VoidCallback? onConfirm;
  final VoidCallback? onSkip;
  final String? selectedOptionId;

  const CardEffectPanel({
    super.key,
    required this.card,
    this.hasConflict = false,
    this.conflictMessage,
    this.onOptionSelected,
    this.onConfirm,
    this.onSkip,
    this.selectedOptionId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252A34).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasConflict ? const Color(0xFFC94A4A) : const Color(0xFF393E46),
          width: hasConflict ? 2 : 1,
        ),
        boxShadow: [
          if (hasConflict)
            BoxShadow(
              color: const Color(0xFFC94A4A).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conflict warning
          if (hasConflict) _buildConflictWarning(),

          // Type badge
          _buildTypeBadge(),

          const SizedBox(height: 12),

          // Blank card special UI
          if (card.isBlank)
            _buildBlankCardUI()
          else
            _buildNormalOptions(),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, delay: 200.ms);
  }

  Widget _buildConflictWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC94A4A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC94A4A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFC94A4A), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              conflictMessage ?? '此卡与当前生效卡牌互斥，将替代前者',
              style: const TextStyle(
                color: Color(0xFFC94A4A),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildTypeBadge() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: card.type.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(card.type.icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                card.type.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          card.name,
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNormalOptions() {
    return Column(
      children: [
        ...card.options.map((option) {
          final isSelected = option.id == selectedOptionId;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onOptionSelected?.call(option.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFC4A35A).withOpacity(0.2)
                        : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD4A843)
                          : const Color(0xFF393E46),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFFD4A843)
                              : const Color(0xFF393E46),
                        ),
                        child: Center(
                          child: Text(
                            option.id.toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF1A1A2E)
                                  : const Color(0xFFB0B0B0),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFD4A843)
                                : const Color(0xFFE0E0E0),
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (option.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A843).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '推荐',
                            style: TextStyle(
                              color: Color(0xFFD4A843),
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: (card.options.indexOf(option) * 100).ms);
        }),

        const SizedBox(height: 8),

        // Confirm and Skip buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF4A5568)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '跳过',
                  style: TextStyle(color: Color(0xFFB0B0B0)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: selectedOptionId != null ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC4A35A),
                  foregroundColor: const Color(0xFF1A1A2E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: const Color(0xFF393E46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '确认选择',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlankCardUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4A4A4A)),
      ),
      child: Column(
        children: [
          // Large "空" character
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A4A4A).withOpacity(0.3),
              border: Border.all(color: const Color(0xFF4A4A4A), width: 2),
            ),
            child: const Center(
              child: Text(
                '空',
                style: TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontSize: 40,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            '此卡为自由行动卡，不占事件上限',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            '请书写你的江湖故事',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 14,
              fontFamily: 'serif',
            ),
          ),

          const SizedBox(height: 16),

          // Custom text input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF393E46)),
            ),
            child: const TextField(
              maxLines: 2,
              style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
              decoration: InputDecoration(
                hintText: '输入你的自由行动...',
                hintStyle: TextStyle(color: Color(0xFF666666)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFF4A5568)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '返回',
                    style: TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A4A4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '确认自由行动',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
