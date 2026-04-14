# Code Review Report - commit ae4413a → 673357b

**审查人：** 阿健（代码检测师）  
**审查时间：** 2026-04-12  
**commit范围：** 世界地图 + 技能系统 + 装备道具系统

---

## 🔴 严重问题（必须修复）

### 1. 技能冷却计算逻辑完全错误
**文件：** `internal/game/skill/service.go` 第 96-102 行

```go
func (s *Service) GetSkillCooldownRemaining(playerID, skillID string) int {
    s.cooldownMu.RLock()
    defer s.cooldownMu.RUnlock()
    if playerCooldowns, ok := s.cooldowns[playerID]; ok {
        if lastUsed, ok := playerCooldowns[skillID]; ok {
            return int(time.Since(lastUsed).Seconds())  // ❌ 错误！
        }
    }
    return 0
}
```

**问题：** `time.Since(lastUsed)` 返回的是**已经过去的秒数**，不是剩余秒数。刚使用技能时返回 0（看似可用），等待 cooldown 秒后反而返回正值（显示冷却中）。

**正确逻辑：**
```go
elapsed := int(time.Since(lastUsed).Seconds())
return max(0, skill.CooldownSeconds - elapsed)
```

---

### 2. 物品数据两套定义，数据不一致
**文件：** `internal/game/item/preset.go` 和 `internal/game/item/preset_items.go`

两文件定义了**不同的物品数组**：
- `preset.go` → `PresetItems` + `GetPresetItem()`
- `preset_items.go` → `MVPItems` + `GetItemByID()`

`handler.go` 用 `item.MVPItems`（preset_items.go），但 `service.go` 和 `shop.go` 用 `GetPresetItem()`（preset.go）。同名物品价格/属性/图标路径**完全不同**，例如：

| 物品ID | preset.go 价格 | preset_items.go 价格 |
|--------|----------------|---------------------|
| weapon_iron_sword | 200 | 100 |
| weapon_wudang_blade | 3000 | 800 |
| potion_hp | 50 | 50 |

**修复：** 保留一套 `MVPItems`，删除 `PresetItems`。

---

### 3. 装备槽位状态不一致（内存泄漏风险）
**文件：** `internal/game/item/inventory.go` 第 187-191 行

```go
targetSlot.Item = nil
targetSlot.Count = 0
targetSlot.Equipped = true  // ❌ Item为nil时Equipped=true，状态矛盾
```

同时在 `UnequipItem` 中（第 271 行）：
```go
targetSlot.Item = oldAcc
targetSlot.Count = 1
targetSlot.Equipped = false  // ✅ 正确
```

**问题：** `EquipItem` 结束时把格子 Item 置 nil 但 Equipped 仍为 true，导致 `HasItem` 和 `RemoveItem` 后续逻辑可能错误判断格子状态。

---

### 4. shop.go 依赖可能返回空对象的 GetPresetItem
**文件：** `internal/game/item/shop.go`

```go
{Item: MustGetItem("potion_hp"), ...}
```

`MustGetItem` 内部调用 `GetPresetItem`（preset.go 那个），但 `MVPItems` 里是 `potion_hp`，应该能匹配。不过由于问题2的存在，两套数据不一致时可能返回错误的 fallback 空对象。

---

## 🟡 中等问题（建议修复）

### 5. UseSkill targetHP 类型处理不健壮
**文件：** `internal/api/handler.go` 第 1098-1103 行

```go
if v, ok := req.TargetID.(float64); ok {
    hpi := int(v)
    targetHP = &hpi
}
```

**问题：** JSON 解码数字默认是 `float64`，但如果前端传了字符串或 `null`，这里会静默跳过。缺少对 `json.Number` 的处理，也没有对 `nil` 值的判断。

---

### 6. 饰品装备替换逻辑复杂且有歧义
**文件：** `internal/game/item/inventory.go` 第 147-180 行

accessory2 替换 accessory1 时的处理：
```go
oldAcc := eq.Accessory1
eq.Accessory1 = eq.Accessory2
eq.Accessory2 = item
if oldAcc != nil {
    targetSlot.Item = oldAcc
    targetSlot.Count = 1
    s.store.UpdateInventory(inv)
    s.store.UpdateEquipment(eq)
    return eq, nil
}
```

**问题：** 当 accessory2 替换 accessory1 时，原 accessory1 被放回 `targetSlot`（即传入的 slotIndex），这要求传入的 slot 必须是 accessory1 对应的格子。但如果用户传入的是 accessory2 的格子索引，逻辑就不对了。建议明确：按 `slot_type`（"accessory1" | "accessory2"）而非 slotIndex 来处理饰品。

---

### 7. 玩家位置 regionID 硬编码
**文件：** `internal/store/store.go` 第 277 行 & 第 296 行

```go
regionID := "region-central-plains" // 简化处理
```

世界地图有多 region，但 SetPlayerLocation 和 AddVisited 都写死了 regionID。这会导致后续多 region 支持时玩家 region 追踪完全错误。

---

### 8. world_handler.go GetLocation 返回值结构与路径不匹配
**文件：** `internal/api/world_handler.go` 第 52-55 行

```go
id := strings.TrimPrefix(r.URL.Path, "/api/v1/world/locations/")
```

`strings.TrimPrefix` 不会递归删除路径前缀，`/api/v1/world/locations/xxx` 会变成 `xxx/connections`，然后再 `TrimSuffix` 就错了。`/api/v1/world/locations/loc-pingyang/connections` → `loc-pingyang/connections` → `loc-pingyang`，**但**如果路径有双斜杠或特殊格式会失败。

建议用 `r.PathValue("id")` 或正则。

---

## 🟢 小问题（可选修复）

### 9. PresetSkills 中 SkillCategories 的 init 覆盖问题
**文件：** `internal/game/skill/preset.go`

```go
var SkillCategories = map[string][]model.Skill{
    "通用": {},
    "Q技能": {},
    "终极": {},
}

func init() {
    for _, s := range PresetSkills {
        switch s.Type {
        case "E", "passive":
            SkillCategories["通用"] = append(SkillCategories["通用"], s)
        ...
        }
    }
}
```

SkillCategories 有初始空 slice，但 `append` 会追加到原 slice，不会覆盖。建议初始化为 nil slice：
```go
var SkillCategories = map[string][]model.Skill{
    "通用": nil,
    "Q技能": nil,
    "终极": nil,
}
```

### 10. GetWorldOverview 的 available count 有隐性依赖
**文件：** `internal/game/world/service.go`

```go
if loc.Unlocked {
    available++
}
```

只读内存中的 `MVPLocations`，不考虑玩家实际解锁状态。玩家通过剧情解锁场景后，`loc.Unlocked` 仍为 false，API 返回的 `available_locations` 永远只是初始解锁数。

---

## ✅ 总结

| 等级 | 数量 | 说明 |
|------|------|------|
| 🔴 严重 | 4 | 冷却计算错误、物品数据不一致、装备状态矛盾、shop数据不一致 |
| 🟡 中等 | 4 | 类型处理、饰品逻辑、region硬编码、路径解析 |
| 🟢 小 | 2 | init覆盖、available计数 |

**建议：先修复严重问题再合main。**
