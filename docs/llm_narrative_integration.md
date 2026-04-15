# LLM 叙事接入方案 — ChronoCards

> **负责人：** 乃乃/彬仔  
> **版本：** v1.0  
> **日期：** 2026-04-14  
> **状态：** 设计中

---

## 1. 背景与目标

### 1.1 MVP 叙事需求

| 场景 | 输入 | LLM 输出 |
|------|------|---------|
| 抽卡叙事 | 玩家抽到某张卡 | AI 生成氛围描写 + NPC 对话（`event_narrative`） |
| NPC 台词 | 触发 NPC 交互事件 | NPC 风格化对话 + 旁白 |
| 事件描述 | 遭遇战、随机事件触发 | 第一/第三人称事件叙事文字 |

### 1.2 现有架构

- **WebSocket 后端**：`server/ws/hub.go` — `Hub.PushNarrativeEvent()` 已实现
- **WebSocket 协议**：`event_narrative` 事件类型已定义（`EventNarrativeData`）
- **LLM 提供商**：MiniMax（`sk-cp-` 格式 Key，`https://api.minimaxi.com` 端点）

---

## 2. LLM API 调用设计

### 2.1 API 基本信息

| 项目 | 值 |
|------|---|
| API Host | `https://api.minimaxi.com` |
| 聊天端点 | `POST /v1/text/chatcompletion_v2` |
| 模型 | `MiniMax-Text-01`（推荐）/ `abab7-chat`（备选） |
| API Key 来源 | 环境变量 `MINIMAX_API_KEY` |
| 超时时间 | 10 秒（含连接） |
| 重试策略 | 最多 2 次，指数退避 500ms / 1000ms |

### 2.2 请求格式（MiniMax Chat V2）

```go
type ChatRequest struct {
    Model      string            `json:"model"`
    Messages   []ChatMessage     `json:"messages"`
    Temperature float64           `json:"temperature,omitempty"`
    MaxTokens  int               `json:"max_tokens,omitempty"`
}

type ChatMessage struct {
    Role    string `json:"role"`    // system / user / assistant
    Content string `json:"content"`
}
```

**请求头：**
```
Authorization: Bearer {MINIMAX_API_KEY}
Content-Type: application/json
```

### 2.3 模型选择策略

| 场景 | 推荐模型 | 理由 |
|------|---------|------|
| 抽卡叙事 | `MiniMax-Text-01` | 长上下文，叙事连贯性强 |
| NPC 台词 | `MiniMax-Text-01` | 多轮对话保持人设一致 |
| 事件描述 | `MiniMax-Text-01` | 短文本，`abab7-chat` 可作为低价替代 |

> **注意：** MiniMax 计费按 token 数，Text-01 成本高于 abab 系列。MVP 阶段全用 `abab7-chat` 可控成本。

---

## 3. 服务端架构

### 3.1 模块划分

```
server/
├── ws/
│   ├── hub.go           # 已有：PushNarrativeEvent()
│   └── handler.go       # 已有：handleCardDraw() 等
└── narrative/                    # 新增目录
    ├── llm_client.go             # MiniMax API 调用封装
    ├── service.go                 # 叙事服务（路由、生成、推送）
    ├── cache.go                   # 缓存层（nil / Redis）
    ├── fallback.go                # 降级策略
    └── prompts/
        ├── card_draw.go           # 抽卡叙事 Prompt 模板
        ├── npc_dialogue.go        # NPC 台词 Prompt 模板
        └── event_desc.go          # 事件描述 Prompt 模板
```

### 3.2 数据流

```
客户端抽卡请求 (card_draw)
    │
    ▼
handleCardDraw() 接收请求
    │
    ├─ 业务逻辑抽牌（现有）
    │
    ▼
narrativeService.GenerateCardDrawNarrative(ctx, cardInfo, playerContext)
    │
    ├─ ① 查缓存 cache.Get(cardID + seed) ──hit──▶ 直接返回
    │
    ├─ ② 缓存 miss ──▶ 构建 Prompt ──▶ llmClient.Chat()
    │
    │       ├─ 成功 ──▶ cache.Set() ──▶ 构造 EventNarrativeData
    │       │
    │       └─ LLM 失败 ──▶ fallback.Fill(cardType) ──▶ 构造 EventNarrativeData
    │
    ▼
hub.PushNarrativeEvent(playerID, data)  ──WebSocket──▶ 客户端
```

### 3.3 核心接口

```go
// service.go
type NarrativeService interface {
    // 抽卡叙事生成
    GenerateCardDrawNarrative(ctx context.Context, req CardDrawNarrativeReq) (*EventNarrativeData, error)

    // NPC 台词生成
    GenerateNPCDialogue(ctx context.Context, req NPCDialogueReq) (*EventNarrativeData, error)

    // 事件描述生成
    GenerateEventDescription(ctx context.Context, req EventDescReq) (*EventNarrativeData, error)
}

type CardDrawNarrativeReq struct {
    PlayerID   string
    CardInfo   CardInfo       // 来自抽牌结果
    DealerID   string
    DealerName string
    Location   string
    DrawCount  int            // 本次抽了几张
}

type NPCDialogueReq struct {
    PlayerID  string
    NPCID     string
    NPCName   string
    Scene     string         // 场景描述
    Emotion   string         // 当前情绪基调
}

type EventDescReq struct {
    PlayerID       string
    EventType      string    // "encounter" | "random_event" | "level_up"
    LocationName   string
    EnemyName      string
}
```

---

## 4. Prompt 模板设计

### 4.1 抽卡叙事模板

**核心原则：** 根据卡牌类型（`attack` / `defense` / `skill` / `event`）生成不同文学风格的叙事。

```go
func CardDrawPrompt(card CardInfo, player PlayerContext) string {
    styleHints := map[string]string{
        "attack": "豪迈激昂，江湖快意，刀光剑影，字里行间透着杀气",
        "defense": "沉稳内敛，以静制动，旁白如古卷徐徐展开",
        "skill":  "神秘悠远，道法自然，带有一丝禅意和仙气",
        "event":  "跌宕起伏，命数轮回，带有因果宿命的厚重感",
    }
    style := styleHints[card.Type]
    if style == "" {
        style = "叙事沉稳，画面感强"
    }

    return fmt.Sprintf(`你是 ChronoCards 武侠叙事引擎。
当前场景：%s，说书人「%s」正在发牌。
玩家「%s」抽到了：

【%s】%s
类型：%s | 元素：%s | 伤害：%.0f | 消耗：%d MP
效果：%s

请生成一段 %s 风格的抽卡叙事，包含：

1. **氛围描写**（30-60字）：渲染抽牌瞬间的视觉效果和情绪
2. **说书人旁白**（可选，20-40字）：说书人风格的口吻，带有评书韵味
3. **卡牌故事**（50-100字）：这张卡背后的江湖往事或武学渊源

输出格式（JSON，不要包含任何 markdown 标记）：
{
  "atmosphere": "氛围描写",
  "dialogue": "说书人旁白（可为空）",
  "card_story": "卡牌故事",
  "audio_cue": "背景音建议（如：古琴独奏、刀剑相击声、风声）"
}

要求：
- 武侠题材，使用古白话文风格
- 氛围描写需贴合卡牌的元素属性（火系用热烈、土系用厚重）
- 不要输出任何解释性文字，直接输出 JSON`, card.DealerName, card.DealerName,
        player.Name, card.Title, card.Description, card.Type,
        card.Element, card.Damage, card.MPCost,
        strings.Join(card.Effects, "、"), style)
}
```

### 4.2 NPC 台词模板

```go
func NPCDialoguePrompt(npc NPCInfo, scene SceneContext) string {
    return fmt.Sprintf(`你是 ChronoCards NPC 对话引擎。
NPC：「%s」（%s）
当前场景：%s
情绪基调：%s

请生成一段 NPC 台词，要求：

1. **台词**（30-100字）：符合 NPC 性格和当前场景的第一人称对白
2. **动作描写**（10-30字）：NPC 的肢体语言或表情变化
3. **内话/心理**（可选，20-40字）：NPC 内心独白，玩家不可见（可作为后续剧情伏笔）

输出格式（JSON，不要包含任何 markdown 标记）：
{
  "dialogue": "NPC 对话内容",
  "action": "动作描写",
  "inner_thought": "内心独白（可为空）",
  "emotion_hint": "情绪提示（angry/happy/sad/mysterious/calm 等）",
  "audio_cue": "语音提示（如：冷笑、语气低沉、语速加快）"
}

要求：
- 对话风格与 NPC 人设高度一致
- 不输出任何解释，直接输出 JSON`, npc.Name, npc.Personality,
        scene.Description, scene.Emotion)
}
```

### 4.3 事件描述模板

```go
func EventDescPrompt(event EventContext) string {
    templates := map[string]string{
        "encounter":      "江湖险恶，迎面撞上了一场厮杀",
        "random_event":  "天有不测风云，江湖中总有意外",
        "level_up":      "厚积薄发，武功修为突破新境界",
    }
    base := templates[event.Type]
    if base == "" {
        base = "江湖风云，变幻莫测"
    }

    return fmt.Sprintf(`你是 ChronoCards 事件叙事引擎。
事件类型：%s
发生地点：%s
玩家角色：%s

请生成一段 %s 的事件描述，要求：

1. **事件叙事**（80-150字）：以第三人称或第一人称叙述事件发生、发展
2. **氛围烘托**（20-50字）：环境描写、天气、声音等氛围元素
3. **玩家感受**（可选，20-40字）：玩家角色此刻的内心或身体感受

输出格式（JSON，不要包含任何 markdown 标记）：
{
  "narrative": "事件叙事",
  "atmosphere": "氛围烘托",
  "player_feeling": "玩家感受（可为空）",
  "audio_cue": "背景音建议"
}

要求：
- 叙事节奏感强，有起承转合
- 不要输出任何解释，直接输出 JSON`, event.Type, event.LocationName,
        event.PlayerName, base)
}
```

---

## 5. 缓存策略

### 5.1 缓存目标

减少 LLM 调用次数，降低延迟和成本。

| 内容 | 缓存 Key | TTL | 说明 |
|------|---------|-----|------|
| 抽卡叙事 | `narrative:card:{cardType}:{element}:{hash(deckID+drawCount)}` | 24h | 同卡牌类型+元素组合在24小时内复用 |
| NPC 台词 | `narrative:npc:{npcID}:{scene}` | 1h | 场景固定则台词固定 |
| 事件描述 | `narrative:event:{eventType}:{locationID}:{timestamp/date}` | 6h | 每日事件不重复 |

### 5.2 MVP 简化方案（内存缓存）

```go
// cache.go — MVP 用 sync.Map 实现
type NarrativeCache struct {
    data sync.Map
    ttl  time.Duration
}

func (c *NarrativeCache) Get(key string) (string, bool) {
    val, ok := c.data.Load(key)
    if !ok {
        return "", false
    }
    entry := val.(cacheEntry)
    if time.Since(entry.created) > c.ttl {
        c.data.Delete(key)
        return "", false
    }
    return entry.value, true
}

func (c *NarrativeCache) Set(key, value string) {
    c.data.Store(key, cacheEntry{value: value, created: time.Now()})
}
```

**扩展性：** 生产环境可替换为 Redis（`SETEX` + `GET`），Key 格式不变。

### 5.3 缓存不命中的种子设计

为避免同一玩家抽同一张牌每次都生成相同内容，Prompt 中注入 **随机种子字段**：

```go
seed := fmt.Sprintf("%s:%d:%d", cardID, time.Now().Unix() / 3600) // 每小时不同种子
prompt := CardDrawPrompt(card, player) + fmt.Sprintf("\n随机种子：%s（保持变化）", seed)
```

---

## 6. 降级方案（Fallback）

### 6.1 降级链路

```
LLM 调用
    │
    ├─ 成功（HTTP 200）──▶ 解析 JSON 返回
    │
    ├─ 超时（>10s）──▶ 降级
    │
    ├─ 429 Rate Limit ──▶ 等待 5s 重试一次，再失败 ──▶ 降级
    │
    ├─ 5xx 服务错误 ──▶ 指数退避重试 2 次，再失败 ──▶ 降级
    │
    └─ 网络错误 ──▶ 立即降级
             │
             ▼
        Fallback 兜底数据
```

### 6.2 降级数据（静态模板）

```go
// fallback.go

var CardDrawFallback = map[string]NarrativeContent{
    "attack": {
        Text: "剑光一闪，寒芒乍现。江湖恩怨，在这一招间尽数展现。",
        Atmosphere: "肃杀之气弥漫，刀光剑影交错",
        AudioCue:   "刀剑相击金属声",
    },
    "defense": {
        Text: "以静制动，后发先至。防守之道，乃武者根基。",
        Atmosphere: "气息沉稳，如山岳般不可撼动",
        AudioCue:   "沉稳鼓点",
    },
    "skill": {
        Text: "内息运转，真气流转。技能释放，天地为之变色。",
        Atmosphere: "灵气环绕，若隐若现",
        AudioCue:   "空灵的风铃声",
    },
    "event": {
        Text: "江湖风云变幻，命运齿轮悄然转动。",
        Atmosphere: "神秘而悠远，命运感强烈",
        AudioCue:   "低沉的弦乐",
    },
}

var NPCDialogueFallback = map[string]NarrativeContent{
    "default": {
        Text: "（NPC 沉默不语，似乎在思考着什么）",
        Atmosphere: "气氛微妙，沉默中暗藏玄机",
        AudioCue:   "静谧中的远处鸟鸣",
    },
}

var EventFallback = map[string]NarrativeContent{
    "encounter": {
        Text: "江湖险恶，一场遭遇在所难免。",
        Atmosphere: "紧张压抑，危机四伏",
        AudioCue:   "紧张鼓点",
    },
    "level_up": {
        Text: "修炼突破，武功更上一层楼！",
        Atmosphere: "光芒四射，精神焕发",
        AudioCue:   "激昂的铜管乐",
    },
}
```

### 6.3 降级触发后的日志

```go
log.Printf("[Narrative] LLM failed for %s:%s, using fallback (reason: %v)", 
    triggerType, cardID, err)
```

---

## 7. WebSocket 集成

### 7.1 `handleCardDraw` 修改点

```go
// handler.go

// 在 handleCardDraw() 中，抽牌成功后：
// 1. 业务逻辑抽牌（现有）
drawnCards := /* ... */ 

// 2. 异步生成并推送叙事（不阻塞响应）
go func() {
    for _, card := range drawnCards {
        narrativeData, err := narrativeSvc.GenerateCardDrawNarrative(ctx, CardDrawNarrativeReq{
            PlayerID:   packet.Client.PlayerID,
            CardInfo:   card,
            DealerID:   req.DealerID,
            Location:   player.Location,
            DrawCount:  len(drawnCards),
        })
        if err != nil {
            log.Printf("[Narrative] generate error: %v", err)
            narrativeData = fallbackDefault(card.Type)
        }
        h.hub.PushNarrativeEvent(packet.Client.PlayerID, *narrativeData)
    }
}()
```

### 7.2 `event_narrative` 推送结构

```go
// 推送到客户端的数据结构（已在 messages.go 定义）
EventNarrativeData{
    TriggerType:       "card_draw",       // card_draw | npc_dialogue | event_desc
    PlayerID:          playerID,
    CardID:            "card_xxx",
    CardTitle:         "破天一剑",
    DealerID:          "teahouse-1",
    Location:          "长安城",
    Content: NarrativeContent{
        Text:       "剑光一闪...",       // 叙事主体文本
        Dialogue:   "说书人：这...",     // 对话/旁白（可选）
        Atmosphere: "肃杀之气...",       // 氛围描写
        AudioCue:   "刀剑相击声",         // 音效提示
    },
    DisplayDurationMs: 5000,              // 客户端显示时长
}
```

---

## 8. 错误处理与可观测性

### 8.1 关键日志点

| 操作 | 日志级别 | 内容 |
|------|---------|------|
| LLM 调用成功 | INFO | `{type}: generated {token_count} tokens in {duration}ms` |
| LLM 调用失败 | WARN | `{type}: LLM error={err}, falling back` |
| 缓存命中 | DEBUG | `{type}: cache hit for key={cache_key}` |
| 降级触发 | WARN | `{type}: using fallback for {trigger_id}, reason={reason}` |
| 推送成功 | DEBUG | `pushed narrative to player={playerID}, seq={seq}` |

### 8.2 监控指标（MVP 可省略，生产建议添加）

- `narrative_llm_calls_total` (counter) — 标签：`status=success|fallback|error`
- `narrative_llm_latency_seconds` (histogram)
- `narrative_cache_hit_ratio` (gauge)

---

## 9. 安全注意事项

1. **API Key 安全**：通过环境变量注入，不要硬编码，不写入 git
2. **Prompt 注入**：用户可见输入（卡牌名、位置名）需要做长度限制（≤50字）和基本过滤（禁止 `\`、`{`、`}` 等结构化字符）
3. **Token 限制**：`max_tokens` 设置上限（建议 512），防止无限输出
4. **Rate Limit**：MiniMax 账户有 QPS 限制，NarrativeService 内部加锁防止突发流量冲击

---

## 10. 实施计划

| 阶段 | 内容 | 依赖 |
|------|------|------|
| Phase 1 | `narrative/llm_client.go` — MiniMax API 调用封装 | MiniMax API Key |
| Phase 1 | `narrative/service.go` — 服务主体 + 抽卡叙事 | Phase 1 |
| Phase 2 | `narrative/prompts/` — 三个 Prompt 模板 | Phase 1 |
| Phase 2 | `narrative/cache.go` — 内存缓存实现 | Phase 1 |
| Phase 3 | `narrative/fallback.go` — 降级策略 | Phase 2 |
| Phase 3 | `handler.go` — 集成 `GenerateCardDrawNarrative` 到 `handleCardDraw` | Phase 2 |
| Phase 4 | NPC 台词、事件描述生成接入 | Phase 3 |
| Phase 4 | 飞书通知 @阿健 验证 | 全部 |

---

## 11. 附录

### A. MiniMax Chat API 完整调用示例

```bash
curl -X POST "https://api.minimaxi.com/v1/text/chatcompletion_v2" \
  -H "Authorization: Bearer ${MINIMAX_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "abab7-chat",
    "messages": [
      {"role": "user", "content": "抽卡叙事 prompt..."}
    ],
    "temperature": 0.7,
    "max_tokens": 512
  }'
```

### B. 响应解析

```json
{
  "id": "gen-xxx",
  "choices": [{
    "finish_reason": "stop",
    "messages": [{"role": "assistant", "content": "{\"atmosphere\": \"...\", ...}"}]
  }],
  "usage": {"total_tokens": 256}
}
```

### C. 相关文件索引

| 文件 | 作用 |
|------|------|
| `server/ws/messages.go` | `EventNarrativeData`、`NarrativeContent` 定义 |
| `server/ws/hub.go` | `PushNarrativeEvent()` 推送方法 |
| `server/ws/handler.go` | `handleCardDraw()` 入口，需接入 LLM |
| `server/narrative/` | 新增叙事服务目录 |
