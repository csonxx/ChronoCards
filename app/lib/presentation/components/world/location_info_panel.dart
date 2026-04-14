import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/world_location.dart';

/// Location Info Panel - Slide-up panel showing current scene details
/// Displays: name, description, region, dealers, visit history, bgm
class LocationInfoPanel extends StatelessWidget {
  final WorldLocation location;
  final List<String> dealers;
  final int visitCount;
  final VoidCallback onClose;
  final ValueChanged<String> onNavigate;

  const LocationInfoPanel({
    super.key,
    required this.location,
    required this.dealers,
    required this.visitCount,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryDark.withOpacity(0.95),
            AppTheme.primaryMid.withOpacity(0.98),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          _buildHandleBar(),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildDescription(),
                const SizedBox(height: 16),
                _buildDealersRow(),
                const SizedBox(height: 16),
                _buildBottomRow(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.cardBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Location icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _getLocationColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getLocationColor(), width: 2),
          ),
          child: Icon(
            _getLocationIcon(),
            color: _getLocationColor(),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        // Name and region
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      location.name,
                      style: const TextStyle(
                        color: AppTheme.textGold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!location.isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: Colors.grey, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'LOCKED',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      location.regionId,
                      style: const TextStyle(
                        color: AppTheme.textGold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Danger level
                  _buildDangerBadge(),
                ],
              ),
            ],
          ),
        ),
        // Close button
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDangerBadge() {
    final color = AppTheme.getDangerColor(location.dangerLevel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            'Lv.${location.dangerLevel}',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.format_quote,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              location.description.isNotEmpty
                  ? location.description
                  : 'A mysterious place waiting to be explored.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealersRow() {
    if (dealers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.people, color: AppTheme.textGold, size: 16),
            SizedBox(width: 8),
            Text(
              'Available Dealers',
              style: TextStyle(
                color: AppTheme.textGold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dealers.map((dealer) => _buildDealerChip(dealer)).toList(),
        ),
      ],
    );
  }

  Widget _buildDealerChip(String dealer) {
    final dealerInfo = _getDealerInfo(dealer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dealerInfo['color']!.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dealerInfo['color']!.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dealerInfo['icon'] as IconData,
            color: dealerInfo['color'] as Color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            dealer,
            style: TextStyle(
              color: dealerInfo['color'] as Color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDealerInfo(String dealer) {
    switch (dealer.toLowerCase()) {
      case 'tea':
        return {'icon': Icons.local_cafe, 'color': const Color(0xFF8B4513)};
      case 'bounty':
        return {'icon': Icons.assignment, 'color': const Color(0xFFFF6B35)};
      case 'enemy':
        return {'icon': Icons.sports_kabaddi, 'color': AppTheme.healthRed};
      case 'inn':
        return {'icon': Icons.hotel, 'color': AppTheme.accentMystic};
      case 'merchant':
        return {'icon': Icons.store, 'color': AppTheme.accentGold};
      default:
        return {'icon': Icons.help_outline, 'color': AppTheme.textSecondary};
    }
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      children: [
        // Visit history
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history, color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Visited $visitCount times',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // BGM button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, color: AppTheme.textSecondary, size: 16),
              SizedBox(width: 6),
              Text(
                'BGM',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Navigate button
        if (location.isUnlocked)
          ElevatedButton.icon(
            onPressed: () => onNavigate(location.id),
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text('NAVIGATE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock, size: 18),
            label: const Text('LOCKED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Color _getLocationColor() {
    return AppTheme.getLocationTypeColor(location.type);
  }

  IconData _getLocationIcon() {
    switch (location.type.toLowerCase()) {
      case 'city':
        return Icons.location_city;
      case 'town':
        return Icons.home;
      case 'village':
        return Icons.house;
      case 'wilderness':
        return Icons.park;
      case 'dungeon':
        return Icons.castle;
      case 'inn':
        return Icons.hotel;
      case 'special':
        return Icons.star;
      default:
        return Icons.place;
    }
  }
}
