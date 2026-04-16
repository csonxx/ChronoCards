import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/equipment_provider.dart';
import '../../../../domain/combat/martial_arts_system.dart';

/// 装备面板 - 显示和管理角色装备
class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EquipmentProvider(),
      child: const _EquipmentScreenContent(),
    );
  }
}

class _EquipmentScreenContent extends StatelessWidget {
  const _EquipmentScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('装备管理'),
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF16213e),
      body: Consumer<EquipmentProvider>(
        builder: (context, equipment, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 属性加成总览
                _buildStatsOverview(equipment),
                const SizedBox(height: 24),
                // 装备槽位
                _buildEquipmentSlots(context, equipment),
                const SizedBox(height: 24),
                // 物品选择
                _buildItemSelection(context, equipment),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(EquipmentProvider equipment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0f3460),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚔️ 当前属性加成',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('攻击', equipment.totalAttackBonus, Icons.flash_on, Colors.red),
              _buildStatItem('防御', equipment.totalDefenseBonus, Icons.shield, Colors.blue),
              _buildStatItem('生命', equipment.totalHealthBonus, Icons.favorite, Colors.pink),
              _buildStatItem('内力', equipment.totalQiBonus, Icons.ac_unit, Colors.cyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '+$value',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSlots(BuildContext context, EquipmentProvider equipment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📦 装备栏',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...EquipmentSlotType.values.map((slot) {
          final item = equipment.getEquipped(slot);
          return _buildSlotRow(context, slot, item, equipment);
        }),
      ],
    );
  }

  Widget _buildSlotRow(
    BuildContext context,
    EquipmentSlotType slot,
    EquipmentItem? item,
    EquipmentProvider equipment,
  ) {
    final slotName = _getSlotName(slot);
    final slotIcon = _getSlotIcon(slot);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item != null ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // 槽位图标
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0f3460),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(slotIcon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          // 槽位名称和物品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slotName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item?.name ?? '未装备',
                  style: TextStyle(
                    color: item != null ? Colors.white : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item != null) ...[
                  const SizedBox(height: 4),
                  _buildItemStats(item),
                ],
              ],
            ),
          ),
          // 操作按钮
          if (item != null)
            TextButton(
              onPressed: () => equipment.unequipItem(slot),
              child: const Text(
                '卸下',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemStats(EquipmentItem item) {
    final stats = <String>[];
    if (item.attackBonus > 0) stats.add('攻击+${item.attackBonus}');
    if (item.defenseBonus > 0) stats.add('防御+${item.defenseBonus}');
    if (item.healthBonus > 0) stats.add('生命+${item.healthBonus}');
    if (item.qiBonus > 0) stats.add('内力+${item.qiBonus}');

    return Wrap(
      spacing: 8,
      children: stats.map((s) => Text(
        s,
        style: const TextStyle(color: Colors.amber, fontSize: 12),
      )).toList(),
    );
  }

  Widget _buildItemSelection(BuildContext context, EquipmentProvider equipment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎒 可用物品',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // 按槽位分类显示
        ...EquipmentSlotType.values.map((slot) {
          final available = equipment.getAvailableForSlot(slot);
          return _buildSlotItems(context, slot, available, equipment);
        }),
      ],
    );
  }

  Widget _buildSlotItems(
    BuildContext context,
    EquipmentSlotType slot,
    List<EquipmentItem> items,
    EquipmentProvider equipment,
  ) {
    final slotName = _getSlotName(slot);
    final slotIcon = _getSlotIcon(slot);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(slotIcon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                slotName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isEquipped = equipment.getEquipped(slot)?.id == item.id;
                return _buildItemCard(context, item, isEquipped, equipment, slot);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    EquipmentItem item,
    bool isEquipped,
    EquipmentProvider equipment,
    EquipmentSlotType slot,
  ) {
    return GestureDetector(
      onTap: isEquipped ? null : () => equipment.equipItem(item),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEquipped ? const Color(0xFF0f3460) : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEquipped ? Colors.green : Colors.grey.withOpacity(0.3),
            width: isEquipped ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.iconEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Lv.${item.levelRequired}',
              style: TextStyle(
                color: item.levelRequired <= 5 ? Colors.green : Colors.orange,
                fontSize: 10,
              ),
            ),
            if (isEquipped)
              const Text(
                '已装备',
                style: TextStyle(color: Colors.green, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }

  String _getSlotName(EquipmentSlotType slot) {
    switch (slot) {
      case EquipmentSlotType.weapon:
        return '武器';
      case EquipmentSlotType.armor:
        return '防具';
      case EquipmentSlotType.accessory1:
        return '饰品 1';
      case EquipmentSlotType.accessory2:
        return '饰品 2';
    }
  }

  String _getSlotIcon(EquipmentSlotType slot) {
    switch (slot) {
      case EquipmentSlotType.weapon:
        return '⚔️';
      case EquipmentSlotType.armor:
        return '🛡️';
      case EquipmentSlotType.accessory1:
        return '💍';
      case EquipmentSlotType.accessory2:
        return '🏮';
    }
  }
}
