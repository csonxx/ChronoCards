# MEMORY.md - 小阳 · UI设计师 永久记忆

## 身份
- **角色**: UI设计师（ui agent）
- **open_id**: ou_c95cca24fd29c5b66d4e335522cfb957

## 职责
- 根据产品方案完成UI设计稿
- 把设计稿交给嘴哥审查
- 有打回权：可打回 will（需求不合理）

## 主干流程
will（产品经理）→ 嘴哥（评论员）→ 小阳（UI设计师）→ 嘴哥（评论员）→ 彬仔(前端)+F哥(Flutter)+乃乃(Go后端) → qa → devops → 上线

## 打回路径
- 小阳 → 打回 will（需求不合理）
- 彬仔/F哥/乃乃 → 打回 小阳（设计无法实现）

## 项目看板（唯一真理源）
https://ocnghmk3m2ae.feishu.cn/base/TWW7baLT5aiuAjsF2OycGvmEnmf

## 团队成员 open_id
| 成员 | open_id |
|------|---------|
| will（产品经理）| ou_58e0f766716e7654cb042d57e3608c9e |
| 嘴哥（评论员）| ou_0aa7f7f44963ab8b87c21bf0084d20f1 |
| 小阳(UI) | ou_c95cca24fd29c5b66d4e335522cfb957（我自己）|
| 彬仔(前端) | ou_b80d1a91fc737a4775681deb4547995b |
| F哥(Flutter) | ou_5460ac5e6af4d1fa9fdd7ca026cf49f1 |
| 乃乃(Go后端) | ou_f0832172ca703528de3f4cba458dc0f9 |
| qa | ou_b7bb759847d94f1e8ec837a2742ccce0 |
| 阿健(代码检测) | ou_93282698f9d8a402b4d1f4f426880501 |
| devops | ou_d6b89e9490fd40f99d690682afd2c435 |
| Eva | ou_44dbd580763b4fb4010246344c2c18d5 |
| 无影手（内容策划总控）| 待确认（飞书bot刚配置）|

## AI World Game 项目（2026-04-10 启动）

### 核心愿景
- 事件卡组驱动、AI生成世界
- 每张卡都是世界碎片
- Pokemon像素风
- 目标：10万日活

### 原始产品文档（飞书）
https://ocnghmk3m2ae.feishu.cn/docx/R4xSdmohtoMgJxxXHSrcD7wWnpd

### 项目看板（唯一真理源）
https://ocnghmk3m2ae.feishu.cn/base/TWW7baLT5aiuAjsF2OycGvmEnmf

### 已完成的设计文档
- `/root/.openclaw/workspace-ui/docs/S5_战斗界面设计_ARPG_v2.md` - S5战斗界面v2.0（即时ARPG版）

## AI World Game 项目（2026-04-10 启动）

### 核心愿景
- 事件卡组驱动、AI生成世界
- 每张卡都是世界碎片
- Pokemon像素风 → 中国武侠古风（水墨风）
- 目标：10万日活

### 战斗系统更新（v1.5审核通过，2026-04-10）
- 回合制 → 即时ARPG（类原神）
- S5战斗界面重新设计，详见：`docs/S5_战斗界面设计_ARPG_v2.md`
- 新增：普攻三段连击、元素附着、体力/内力/剑意三资源、E/Q技能按钮、完美格挡/反击、六元素反应

### 与无影手的协作
- 无影手（agentId: nash）负责 ChronoCards 世界观/角色/事件内容设计
- 无影手产出 World Bible → 小阳接 UI 视觉设计
- **新流程**：无影手产出「角色美术描述卡」（外貌/服装/武器/配色规范）→ 小阳 Blender 建模 → 交付开发

### 美术资源生产计划（第一阶段）
- **风格**：水墨古风（唯一契合游戏世界观）
- **工具**：Blender 4.3.2 + MiniMax 概念图
- **阶段一资产**：主角x1、NPCx3-5、场景模块x6-8、动画三套
- **当前状态**：#001 粗模交付中，持续接卡产出

### #002-#004 #006 交付物（2026-04-11）
- #002 光明左使：`minimax-output/guangming_left_concept.png` + `光明左使_粗模.glb`
- #003 光明右使：`minimax-output/guangming_right_concept.png` + `光明右使_粗模.glb`
- #004 玩家化身：`minimax-output/玩家化身_粗模.glb`（空手/粗布/无标识，可自定义）
- #006 丐帮帮主：等待描述卡

### #005 空慧禅师 交付物
- `minimax-output/konghui_concept.png` - 角色立绘
- `minimax-output/空慧禅师_粗模.glb` - Blender 粗模 GLB
- `docs/charsheet_005_konghui.md` - 角色描述卡存档
- 与#001沈墨渊形成视觉对照：暗赭红+金边 vs 玄黑+深赭

### #001 沈墨渊 交付物
- `minimax-output/shenmoyan_concept.png` - 角色正背立绘
- `minimax-output/shenmoyan_side.png` - 侧面轮廓
- `minimax-output/沈墨渊_粗模.glb` - Blender 粗模 GLB（开发可用）
- `docs/charsheet_001_shenmoyan.md` - 角色描述卡存档
- `docs/blender_export_single.py` - Blender 导出脚本

### 待开始（阻塞皇上审批）
- 事件卡组方案审批
- 游戏链接重新部署
- GitHub Push权限修复

---

## 协作规则（2026-04-10 华仔确认）

### 找人方法
- 如果飞书bot找不到人（私信/群发没回应），用 sessions_spawn 强制激活对方 agent
- 格式：sessions_spawn(agentId="目标agent的id", task="具体任务内容", mode="run")

### 看板困难标记机制
- 如果遇到任何困难（找不到人/流程卡住/技术难题），在飞书看板新增一个视图标记
- Eva（ou_44dbd580763b4fb4010246344c2c18d5）会定时轮询看板，发现困难标记就主动去解决
