import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Card draw instructions dialog - explains how card drawing works
class CardDrawInstructionsDialog extends StatelessWidget {
  final VoidCallback onGotIt;

  const CardDrawInstructionsDialog({
    super.key,
    required this.onGotIt,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onGotIt}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CardDrawInstructionsDialog(onGotIt: onGotIt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accentCosmic.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentCosmic.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentCosmic.withOpacity(0.4),
                    AppTheme.primaryDark,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentCosmic.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.style,
                      size: 48,
                      color: AppTheme.accentGold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '✨ Card Draw ✨',
                    style: TextStyle(
                      color: AppTheme.textGold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build your deck with powerful cards!',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  _InstructionItem(
                    icon: Icons.touch_app,
                    title: 'Tap Draw',
                    description: 'Press the DRAW button to pull 3 cards from the deck',
                  ),
                  SizedBox(height: 16),
                  _InstructionItem(
                    icon: Icons.visibility,
                    title: 'Preview Cards',
                    description: 'See what cards you\'ve drawn and their stats',
                  ),
                  SizedBox(height: 16),
                  _InstructionItem(
                    icon: Icons.check_circle,
                    title: 'Confirm or Redraw',
                    description: 'Keep your cards or draw again for new ones',
                  ),
                  SizedBox(height: 16),
                  _InstructionItem(
                    icon: Icons.celebration,
                    title: 'Rarity Matters',
                    description: 'Common, Rare, Epic, and Legendary cards have different drop rates!',
                  ),
                ],
              ),
            ),

            // Rarity guide
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Card Rarities',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _RarityRow(
                    rarity: 'Common',
                    color: Colors.grey,
                    probability: '60%',
                  ),
                  _RarityRow(
                    rarity: 'Rare',
                    color: Colors.blue,
                    probability: '25%',
                  ),
                  _RarityRow(
                    rarity: 'Epic',
                    color: Colors.purple,
                    probability: '12%',
                  ),
                  _RarityRow(
                    rarity: 'Legendary',
                    color: AppTheme.textGold,
                    probability: '3%',
                  ),
                ],
              ),
            ),

            // Got it button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onGotIt();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got It!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InstructionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentCosmic.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.accentGold, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RarityRow extends StatelessWidget {
  final String rarity;
  final Color color;
  final String probability;

  const _RarityRow({
    required this.rarity,
    required this.color,
    required this.probability,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rarity,
              style: TextStyle(
                color: color,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            probability,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
