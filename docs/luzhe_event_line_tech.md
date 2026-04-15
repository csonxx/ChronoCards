# #006 陆喆角色主导卡事件线 · 技术实现方案

> 文档版本：v1.0
> 撰写日期：2026-04-14
> 状态：✅ 方案初稿，待评审
> 负责人：乃乃/彬仔（子agent）

---

## 一、概述

### 1.1 目标

将 #006 陆喆（丐帮帮主）角色主导卡事件线接入现有 ChronoCards 叙事系统。玩家首次进入丐帮相关场景时触发完整事件线：考验玩家 → 揭示身世 → 丐帮内乱 → 结局分支。

### 1.2 现有系统对接点

| 现有模块 | 对接方式 |
|---------|---------|
| `model/deck.go` | 新增 `CardType = CardCharacterLuzhe`，注册为"角色主导卡"类型 |
| `game/narrative/service.go` | 新增 `TriggerCharacterEvent`，接收角色事件上下文 |
| `game/deck/service.go` | 新增 `TriggerCharacterEvent()` 方法，按角色状态机推进 |
| `game/world/service.go` | 在 `ProcessNavigation` / `GetPlayerLocation` 中埋入触发检查 |
| `ws/messages.go` | 新增 `EventCharacterCardTrigger` 推送类型 |

---

## 二、卡牌设计

### 2.1 新增卡牌类型

```go
// model/deck.go

const (
    CardMainStory   CardType = "main_story"
    CardSideStory   CardType = "side_story"
    CardSkillUnlock CardType = "skill_unlock"
    CardStatUp      CardType = "stat_up"
    CardEmotion     CardType = "emotion"
    CardEconomy     CardType = "economy"
    CardBlank       CardType = "blank"
    CardCharacter   CardType = "character"  // ⬅️ 新增：角色主导卡（父类型）
)

// LuzheCardType 陆喆专属卡牌子类型
type LuzheCardType string

const (
    LuzheEncounter   LuzheCardType = "luzhe_encounter"    // 首次遭遇
    LuzheTrial       LuzheCardType = "luzhe_trial"        // 考验玩家
    LuzheBackground  LuzheCardType = "luzhe_background"   // 揭示身世
    LuzheUprising    LuzheCardType = "luzhe_uprising"     // 丐帮内乱
    LuzheResolution  LuzheCardType = "luzhe_resolution"   // 结局分支
)
```

### 2.2 陆喆专属卡组注册

```go
// 初期码（待落地后迁移至数据库）
var LuzheCharacterCards = []*Card{
    {
        ID:          "char-luzhe-001",
        Type:        CardCharacter,
        SubType:     LuzheEncounter,
        Title:       "丐帮九袋",
        Description: "江南水乡，平阳客栈外，一个衣衫褴褛的老者正靠在墙角，看似随意，眼神却扫过每一个路过之人。",
        TriggerConditions: []string{
            "location:loc-suzhou",          // 苏州城（丐帮据点）
            "location:loc-inn-anchor",      // 或平阳客栈
            "faction:gaibang_npc_interact", // 或与丐帮NPC交互
            "first_visit:region-jiangnan", // 首次进入江南水乡
        },
        AIPromptHints: []string{"陆喆", "丐帮", "九袋帮主", "草根正义"},
        Priority: 10,
        Rewards: &CardRewards{
            Reputation: &Reputation{
                Zhengpai: 5, // 正派声望小幅提升
            },
        },
    },
    {
        ID:          "char-luzhe-002",
        Type:        CardCharacter,
        SubType:     LuzheTrial,
        Title:       "江湖试炼",
        Description: "陆喆提出三个江湖考验：义气、勇气、智谋。玩家必须通过至少两项才能获得丐帮认可。",
        TriggerConditions: []string{
            "state:luzhe_trial_available",
            "triggered_by:char-luzhe-001",
        },
        AIPromptHints: []string{"陆喆", "考验", "江湖道义", "丐帮入门"},
        Priority: 9,
        Rewards: &CardRewards{
            Exp: 100,
        },
    },
    {
        ID:          "char-luzhe-003",
        Type:        CardCharacter,
        SubType:     LuzheBackground,
        Title:       "身世之谜",
        Description: "通过考验后，陆喆私下透露：你父亲当年与丐帮有一段渊源……此事牵涉三十年前一桩旧案。",
        TriggerConditions: []string{
            "state:luzhe_trial_passed",
            "triggered_by:char-luzhe-002",
        },
        AIPromptHints: []string{"陆喆", "镖局", "父亲", "三十年前", "身世"},
        Priority: 8,
        Rewards: &CardRewards{
            Exp:        200,
            Reputation: &Reputation{Zhengpai: 10},
            // 触发主线"镖局旧案"前置flag
        },
    },
    {
        ID:          "char-luzhe-004",
        Type:        CardCharacter,
        SubType:     LuzheUprising,
        Title:       "丐帮内乱",
        Description: "丐帮内部两派分裂：保守派欲与明教暗中交易，激进派则要正面对抗。陆喆被架空，玩家必须选边站。",
        TriggerConditions: []string{
            "state:luzhe_trust_high",
            "main_story_progress:>=30%",
        },
        AIPromptHints: []string{"丐帮内乱", "明教渗透", "帮派分裂", "陆喆危机"},
        Priority: 7,
        Rewards: &CardRewards{
            Reputation: &Reputation{Zhengpai: -5}, // 选边站有代价
        },
    },
    {
        ID:          "char-luzhe-005a",
        Type:        CardCharacter,
        SubType:     LuzheResolution,
        Title:       "正道结局：丐帮团结",
        Description: "玩家协助陆喆稳住帮主之位，丐帮成为正派联盟核心，明教势力被压制。",
        TriggerConditions: []string{
            "state:luzhe_uprising_resolved",
            "choice:support_luzhe",
        },
        AIPromptHints: []string{"正道结局", "丐帮团结", "陆喆胜利"},
        Rewards: &CardRewards{
            Reputation: &Reputation{Zhengpai: 50},
            SkillID:    "skill-luzhe-stick", // 解锁打狗棒法
        },
    },
    {
        ID:          "char-luzhe-005b",
        Type:        CardCharacter,
        SubType:     LuzheResolution,
        Title:       "暗流结局：丐帮分裂",
        Description: "帮内分裂不可挽回，丐帮元气大伤，陆喆远遁江湖。玩家独木难支，正派联盟摇摇欲坠。",
        TriggerConditions: []string{
            "state:luzhe_uprising_resolved",
            "choice:abandon_luzhe",
        },
        AIPromptHints: []string{"悲剧结局", "丐帮分裂", "陆喆远遁"},
        Rewards: &CardRewards{
            Reputation: &Reputation{Zhengpai: -20, Mingjiao: 10},
        },
    },
}
```

---

## 三、事件状态机

### 3.1 状态定义

```go
// game/deck/luzhe_state.go（新建）

package deck

// LuzheEventState 陆喆事件线状态
type LuzheEventState string

const (
    LuzheStateNotStarted  LuzheEventState = "not_started"
    LuzheStateEncountered LuzheEventState = "encountered"   // 首次遭遇
    LuzheStateTrial       LuzheEventState = "trial"         // 考验中
    LuzheStateTrialPassed LuzheEventState = "trial_passed"  // 考验通过
    LuzheStateTrialFailed LuzheEventState = "trial_failed"  // 考验失败（可重试）
    LuzheStateBackground  LuzheEventState = "background"    // 身世揭示
    LuzheStateUprising    LuzheEventState = "uprising"      // 内乱触发
    LuzheStateResolved    LuzheEventState = "resolved"      // 结局分支完成
)

// LuzhePlayerState 玩家在陆喆事件线中的状态
type LuzhePlayerState struct {
    PlayerID    string             `json:"player_id"`
    State       LuzheEventState    `json:"state"`
    TrustLevel  int                `json:"trust_level"`  // 0-100，信任值
    TrialScores *LuzheTrialScores  `json:"trial_scores"`
    Choices     []string           `json:"choices"`       // 记录关键选择
    CardHistory []string           `json:"card_history"`  // 已触发卡ID序列
    UpdatedAt   string             `json:"updated_at"`
}

// LuzheTrialScores 三项考验得分
type LuzheTrialScores struct {
    YiQi  int `json:"yiqi"`  // 义气
    YongQi int `json:"yongqi"` // 勇气
    ZhiHui int `json:"zhihui"` // 智谋
}
```

### 3.2 状态流转图

```
[not_started]
    │ 触发条件：首次进入苏州城 / 丐帮NPC交互 / 江南水乡首次到访
    ▼
[encountered] ──── 事件：char-luzhe-001 ──── 奖励：正派声望+5
    │ 状态更新：TrustLevel += 10
    ▼
[trial] ──────── 事件：char-luzhe-002 ──── 三项考验（义气/勇气/智谋）
    │ 玩家选择 → 评分
    ├─ 通过（≥2项合格）→ [trial_passed]
    └─ 失败            → [trial_failed]（可重试，最多3次）
           │ 失败重试 → 回到 [trial]
           │ 放弃     → [not_started]（降级为普通NPC交互）
    ▼
[trial_passed] ─── 事件：char-luzhe-003 ─── 揭示身世
    │ 奖励：Exp+200，正派声望+10
    │ 触发：镖局旧案主线flag
    │ 状态更新：TrustLevel += 30
    ▼
[background] ──── 等待：main_story_progress >= 30%
    │
    ▼
[uprising] ────── 事件：char-luzhe-004 ─── 丐帮内乱
    │ 玩家必须选边：support_luzhe / abandon_luzhe / negotiate
    │
    ├─ choice:support_luzhe  → [resolved] + 结局a
    ├─ choice:abandon_luzhe  → [resolved] + 结局b
    └─ choice:negotiate      → [resolved] + 隐藏结局c（需TrustLevel≥80）
```

### 3.3 信任值（TrustLevel）机制

| TrustLevel 区间 | 解锁选项 | 影响 |
|----------------|---------|------|
| 0-29 | 仅基础对话 | 普通互动 |
| 30-59 | 可参与考验 | 考验解锁 |
| 60-79 | 知晓身世细节 | 背景揭示完整度 |
| 80-100 | 协商选项 | 隐藏结局c |

---

## 四、触发条件设计

### 4.1 首次触发（一次性）

玩家首次进入以下任一条件时，触发 `char-luzhe-001`：

```go
// game/deck/luzhe_trigger.go（新建）

func ShouldTriggerLuzheEncounter(playerLoc *model.PlayerLocation) (bool, string) {
    // 条件1：首次进入江南水乡大区（苏州城）
    if slices.Contains(playerLoc.VisitedRegions, "region-jiangnan") &&
       !slices.Contains(playerLoc.VisitedLocations, "loc-suzhou") {
        return true, "first_jiangnan_entry"
    }

    // 条件2：平阳客栈内与丐帮弟子NPC交互（由NPC交互事件触发）
    // 由外部调用方传入触发信号

    // 条件3：主线进度>=5%时，丐帮弟子主动联络（概率触发）
    // 由 deck/service.go 的抽牌逻辑在特定时机检查

    return false, ""
}
```

### 4.2 后续触发检查（每次抽牌/导航时）

```go
// 在 deck/service.go 的 Trigger() 或 TriggerWithWeight() 中
// 每次抽牌前检查是否应插入角色主导卡

func (s *Service) ShouldInsertCharacterCard(
    playerState *LuzhePlayerState,
    deck *model.Deck,
) (bool, *Card) {
    // 如果事件线已完成，不插入
    if playerState.State == LuzheStateResolved {
        return false, nil
    }

    // 检查当前状态对应的待触发卡
    nextCard := s.getNextLuzheCard(playerState)
    if nextCard == nil {
        return false, nil
    }

    // 验证触发条件是否满足
    if !s.checkTriggerConditions(nextCard, playerState) {
        return false, nil
    }

    return true, nextCard
}
```

### 4.3 触发条件注册表

| 卡ID | 触发条件 | 检查时机 |
|------|---------|---------|
| char-luzhe-001 | `first_jiangnan_entry` ∨ `gaibang_npc_first_talk` | `location_enter` / `npc_interact` |
| char-luzhe-002 | `state:encountered` | `card_drawn` (自动) |
| char-luzhe-003 | `state:trial_passed` | `card_drawn` (自动) |
| char-luzhe-004 | `state:background` AND `main_progress >= 30%` | `card_drawn` (自动) |
| char-luzhe-005a/b/c | `state:uprising` AND `player_choice` | `choice_made` |

---

## 五、与 WorldMap 的集成

### 5.1 位置数据扩展

`model/player_location.go` 新增字段：

```go
type PlayerLocation struct {
    // ... 现有字段 ...

    // 新增：角色事件线状态
    LuzheState *LuzhePlayerState `json:"luzhe_state,omitempty"`

    // 新增：各角色信任值（通用结构，方便扩展其他角色）
    CharacterTrust map[string]int `json:"character_trust"` // characterID -> trustLevel
}
```

### 5.2 导航时的触发检查

```go
// game/world/service.go — ProcessNavigation()

func (s *Service) ProcessNavigation(playerID, targetLocationID string) *NavigateResult {
    // ... 现有逻辑 ...

    // ⬇️ 新增：检查陆喆事件触发
    luzheState := s.getLuzheState(playerID)
    if luzheState != nil {
        trigger, card := s.deckService.ShouldInsertCharacterCard(luzheState, deck)
        if trigger {
            // 导航到达后立即触发角色主导卡
            // 将 card 注入 pendingEvents，由 WS 推送
            result.PendingEvents = append(result.PendingEvents, s.buildCharacterCardEvent(card))
        }
    }

    return result
}
```

### 5.3 苏州城（丐帮江南据点）添加到地图

```go
// game/world/init_data.go — 新增场景

{ID: "loc-suzhou", Name: "苏州城", RegionID: "region-jiangnan",
    LocationType: "city", LocationTypeExt: "faction_headquarters",
    Description: "江南水乡，河道纵横。丐帮江南分舵在此扎根，陆喆偶尔现身。",
    Atmosphere: "烟雨江南，暗流涌动", DangerLevel: 2, NPCCount: 50,
    AvailableDealers: []string{"teahouse", "bounty_board", "gaibang_informant"},
    FactionControlling: "gaibang",  // 丐帮控制
    AvailableDealers: []string{"teahouse", "gaibang_informant", "inn"},
    StoryChapters: []string{"ch1", "ch2"},
    Unlocked: true, SceneBG: "/assets/scenes/suzhou_city.webp", MusicTrack: "suzhou_ambient"},
```

---

## 六、WebSocket 推送联动

### 6.1 新增推送事件类型

```go
// ws/messages.go

// EventCharacterCardTrigger 角色主导卡触发（服务器主动推送）
const EventCharacterCardTrigger EventType = "event_character_card_trigger"

// EventCharacterCardTriggerData 角色主导卡推送数据
type EventCharacterCardTriggerData struct {
    PlayerID       string               `json:"player_id"`
    CharacterID   string               `json:"character_id"`   // "luzhe"
    CharacterName string               `json:"character_name"` // "陆喆"
    CardID        string               `json:"card_id"`
    CardTitle     string               `json:"card_title"`
    State         string               `json:"state"`
    TrustLevel    int                  `json:"trust_level"`
    Narrative     *NarrativeContent   `json:"narrative"`      // AI生成叙事
    Choices       []Choice             `json:"choices"`       // 玩家选项
    ChoicesPrompt string               `json:"choices_prompt"` // 玩家选项描述
}
```

### 6.2 Hub 推送方法

```go
// ws/hub.go — 新增方法

// PushCharacterCardEvent 向指定玩家推送角色主导卡事件
func (h *Hub) PushCharacterCardEvent(playerID string, data *EventCharacterCardTriggerData) {
    msg := BaseMessage{
        Type:      TypeEvent,
        Event:     EventCharacterCardTrigger,
        Seq:       h.NextSeq(),
        Timestamp: NowISO(),
        Data:      data,
    }
    h.broadcastToPlayer(playerID, MustMarshal(msg))
}
```

### 6.3 推送时序

```
1. 玩家进入苏州城 / 与丐帮NPC交互
        ↓
2. WorldService.ProcessNavigation() → 检测到触发条件
        ↓
3. 调用 DeckService.ShouldInsertCharacterCard() → 获取下一张卡
        ↓
4. 调用 NarrativeService.Generate() → AI生成叙事内容
        ↓
5. Hub.PushCharacterCardEvent() → WS 推送给玩家
        ↓
6. 前端收到 event_character_card_trigger → 展示角色对话框+选项
        ↓
7. 玩家选择 → client 发送 choice_made 请求
        ↓
8. 服务器更新 LuzhePlayerState → 状态机推进
        ↓
9. 循环到步骤3（下一张卡）
```

---

## 七、AI 叙事集成

### 7.1 Prompt 上下文构建

```go
// game/narrative/service.go — 新增方法

func (s *Service) GenerateCharacterNarrative(
    req *TriggerRequest,
    luzheState *LuzhePlayerState,
) (*NarrativeContent, error) {
    req.TriggerType = TriggerCharacterEvent
    req.CardType = string(CardCharacter)
    req.CharacterID = "luzhe"

    // 构建陆喆专属上下文
    req.Context = NarrativeContext{
        WorldState:        s.getWorldState(),
        FactionRelations:  s.getFactionRelations(),
        RecentEvents:      luzheState.GetRecentEvents(),
        PlayerBackground:  s.getPlayerBackground(req.PlayerID),
        Tone:              s.getLuzheTone(luzheState.State),
        CharacterSpecific: map[string]interface{}{
            "character_name": "陆喆",
            "trust_level":    luzheState.TrustLevel,
            "event_state":    luzheState.State,
            "trial_scores":   luzheState.TrialScores,
        },
    }

    req.Constraints = NarrativeConstraints{
        MaxLength:        400,
        DialogueRequired: true,
        NPCName:          "陆喆",
    }

    return s.Generate(req)
}
```

### 7.2 陆喆专属 System Prompt 片段

```go
const luzheSystemPrompt = `
你正在为 ChronoCards 游戏生成陆喆（丐帮帮主）角色主导事件的叙事内容。

【陆喆角色设定】
- 身份：丐帮九袋帮主，约五十岁，正派精神领袖
- 性格：不拘小节，豪爽直接，带江湖草根气息
- 说话风格：不说"本座"，而说"咱们丐帮"、"老子"、"咱"；动辄引用江湖俗语
- 外形：瘦长脸，花白眉短须，左眉眉尾旧疤，左手小指缺一截；百衲衣（土黄+暗青），翠绿打狗棒，紫漆葫芦
- 关键台词示例：
  * "江湖？这江湖是有权有势的人的棋盘，咱们叫花子不过是几颗棋子——但有时候，棋子也能把棋盘掀了。"
  * "别叫我帮主，叫我老陆就行。"

【当前事件状态】
- 事件状态：{{.EventState}}
- 玩家信任值：{{.TrustLevel}}/100
- 玩家已做选择：{{.PlayerChoices}}

请根据以上信息生成符合陆喆性格的叙事内容，包含对话和选项。
`
```

---

## 八、数据库模型

### 8.1 新增表（PostgreSQL）

```sql
-- 角色主导卡注册表
CREATE TABLE character_cards (
    id          VARCHAR(64) PRIMARY KEY,
    character_id VARCHAR(32) NOT NULL,      -- 'luzhe', 'shenmoyan', ...
    sub_type    VARCHAR(32) NOT NULL,      -- luzhe_encounter, luzhe_trial, ...
    title       VARCHAR(128) NOT NULL,
    description TEXT,
    trigger_conditions JSONB,              -- 触发条件数组
    rewards     JSONB,                      -- 奖励结构
    ai_prompt_hints TEXT[],
    priority    INT DEFAULT 5,
    created_at  TIMESTAMP DEFAULT NOW(),
    updated_at  TIMESTAMP DEFAULT NOW()
);

-- 玩家角色事件状态表
CREATE TABLE player_character_states (
    player_id   VARCHAR(64) NOT NULL,
    character_id VARCHAR(32) NOT NULL,
    state       VARCHAR(32) NOT NULL,
    trust_level INT DEFAULT 0,
    trial_scores JSONB,                      -- LuzheTrialScores
    choices     TEXT[],                     -- 关键选择记录
    card_history TEXT[],                    -- 已触发卡ID
    updated_at  TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (player_id, character_id)
);

-- 索引
CREATE INDEX idx_character_cards_char ON character_cards(character_id);
CREATE INDEX idx_player_char_state ON player_character_states(player_id, character_id);
```

---

## 九、实现计划

### 9.1 第一阶段：基础设施（约1天）

| 任务 | 文件 | 负责人 |
|------|------|-------|
| 新增 `CardType = CardCharacter` | `model/deck.go` | 后端 |
| 新增 `LuzheCardType` 及常量 | `model/deck.go` | 后端 |
| 新增 `LuzheEventState` / `LuzhePlayerState` | `game/deck/luzhe_state.go` (新建) | 后端 |
| 新增 DB 表 SQL 迁移脚本 | `migrations/004_character_cards.sql` (新建) | 后端 |

### 9.2 第二阶段：核心逻辑（约1天）

| 任务 | 文件 | 负责人 |
|------|------|-------|
| 触发条件检查逻辑 | `game/deck/luzhe_trigger.go` (新建) | 后端 |
| 状态机推进逻辑 | `game/deck/luzhe_state_machine.go` (新建) | 后端 |
| 导航时触发集成 | `game/world/service.go` | 后端 |
| WS 推送方法 | `ws/hub.go` | 后端 |
| 新增 WS 消息类型 | `ws/messages.go` | 后端 |

### 9.3 第三阶段：AI 叙事集成（约0.5天）

| 任务 | 文件 | 负责人 |
|------|------|-------|
| `GenerateCharacterNarrative()` | `game/narrative/service.go` | 后端 |
| 陆喆专属 Prompt 模板 | `game/narrative/luzhe_prompts.go` (新建) | 后端 |
| 前端角色卡对话框组件 | `web/src/components/CharacterCardDialog.tsx` | 前端 |

### 9.4 第四阶段：测试与联调（约0.5天）

| 任务 | 说明 |
|------|------|
| 单元测试 | `game/deck/luzhe_*_test.go` |
| WS 联调 | 验证推送时序 |
| 前端 UI 验收 | 确认对话框、选项、奖励展示正确 |
| 状态机完整流程 | 从 not_started → resolved 全链路跑通 |

---

## 十、待确认事项

| 序号 | 决策项 | 状态 |
|------|--------|------|
| 1 | 苏州城（loc-suzhou）是否需要添加到 `init_data.go`？目前 MVP 只有中原武林 | 🟡 待确认 |
| 2 | 考验（trial）三项的具体实现方式：纯对话选择 or 需要小游戏？ | 🟡 待确认 |
| 3 | 信任值 TrustLevel 初始值是多少（0 还是 10）？ | 🟡 待确认 |
| 4 | 结局c（协商）是否需要额外前置条件？ | 🟡 待确认 |
| 5 | 陆喆是否需要区分"首次遭遇"和"非首次遭遇"的对话内容？ | 🟡 待确认 |

---

## 附录：文件变更清单

```
server/
├── internal/
│   ├── model/
│   │   └── deck.go           [修改] 新增 CardCharacter 类型 + LuzheCardType
│   └── game/
│       ├── deck/
│       │   ├── service.go    [修改] 新增 ShouldInsertCharacterCard()
│       │   ├── luzhe_state.go          [新建] 状态定义
│       │   ├── luzhe_trigger.go        [新建] 触发条件检查
│       │   └── luzhe_state_machine.go  [新建] 状态机推进
│       ├── narrative/
│       │   ├── service.go     [修改] 新增 GenerateCharacterNarrative()
│       │   └── luzhe_prompts.go        [新建] 陆喆专属prompts
│       └── world/
│           └── service.go     [修改] ProcessNavigation 集成触发检查
└── ws/
    ├── hub.go                 [修改] 新增 PushCharacterCardEvent()
    └── messages.go            [修改] 新增 EventCharacterCardTrigger 及 Data 结构

migrations/
└── 004_character_cards.sql    [新建] 表结构迁移

docs/
└── luzhe_event_line_tech.md   [新建] 本文档
```
