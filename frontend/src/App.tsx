// ChronoCards 主应用

import { useState, useCallback, useRef, useEffect } from 'react';
import './styles/global.css';
import { OpenWorld } from './components/world/OpenWorld';
import { CardDraw } from './components/card/CardDraw';
import { Battle } from './components/battle/Battle';
import { TutorialOverlay, shouldShowTutorial } from './components/tutorial/TutorialOverlay';
import { CardDrawGuide } from './components/tutorial/CardDrawGuide';
import { LandscapeWarning } from './components/mobile/LandscapeWarning';
import type { Card, CardOption, GameScene } from './types';
import { saveManager } from './services/save-system';
import { applyCardOptionEffect } from './services/card-effects';
import './App.css';

function App() {
  const [currentScene, setCurrentScene] = useState<GameScene>('world');
  const [currentCard, setCurrentCard] = useState<Card | null>(null);
  const [showCardDraw, setShowCardDraw] = useState(false);
  const [showTutorial, setShowTutorial] = useState(shouldShowTutorial);
  const [cardDrawGuideType, setCardDrawGuideType] = useState<string | null>(null);
  const [cardEffectResult, setCardEffectResult] = useState<ReturnType<typeof applyCardOptionEffect> | null>(null);
  const cardDrawGuideTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // 初始化存档
  useEffect(() => {
    // 尝试加载存档槽1，没有则创建新游戏
    const loaded = saveManager.loadGame(1) || saveManager.newGame(1, '江湖游侠');
    console.log('[App] Save loaded:', loaded.player.name, 'Lv.', loaded.player.level);
    // 启动自动保存（每60秒）
    saveManager.startAutoSave(60000);
    // 页面关闭前保存
    window.addEventListener('beforeunload', () => saveManager.save());
    return () => {
      saveManager.stopAutoSave();
      saveManager.save();
    };
  }, []);

  // 打开卡牌抽牌界面
  const handleCardDraw = useCallback((card: Card) => {
    setCurrentCard(card);
    setShowCardDraw(true);
    setCardEffectResult(null);
    // 显示卡牌抽取说明
    if (cardDrawGuideTimerRef.current) clearTimeout(cardDrawGuideTimerRef.current);
    cardDrawGuideTimerRef.current = setTimeout(() => {
      setCardDrawGuideType(card.type);
    }, 1200);
  }, []);

  // 关闭卡牌界面
  const handleCardClose = useCallback(() => {
    setShowCardDraw(false);
    setCurrentCard(null);
    setCardDrawGuideType(null);
    setCardEffectResult(null);
    if (cardDrawGuideTimerRef.current) {
      clearTimeout(cardDrawGuideTimerRef.current);
      cardDrawGuideTimerRef.current = null;
    }
  }, []);

  // 选择卡牌选项 → 应用效果
  const handleCardSelect = useCallback((option: CardOption, card: Card) => {
    const result = applyCardOptionEffect(option.text, card.rewards);
    setCardEffectResult(result);
    setShowCardDraw(false);
    setCurrentCard(null);
    setCardDrawGuideType(null);
    saveManager.onCardDrawn();
    if (card.id) saveManager.onCardTriggered(card.id);
    saveManager.save();

    // 根据效果决定后续场景
    if (result.sceneChange === 'battle' && result.battleConfig) {
      // 触发战斗
      setTimeout(() => setCurrentScene('battle'), 300);
    }
  }, []);

  // 战斗胜利 → 写存档 + 返回世界
  const handleVictory = useCallback(() => {
    saveManager.onBattleWon();
    saveManager.save();
    setCurrentScene('world');
  }, []);

  // 战斗失败 → 扣血 + 返回世界
  const handleDefeat = useCallback(() => {
    saveManager.updatePlayer(p => { p.hp = Math.floor(p.hp * 0.5); });
    saveManager.save();
    setCurrentScene('world');
  }, []);

  // 开始战斗
  const handleBattle = useCallback(() => {
    setCurrentScene('battle');
  }, []);

  // 战斗胜利
  const handleVictory = useCallback(() => {
    console.log('Victory!');
    setCurrentScene('world');
  }, []);

  // 战斗失败
  const handleDefeat = useCallback(() => {
    console.log('Defeat...');
    setCurrentScene('world');
  }, []);

  // 打开设置
  const handleSettings = useCallback(() => {
    setCurrentScene('settings');
  }, []);

  // 返回主世界
  const handleBackToWorld = useCallback(() => {
    setCurrentScene('world');
  }, []);

  // 教程完成回调
  const handleTutorialComplete = useCallback(() => {
    setShowTutorial(false);
  }, []);

  return (
    <div className="app paper-texture">
      {/* 横屏锁定提示 */}
      <LandscapeWarning enabled={true} />

      {/* 新手引导 */}
      {showTutorial && (
        <TutorialOverlay onComplete={handleTutorialComplete} />
      )}

      {/* S2: 开放世界 */}
      {currentScene === 'world' && !showCardDraw && (
        <OpenWorld
          onCardDraw={handleCardDraw}
          onBattle={handleBattle}
          onSettings={handleSettings}
        />
      )}

      {/* S3: 抽牌界面 */}
      {showCardDraw && currentCard && (
        <>
          {/* 卡牌抽取说明 */}
          {cardDrawGuideType && (
            <CardDrawGuide
              cardType={cardDrawGuideType}
              onClose={() => setCardDrawGuideType(null)}
              autoHideMs={5000}
            />
          )}
          <CardDraw
            card={currentCard}
            onSelect={handleCardSelect}
            onClose={handleCardClose}
          />
        </>
      )}

      {/* S5: 战斗界面 */}
      {currentScene === 'battle' && (
        <Battle
          onVictory={handleVictory}
          onDefeat={handleDefeat}
        />
      )}

      {/* 设置界面（简化版） */}
      {currentScene === 'settings' && (
        <div className="settings-overlay">
          <div className="settings-panel">
            <h2 className="settings-title">设置</h2>
            <div className="settings-section">
              <div className="settings-item">
                <span>音量</span>
                <input type="range" min="0" max="100" defaultValue={70} />
              </div>
              <div className="settings-item">
                <span>文字速度</span>
                <select defaultValue="fast">
                  <option value="slow">慢</option>
                  <option value="normal">中</option>
                  <option value="fast">快</option>
                </select>
              </div>
              <div className="settings-item">
                <span>战斗动画</span>
                <input type="checkbox" defaultChecked />
              </div>
            </div>
            <button
              className="settings-back-btn scroll-button scroll-button--md"
              onClick={handleBackToWorld}
            >
              返回
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
