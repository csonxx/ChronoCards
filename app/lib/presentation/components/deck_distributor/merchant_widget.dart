import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'deck_distributor_colors.dart';
import 'deck_distributor_bubble.dart';

/// 商贩类型
enum MerchantType {
  medicine,    // 药贩
  martial,     // 武学贩
  weapon,      // 兵器贩
  oddsAndEnds, // 杂货贩
  mysterious,  // 神秘商贩
}

/// 商贩发牌员组件
/// - 五类型：药贩/武学贩/兵器贩/杂货贩/神秘商贩
/// - 状态：空闲/激活/冷却中
/// - 触发：成长学习卡/宝藏卡
class MerchantWidget extends StatefulWidget {
  final DeckDistributorState state;
  final MerchantType merchantType;
  final VoidCallback? onTap;
  final String? dialogueText;
  final int cooldownSeconds;
  final List<MerchantItem>? items; // 商品列表

  const MerchantWidget({
    super.key,
    required this.state,
    required this.merchantType,
    this.onTap,
    this.dialogueText,
    this.cooldownSeconds = 0,
    this.items,
  });

  @override
  State<MerchantWidget> createState() => _MerchantWidgetState();
}

class _MerchantWidgetState extends State<MerchantWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bobController;
  late Animation<double> _bobAnimation;
  late Animation<double> _bellAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _bobAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );
    _bellAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    if (widget.state == DeckDistributorState.active) {
      _bobController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MerchantWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == DeckDistributorState.active && !_bobController.isAnimating) {
      _bobController.repeat(reverse: true);
    } else if (widget.state != DeckDistributorState.active && _bobController.isAnimating) {
      _bobController.stop();
      _bobController.reset();
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  String _getMerchantEmoji(MerchantType type) {
    switch (type) {
      case MerchantType.medicine:
        return '💊';
      case MerchantType.martial:
        return '📜';
      case MerchantType.weapon:
        return '⚔️';
      case MerchantType.oddsAndEnds:
        return '🎁';
      case MerchantType.mysterious:
        return '🌙';
    }
  }

  String _getMerchantName(MerchantType type) {
    switch (type) {
      case MerchantType.medicine:
        return '药贩';
      case MerchantType.martial:
        return '武学贩';
      case MerchantType.weapon:
        return '兵器贩';
      case MerchantType.oddsAndEnds:
        return '杂货贩';
      case MerchantType.mysterious:
        return '神秘商贩';
    }
  }

  Color _getMerchantColor(MerchantType type) {
    switch (type) {
      case MerchantType.medicine:
        return DeckDistributorColors.herbGreen;
      case MerchantType.martial:
        return const Color(0xFF533483); // 武学紫
      case MerchantType.weapon:
        return DeckDistributorColors.enemyDarkIron;
      case MerchantType.oddsAndEnds:
        return DeckDistributorColors.earthYellow;
      case MerchantType.mysterious:
        return const Color(0xFF7B5EA7); // 神秘紫
    }
  }

  String _getItemEmoji(MerchantType type) {
    switch (type) {
      case MerchantType.medicine:
        return '💊';
      case MerchantType.martial:
        return '📖';
      case MerchantType.weapon:
        return '🗡️';
      case MerchantType.oddsAndEnds:
        return '🎁';
      case MerchantType.mysterious:
        return '✨';
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
    final merchantColor = _getMerchantColor(widget.merchantType);
    final isMysterious = widget.merchantType == MerchantType.mysterious;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isCooldown ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_bobAnimation, _bellAnimation]),
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..translate(0.0, isActive ? _bobAnimation.value : 0.0)
                ..scale(_isHovered && !isCooldown ? 1.05 : 1.0),
              width: 130,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1610),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? (isMysterious
                          ? const Color(0xFF7B5EA7)
                          : DeckDistributorColors.merchantGold)
                      : (isCooldown
                          ? Colors.grey
                          : merchantColor.withOpacity(0.6)),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: (isMysterious
                              ? const Color(0xFF7B5EA7)
                              : merchantColor)
                          .withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  if (_isHovered && !isCooldown)
                    BoxShadow(
                      color: merchantColor.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 神秘商贩紫色光效
                  if (isMysterious && !isCooldown)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.0,
                              colors: [
                                const Color(0xFF7B5EA7).withOpacity(isActive ? 0.3 : 0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 货郎担子主体
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 商贩图标区
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 货郎担子背景
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isCooldown
                                  ? Colors.grey.shade800
                                  : (isMysterious
                                      ? const Color(0xFF7B5EA7).withOpacity(0.2)
                                      : DeckDistributorColors.merchantCloth.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCooldown
                                    ? Colors.grey
                                    : (isActive
                                        ? DeckDistributorColors.merchantGold
                                        : merchantColor.withOpacity(0.5)),
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getMerchantEmoji(widget.merchantType),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          // 神秘商贩黑纱遮面效果
                          if (isMysterious && !isCooldown)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.4),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 扁担（激活时微微起伏动画）
                      Transform.rotate(
                        angle: isActive ? _bellAnimation.value * 0.3 : 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 左布袋
                            Container(
                              width: 20,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isCooldown
                                    ? Colors.grey.shade700
                                    : merchantColor.withOpacity(0.6),
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getItemEmoji(widget.merchantType),
                                  style: const TextStyle(fontSize: 8),
                                ),
                              ),
                            ),
                            // 扁担
                            Container(
                              width: 24,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isCooldown
                                    ? Colors.grey
                                    : const Color(0xFF8B7355),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // 右布袋
                            Container(
                              width: 20,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isCooldown
                                    ? Colors.grey.shade700
                                    : merchantColor.withOpacity(0.6),
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getItemEmoji(widget.merchantType),
                                  style: const TextStyle(fontSize: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 商贩名称标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCooldown
                              ? Colors.grey.withOpacity(0.3)
                              : (isActive
                                  ? merchantColor.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isCooldown
                                ? Colors.grey
                                : (isActive
                                    ? merchantColor
                                    : merchantColor.withOpacity(0.3)),
                          ),
                        ),
                        child: Text(
                          _getMerchantName(widget.merchantType),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCooldown
                                ? Colors.grey
                                : (isActive
                                    ? merchantColor
                                    : DeckDistributorColors.earthYellow),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 铃铛（激活时晃动）
                  if (!isCooldown)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: isActive
                          ? AnimatedBuilder(
                              animation: _bellAnimation,
                              builder: (context, _) {
                                return Transform.rotate(
                                  angle: _bellAnimation.value,
                                  child: const Text('🔔', style: TextStyle(fontSize: 14)),
                                );
                              },
                            )
                          : const Text('🔔', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ),

                  // 激活提示气泡
                  if (isActive)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isMysterious
                              ? const Color(0xFF7B5EA7)
                              : DeckDistributorColors.gold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isMysterious ? '？？？' : '!',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // 商品数量角标
                  if (widget.items != null && widget.items!.isNotEmpty && !isCooldown)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: DeckDistributorColors.merchantGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.items!.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                  // 冷却状态
                  if (isCooldown)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          const Text('⏳', style: TextStyle(fontSize: 16)),
                          Text(
                            _formatCooldown(widget.cooldownSeconds),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 神秘商贩紫光脉冲（激活时）
                  if (isMysterious && isActive)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: AnimatedBuilder(
                          animation: _bobController,
                          builder: (context, _) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: const Color(0xFF7B5EA7)
                                      .withOpacity((_bobAnimation.value + 3) / 6 * 0.5),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 商贩商品项
class MerchantItem {
  final String name;
  final int price;
  final String rarity; // common/rare/epic/legendary

  const MerchantItem({
    required this.name,
    required this.price,
    this.rarity = 'common',
  });
}
