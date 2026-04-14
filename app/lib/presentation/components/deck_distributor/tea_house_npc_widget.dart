import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'deck_distributor_colors.dart';
import 'deck_distributor_bubble.dart';

/// 茶馆NPC发牌员组件
/// - 外观：灰青长衫+铜铃折扇，茶绿配色
/// - 状态：空闲/激活/冷却中
/// - 触发卡牌：主线推进卡/角色主导卡
class TeaHouseNPCWidget extends StatefulWidget {
  final DeckDistributorState state;
  final VoidCallback? onTap;
  final String? dialogueText;
  final int cooldownSeconds; // 冷却倒计时秒数

  const TeaHouseNPCWidget({
    super.key,
    required this.state,
    this.onTap,
    this.dialogueText,
    this.cooldownSeconds = 0,
  });

  @override
  State<TeaHouseNPCWidget> createState() => _TeaHouseNPCWidgetState();
}

class _TeaHouseNPCWidgetState extends State<TeaHouseNPCWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;
  late Animation<double> _fanShakeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breatheAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _fanShakeAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    if (widget.state == DeckDistributorState.active) {
      _breatheController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TeaHouseNPCWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == DeckDistributorState.active && !_breatheController.isAnimating) {
      _breatheController.repeat(reverse: true);
    } else if (widget.state != DeckDistributorState.active && _breatheController.isAnimating) {
      _breatheController.stop();
      _breatheController.reset();
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
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

    Color primaryColor;
    Color secondaryColor;
    double opacity;
    Color overlayColor;

    switch (widget.state) {
      case DeckDistributorState.idle:
        primaryColor = DeckDistributorColors.teahousePrimary;
        secondaryColor = DeckDistributorColors.teahouseSecondary;
        opacity = 0.7;
        overlayColor = Colors.grey.withOpacity(0.3);
        break;
      case DeckDistributorState.active:
        primaryColor = DeckDistributorColors.teahousePrimary;
        secondaryColor = DeckDistributorColors.gold;
        opacity = 1.0;
        overlayColor = Colors.transparent;
        break;
      case DeckDistributorState.cooldown:
        primaryColor = DeckDistributorColors.teahousePrimary.withOpacity(0.3);
        secondaryColor = DeckDistributorColors.darkCyan.withOpacity(0.3);
        opacity = 0.4;
        overlayColor = Colors.grey.withOpacity(0.6);
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isCooldown ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breatheAnimation, _fanShakeAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: isActive ? _breatheAnimation.value : (_isHovered ? 1.05 : 1.0),
              child: child,
            );
          },
          child: Tooltip(
            message: isCooldown
                ? '冷却中：${_formatCooldown(widget.cooldownSeconds)}'
                : (isActive ? '点击对话' : (widget.dialogueText ?? '暂无新消息')),
            child: Container(
              width: 112,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1612),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? DeckDistributorColors.gold : DeckDistributorColors.darkCyan,
                  width: isActive ? 2 : 1,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: DeckDistributorColors.teahousePrimary.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  if (_isHovered && !isCooldown)
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景装饰：茶馆门面
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 渐变底色
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  DeckDistributorColors.teahouseSecondary.withOpacity(0.3),
                                  DeckDistributorColors.teahousePrimary.withOpacity(0.2),
                                ],
                              ),
                            ),
                          ),
                          // 瓦屋顶装饰线
                          Positioned(
                            top: 8,
                            left: 16,
                            right: 16,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: DeckDistributorColors.teahousePrimary.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // 冷却灰度叠加
                          if (isCooldown)
                            Container(color: Colors.grey.withOpacity(0.5)),
                        ],
                      ),
                    ),
                  ),

                  // NPC 主体
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 茶杯热气（活跃时动画）
                      if (isActive)
                        AnimatedBuilder(
                          animation: _breatheController,
                          builder: (context, _) {
                            return Opacity(
                              opacity: 0.6 + (_breatheAnimation.value - 0.98) * 10,
                              child: const Text(
                                '☁️',
                                style: TextStyle(fontSize: 14),
                              ),
                            );
                          },
                        ),

                      // NPC 头像占位（圆角矩形，灰青长衫）
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isCooldown
                                ? [Colors.grey.shade600, Colors.grey.shade800]
                                : [primaryColor.withOpacity(0.8), secondaryColor.withOpacity(0.9)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? DeckDistributorColors.gold : secondaryColor,
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // NPC 面部区域
                            Text(
                              isActive ? '🧓' : '👤',
                              style: const TextStyle(fontSize: 28),
                            ),
                            // 铜铃
                            if (!isCooldown)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: AnimatedBuilder(
                                  animation: _fanShakeAnimation,
                                  builder: (context, _) {
                                    return Transform.rotate(
                                      angle: isActive
                                          ? _fanShakeAnimation.value * 0.05
                                          : 0,
                                      child: const Text('🔔', style: TextStyle(fontSize: 12)),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 折扇（激活时展开）
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          isActive ? '🪭' : '🪭',
                          style: TextStyle(
                            fontSize: 16,
                            color: isActive ? null : Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 名称标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? DeckDistributorColors.teahousePrimary.withOpacity(0.2)
                              : Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '说书人',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCooldown
                                ? Colors.grey
                                : DeckDistributorColors.earthYellow,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 激活金色感叹号气泡
                  if (isActive)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: DeckDistributorColors.gold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DeckDistributorColors.gold.withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          '!',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                  // 冷却砂漏
                  if (isCooldown)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Column(
                        children: [
                          const Text('⏳', style: TextStyle(fontSize: 14)),
                          Text(
                            _formatCooldown(widget.cooldownSeconds),
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
