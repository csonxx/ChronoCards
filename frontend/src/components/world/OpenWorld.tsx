// S2: 开放世界界面 - 主场景

import React, { useState, useCallback } from 'react';
import { TopBar, CardProgress, ScrollPanel } from '../ui';
import type { Dealer, Card, Region } from '../../types';
import './world.css';

// 模拟发牌员数据
const mockDealers: Dealer[] = [
  { id: 'd1', name: '茶馆说书人', type: 'teahouse', position: { x: 200, y: 150 } },
  { id: 'd2', name: '悬赏公告栏', type: 'billboard', position: { x: 400, y: 300 } },
  { id: 'd3', name: '客栈掌柜', type: 'inn', position: { x: 300, y: 400 } },
  { id: 'd4', name: '神秘商贩', type: 'merchant', position: { x: 500, y: 200 } },
  { id: 'd5', name: '巡逻敌人', type: 'enemy', position: { x: 150, y: 350 } },
];

const mockRecentCards = ['支线', '成长', '主线'];

interface OpenWorldProps {
  onCardDraw: (card: Card) => void;
  onBattle: () => void;
  onSettings: () => void;
  playerName?: string;
  currentChapter?: string;
}

export const OpenWorld: React.FC<OpenWorldProps> = ({
  onCardDraw,
  onBattle,
  onSettings,
  playerName = '江湖游侠',
  currentChapter = '第一章',
}) => {
  const [playerPos, setPlayerPos] = useState({ x: 300, y: 250 });
  const [nearbyDealer, setNearbyDealer] = useState<Dealer | null>(null);
  const [currentRegion] = useState<Region>('zhongyuan');
  const [cardProgress] = useState({ current: 3, total: 10 });

  // 检测附近发牌员
  const checkNearbyDealers = useCallback((pos: { x: number; y: number }) => {
    const interactRange = 60;
    const found = mockDealers.find(dealer => {
      const dx = dealer.position.x - pos.x;
      const dy = dealer.position.y - pos.y;
      return Math.sqrt(dx * dx + dy * dy) < interactRange;
    });
    setNearbyDealer(found || null);
  }, []);

  // 移动玩家
  const handleMapClick = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const newPos = {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top,
    };
    setPlayerPos(newPos);
    checkNearbyDealers(newPos);
  }, [checkNearbyDealers]);

  // 与发牌员交互
  const handleInteract = useCallback(() => {
    if (nearbyDealer) {
      if (nearbyDealer.type === 'enemy') {
        onBattle();
      } else {
        // 生成模拟卡牌
        const mockCard: Card = {
          id: `card-${Date.now()}`,
          type: nearbyDealer.type === 'teahouse' ? 'side' : 'growth',
          title: nearbyDealer.type === 'teahouse' ? '江湖传闻' : '奇遇发现',
          description: `你在${nearbyDealer.name}处听闻了一桩江湖轶事...`,
          triggered: false,
          options: [
            { id: 'o1', text: '欣然接受' },
            { id: 'o2', text: '婉言谢绝' },
            { id: 'o3', text: '追问详情' },
          ],
        };
        onCardDraw(mockCard);
      }
    }
  }, [nearbyDealer, onCardDraw, onBattle]);

  // 键盘移动
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    const step = 20;
    let dx = 0, dy = 0;
    
    switch (e.key) {
      case 'ArrowUp':
      case 'w':
      case 'W':
        dy = -step;
        break;
      case 'ArrowDown':
      case 's':
      case 'S':
        dy = step;
        break;
      case 'ArrowLeft':
      case 'a':
      case 'A':
        dx = -step;
        break;
      case 'ArrowRight':
      case 'd':
      case 'D':
        dx = step;
        break;
      case 'e':
      case 'E':
        if (nearbyDealer) handleInteract();
        return;
      default:
        return;
    }
    
    e.preventDefault();
    const newPos = {
      x: Math.max(20, Math.min(580, playerPos.x + dx)),
      y: Math.max(20, Math.min(380, playerPos.y + dy)),
    };
    setPlayerPos(newPos);
    checkNearbyDealers(newPos);
  }, [playerPos, nearbyDealer, handleInteract, checkNearbyDealers]);

  const regionNames: Record<Region, string> = {
    zhongyuan: '中原武林',
    jiangnan: '江南水乡',
    xibei: '西北边塞',
    xinan: '西南苗疆',
    donghai: '东海侠客岛',
  };

  return (
    <div className="open-world" tabIndex={0} onKeyDown={handleKeyDown}>
      {/* 顶部栏 */}
      <TopBar
        title="ChronoCards"
        subtitle={`${playerName} · ${currentChapter}`}
        onSettingsClick={onSettings}
      />

      <div className="open-world__container">
        {/* 左侧卷轴地图 */}
        <aside className="open-world__sidebar">
          <ScrollPanel title="九州舆图">
            <div className="open-world__mini-map">
              <div className="mini-map__region mini-map__region--active">
                <span className="region-name">{regionNames[currentRegion]}</span>
                <div className="player-marker" style={{ left: `${(playerPos.x / 600) * 100}%`, top: `${(playerPos.y / 400) * 100}%` }} />
              </div>
              <div className="mini-map__locations">
                {mockDealers.map(dealer => (
                  <div
                    key={dealer.id}
                    className={`location-marker location-marker--${dealer.type}`}
                    style={{ left: `${(dealer.position.x / 600) * 100}%`, top: `${(dealer.position.y / 400) * 100}%` }}
                    title={dealer.name}
                  />
                ))}
              </div>
            </div>
            <div className="open-world__region-info">
              <span className="region-label">当前位置</span>
              <span className="region-value">{regionNames[currentRegion]} · 华山脚下</span>
            </div>
          </ScrollPanel>
        </aside>

        {/* 主显示区 - 江湖场景 */}
        <main className="open-world__main">
          <div className="world-scene" onClick={handleMapClick}>
            {/* 水墨山水背景 */}
            <div className="world-scene__background">
              <div className="ink-mountain ink-mountain--1" />
              <div className="ink-mountain ink-mountain--2" />
              <div className="ink-mountain ink-mountain--3" />
              <div className="ink-water" />
              <div className="ink-trees">
                {[...Array(8)].map((_, i) => (
                  <div key={i} className="ink-tree" style={{ left: `${10 + i * 12}%`, animationDelay: `${i * 0.2}s` }} />
                ))}
              </div>
            </div>

            {/* 发牌员 */}
            {mockDealers.map(dealer => (
              <div
                key={dealer.id}
                className={`dealer dealer--${dealer.type}`}
                style={{ left: dealer.position.x, top: dealer.position.y }}
              >
                <div className="dealer__sprite">
                  {dealer.type === 'enemy' ? '⚔️' : dealer.type === 'teahouse' ? '🍵' : dealer.type === 'billboard' ? '📜' : dealer.type === 'inn' ? '🏨' : '💰'}
                </div>
                <span className="dealer__name">{dealer.name}</span>
              </div>
            ))}

            {/* 玩家 */}
            <div
              className="player"
              style={{ left: playerPos.x, top: playerPos.y }}
            >
              <div className="player__sprite">🧑</div>
              <div className="player__shadow" />
            </div>

            {/* 交互提示 */}
            {nearbyDealer && (
              <div className="interaction-prompt">
                <div className="prompt__scroll">
                  <span className="prompt__text">
                    {nearbyDealer.type === 'enemy' ? '⚔️ 遭遇敌人！' : `📜 与 ${nearbyDealer.name} 交谈`}
                  </span>
                  <span className="prompt__key">[E]</span>
                </div>
              </div>
            )}
          </div>
        </main>
      </div>

      {/* 底部卡组预览条 */}
      <footer className="open-world__footer">
        <div className="footer__card-progress">
          <span className="footer__label">抽牌进度</span>
          <CardProgress
            current={cardProgress.current}
            total={cardProgress.total}
            recentCards={mockRecentCards}
          />
        </div>
        <div className="footer__controls">
          <span className="footer__hint">WASD/方向键移动 · E交互</span>
        </div>
      </footer>
    </div>
  );
};

export default OpenWorld;
