import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// World HUD - Top bar overlay showing world overview info
class WorldHud extends StatelessWidget {
  final String currentRegionName;
  final String? activeEvent;
  final int unlockedCount;
  final int totalCount;
  final VoidCallback onToggleHud;

  const WorldHud({
    super.key,
    required this.currentRegionName,
    this.activeEvent,
    required this.unlockedCount,
    required this.totalCount,
    required this.onToggleHud,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          // Region indicator
          _buildRegionBadge(),
          const SizedBox(width: 16),

          // Active event alert
          if (activeEvent != null) ...[
            _buildEventAlert(),
            const SizedBox(width: 16),
          ],

          const Spacer(),

          // Location progress
          _buildProgressBadge(),
          const SizedBox(width: 12),

          // Map title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map, color: AppTheme.textGold, size: 16),
                SizedBox(width: 6),
                Text(
                  'World Map',
                  style: TextStyle(
                    color: AppTheme.textGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withOpacity(0.3),
            AppTheme.primaryDark.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place, color: AppTheme.textGold, size: 16),
          const SizedBox(width: 6),
          Text(
            currentRegionName,
            style: const TextStyle(
              color: AppTheme.textGold,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventAlert() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentCosmic.withOpacity(0.4),
            AppTheme.accentMystic.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentMystic.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration, color: AppTheme.accentMystic, size: 16),
          const SizedBox(width: 6),
          Text(
            activeEvent!,
            style: const TextStyle(
              color: AppTheme.accentMystic,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.place,
            color: unlockedCount == totalCount
                ? AppTheme.manaBlue
                : AppTheme.textSecondary,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$unlockedCount / $totalCount',
            style: TextStyle(
              color: unlockedCount == totalCount
                  ? AppTheme.manaBlue
                  : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
