// ChronoCards 主应用

import { useState, useCallback, useRef, useEffect } from 'react';
import './styles/global.css';
import { OpenWorld } from './components/world/OpenWorld';
import { CardDraw } from './components/card/CardDraw';
import { Battle } from './components/battle/Battle';
import { TutorialOverlay, shouldShowTutorial } from './components/tutorial/TutorialOverlay';
import { CardDrawGuide } from './components/tutorial/CardDrawGuide';
import { LandscapeWarning } from './components/mobile/LandscapeWarning';
import { NarrativePanel, type NarrativeData } from './components/narrative/NarrativePanel';
import { narrativeWS } from './services/websocket';
import type { Card, CardOption, GameScene } from './types';
import { saveManager } from './services/save-system';
import { applyCardOptionEffect, applyBattleVictoryRewards, rewardsToDisplay } from './services/card-effects';
import type { RewardDisplay } from './services/card-effects';
import './App.css';

function App() {
  const [currentScene, setCurrentScene] = useState<GameScene>('world');
  const [currentCard, setCurrentCard] = useState<Card | null>(null);
  const [showCardDraw, setShowCardDraw] = useState(false);
  const [showTutorial, setShowTutorial] = useState(shouldShowTutorial);
  const [cardDrawGuideType, setCardDrawGuideType] = useState<string | null>(null);
  const [cardEffectResult, setCardEffectResult] = useState<ReturnType<typeof applyCardOptionEffect> | null>(null);
  const [narrativeData, setNarrativeData] = useState<NarrativeData | null>(null);
  const [victoryRewards, setVictoryRewards] = useState<RewardDisplay[]>([]);
  const [showVictoryPanel, setShowVictoryPanel] = useState(false);
  const cardDrawGuideTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const bgmRef = useRef<HTMLAudioElement | null>(null);

  // 初始化存档
  useEffect(() => {
    // 尝试加载存档槽1，没有则创建新游戏
    const loaded = saveManager.loadGame(1) || saveManager.newGame(1, '江湖游侠');
    console.log('[App] Save loaded:', loaded.player.name, 'Lv.', loaded.player.level);
    // 启动自动保存（每60秒）
    saveManager.startAutoSave(60000);
    // 页面关闭前保存
    window.addEventListener('beforeunload', () => saveManager.save());

    // 连接 WebSocket 监听叙事事件
    narrativeWS.onNarrative((data) => {
      console.log('[App] Narrative event:', data);
      setNarrativeData(data);
    });

    // 建立连接
    narrativeWS.connect().catch(err => {
      console.warn('[App] WS connect failed (running without server):', err);
    });

    // 播放背景音乐
    const bgm = new Audio('/assets/audio/world_bgm.mp3');
    bgm.loop = true;
    bgm.volume = 0.25;
    bgm.play().catch(() => {}); // autoplay may be blocked
    bgmRef.current = bgm;

    return () => {
      saveManager.stopAutoSave();
      saveManager.save();
      narrativeWS.disconnect();
    };
  }, []);

  // 打开卡牌抽牌界面
  const handleCardDraw = useCallback((card: Card) => {
    setCurrentCard(card);
    setShowCardDraw(true);
    const sfx = new Audio('/assets/audio/card_draw.mp3'); sfx.volume = 0.5; sfx.play().catch(() => {});
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

  // 开始战斗
  const handleBattle = useCallback(() => {
    setCurrentScene('battle');
  }, []);

  // 战斗胜利
  const handleVictory = useCallback(() => {
    console.log('Victory!');
    // 应用战斗奖励
    const result = applyBattleVictoryRewards();
    const rewards = rewardsToDisplay({ exp: 50 });
    setVictoryRewards(rewards);
    setShowVictoryPanel(true);
    // 播放胜利音效
    const sfx = new Audio('/assets/audio/quest_complete.mp3');
    sfx.volume = 0.6;
    sfx.play().catch(() => {});
    // 3秒后自动关闭奖励面板并返回地图
    setTimeout(() => {
      setShowVictoryPanel(false);
      setCurrentScene('world');
    }, 3000);
  }, []);

  // 战斗失败
  const handleDefeat = useCallback(() => {
    console.log('Defeat...');
    setCurrentScene('world');
  }, []);

  // 打开设置
  const handleSettings = useCallback(() => {
    setCurrentScene('settings');
    // TODO(QA-P1): 势力声望UI - 打开设置时可改为打开势力面板 - 发现日期 2026-04-15
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

      {/* 战斗胜利奖励面板 */}
      {showVictoryPanel && (
        <div className="victory-overlay">
          <div className="victory-panel">
            <div className="victory-title">🎉 战斗胜利！</div>
            <div className="victory-rewards">
              {victoryRewards.map((r, i) => (
                <div key={i} className="victory-reward-item">
                  <span className="victory-reward-icon">{r.icon}</span>
                  <span className="victory-reward-label">{r.label}</span>
                  <span className="victory-reward-value">{r.value}</span>
                </div>
              ))}
              <div className="victory-reward-item">
                <span className="victory-reward-icon">✨</span>
                <span className="victory-reward-label">经验</span>
                <span className="victory-reward-value">+50</span>
              </div>
            </div>
            <div className="victory-hint">3秒后返回地图...</div>
          </div>
        </div>
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

      {/* LLM 叙事面板 */}
      <NarrativePanel
        data={narrativeData}
        onDismiss={() => setNarrativeData(null)}
      />
    </div>
  );
}

export default App;
