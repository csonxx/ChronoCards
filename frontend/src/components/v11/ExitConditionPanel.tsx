// 退出条件面板 v1.1
// 规范来源：ChronoCards_UI_Design_v1.md §4

import React from 'react';
import './exit-condition-panel.css';

// ========== 退出条件项 ==========
export type ExitConditionStatus = 'completed' | 'active' | 'warning' | 'critical' | 'inactive';

export interface ExitCondition {
  id: string;
  label: string;
  status: ExitConditionStatus;
  current?: number;    // 当前值（如回合数）
  target?: number;    // 目标值（如10回合）
  description?: string;
}

interface ExitConditionPanelProps {
  round: number;           // 当前回合
  maxRound: number;        // 最大回合
  conditions: ExitCondition[];
  onVoluntaryExit?: () => void;  // 玩家主动退出回调
}

const STATUS_CONFIG: Record<ExitConditionStatus, {
  borderColor: string;
  bgColor: string;
  icon: string;
  label: string;
  animated: boolean;
}> = {
  completed: { borderColor: '#C23A2B', bgColor: '#1A1A1A', icon: '✓', label: '已完成', animated: false },
  active:    { borderColor: '#2D5A5A', bgColor: 'rgba(45,90,90,0.15)', icon: '●', label: '进行中', animated: false },
  warning:   { borderColor: '#D4A017', bgColor: 'rgba(212,160,23,0.15)', icon: '⚠', label: '警告', animated: true },
  critical:  { borderColor: '#C23A2B', bgColor: '#1A1A1A', icon: '🔴', label: '临界', animated: true },
  inactive:  { borderColor: '#8A8A8A', bgColor: 'transparent', icon: '○', label: '未触发', animated: false },
};

export const ExitConditionPanel: React.FC<ExitConditionPanelProps> = ({
  round,
  maxRound,
  conditions,
  onVoluntaryExit,
}) => {
  const roundProgress = maxRound > 0 ? (round / maxRound) * 100 : 0;

  // 回合警告等级
  const getRoundStatus = (): ExitConditionStatus => {
    if (round >= 10) return 'critical';
    if (round >= 7) return 'warning';
    return 'active';
  };

  const roundConfig = STATUS_CONFIG[getRoundStatus()];

  return (
    <div className="exit-condition-panel">
      {/* 章节进度条 */}
      <div className="chapter-progress">
        <div className="chapter-progress__label">章节进度</div>
        <div className="chapter-progress__track">
          <div
            className={`chapter-progress__fill ${roundConfig.animated ? 'chapter-progress__fill--pulse' : ''}`}
            style={{
              width: `${roundProgress}%`,
              background: `linear-gradient(90deg, #2D5A5A 0%, ${roundConfig.borderColor} 100%)`,
            }}
          />
        </div>
        <div className="chapter-progress__text">
          第 <strong>{round}</strong> / {maxRound} 回合
        </div>
      </div>

      {/* 退出条件卡片组 */}
      <div className="exit-conditions-grid">
        {conditions.map(cond => {
          const cfg = STATUS_CONFIG[cond.status];
          return (
            <div
              key={cond.id}
              className={[
                'exit-condition-card',
                cond.status === 'warning' ? 'exit-condition-card--warning' : '',
                cond.status === 'critical' ? 'exit-condition-card--critical' : '',
                cond.animated && cfg.animated ? `exit-condition-card--animated` : '',
              ].join(' ')}
              style={{ borderColor: cfg.borderColor, backgroundColor: cfg.bgColor }}
            >
              <div className="exit-condition-card__icon" style={{ color: cfg.borderColor }}>
                {cfg.icon === '●' ? (
                  <span className="progress-dot" style={{ backgroundColor: cfg.borderColor }} />
                ) : (
                  cfg.icon
                )}
              </div>
              <div className="exit-condition-card__body">
                <div className="exit-condition-card__label">{cond.label}</div>
                <div className="exit-condition-card__status" style={{ color: cfg.borderColor }}>
                  {cond.current !== undefined && cond.target !== undefined
                    ? `${cond.current}/${cond.target}`
                    : cfg.label}
                </div>
              </div>
            </div>
          );
        })}

        {/* 主动退出（次级按钮） */}
        <button
          className="exit-condition-card exit-condition-card--voluntary"
          onClick={onVoluntaryExit}
        >
          <div className="exit-condition-card__icon" style={{ color: '#8A8A8A' }}>○</div>
          <div className="exit-condition-card__body">
            <div className="exit-condition-card__label">主动退出</div>
            <div className="exit-condition-card__status" style={{ color: '#8A8A8A' }}>未触发</div>
          </div>
        </button>
      </div>

      {/* 回合警告说明 */}
      <div className="round-warning-legend">
        <div className="legend-item">
          <span className="legend-bar" style={{ backgroundColor: '#3D8B5F' }} />
          <span>1-6回合：安全</span>
        </div>
        <div className="legend-item">
          <span className="legend-bar legend-bar--warning" />
          <span>7-9回合：⚠️ 琥珀黄警告</span>
        </div>
        <div className="legend-item">
          <span className="legend-bar legend-bar--critical" />
          <span>第10回合：🔴 强制退出结算</span>
        </div>
      </div>
    </div>
  );
};

export default ExitConditionPanel;
