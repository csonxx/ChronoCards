import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'deck_distributor_colors.dart';
import 'deck_distributor_bubble.dart';

/// 悬赏板发牌员组件
/// - 外观：朱砂红卷轴悬赏令
/// - 状态：空闲/有可用悬赏/已领取冷却
/// - 星级难度、触发：支线探索卡/宝藏卡
class QuestBoardWidget extends StatefulWidget {
  final DeckDistributorState state;
  final VoidCallback? onTap;
  final int starDifficulty; // 1-5 星级难度
  final String? questTitle;
  final String? questReward;
  final int cooldownSeconds;
  final int availableQuests; // 可用悬赏数量

  const QuestBoardWidget({
    super.key,
    required this.state,
    this.onTap,
    this.starDifficulty = 1,
    this.questTitle,
    this.questReward,
    this.cooldownSeconds = 0,
    this.availableQuests = 0,
  });

  @override
  State<QuestBoardWidget> createState() => _QuestBoardWidgetState();
}

class _QuestBoardWidgetState extends State<QuestBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.state == DeckDistributorState.active) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(QuestBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == DeckDistributorState.active && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (widget.state != DeckDistributorState.active && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Color _getStarColor(int stars) {
    switch (stars) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.orange;
      case 5:
        return DeckDistributorColors.vermillion;
      default:
        return Colors.grey;
    }
  }

  String _formatCooldown(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  String _buildStars(int count) {
    return '★' * count + '☆' * (5 - count);
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = widget.state == DeckDistributorState.idle;
    final isActive = widget.state == DeckDistributorState.active;
    final isCooldown = widget.state == DeckDistributorState.cooldown;

    final starColor = _getStarColor(widget.starDifficulty);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isCooldown ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..scale(_isHovered && !isCooldown ? 1.05 : 1.0),
              child: child,
            );
          },
          child: Tooltip(
            message: isCooldown
                ? '刷新冷却：${_formatCooldown(widget.cooldownSeconds)}'
                : (isActive ? (widget.questTitle ?? '点击领取悬赏') : '可接悬赏：${widget.availableQuests}个'),
            child: Container(
              width: 128,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1612),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? DeckDistributorColors.vermillion : DeckDistributorColors.darkCyan,
                  width: isActive ? 2 : 1,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: DeckDistributorColors.vermillion.withOpacity(_glowAnimation.value),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  if (_isHovered && !isCooldown)
                    BoxShadow(
                      color: starColor.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // 悬赏板背景（卷轴/羊皮纸质感）
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isCooldown
                                ? [
                                    Colors.grey.shade800,
                                    Colors.grey.shade900,
                                  ]
                                : [
                                    const Color(0xFFD4B896).withOpacity(0.3),
                                    const Color(0xFF6B4423).withOpacity(0.2),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 多张悬赏令叠放效果（可见3-4张边缘）
                  ...List.generate(3, (index) {
                    return Positioned(
                      top: 8.0 + index * 4,
                      left: 12.0 - index * 2,
                      right: 12.0 + index * 2,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCooldown
                              ? Colors.grey.shade700.withOpacity(0.5)
                              : Color.lerp(
                                  const Color(0xFFD4B896),
                                  const Color(0xFF6B4423),
                                  index * 0.3,
                                )?.withOpacity(0.4 - index * 0.1),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isCooldown
                                ? Colors.grey
                                : const Color(0xFF6B4423).withOpacity(0.5 - index * 0.1),
                            width: 0.5,
                          ),
                        ),
                      ),
                    );
                  }),

                  // 当前悬赏令（高亮）
                  Positioned(
                    top: 20,
                    left: 12,
                    right: 12,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 90,
                      decoration: BoxDecoration(
                        color: isCooldown
                            ? Colors.grey.shade600.withOpacity(0.6)
                            : const Color(0xFFD4B896).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive ? DeckDistributorColors.vermillion : const Color(0xFF6B4423),
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: DeckDistributorColors.vermillion.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 顶部标题
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isCooldown
                                  ? Colors.grey
                                  : DeckDistributorColors.vermillion,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                            child: const Text(
                              '悬 赏',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                          // 悬赏内容
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 星级难度
                                  Text(
                                    _buildStars(widget.starDifficulty),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: starColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // 任务名
                                  if (widget.questTitle != null)
                                    Text(
                                      widget.questTitle!,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isCooldown
                                            ? Colors.grey
                                            : const Color(0xFF3D2B1F),
                                      ),
                                    )
                                  else
                                    Text(
                                      isActive ? '可接任务' : '等待领取',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isCooldown
                                            ? Colors.grey
                                            : const Color(0xFF3D2B1F),
                                      ),
                                    ),
                                  // 奖励
                                  if (widget.questReward != null && !isCooldown)
                                    Text(
                                      '赏金：${widget.questReward}',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: DeckDistributorColors.gold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 红绳垂落
                  if (!isCooldown)
                    Positioned(
                      top: 0,
                      right: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 2,
                            height: 12,
                            color: DeckDistributorColors.vermillion,
                          ),
                          const Text('🔔', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),

                  // 新！角标
                  if (isActive)
                    Positioned(
                      top: 0,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: DeckDistributorColors.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          '新！',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                  // 冷却倒计时
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
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 铜铃（可交互时摇晃）
                  if (!isCooldown)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: isActive
                          ? AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, _) {
                                return Transform.rotate(
                                  angle: _glowAnimation.value * 0.1,
                                  child: const Text('🔔', style: TextStyle(fontSize: 14)),
                                );
                              },
                            )
                          : const Text('🔔', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
