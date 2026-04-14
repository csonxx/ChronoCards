import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'deck_distributor_colors.dart';
import 'deck_distributor_bubble.dart';

/// 客栈发牌员组件
/// - 外观：红灯笼暖黄光晕
/// - 三功能：休息/打听/随机事件
/// - 状态：空闲/激活/冷却中
/// - 触发：空白卡/角色主导卡
class InnWidget extends StatefulWidget {
  final DeckDistributorState state;
  final VoidCallback? onRest;
  final VoidCallback? onGossip;
  final VoidCallback? onEvent;
  final int cooldownSeconds;
  final bool restOnCooldown;

  const InnWidget({
    super.key,
    required this.state,
    this.onRest,
    this.onGossip,
    this.onEvent,
    this.cooldownSeconds = 0,
    this.restOnCooldown = false,
  });

  @override
  State<InnWidget> createState() => _InnWidgetState();
}

class _InnWidgetState extends State<InnWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _lanternController;
  late Animation<double> _lanternGlowAnimation;
  late Animation<double> _lanternSwingAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _lanternController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _lanternGlowAnimation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _lanternController, curve: Curves.easeInOut),
    );
    _lanternSwingAnimation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _lanternController, curve: Curves.easeInOut),
    );

    if (widget.state == DeckDistributorState.active) {
      _lanternController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(InnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == DeckDistributorState.active && !_lanternController.isAnimating) {
      _lanternController.repeat(reverse: true);
    } else if (widget.state != DeckDistributorState.active && _lanternController.isAnimating) {
      _lanternController.stop();
      _lanternController.reset();
    }
  }

  @override
  void dispose() {
    _lanternController.dispose();
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_lanternGlowAnimation, _lanternSwingAnimation]),
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()
              ..scale(_isHovered && !isCooldown ? 1.05 : 1.0),
            width: 130,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1410),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? DeckDistributorColors.innWarmYellow
                    : (isIdle ? DeckDistributorColors.innRed.withOpacity(0.5) : Colors.grey),
                width: isActive ? 2 : 1,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: DeckDistributorColors.innWarmYellow.withOpacity(_lanternGlowAnimation.value * 0.6),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                if (_isHovered && !isCooldown)
                  BoxShadow(
                    color: DeckDistributorColors.innRed.withOpacity(0.3),
                    blurRadius: 12,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 暖黄光晕背景
                if (!isCooldown)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          gradient: RadialGradient(
                            center: Alignment.bottomCenter,
                            radius: 1.2,
                            colors: isActive
                                ? [
                                    DeckDistributorColors.innWarmYellow.withOpacity(_lanternGlowAnimation.value * 0.25),
                                    DeckDistributorColors.innRed.withOpacity(0.1),
                                    Colors.transparent,
                                  ]
                                : [
                                    DeckDistributorColors.innWarmYellow.withOpacity(0.08),
                                    Colors.transparent,
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 冷却灰度叠加
                if (isCooldown)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        color: Colors.grey.withOpacity(0.4),
                      ),
                    ),
                  ),

                // 客栈主体
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 红灯笼 ×2（摇摆动画）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 左灯笼
                        Transform.rotate(
                          angle: isActive ? _lanternSwingAnimation.value : 0,
                          child: _LanternIcon(
                            glow: _lanternGlowAnimation.value,
                            isActive: isActive,
                            isCooldown: isCooldown,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 客栈招牌
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCooldown
                                ? Colors.grey.withOpacity(0.5)
                                : const Color(0xFF6B4423).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isCooldown
                                  ? Colors.grey
                                  : DeckDistributorColors.innWarmYellow.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            '客栈',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isCooldown ? Colors.grey : DeckDistributorColors.earthYellow,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 右灯笼
                        Transform.rotate(
                          angle: isActive ? -_lanternSwingAnimation.value : 0,
                          child: _LanternIcon(
                            glow: _lanternGlowAnimation.value,
                            isActive: isActive,
                            isCooldown: isCooldown,
                            size: 32,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 酒旗（激活时全展）
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isActive ? '🏮' : '🏮',
                        style: TextStyle(
                          fontSize: 20,
                          color: isCooldown ? Colors.grey : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 状态文字
                    Text(
                      isCooldown
                          ? '客满'
                          : (isActive ? '可入内' : '营业中'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCooldown
                            ? Colors.grey
                            : (isActive
                                ? DeckDistributorColors.innWarmYellow
                                : DeckDistributorColors.earthYellow.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),

                // 门口光晕扩散（激活时）
                if (isActive)
                  Positioned(
                    bottom: 0,
                    child: AnimatedBuilder(
                      animation: _lanternGlowAnimation,
                      builder: (context, _) {
                        return Container(
                          width: 60,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: DeckDistributorColors.innWarmYellow.withOpacity(_lanternGlowAnimation.value * 0.6),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // 客满木牌（冷却时）
                if (isCooldown)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '客满',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                // 三功能入口（激活时显示）
                if (isActive)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      children: [
                        // 休息/打听/随机事件
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _InnOptionButton(
                              icon: '🛏️',
                              label: '休息',
                              color: DeckDistributorColors.herbGreen,
                              isOnCooldown: widget.restOnCooldown,
                              onTap: widget.restOnCooldown ? null : widget.onRest,
                            ),
                            _InnOptionButton(
                              icon: '💬',
                              label: '打听',
                              color: DeckDistributorColors.innWarmYellow,
                              onTap: widget.onGossip,
                            ),
                            _InnOptionButton(
                              icon: '🎲',
                              label: '事件',
                              color: DeckDistributorColors.vermillion,
                              onTap: widget.onEvent,
                            ),
                          ],
                        ),
                        if (isCooldown) ...[
                          const SizedBox(height: 4),
                          Text(
                            '⏳ 休息冷却：${_formatCooldown(widget.cooldownSeconds)}',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanternIcon extends StatelessWidget {
  final double glow;
  final bool isActive;
  final bool isCooldown;
  final double size;

  const _LanternIcon({
    required this.glow,
    required this.isActive,
    required this.isCooldown,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 光晕
        if (isActive)
          Container(
            width: size * 1.5,
            height: size * 1.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DeckDistributorColors.innWarmYellow.withOpacity(glow * 0.5),
                  blurRadius: size * 0.8,
                  spreadRadius: size * 0.2,
                ),
              ],
            ),
          ),
        // 灯笼emoji
        Text(
          isCooldown ? '🏮' : '🏮',
          style: TextStyle(
            fontSize: size,
            color: isCooldown ? Colors.grey : null,
          ),
        ),
      ],
    );
  }
}

class _InnOptionButton extends StatefulWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isOnCooldown;

  const _InnOptionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isOnCooldown = false,
  });

  @override
  State<_InnOptionButton> createState() => _InnOptionButtonState();
}

class _InnOptionButtonState extends State<_InnOptionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isOnCooldown || widget.onTap == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered && !isDisabled
                ? widget.color.withOpacity(0.3)
                : widget.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.3)
                  : widget.color.withOpacity(_isHovered ? 0.8 : 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.icon,
                style: TextStyle(
                  fontSize: 12,
                  color: isDisabled ? Colors.grey : null,
                ),
              ),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: isDisabled ? Colors.grey : widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
