// ChronoCards 主应用

import { useState, useCallback } from 'react';
import './styles/global.css';
import { OpenWorld } from './components/world/OpenWorld';
import { CardDraw } from './components/card/CardDraw';
import { Battle } from './components/battle/Battle';
import type { Card, CardOption, GameScene } from './types';
import './App.css';

function App() {
  const [currentScene, setCurrentScene] = useState<GameScene>('world');
  const [currentCard, setCurrentCard] = useState<Card | null>(null);
  const [showCardDraw, setShowCardDraw] = useState(false);

  // 打开卡牌抽牌界面
  const handleCardDraw = useCallback((card: Card) => {
    setCurrentCard(card);
    setShowCardDraw(true);
  }, []);

  // 关闭卡牌界面
  const handleCardClose = useCallback(() => {
    setShowCardDraw(false);
    setCurrentCard(null);
  }, []);

  // 选择卡牌选项
  const handleCardSelect = useCallback((option: CardOption) => {
    console.log('Selected option:', option);
    setShowCardDraw(false);
    setCurrentCard(null);
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

  // 撤退 (暂未使用)
  // const handleEscape = useCallback(() => {
  //   setCurrentScene('world');
  // }, []);

  // 打开设置
  const handleSettings = useCallback(() => {
    setCurrentScene('settings');
  }, []);

  // 返回主世界
  const handleBackToWorld = useCallback(() => {
    setCurrentScene('world');
  }, []);

  return (
    <div className="app paper-texture">
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
        <CardDraw
          card={currentCard}
          onSelect={handleCardSelect}
          onClose={handleCardClose}
        />
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
