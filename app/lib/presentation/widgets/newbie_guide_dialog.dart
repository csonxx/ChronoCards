import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Newbie guide dialog - 5-step guide for new players in Suzhou City
/// 阿康 is the NPC guide: chatty card dealer, warm and helpful
class NewbieGuideDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const NewbieGuideDialog({
    super.key,
    required this.onComplete,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onComplete}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NewbieGuideDialog(onComplete: onComplete),
    );
  }

  @override
  State<NewbieGuideDialog> createState() => _NewbieGuideDialogState();
}

class _NewbieGuideDialogState extends State<NewbieGuideDialog> {
  int _currentPage = 0;

  // 阿康的5步新手引导
  // 每步对应一个场景，带NPC对话和高亮引导
  final List<GuidePage> _pages = [
    // ========== 步骤1：欢迎来到苏州城 ==========
    const GuidePage(
      step: 1,
      icon: Icons.location_city,
      title: '欢迎来到苏州城',
      dialogueLines: [
        '哟，新面孔！欢迎来到苏州城～',
        '我是阿康，这儿的发牌员。以后你在这儿\n的每一张牌，都得从我手里过。',
        '看到屏幕下方的【事件卡】按钮了吗？\n点一下，我们开始说正事！',
      ],
      highlightWidget: 'event_card_button',
      highlightHint: '点击【事件卡】按钮',
      highlightColor: AppTheme.accentGold,
      npcMood: NpcMood.friendly,
    ),

    // ========== 步骤2：抽取第一张事件卡 ==========
    const GuidePage(
      step: 2,
      icon: Icons.style,
      title: '抽取你的第一张事件卡',
      dialogueLines: [
        '好嘞！每张卡都是世界的碎片——\n战斗、宝藏、奇遇，都装在这些牌里。',
        '你准备好看看命运给你安排了啥没？',
        '点击抽卡，看看第一张牌\n会带你去哪里！',
      ],
      highlightWidget: 'draw_card_button',
      highlightHint: '点击【抽卡】',
      highlightColor: Color(0xFF6C5CE7),
      npcMood: NpcMood.excited,
    ),

    // ========== 步骤3：触发事件 ==========
    const GuidePage(
      step: 3,
      icon: Icons.flash_on,
      title: '事件已触发！',
      dialogueLines: [
        '哦豁！这是张【战斗卡】！\n前方有江湖人士拦路～',
        '别慌，赢了有奖励，输了也不亏，\n咱们苏州城讲究的是来回。',
        '点击【前往挑战】，迎上去吧！',
      ],
      highlightWidget: 'challenge_button',
      highlightHint: '点击【前往挑战】',
      highlightColor: AppTheme.healthRed,
      npcMood: NpcMood.surprised,
    ),

    // ========== 步骤4：完成战斗 ==========
    const GuidePage(
      step: 4,
      icon: Icons.sports_kabaddi,
      title: '战斗教学',
      dialogueLines: [
        '左下角遥感控制走位，',
        '看到敌人点一下就是攻击！',
        '别贪刀，闪躲也重要～\n去吧，赢了这波！',
      ],
      highlightWidget: 'virtual_joystick',
      highlightHint: '左：遥感移动  右：点击攻击',
      highlightColor: Colors.orange,
      npcMood: NpcMood.encouraging,
    ),

    // ========== 步骤5：探索更多 ==========
    const GuidePage(
      step: 5,
      icon: Icons.explore,
      title: '探索更多',
      dialogueLines: [
        '苏州城不只有一条路。\n地图上还有很多节点，藏着各种事件和奖励。',
        '对了，你现在加入了【江湖势力】。\n声望越高，你在江湖里的地位就越稳！',
        '好了，阿康话已说完——\n去闯荡吧，少侠！有事随时回来找我！',
      ],
      highlightWidget: 'map_explore',
      highlightHint: '自由探索苏州城',
      highlightColor: Colors.teal,
      npcMood: NpcMood.proud,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: page.highlightColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: page.highlightColor.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NPC badge + progress dots
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
              child: Row(
                children: [
                  // 阿康 badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: page.highlightColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: page.highlightColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _npcMoodEmoji(page.npcMood),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '阿康',
                          style: TextStyle(
                            color: page.highlightColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Step indicator
                  Text(
                    '${_currentPage + 1} / ${_pages.length}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _pages.length,
                  backgroundColor: AppTheme.cardBorder,
                  valueColor: AlwaysStoppedAnimation(page.highlightColor),
                  minHeight: 4,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Icon with glow
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          page.highlightColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(
                      page.icon,
                      size: 56,
                      color: page.highlightColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    page.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Dialogue lines (阿康's speech)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: page.highlightColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: page.dialogueLines.map((line) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Highlight hint (what to do)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: page.highlightColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: page.highlightColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            page.highlightHint,
                            style: TextStyle(
                              color: page.highlightColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // Skip button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '跳过',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),

                  const Spacer(),

                  // Prev button (if not first)
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: () {
                        setState(() => _currentPage--);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        setState(() => _currentPage++);
                      } else {
                        Navigator.pop(context);
                        widget.onComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: page.highlightColor,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage < _pages.length - 1
                              ? '下一步'
                              : '开始冒险！',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (_currentPage < _pages.length - 1) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _npcMoodEmoji(NpcMood mood) {
    switch (mood) {
      case NpcMood.friendly:
        return '😊';
      case NpcMood.excited:
        return '🤩';
      case NpcMood.surprised:
        return '😮';
      case NpcMood.encouraging:
        return '💪';
      case NpcMood.proud:
        return '😎';
      case NpcMood.worried:
        return '😟';
      case NpcMood.celebrating:
        return '🎉';
    }
  }
}

/// NPC情绪状态（影响阿康的表情emoji）
enum NpcMood {
  friendly,     // 友好欢迎
  excited,      // 兴奋期待
  surprised,    // 惊讶
  encouraging,  // 鼓励
  proud,        // 自豪
  worried,      // 担忧
  celebrating,  // 庆祝
}

/// 单页引导数据模型
class GuidePage {
  final int step;
  final IconData icon;
  final String title;
  final List<String> dialogueLines;
  final String highlightWidget;
  final String highlightHint;
  final Color highlightColor;
  final NpcMood npcMood;

  const GuidePage({
    required this.step,
    required this.icon,
    required this.title,
    required this.dialogueLines,
    required this.highlightWidget,
    required this.highlightHint,
    required this.highlightColor,
    required this.npcMood,
  });
}
