import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'deck_distributor_colors.dart';
import 'deck_distributor_bubble.dart';

/// 敌人遭遇发牌员组件
/// - 外观：交叉双刀+血红气息
/// - 三选项：战斗/智取/逃跑
/// - 状态：空闲/激活/冷却中
/// - 触发：战斗卡/角色主导卡
class EnemyEncounterWidget extends StatefulWidget {
  final DeckDistributorState state;
  final VoidCallback? onBattle;
  final VoidCallback? onClever;
  final VoidCallback? onEscape;
  final int starDangerLevel; // 1-5 危险等级
  final String? enemyName;
  final String? enemyType; // 流寇/门派弟子/野兽/BOSS
  final int cooldownSeconds;

  const EnemyEncounterWidget({
    super.key,
    required this.state,
    this.onBattle,
    this.onClever,
    this.onEscape,
    this.starDangerLevel = 1,
    this.enemyName,
    this.enemyType,
    this.cooldownSeconds = 0,
  });

  @override
  State<EnemyEncounterWidget> createState() => _EnemyEncounterWidgetState();
}

class _EnemyEncounterWidgetState extends State<EnemyEncounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bloodGlowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _bloodGlowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.state == DeckDistributorState.active) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EnemyEncounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == DeckDistributorState.active && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.state != DeckDistributorState.active && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getDangerColor(int level) {
    if (level <= 1) return DeckDistributorColors.manaBlue;
    if (level <= 2) return DeckDistributorColors.energyYellow;
    if (level <= 3) return Colors.orange;
    return DeckDistributorColors.healthRed;
  }

  String _buildDangerStars(int count) {
    return '★' * count + '☆' * (5 - count);
  }

  String _getEnemyEmoji(String? type) {
    switch (type?.toLowerCase()) {
      case 'boss':
        return '👹';
      case '野兽':
        return '🐺';
      case '流寇':
        return '🗡️';
      case '门派弟子':
        return '⚔️';
      default:
        return '💀';
    }
  }

  String _formatCooldown(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = widget.state == DeckDistributorState.idle;
    final isActive = widget.state == DeckDistributorState.active;
    final isCooldown = widget.state == DeckDistributorState.cooldown;
    final dangerColor = _getDangerColor(widget.starDangerLevel);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _bloodGlowAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? _pulseAnimation.value : (_isHovered && !isCooldown ? 1.05 : 1.0),
            child: Container(
              width: 140,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? DeckDistributorColors.vermillionDeep
                      : DeckDistributorColors.enemyDarkIron,
                  width: isActive ? 2 : 1,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: DeckDistributorColors.vermillionDeep.withOpacity(_bloodGlowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  if (_isHovered && !isCooldown)
                    BoxShadow(
                      color: dangerColor.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 黑色阴云/暗雾纹理背景
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.2,
                            colors: isCooldown
                                ? [Colors.grey.shade900, Colors.black]
                                : [
                                    DeckDistributorColors.enemyBlack.withOpacity(0.8),
                                    const Color(0xFF0D0A0A),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 血红气息环绕（激活时）
                  if (isActive)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: DeckDistributorColors.vermillionDeep.withOpacity(_bloodGlowAnimation.value * 0.5),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 交叉双刀图标
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        '⚔️',
                        style: TextStyle(
                          fontSize: 20,
                          color: isCooldown ? Colors.grey : null,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Transform.rotate(
                      angle: 0.5,
                      child: Text(
                        '⚔️',
                        style: TextStyle(
                          fontSize: 20,
                          color: isCooldown ? Colors.grey : null,
                        ),
                      ),
                    ),
                  ),

                  // 敌人立绘/占位
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 危险等级HUD
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCooldown
                              ? Colors.grey.withOpacity(0.5)
                              : dangerColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isCooldown ? Colors.grey : dangerColor),
                        ),
                        child: Text(
                          _buildDangerStars(widget.starDangerLevel),
                          style: TextStyle(
                            fontSize: 10,
                            color: isCooldown ? Colors.grey : dangerColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 敌人头像/类型
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isCooldown
                              ? Colors.grey.shade800
                              : DeckDistributorColors.enemyBlack,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isCooldown
                                ? Colors.grey
                                : DeckDistributorColors.vermillionDeep,
                            width: isActive ? 2 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: DeckDistributorColors.vermillionDeep.withOpacity(_bloodGlowAnimation.value),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            isActive
                                ? (_getEnemyEmoji(widget.enemyType))
                                : (isCooldown ? '💨' : '👤'),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 敌人名称
                      Text(
                        widget.enemyName ?? (isCooldown ? '消散中' : '遭遇敌人'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCooldown ? Colors.grey : DeckDistributorColors.vermillionDeep,
                        ),
                      ),
                      Text(
                        widget.enemyType ?? '未知类型',
                        style: TextStyle(
                          fontSize: 8,
                          color: isCooldown ? Colors.grey.shade600 : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // 脚下暗红光环（激活时）
                  if (isActive)
                    Positioned(
                      bottom: 40,
                      child: AnimatedBuilder(
                        animation: _bloodGlowAnimation,
                        builder: (context, _) {
                          return Container(
                            width: 48,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: DeckDistributorColors.vermillionDeep.withOpacity(_bloodGlowAnimation.value),
                                  blurRadius: 12,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // 骷髅危险标记（左上角）
                  if (!isCooldown)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Text(
                        '💀',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? null : Colors.grey,
                        ),
                      ),
                    ),

                  // 冷却状态：双刀插地
                  if (isCooldown)
                    Positioned(
                      bottom: 16,
                      child: Column(
                        children: [
                          const Text('🗡️', style: TextStyle(fontSize: 20}),
                          const SizedBox(height: 4),
                          Text(
                            '⏳ ${_formatCooldown(widget.cooldownSeconds)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 三选项按钮（激活时显示）
                  if (isActive)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _OptionButton(
                            icon: '⚔️',
                            label: '战斗',
                            color: DeckDistributorColors.vermillionDeep,
                            onTap: widget.onBattle,
                          ),
                          _OptionButton(
                            icon: '🧠',
                            label: '智取',
                            color: DeckDistributorColors.darkCyan,
                            onTap: widget.onClever,
                          ),
                          _OptionButton(
                            icon: '🏃',
                            label: '逃跑',
                            color: DeckDistributorColors.teahouseSecondary,
                            onTap: widget.onEscape,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OptionButton extends StatefulWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withOpacity(0.3)
                : widget.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.color.withOpacity(_isHovered ? 0.8 : 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 12)),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
