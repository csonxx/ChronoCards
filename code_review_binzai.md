# Code Review Report - PR: 事件卡组UI设计v1.1全量实现

**审查人：** 阿健（代码检测师）  
**分支：** origin/binzai → origin/main  
**commit：** `21942ed feat(v11): 事件卡组UI设计v1.1全量实现`

---

## 🔴 严重问题（必须修复）

### 1. CompatibilityMatrix 点击逻辑完全错误 ❌
**文件：** `frontend/src/components/v11/CompatibilityMatrix.tsx` 第 188 行

```typescript
const selected = selectedTypes[selectedTypes.length - 1]; // 最新选中
```

**问题：** 点击矩阵中的**任意格子**时，只取 `selectedTypes` 数组的**最后一个元素**作为当前选中类型，而不是使用被点击的行/列的类型。这意味着点击矩阵永远不会选中用户实际想选的类型。

同时，`onTypeClick` 实际传入的是 `row.type`（行类型），但显示用的却是 `selectedTypes` 最后一个元素。

**修复建议：**
```typescript
// onTypeClick 应该是切换选中状态，而非仅仅是回调
const handleCellClick = useCallback((type: CardType) => {
  setSelectedTypes(prev => {
    if (prev.includes(type)) {
      return prev.filter(t => t !== type);
    }
    return [...prev, type];
  });
  onTypeClick?.(type);
}, [onTypeClick]);

// 或者 if onTypeClick is meant to set the "current selection" for display:
const displaySelected = selectedTypes.length > 0
  ? selectedTypes[selectedTypes.length - 1]
  : null;
```

---

### 2. ExitConditionPanel 进度条与 conditions prop 不同步
**文件：** `frontend/src/components/v11/ExitConditionPanel.tsx` 第 59-65 行

```typescript
const roundProgress = maxRound > 0 ? (round / maxRound) * 100 : 0;

// ...

const roundConfig = STATUS_CONFIG[getRoundStatus()]; // 这里的 round/maxRound 来自 props
// 但 getRoundStatus() 的判断是：
// round >= 10 → critical
// round >= 7 → warning
// 否则 → active
```

**问题：** 进度条用的是**独立传入的 `round/maxRound` props**，与 `conditions` 数组中的 `round_limit` 条件**完全无关**。当 `round_limit` 状态为 `critical` 时，进度条颜色可能不一致。如果父组件传了 `round=6` 但 `conditions` 里 `round_limit` 是 `critical`（例如手动设置了 status），UI 会产生误导。

**修复建议：** `roundProgress` 和 `roundConfig` 应该从 `conditions` 数组中取 `round_limit` 的 `current/target` 值，或确保 props 和 conditions 始终同步。

---

### 3. tokens.css 完全替换旧主题，无渐进迁移
**文件：** `frontend/src/styles/tokens.css`

**问题：** 整个设计 token 系统被完全替换：
- 旧：`#F5EBD7` 暖色羊皮纸风格
- 新：`#0D0D0D` 深色主题

**影响：** 所有使用旧 token 的组件（如 `Battle.tsx`、`App.tsx` 其他部分）会突然变成深色背景。如果这是有意为之，需要确认所有相关组件已同步适配。如果是分阶段迁移，应该用 CSS 变量开关控制。

---

## 🟡 中等问题（建议修复）

### 4. EventCard.tsx 动画状态管理复杂，有死锁风险
**文件：** `frontend/src/components/v11/EventCard.tsx`

```typescript
const timer3 = setTimeout(() => setFlipped(false), 1400); // 飞入后翻面
// ...
// 但当 isAnimating=false 时，useEffect 不清理这些 timer
```

**问题：** 当 `isAnimating` 传入 `false`（组件直接挂载而非动画入场）时，不会触发 `useEffect`，但之前动画的 timer 可能还在。如果快速切换 `isAnimating=true → false → true`，timer 会重叠。**建议：** timer 清理依赖应该包含 `isAnimating` key。

---

### 5. AdjustmentPanel 的预设数据是硬编码示例
**文件：** `frontend/src/components/v11/AdjustmentPanel.tsx` 第 116-144 行

```typescript
export const PRESET_CONTENT_INDICATORS: AdjustmentIndicator[] = [
  { id: 'chapter_progress', label: '章节进度', current: 3, max: 5, status: 'warning', hint: '⚠ 偏低' },
  { id: 'bond_value', label: '角色羁绊', current: 12, max: 15, status: 'safe', hint: '✓ 正常' },
  // ...
];
```

**问题：** 预设数据写死 `current: 3, max: 5` 等示例值。如果产品需要这些作为真实数据，应该通过 props 传入而非硬编码。如果是占位符，应该在注释中明确标注 "MOCK DATA - TODO: replace with real values"。

---

### 6. CardDrawScene 的 triggerDraw 在两处绑定同一 handler
**文件：** `frontend/src/components/v11/CardDrawScene.tsx` 第 92 行 & 第 185 行

```typescript
<button className="scene-draw-btn" onClick={triggerDraw}>
// 和
<button className="scene-action-btn scene-action-btn--primary" onClick={triggerDraw}>
```

**问题：** 两个不同的按钮指向同一个 `triggerDraw`，如果用户快速连击，可能同时触发两次 `setIsAnimating(true)`。虽然 `isAnimating` 有保护，但如果用户在动画期间点击第二个按钮，状态可能混乱。

**建议：** 动画期间禁用两个按钮。

---

### 7. useWorld hook 的 navigate 错误处理返回硬编码错误
**文件：** `frontend/src/hooks/useWorld.ts` 第 100-107 行

```typescript
return {
  success: false,
  error_code: 'PLAYER_NOT_FOUND', // ❌ 可能不是真正的原因
  message: '导航请求失败',
  alternative_routes: [],
};
```

**问题：** catch 块里返回固定的 `PLAYER_NOT_FOUND`，但实际错误可能是网络问题、超时、后端崩溃等。QA 测试时看到 `PLAYER_NOT_FOUND` 会以为玩家数据有问题，但实际上可能是网络断开了。

---

### 8. worldApi.playerLocation 路径不一致
**文件：** `frontend/src/services/api-client.ts` 第 164 行

```typescript
playerLocation(playerId: string): Promise<...> {
  return api.get(`/players/${playerId}/current-location`);
}
```

**但** `CardDrawScene.tsx` 第 73 行调用的是：
```typescript
<span className="scene-round">⚔️ 第 {round} 回合</span>
```

playerLocation API 返回的字段名与 `types/world-map-schema.ts` 中的 `PlayerLocationInfo` 需要对齐。检查一下 `/current-location` 端点在后端是否实际存在（之前 backend 的 API 是 `/players/{id}/location`）。

---

## 🟢 小问题

### 9. ExitConditionPanel 的 maxRound=0 会导致 NaN
**文件：** `frontend/src/components/v11/ExitConditionPanel.tsx` 第 59 行

```typescript
const roundProgress = maxRound > 0 ? (round / maxRound) * 100 : 0;
```

虽然有 `maxRound > 0` 检查，但如果 `maxRound` 是负数或非数字，结果仍是 0。**影响较小**，但建议加 `max(0, ...)` 兜底。

---

### 10. vite.config.ts 的代理配置只用于开发
**文件：** `frontend/vite.config.ts`

```typescript
proxy: {
  '/api': {
    target: 'http://localhost:8080',
    changeOrigin: true,
  },
},
```

这是正确的开发配置。但需要确认生产环境的 API 地址是如何配置的，否则部署后会 404。

---

## ✅ 总结

| 等级 | 数量 | 关键问题 |
|------|------|---------|
| 🔴 严重 | 3 | 矩阵点击逻辑错误、进度条与conditions不同步、主题全量替换 |
| 🟡 中等 | 5 | 动画状态管理、预设数据硬编码、双按钮连击风险、错误处理误导、API路径不一致 |
| 🟢 小 | 2 | NaN风险、vite代理配置 |

**最大阻塞：问题1（矩阵点击逻辑）会导致卡牌选择完全不可用，必须修。**

**建议先修严重问题再合 main。**
