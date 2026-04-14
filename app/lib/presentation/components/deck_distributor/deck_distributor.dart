// Deck Distributor Components - 5种发牌员UI组件
//
// 设计规范来源：mvp_ui_roadmap.md
//
// 组件列表：
// 1. TeaHouseNPCWidget    - 茶馆NPC发牌员（主线推进卡/角色主导卡）
// 2. QuestBoardWidget      - 悬赏板发牌员（支线探索卡/宝藏卡）
// 3. EnemyEncounterWidget  - 敌人遭遇发牌员（战斗卡/角色主导卡）
// 4. InnWidget             - 客栈发牌员（空白卡/角色主导卡）
// 5. MerchantWidget         - 商贩发牌员（成长学习卡/宝藏卡）
//
// 通用规范：
// - 状态系统：空闲/激活/冷却
// - Char006同款对话气泡（缺角土黄宣纸风）
// - 复用Char006Avatar的情绪色调

export 'deck_distributor_colors.dart';
export 'deck_distributor_bubble.dart';
export 'tea_house_npc_widget.dart';
export 'quest_board_widget.dart';
export 'enemy_encounter_widget.dart';
export 'inn_widget.dart';
export 'merchant_widget.dart';
