// 兼容矩阵可视化组件 v1.1
// 规范来源：ChronoCards_UI_Design_v1.md §3

import React, { useState } from 'react';
import './compatibility-matrix.css';

export type CardType =
  | 'main_story'
  | 'emotion'
  | 'side_story'
  | 'fate'
  | 'era'
  | 'mechanic'
  | 'stat_up'
  | 'economy'
  | 'blank';

export interface CardTypeInfo {
  type: CardType;
  label: string;
  icon: string;
  color: string;
  borderColor: string;
}

// 9大卡牌类型配置
export const CARD_TYPE_LIST: CardTypeInfo[] = [
  { type: 'main_story', label: '主线', icon: '🐉', color: '#C23A2B', borderColor: '#D4AF37' },
  { type: 'emotion',   label: '情感', icon: '🔗', color: '#D4606A', borderColor: '#8B7355' },
  { type: 'side_story', label: '支线', icon: '📜', color: '#2D5A5A', borderColor: '#A9A9A9' },
  { type: 'fate',       label: '命运', icon: '⚡', color: '#4A3A5C', borderColor: '#6B4C7A' },
  { type: 'era',        label: '时代', icon: '🏮', color: '#D4A017', borderColor: '#8B6914' },
  { type: 'mechanic',   label: '机制', icon: '⚙️', color: '#4A6FA5', borderColor: '#5C7DA3' },
  { type: 'stat_up',    label: '数值', icon: '📈', color: '#3D8B5F', borderColor: '#2D6B4F' },
  { type: 'economy',    label: '经济', icon: '💰', color: '#8B6914', borderColor: '#A67C00' },
  { type: 'blank',      label: '空白⭐', icon: '🎭', color: '#E8E4DC', borderColor: '#C0C0C0' },
];

// 兼容矩阵核心数据（v1.1 审核通过版）
// ✓=可叠加  ✗=互斥  —=自身
type CellValue = 'compatible' | 'exclusive' | 'self' | 'unknown';

const MATRIX: Record<CardType, Record<CardType, CellValue>> = {
  main_story: {
    main_story: 'self', emotion: 'exclusive', side_story: 'exclusive',
    fate: 'exclusive', era: 'exclusive', mechanic: 'exclusive',
    stat_up: 'exclusive', economy: 'exclusive', blank: 'compatible',
  },
  emotion: {
    main_story: 'exclusive', emotion: 'self', side_story: 'compatible',
    fate: 'exclusive', era: 'compatible', mechanic: 'compatible',
    stat_up: 'compatible', economy: 'compatible', blank: 'compatible',
  },
  side_story: {
    main_story: 'exclusive', emotion: 'compatible', side_story: 'self',
    fate: 'compatible', era: 'compatible', mechanic: 'compatible',
    stat_up: 'compatible', economy: 'compatible', blank: 'compatible',
  },
  fate: {
    main_story: 'exclusive', emotion: 'exclusive', side_story: 'compatible',
    fate: 'self', era: 'compatible', mechanic: 'compatible',
    stat_up: 'exclusive', economy: 'compatible', blank: 'compatible',
  },
  era: {
    main_story: 'exclusive', emotion: 'compatible', side_story: 'compatible',
    fate: 'compatible', era: 'self', mechanic: 'compatible',
    stat_up: 'compatible', economy: 'compatible', blank: 'compatible',
  },
  mechanic: {
    main_story: 'exclusive', emotion: 'compatible', side_story: 'compatible',
    fate: 'compatible', era: 'compatible', mechanic: 'self',
    stat_up: 'compatible', economy: 'compatible', blank: 'compatible',
  },
  stat_up: {
    main_story: 'exclusive', emotion: 'compatible', side_story: 'compatible',
    fate: 'exclusive', era: 'compatible', mechanic: 'compatible',
    stat_up: 'self', economy: 'exclusive', blank: 'compatible',
  },
  economy: {
    main_story: 'exclusive', emotion: 'compatible', side_story: 'compatible',
    fate: 'compatible', era: 'compatible', mechanic: 'compatible',
    stat_up: 'exclusive', economy: 'self', blank: 'compatible',
  },
  blank: {
    main_story: 'compatible', emotion: 'compatible', side_story: 'compatible',
    fate: 'compatible', era: 'compatible', mechanic: 'compatible',
    stat_up: 'compatible', economy: 'compatible', blank: 'self',
  },
};

// 获取当前选中卡与目标卡的兼容关系
export function getCompatibility(selected: CardType, target: CardType): CellValue {
  if (selected === target) return 'self';
  return MATRIX[selected]?.[target] ?? 'unknown';
}

// 检查一组已选卡是否与目标卡兼容
export function areAllCompatible(selected: CardType[], target: CardType): boolean {
  return selected.every(s => getCompatibility(s, target) !== 'exclusive');
}

interface CompatibilityMatrixProps {
  selectedTypes: CardType[];           // 当前已选中的卡类型
  onTypeClick?: (type: CardType) => void; // 点击类型切换选中
  compact?: boolean;                  // 紧凑模式（手机用）
}

export const CompatibilityMatrix: React.FC<CompatibilityMatrixProps> = ({
  selectedTypes,
  onTypeClick,
  compact = false,
}) => {
  const [hoveredCell, setHoveredCell] = useState<{ row: CardType; col: CardType } | null>(null);

  const getCellClass = (rowType: CardType, colType: CardType): string => {
    const val = getCompatibility(rowType, colType);
    const classes = ['matrix-cell'];
    if (val === 'compatible') classes.push('matrix-cell--compatible');
    if (val === 'exclusive') classes.push('matrix-cell--exclusive');
    if (val === 'self') classes.push('matrix-cell--self');
    if (selectedTypes.includes(rowType)) classes.push('matrix-cell--selected-row');
    if (selectedTypes.includes(colType)) classes.push('matrix-cell--selected-col');
    if (hoveredCell?.row === rowType || hoveredCell?.col === colType) classes.push('matrix-cell--hovered');
    return classes.join(' ');
  };

  const getCellContent = (rowType: CardType, colType: CardType): React.ReactNode => {
    const val = getCompatibility(rowType, colType);
    if (val === 'self') return '—';
    if (val === 'compatible') return '✓';
    if (val === 'exclusive') return '✗';
    return '?';
  };

  const selected = selectedTypes[selectedTypes.length - 1]; // 最新选中

  return (
    <div className={`compatibility-matrix ${compact ? 'compatibility-matrix--compact' : ''}`}>
      <div className="matrix-header">
        <div className="matrix-title">卡牌兼容矩阵</div>
        {selected && (
          <div className="matrix-selected-label">
            当前已选：<span style={{ color: CARD_TYPE_LIST.find(t => t.type === selected)?.color }}>{CARD_TYPE_LIST.find(t => t.type === selected)?.label}</span>
          </div>
        )}
      </div>

      <div className="matrix-scroll-wrapper">
        <table className="matrix-table" role="grid">
          <thead>
            <tr>
              <th className="matrix-corner" />
              {CARD_TYPE_LIST.map(t => (
                <th key={t.type} className="matrix-col-header" style={{ color: t.color }}>
                  <span className="matrix-col-icon">{t.icon}</span>
                  {!compact && <span className="matrix-col-label">{t.label}</span>}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {CARD_TYPE_LIST.map(row => (
              <tr key={row.type}>
                <td className="matrix-row-header" style={{ color: row.color }}>
                  <span className="matrix-row-icon">{row.icon}</span>
                  {!compact && <span className="matrix-row-label">{row.label}</span>}
                </td>
                {CARD_TYPE_LIST.map(col => (
                  <td
                    key={col.type}
                    className={getCellClass(row.type, col.type)}
                    onMouseEnter={() => setHoveredCell({ row: row.type, col: col.type })}
                    onMouseLeave={() => setHoveredCell(null)}
                    onClick={() => onTypeClick?.(row.type)}
                    role="gridcell"
                    aria-label={`${row.label} × ${col.label}: ${getCompatibility(row.type, col.type)}`}
                  >
                    <span className="matrix-cell-content">{getCellContent(row.type, col.type)}</span>
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* 图例 */}
      <div className="matrix-legend">
        <div className="legend-item">
          <span className="legend-dot legend-dot--compatible">✓</span>
          <span>可叠加</span>
        </div>
        <div className="legend-item">
          <span className="legend-dot legend-dot--exclusive">✗</span>
          <span>互斥</span>
        </div>
        <div className="legend-item">
          <span className="legend-dot legend-dot--self">—</span>
          <span>自身</span>
        </div>
        <div className="legend-item">
          <span className="legend-dot legend-dot--star">⭐</span>
          <span>不占2张上限</span>
        </div>
      </div>

      {/* 兼容提示 */}
      {selected && (
        <div className="matrix-compatibility-hint">
          {selectedTypes.length > 0 && (
            <span className="hint-text">
              当前生效卡：
              {selectedTypes.map(t => {
                const info = CARD_TYPE_LIST.find(x => x.type === t)!;
                return (
                  <span key={t} className="active-card-tag" style={{ borderColor: info.color, color: info.color }}>
                    {info.icon} {info.label}
                  </span>
                );
              })}
            </span>
          )}
        </div>
      )}
    </div>
  );
};

export default CompatibilityMatrix;
