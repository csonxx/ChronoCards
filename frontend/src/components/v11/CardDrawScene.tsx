// v1.1 抽卡场景 - 整合所有UI组件
// 规范来源：ChronoCards_UI_Design_v1.md 全章节

import React, { useState, useCallback } from 'react';
import {
  EventCard,
  CompatibilityMatrix,
  ExitConditionPanel,
  AdjustmentPanel,
  PRESET_LAYERS,
  type CardType,
  type EventCardData,
  type CardOption,
  type ExitCondition,
  type AdjustmentLayer,
} from './index';
import './card-draw-scene.css';

interface CardDrawSceneProps {
  initialCard?: EventCardData;
  selectedTypes?: CardType[];
  round?: number;
  maxRound?: number;
  onCardSelect?: (option: CardOption, card: EventCardData) => void;
  onClose?: () => void;
  onVoluntaryExit?: () => void;
}

export const CardDrawScene: React.FC<CardDrawSceneProps> = ({
  initialCard,
  selectedTypes = [],
  round = 1,
  maxRound = 10,
  onCardSelect,
  onClose,
  onVoluntaryExit,
}) => {
  const [currentCard, setCurrentCard] = useState<EventCardData | null>(initialCard || null);
  const [isAnimating, setIsAnimating] = useState(false);
  const [compatibilityResult, setCompatibilityResult] = useState<'compatible' | 'exclusive' | 'forced' | null>(null);
  const [showMatrix, setShowMatrix] = useState(false);
  const [showExitPanel, setShowExitPanel] = useState(false);
  const [activeTypes, setActiveTypes] = useState<CardType[]>(selectedTypes);
  const [panelsTab, setPanelsTab] = useState<'exit' | 'adjust'>('exit');

  // 预设退出条件
  const exitConditions: ExitCondition[] = [
    { id: 'main_complete', label: '主线完成', status: 'inactive' },
    { id: 'char_alive', label: '角色存活', status: 'active' },
    { id: 'round_limit', label: '回合限制', status: round >= 7 ? (round >= 10 ? 'critical' : 'warning') : 'active', current: round, target: maxRound },
    { id: 'voluntary', label: '主动退出', status: 'inactive' },
  ];

  // 触发抽卡动画
  const triggerDraw = useCallback(() => {
    if (!currentCard) return;
    setIsAnimating(true);
    setCompatibilityResult(null);
    // 动画结束后显示结果
    setTimeout(() => {
      setIsAnimating(false);
      // 模拟兼容判定（实际应由引擎返回）
      const isCompatible = activeTypes.every(t => {
        const COMPATIBLE = ['emotion', 'side_story', 'era', 'mechanic', 'blank'];
        return COMPATIBLE.includes(t) || t === currentCard.type;
      });
      setCompatibilityResult(isCompatible ? 'compatible' : 'exclusive');
    }, 2000);
  }, [currentCard, activeTypes]);

  // 选择选项
  const handleCardSelect = useCallback((option: CardOption) => {
    if (!currentCard) return;
    onCardSelect?.(option, currentCard);
    // 重置状态
    setCurrentCard(null);
    setCompatibilityResult(null);
    setIsAnimating(false);
  }, [currentCard, onCardSelect]);

  // 关闭
  const handleClose = useCallback(() => {
    setCurrentCard(null);
    setCompatibilityResult(null);
    setIsAnimating(false);
    onClose?.();
  }, [onClose]);

  return (
    <div className="card-draw-scene">
      {/* ========== 顶部信息栏 ========== */}
      <header className="scene-topbar">
        <div className="scene-topbar__left">
          <span className="scene-round">⚔️ 第 {round} 回合</span>
        </div>
        <div className="scene-topbar__center">
          <span className="scene-era">🏮 明朝 · 万历</span>
        </div>
        <div className="scene-topbar__right">
          <div className="scene-resource">
            <span className="resource-label">🔗 羁绊值</span>
            <div className="resource-bar">
              <div className="resource-fill resource-fill--bond" style={{ width: '80%' }} />
            </div>
          </div>
          <div className="scene-resource">
            <span className="resource-label">❤️ 气力</span>
            <div className="resource-bar">
              <div className="resource-fill resource-fill--hp" style={{ width: '72%' }} />
            </div>
          </div>
        </div>
        <button className="scene-menu-btn">≡ 菜单</button>
      </header>

      {/* ========== 主内容区 ========== */}
      <main className="scene-main">
        {/* 左侧：当前抽到的事件卡 */}
        <section className="scene-card-area">
          {currentCard ? (
            <EventCard
              card={currentCard}
              options={currentCard.options || []}
              isAnimating={isAnimating}
              compatibilityResult={compatibilityResult}
              onSelect={handleCardSelect}
              onClose={handleClose}
            />
          ) : (
            <div className="scene-empty">
              <div className="scene-empty__deck">
                <span className="deck-icon">🀄</span>
                <span className="deck-label">牌堆</span>
              </div>
              <button className="scene-draw-btn" onClick={triggerDraw}>
                抽 下一张
              </button>
            </div>
          )}
        </section>

        {/* 右侧面板区（桌面端） */}
        <aside className="scene-side-panel">
          {/* 已生效/待生效卡 */}
          <div className="scene-active-cards">
            <div className="active-cards-section">
              <div className="section-label">✓ 已生效</div>
              <div className="mini-cards-row">
                {activeTypes.map(t => (
                  <div key={t} className={`mini-card mini-card--${t}`}>{t.slice(0, 2)}</div>
                ))}
                {activeTypes.length === 0 && <span className="empty-hint">暂无</span>}
              </div>
            </div>
            <div className="active-cards-section">
              <div className="section-label">⏳ 待生效</div>
              <div className="mini-cards-row">
                <span className="empty-hint">抽卡后展示</span>
              </div>
            </div>
          </div>

          {/* 兼容矩阵切换 */}
          <button
            className={`panel-toggle-btn ${showMatrix ? 'panel-toggle-btn--active' : ''}`}
            onClick={() => setShowMatrix(v => !v)}
          >
            📊 {showMatrix ? '收起' : ''}卡组概览
          </button>

          {showMatrix && (
            <div className="scene-matrix-wrapper">
              <CompatibilityMatrix
                selectedTypes={activeTypes}
                compact={true}
              />
            </div>
          )}

          {/* 底部面板切换：退出条件 / 调整阈值 */}
          <div className="scene-panel-tabs">
            <button
              className={`tab-btn ${panelsTab === 'exit' ? 'tab-btn--active' : ''}`}
              onClick={() => { setPanelsTab('exit'); setShowExitPanel(v => !v); }}
            >
              📋 退出条件
            </button>
            <button
              className={`tab-btn ${panelsTab === 'adjust' ? 'tab-btn--active' : ''}`}
              onClick={() => { setPanelsTab('adjust'); setShowExitPanel(v => !v); }}
            >
              📈 调整阈值
            </button>
          </div>

          {showExitPanel && panelsTab === 'exit' && (
            <ExitConditionPanel
              round={round}
              maxRound={maxRound}
              conditions={exitConditions}
              onVoluntaryExit={onVoluntaryExit}
            />
          )}

          {showExitPanel && panelsTab === 'adjust' && (
            <AdjustmentPanel layers={PRESET_LAYERS} currentChapter="第一章" eraName="明朝·万历" />
          )}
        </aside>
      </main>

      {/* ========== 底部操作区 ========== */}
      <footer className="scene-footer">
        <button className="scene-action-btn">
          <span className="action-icon">📜</span>
          <span className="action-label">正面解读</span>
        </button>
        <button className="scene-action-btn">
          <span className="action-icon">📖</span>
          <span className="action-label">负面变奏</span>
        </button>
        <button className="scene-action-btn scene-action-btn--primary" onClick={triggerDraw}>
          <span className="action-icon">🎴</span>
          <span className="action-label">抽下一张</span>
        </button>
        <button
          className="scene-action-btn"
          onClick={() => { setShowMatrix(v => !v); setPanelsTab('exit'); setShowExitPanel(true); }}
        >
          <span className="action-icon">📋</span>
          <span className="action-label">卡组概览</span>
        </button>
      </footer>
    </div>
  );
};

export default CardDrawScene;
