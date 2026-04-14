# WebSocket 接口协议 v1.0

> 文档版本：v1.0  
> 日期：2026-04-14  
> 状态：草稿  
> 描述：ChronoCards 实时游戏事件推送协议

---

## 1. 连接

### 连接地址

| 环境 | URL |
|------|-----|
| 生产环境 | `wss://api.chronocards.game/ws/v1` |
| 本地开发 | `ws://localhost:8080/ws/v1` |

### 认证方式

客户端在建立 WebSocket 连接时，通过 HTTP Header 携带认证信息：

```
GET /ws/v1?player_id={player_id} HTTP/1.1
Host: api.chronocards.game
Authorization: Bearer {jwt_token}
X-Device-ID: {device_id}
```

或者通过连接建立后的第一条消息进行认证：

```json
// 客户端 → 服务端（连接建立后 5 秒内必须发送）
{
  "type": "auth",
  "player_id": "uuid-xxxx-xxxx",
  "token": "jwt_token_here",
  "device_id": "device_001"
}
```

```json
// 服务端 → 客户端（认证成功）
{
  "type": "auth_ack",
  "success": true,
  "player_id": "uuid-xxxx-xxxx",
  "session_id": "sess_xxxxx",
  "server_time": "2026-04-14T14:00:00Z"
}

// 服务端 → 客户端（认证失败）
{
  "type": "auth_ack",
  "success": false,
  "error_code": "INVALID_TOKEN",
  "message": "认证失败，请重新登录"
}
```

---

## 2. 消息格式

### 通用结构

所有消息均为 JSON 格式，包含以下字段：

```json
{
  "type": "event_type",
  "event": "event_name",
  "seq": 12345,
  "timestamp": "2026-04-14T14:00:00.123Z",
  "data": { ... }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | string | 是 | 消息类型：`event`/`request`/`response`/`error` |
| `event` | string | 是 | 事件名称，详见事件类型章节 |
| `seq` | integer | 是 | 消息序列号，用于消息排序和丢包检测 |
| `timestamp` | string | 是 | ISO 8601 时间戳（服务端时间） |
| `data` | object | 是 | 事件数据负载 |

### 消息流向

- **服务端推送（Server Push）**：服务端主动向客户端推送事件
- **客户端请求（Client Request）**：客户端主动发起请求，服务端响应
- **服务端事件（Server Event）**：由服务端业务逻辑触发的事件推送

---

## 3. 客户端 → 服务端（请求）

### 3.1 抽牌请求 `card_draw`

```json
{
  "type": "request",
  "event": "card_draw",
  "seq": 100,
  "timestamp": "2026-04-14T14:00:00Z",
  "data": {
    "deck_id": "deck_xxxx",
    "count": 1,
    "dealer_id": "teahouse-1",
    "force_card_type": ""
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `deck_id` | string | 是 | 卡组ID |
| `count` | integer | 否 | 抽牌数量，默认1，最大3 |
| `dealer_id` | string | 否 | 发牌员ID（触发发牌员效果） |
| `force_card_type` | string | 否 | 强制抽牌类型：`attack`/`defense`/`skill`/`special` |

### 3.2 战斗动作请求 `battle_action`

```json
{
  "type": "request",
  "event": "battle_action",
  "seq": 101,
  "timestamp": "2026-04-14T14:00:01Z",
  "data": {
    "player_id": "uuid-xxxx",
    "action": "dodge",
    "attack_timing_ms": 500,
    "action_timing_ms": 480,
    "stamina_available": 80,
    "mp_available": 50
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `player_id` | string | 是 | 玩家ID |
| `action` | string | 是 | 动作类型：`dodge`/`block`/`counter`/`attack` |
| `attack_timing_ms` | integer | 否 | 攻击时机（毫秒），dodge/block 时必填 |
| `action_timing_ms` | integer | 否 | 玩家操作时机（毫秒），dodge/block 时必填 |
| `stamina_available` | integer | 否 | 可用体力，dodge/block 时必填 |
| `mp_available` | integer | 否 | 可用内力，用于技能消耗 |
| `base_damage` | float | 否 | 基础伤害，attack 时使用 |
| `element` | string | 否 | 元素类型：`fire`/`water`/`thunder`/`wind`/`earth`/`ice`/`lightning` |
| `defender_element` | string | 否 | 目标元素类型 |
| `element_mastery` | integer | 否 | 元素精通等级 |
| `defender_level` | integer | 否 | 目标等级（用于元素反应计算） |
| `is_critical` | boolean | 否 | 是否暴击 |
| `counter_base_damage` | float | 否 | 反击基础伤害，counter 时使用 |

### 3.3 世界导航请求 `world_navigate`

```json
{
  "type": "request",
  "event": "world_navigate",
  "seq": 102,
  "timestamp": "2026-04-14T14:00:02Z",
  "data": {
    "player_id": "uuid-xxxx",
    "target_location_id": "loc-suzhou",
    "use_optimal_route": true
  }
}
```

### 3.4 技能使用请求 `skill_use`

```json
{
  "type": "request",
  "event": "skill_use",
  "seq": 103,
  "timestamp": "2026-04-14T14:00:03Z",
  "data": {
    "player_id": "uuid-xxxx",
    "skill_id": "skill_001",
    "target_id": "enemy_001"
  }
}
```

### 3.5 物品使用请求 `item_use`

```json
{
  "type": "request",
  "event": "item_use",
  "seq": 104,
  "timestamp": "2026-04-14T14:00:04Z",
  "data": {
    "player_id": "uuid-xxxx",
    "item_id": "item_001",
    "count": 1
  }
}
```

### 3.6 心跳/保活 `ping`

```json
{
  "type": "request",
  "event": "ping",
  "seq": 105,
  "timestamp": "2026-04-14T14:00:05Z",
  "data": {}
}
```

```json
// 服务端响应
{
  "type": "response",
  "event": "pong",
  "seq": 105,
  "timestamp": "2026-04-14T14:00:05.010Z",
  "data": {
    "server_time": "2026-04-14T14:00:05.010Z",
    "latency_ms": 10
  }
}
```

---

## 4. 服务端 → 客户端（响应）

### 4.1 抽牌响应 `card_draw`

```json
{
  "type": "response",
  "event": "card_draw",
  "seq": 100,
  "timestamp": "2026-04-14T14:00:00.200Z",
  "data": {
    "success": true,
    "drawn_cards": [
      {
        "id": "card_001",
        "type": "attack",
        "title": "破天一剑",
        "description": "凝聚全身真气，发出毁天灭地的一击",
        "element": "thunder",
        "damage": 85,
        "mp_cost": 20,
        "cooldown": 0,
        "effects": ["破甲", "眩晕"]
      }
    ],
    "next_card_type_hint": "defense",
    "deck_exhausted": false,
    "dealer_hint": "说书人轻敲桌面：此剑一出，江湖再无安宁",
    "cards_remaining": 23
  }
}
```

### 4.2 战斗动作响应 `battle_action`

```json
{
  "type": "response",
  "event": "battle_action",
  "seq": 101,
  "timestamp": "2026-04-14T14:00:01.150Z",
  "data": {
    "action": "dodge",
    "success": true,
    "dodge_result": {
      "dodged": true,
      "timing_diff_ms": 20,
      "timing_rating": "perfect",
      "stamina_cost": 20,
      "sword_intent_gained": 5,
      "description": "完美闪避！时机拿捏分毫不差"
    },
    "sword_intent_gained": 5,
    "description": "完美闪避！时机拿捏分毫不差"
  }
}
```

**Block 响应示例：**

```json
{
  "type": "response",
  "event": "battle_action",
  "seq": 101,
  "timestamp": "2026-04-14T14:00:01.150Z",
  "data": {
    "action": "block",
    "success": true,
    "block_result": {
      "blocked": true,
      "perfect_block": true,
      "timing_diff_ms": 80,
      "timing_rating": "perfect",
      "damage_reduction": 1.0,
      "stamina_cost": 15,
      "counter_window_ms": 500,
      "sword_intent_gained": 8,
      "description": "完美格挡！刀光剑影中尽显宗师风范"
    },
    "sword_intent_gained": 8,
    "description": "完美格挡！刀光剑影中尽显宗师风范"
  }
}
```

**Attack 响应示例：**

```json
{
  "type": "response",
  "event": "battle_action",
  "seq": 101,
  "timestamp": "2026-04-14T14:00:01.150Z",
  "data": {
    "action": "attack",
    "success": true,
    "attack_damage": {
      "final_damage": 127.5,
      "elemental_reaction": {
        "reaction_type": "evaporation",
        "reaction_damage": 25.5,
        "suppression_multiplier": 1.2,
        "description": "蒸发！水火相激，威力倍增"
      },
      "sword_intent_gained": 10,
      "mp_consumed": 15,
      "description": "造成 127.5 点伤害（+蒸发反应 25.5）"
    },
    "sword_intent_gained": 10,
    "description": "造成 127.5 点伤害（+蒸发反应 25.5）"
  }
}
```

### 4.3 导航响应 `world_navigate`

```json
{
  "type": "response",
  "event": "world_navigate",
  "seq": 102,
  "timestamp": "2026-04-14T14:00:02.300Z",
  "data": {
    "success": true,
    "message": "你踏上了前往苏州城的旅程，沿着京杭大运河顺流而下。",
    "travel_time": "1天",
    "route": {
      "path": [
        {"id": "loc-changan", "name": "长安城"},
        {"id": "loc-luoyang", "name": "洛阳"},
        {"id": "loc-suzhou", "name": "苏州城"}
      ],
      "total_distance": 500,
      "dangers": []
    },
    "new_location": {
      "id": "loc-suzhou",
      "name": "苏州城",
      "location_type": "city",
      "danger_level": 2
    },
    "available_dealers": [
      {"id": "teahouse-2", "type": "teahouse", "name": "茶馆说书人"},
      {"id": "bounty-1", "type": "bounty_board", "name": "江湖悬赏令"}
    ],
    "encounter_probability": {
      "on_route": 0.15,
      "at_destination": 0.25
    }
  }
}
```

---

## 5. 服务端推送事件（Server Push）

以下事件由服务端业务逻辑主动推送，客户端无需请求。

### 5.1 抽牌事件 `event_card_draw`

当其他玩家抽牌时（用于多人同步场景），推送抽牌事件：

```json
{
  "type": "event",
  "event": "event_card_draw",
  "seq": 200,
  "timestamp": "2026-04-14T14:00:10Z",
  "data": {
    "player_id": "uuid-xxxx",
    "player_name": "张三",
    "dealer_id": "teahouse-1",
    "dealer_name": "茶馆说书人",
    "drawn_cards": [
      {
        "id": "card_002",
        "type": "skill",
        "title": "九阴真经",
        "element": "wind",
        "damage": 60,
        "mp_cost": 30
      }
    ],
    "cards_remaining": 22,
    "narrative": "一阵风吹过，书页翻动，说书人缓缓道出一段江湖旧事..."
  }
}
```

### 5.2 世界地图更新 `event_world_map_update`

当玩家位置发生变化（主动导航或被动传送）时，推送地图更新：

```json
{
  "type": "event",
  "event": "event_world_map_update",
  "seq": 201,
  "timestamp": "2026-04-14T14:00:15Z",
  "data": {
    "player_id": "uuid-xxxx",
    "previous_location": {
      "id": "loc-changan",
      "name": "长安城",
      "region_id": "region-central-plains"
    },
    "current_location": {
      "id": "loc-suzhou",
      "name": "苏州城",
      "region_id": "region-jiangnan"
    },
    "travel_stats": {
      "total_travels": 12,
      "total_distance": 3500,
      "last_travel_at": "2026-04-14T14:00:15Z"
    },
    "visited_locations_count": 8,
    "visited_regions_count": 3
  }
}
```

### 5.3 战斗状态更新 `event_battle_update`

战斗状态发生变化时推送（如敌人攻击、HP变化）：

```json
{
  "type": "event",
  "event": "event_battle_update",
  "seq": 202,
  "timestamp": "2026-04-14T14:00:20Z",
  "data": {
    "battle_id": "battle_xxxx",
    "turn": 5,
    "active_player_id": "enemy_001",
    "enemy_action": "attack",
    "enemy_intent": "普通攻击",
    "attack_timing_ms": 500,
    "player_status": {
      "hp": 80,
      "max_hp": 100,
      "mp": 45,
      "max_mp": 80,
      "stamina": 60,
      "max_stamina": 100,
      "sword_intent": 35
    },
    "available_actions": ["dodge", "block", "attack"],
    "message": "敌人蓄势待发，准备发出凌厉一击！"
  }
}
```

### 5.4 玩家状态变化 `event_player_status`

玩家属性（HP/MP/体力/剑意值等）发生显著变化时推送：

```json
{
  "type": "event",
  "event": "event_player_status",
  "seq": 203,
  "timestamp": "2026-04-14T14:00:25Z",
  "data": {
    "player_id": "uuid-xxxx",
    "changes": {
      "hp": { "from": 100, "to": 80, "delta": -20 },
      "sword_intent": { "from": 25, "to": 35, "delta": 10 }
    },
    "current_status": {
      "hp": 80,
      "max_hp": 100,
      "mp": 45,
      "max_mp": 80,
      "stamina": 60,
      "max_stamina": 100,
      "sword_intent": 35,
      "level": 5,
      "exp": 350
    }
  }
}
```

### 5.5 技能冷却更新 `event_skill_cooldown`

技能冷却状态变化时推送：

```json
{
  "type": "event",
  "event": "event_skill_cooldown",
  "seq": 204,
  "timestamp": "2026-04-14T14:00:30Z",
  "data": {
    "player_id": "uuid-xxxx",
    "skill_id": "skill_001",
    "skill_name": "排山倒海",
    "cooldown_remaining_seconds": 0,
    "available": true
  }
}
```

### 5.6 卡组耗尽事件 `event_deck_exhausted`

卡组抽完时推送，提示客户端需要重新构建或洗牌：

```json
{
  "type": "event",
  "event": "event_deck_exhausted",
  "seq": 205,
  "timestamp": "2026-04-14T14:00:35Z",
  "data": {
    "player_id": "uuid-xxxx",
    "deck_id": "deck_xxxx",
    "deck_name": "默认卡组",
    "total_cards_drawn": 30,
    "auto_reshuffle": true,
    "message": "卡组已耗尽，自动洗牌重组"
  }
}
```

### 5.7 物品使用事件 `event_item_used`

物品被使用时推送（可能影响战斗或世界状态）：

```json
{
  "type": "event",
  "event": "event_item_used",
  "seq": 206,
  "timestamp": "2026-04-14T14:00:40Z",
  "data": {
    "player_id": "uuid-xxxx",
    "item_id": "item_potion_001",
    "item_name": "九转还魂丹",
    "effects": {
      "hp_restored": 50,
      "buff_active": false
    },
    "current_hp": 80,
    "item_count_remaining": 2
  }
}
```

### 5.8 遭遇事件 `event_encounter`

玩家在旅行中遭遇敌人或触发随机事件时推送：

```json
{
  "type": "event",
  "event": "event_encounter",
  "seq": 207,
  "timestamp": "2026-04-14T14:00:45Z",
  "data": {
    "player_id": "uuid-xxxx",
    "encounter_type": "enemy",
    "location": {
      "id": "loc-wilderness-001",
      "name": "荒野小路",
      "region_id": "region-jiangnan"
    },
    "enemy": {
      "id": "enemy_bandit_001",
      "name": "山贼喽啰",
      "level": 4,
      "hp": 60,
      "max_hp": 60,
      "danger_level": 2
    },
    "encounter_probability": 0.15,
    "narrative": "林中突然窜出几名山贼，将你团团围住！",
    "battle_id": "battle_xxxx"
  }
}
```

### 5.9 等级提升事件 `event_level_up`

玩家升级时推送：

```json
{
  "type": "event",
  "event": "event_level_up",
  "seq": 208,
  "timestamp": "2026-04-14T14:00:50Z",
  "data": {
    "player_id": "uuid-xxxx",
    "from_level": 4,
    "new_level": 5,
    "exp": 400,
    "exp_needed": 500,
    "stat_changes": {
      "max_hp": { "from": 100, "to": 115, "delta": 15 },
      "max_mp": { "from": 80, "to": 90, "delta": 10 },
      "max_stamina": { "from": 100, "to": 110, "delta": 10 }
    },
    "message": "突破！等级提升至 5，气血内力均有长进"
  }
}
```

### 5.10 元素反应事件 `event_element_reaction`

元素反应触发时推送：

```json
{
  "type": "event",
  "event": "event_element_reaction",
  "seq": 209,
  "timestamp": "2026-04-14T14:00:55Z",
  "data": {
    "player_id": "uuid-xxxx",
    "attacker_element": "fire",
    "defender_element": "water",
    "reaction_type": "evaporation",
    "reaction_damage": 35.0,
    "suppression_multiplier": 1.3,
    "description": "蒸发！水火相激，蒸气弥漫，威力倍增"
  }
}
```

### 5.11 叙事事件 `event_narrative`

游戏叙事内容生成时推送：

```json
{
  "type": "event",
  "event": "event_narrative",
  "seq": 210,
  "timestamp": "2026-04-14T14:01:00Z",
  "data": {
    "trigger_type": "card_drawn",
    "player_id": "uuid-xxxx",
    "card_id": "card_001",
    "card_title": "破天一剑",
    "dealer_id": "teahouse-1",
    "location": "loc-changan",
    "content": {
      "text": "茶馆中，说书人轻敲桌面：「话说那一剑破空而出，天地为之变色...」",
      "dialogue": "说书人：这便是江湖传说中的破天一剑！",
      "atmosphere": "神秘、激昂",
      "audio_cue": "sword_clash_01"
    },
    "display_duration_ms": 5000
  }
}
```

---

## 6. 错误码

| 错误码 | 说明 |
|--------|------|
| `INVALID_TOKEN` | JWT token 无效或已过期 |
| `PLAYER_NOT_FOUND` | 玩家不存在 |
| `DECK_NOT_FOUND` | 卡组不存在 |
| `DECK_EXHAUSTED` | 卡组已耗尽 |
| `INSUFFICIENT_STAMINA` | 体力不足 |
| `INSUFFICIENT_MP` | 内力不足 |
| `SKILL_NOT_LEARNED` | 技能未学习 |
| `SKILL_ON_COOLDOWN` | 技能在冷却中 |
| `LOCATION_LOCKED` | 场景已锁定 |
| `LOCATION_UNREACHABLE` | 场景不可达 |
| `ITEM_NOT_FOUND` | 物品不存在 |
| `INVALID_ACTION` | 无效的战斗动作 |
| `SESSION_EXPIRED` | 会话已过期，需重新认证 |
| `RATE_LIMITED` | 请求过于频繁 |

---

## 7. 连接生命周期

### 7.1 连接建立流程

```
1. 客户端 TCP 连接到 ws://localhost:8080/ws/v1
2. 客户端发送 auth 消息（5秒超时）
3. 服务端返回 auth_ack
4. 双方开始正常消息交换
```

### 7.2 心跳策略

- 客户端每 **30 秒** 发送一条 `ping` 消息
- 服务端在 **5 秒** 内回复 `pong`
- 如果连续 **3 次** 未收到 `pong`，服务端断开连接
- 服务端也会主动发送 `ping`，要求客户端回复 `pong`

### 7.3 重连策略

客户端断开后重连时：

1. 等待 1 秒后重试（指数退避：1s → 2s → 4s → 8s → 最大 30s）
2. 重连成功后重新发送 auth
3. 请求 `sync` 事件获取断开期间的状态快照

```json
// 客户端 → 服务端（重连后同步）
{
  "type": "request",
  "event": "sync",
  "seq": 1,
  "timestamp": "2026-04-14T14:02:00Z",
  "data": {
    "last_seq": 210,
    "player_id": "uuid-xxxx"
  }
}

// 服务端 → 客户端
{
  "type": "response",
  "event": "sync",
  "seq": 1,
  "timestamp": "2026-04-14T14:02:00.100Z",
  "data": {
    "current_player_status": { ... },
    "current_location": { ... },
    "current_battle": null,
    "pending_events": [ ... ]
  }
}
```

### 7.4 连接断开

- 客户端发送 `close` 消息后，服务端优雅关闭连接
- 服务端也可主动发送 `close` 事件（带错误码）后断开

```json
{
  "type": "close",
  "event": "session_expired",
  "seq": 999,
  "timestamp": "2026-04-14T15:00:00Z",
  "data": {
    "reason": "idle_timeout",
    "reconnect_after_ms": 0
  }
}
```

---

## 8. 实现注意事项

### 8.1 推荐库

- **Go 后端**：推荐使用 `nhooyr.io/websocket`（轻量、完整支持 RFC 6455）
- **前端**：标准 WebSocket API 或 `socket.io`（视项目技术栈而定）

### 8.2 消息序列化

- 字符编码：**UTF-8**
- 数字类型：浮点数使用字符串传递（避免精度丢失）
- 时间格式：**ISO 8601**，时区统一使用 UTC

### 8.3 安全考虑

- WebSocket 握手时强制验证 JWT
- 敏感操作（如抽牌、战斗）服务端需二次校验玩家状态
- 限制单连接消息频率（建议 100 条/秒）

### 8.4 消息顺序

- 使用 `seq` 字段保证消息顺序
- 客户端按 `seq` 顺序处理，丢弃 `seq` 小于当前已处理值的消息

---

## 9. 事件总览

| 事件名 | 方向 | 触发时机 |
|--------|------|----------|
| `auth` / `auth_ack` | 双向 | 连接建立时的身份验证 |
| `card_draw` | 双向 | 抽牌请求/响应 |
| `battle_action` | 双向 | 战斗动作（闪避/格挡/反击/攻击） |
| `world_navigate` | 双向 | 世界地图导航 |
| `skill_use` | 双向 | 技能使用 |
| `item_use` | 双向 | 物品使用 |
| `ping` / `pong` | 双向 | 心跳保活 |
| `sync` | 双向 | 重连后状态同步 |
| `event_card_draw` | 服务端推送 | 其他玩家抽牌（多人同步） |
| `event_world_map_update` | 服务端推送 | 玩家位置变化 |
| `event_battle_update` | 服务端推送 | 战斗状态变化 |
| `event_player_status` | 服务端推送 | 玩家属性显著变化 |
| `event_skill_cooldown` | 服务端推送 | 技能冷却变化 |
| `event_deck_exhausted` | 服务端推送 | 卡组耗尽 |
| `event_item_used` | 服务端推送 | 物品使用效果 |
| `event_encounter` | 服务端推送 | 遭遇敌人/随机事件 |
| `event_level_up` | 服务端推送 | 玩家升级 |
| `event_element_reaction` | 服务端推送 | 元素反应触发 |
| `event_narrative` | 服务端推送 | 叙事内容生成 |
