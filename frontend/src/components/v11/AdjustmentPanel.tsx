// 调整阈值面板 v1.1（双层指标仪表盘）
// 规范来源：ChronoCards_UI_Design_v1.md §5

import React from 'react';
import './adjustment-panel.css';

// ========== 指标数据 ==========
export type IndicatorStatus = 'safe' | 'warning' | 'danger';

export interface AdjustmentIndicator {
  id: string;
  label: string;
  current: number;
  max: number;
  status: IndicatorStatus;
  unit?: string;
  hint?: string;         // 状态提示文本
  threshold?: number;    // 阈值参考
}

export interface AdjustmentLayer {
  id: 'content' | 'numeric';
  label: string;
  priority: number;      // 数字越小优先级越高
  indicators: AdjustmentIndicator[];
  triggerHint?: string;  // 触发时的说明文案
}

// ========== 状态颜色配置 ==========
const STATUS_COLORS: Record<IndicatorStatus, string> = {
  safe: '#3D8B5F',
  warning: '#D4A017',
  danger: '#C23A2B',
};

// ========== 阈值指示器组件 ==========
const IndicatorGauge: React.FC<{ indicator: AdjustmentIndicator }> = ({ indicator }) => {
  const pct = indicator.max > 0 ? Math.min(100, (indicator.current / indicator.max) * 100) : 0;
  const color = STATUS_COLORS[indicator.status];

  return (
    <div className={`indicator-gauge indicator-gauge--${indicator.status}`}>
      <div className="indicator-gauge__label">{indicator.label}</div>
      <div className="indicator-gauge__track">
        <div
          className={`indicator-gauge__fill ${indicator.status === 'danger' ? 'indicator-gauge__fill--pulse' : indicator.status === 'warning' ? 'indicator-gauge__fill--glow' : ''}`}
          style={{ width: `${pct}%`, backgroundColor: color }}
        />
      </div>
      <div className="indicator-gauge__value" style={{ color }}>
        {indicator.current}{indicator.unit || ''}/{indicator.max}{indicator.unit || ''}
      </div>
      {indicator.hint && (
        <div className="indicator-gauge__hint" style={{ color }}>
          {indicator.status === 'safe' ? '✓' : indicator.status === 'warning' ? '⚠' : '🔴'} {indicator.hint}
        </div>
      )}
    </div>
  );
};

// ========== 双层面板组件 ==========
interface AdjustmentPanelProps {
  layers: AdjustmentLayer[];
  currentChapter?: string;
  eraName?: string;         // 当前时代名，如"明朝·万历"
}

export const AdjustmentPanel: React.FC<AdjustmentPanelProps> = ({
  layers,
  currentChapter = '第一章',
  eraName,
}) => {
  // 按优先级排序
  const sortedLayers = [...layers].sort((a, b) => a.priority - b.priority);

  return (
    <div className="adjustment-panel">
      <div className="adjustment-panel__header">
        <span className="adjustment-panel__chapter">{currentChapter}</span>
        {eraName && <span className="adjustment-panel__era">🏮 {eraName}</span>}
      </div>

      <div className="adjustment-layers">
        {sortedLayers.map(layer => (
          <div
            key={layer.id}
            className={`adjustment-layer adjustment-layer--${layer.id}`}
          >
            {/* 层级标识 */}
            <div className="layer-header">
              <span className="layer-arrow">{layer.id === 'content' ? '▼' : '▶'}</span>
              <span className="layer-label">{layer.label}</span>
              {layer.id === 'content' && (
                <span className="layer-priority-tag">优先触发</span>
              )}
            </div>

            {/* 指标网格 */}
            <div className="layer-indicators">
              {layer.indicators.map(ind => (
                <IndicatorGauge key={ind.id} indicator={ind} />
              ))}
            </div>

            {/* 触发提示 */}
            {layer.triggerHint && (
              <div className="layer-trigger-hint">
                ▶ {layer.triggerHint}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

// ========== 预设内容层指标（示例数据） ==========
export const PRESET_CONTENT_INDICATORS: AdjustmentIndicator[] = [
  { id: 'chapter_progress', label: '章节进度', current: 3, max: 5, status: 'warning', hint: '⚠ 偏低' },
  { id: 'bond_value', label: '角色羁绊', current: 12, max: 15, status: 'safe', hint: '✓ 正常' },
  { id: 'event_density', label: '事件密度', current: 80, max: 100, status: 'safe', hint: '✓ 正常' },
  { id: 'era_fit', label: '时代契合', current: 2, max: 3, status: 'warning', hint: '⚠ 偏低' },
];

export const PRESET_NUMERIC_INDICATORS: AdjustmentIndicator[] = [
  { id: 'player_stamina', label: '玩家气力', current: 28, max: 100, status: 'danger', unit: '%', hint: '🔴 危险' },
];

export const PRESET_LAYERS: AdjustmentLayer[] = [
  {
    id: 'content',
    label: '内容层 — 卡组调整',
    priority: 1,
    indicators: PRESET_CONTENT_INDICATORS,
    triggerHint: '情感联结卡出现率→40%（连续3次无羁绊）',
  },
  {
    id: 'numeric',
    label: '数值层 — 自适应难度',
    priority: 2,
    indicators: PRESET_NUMERIC_INDICATORS,
    triggerHint: 'NPC态度主动示弱（气力28%<30%时）',
  },
];

export default AdjustmentPanel;
