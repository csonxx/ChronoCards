// S2: 开放世界界面 - 主场景

import React, { useState, useCallback, useRef } from 'react';
import { TopBar, CardProgress, ScrollPanel } from '../ui';
import { MobileControls, isMobile } from '../mobile/MobileControls';
import { PlayerContextMenu } from '../tutorial/PlayerContextMenu';
import type { Dealer, Card, Region } from '../../types';
import './world.css';

// 区域 → 场景立绘映射（5场景×3变体轮播）
const REGION_SCENE_MAP: Record<Region, string[]> = {
  zhongyuan: ['--asset-scene-01-1', '--asset-scene-01-2', '--asset-scene-01-3'],
  jiangnan:  ['--asset-scene-02-1', '--asset-scene-02-2', '--asset-scene-02-3'],
  xibei:    ['--asset-scene-03-1', '--asset-scene-03-2', '--asset-scene-03-3'],
  xinan:    ['--asset-scene-04-1', '--asset-scene-04-2', '--asset-scene-04-3'],
  donghai:  ['--asset-scene-05-1', '--asset-scene-05-2', '--asset-scene-05-3'],
};

// 门派 → 角色立绘映射（10门派×3姿态）
export const SECT_CHAR_MAP: Record<string, string[]> = {
  shaolin:    ['--asset-char-shaolin-1',    '--asset-char-shaolin-2',    '--asset-char-shaolin-3'],
  emei:       ['--asset-char-emei-1',       '--asset-char-emei-2',       '--asset-char-emei-3'],
  wudang:     ['--asset-char-wudang-1',     '--asset-char-wudang-2',     '--asset-char-wudang-3'],
  tang:       ['--asset-char-tang-1',       '--asset-char-tang-2',       '--asset-char-tang-3'],
  gaibang:    ['--asset-char-gaibang-1',    '--asset-char-gaibang-2',    '--asset-char-gaibang-3'],
  mingjiao:   ['--asset-char-mingjiao-1',   '--asset-char-mingjiao-2',   '--asset-char-mingjiao-3'],
  huashan:    ['--asset-char-huashan-1',    '--asset-char-huashan-2',    '--asset-char-huashan-3'],
  luoyang:    ['--asset-char-luoyang-1',    '--asset-char-luoyang-2',    '--asset-char-luoyang-3'],
  shadowfang: ['--asset-char-shadowfang-1', '--asset-char-shadowfang-2', '--asset-char-shadowfang-3'],
  peacock:    ['--asset-char-peacock-1',    '--asset-char-peacock-2',    '--asset-char-peacock-3'],
};

// 模拟发牌员数据
const mockDealers: Dealer[] = [
  { id: 'd1', name: '茶馆说书人', type: 'teahouse', position: { x: 200, y: 150 } },
  { id: 'd2', name: '悬赏公告栏', type: 'billboard', position: { x: 400, y: 300 } },
  { id: 'd3', name: '客栈掌柜', type: 'inn', position: { x: 300, y: 400 } },
  { id: 'd4', name: '神秘商贩', type: 'merchant', position: { x: 500, y: 200 } },
  { id: 'd5', name: '巡逻敌人', type: 'enemy', position: { x: 150, y: 350 } },
];

const mockRecentCards = ['支线', '成长', '主线'];

// 发牌员交互提示文案
const DEALER_HINTS: Record<string, { near: string; label: string }> = {
  teahouse: { near: '点击这里和说书人对话', label: '📜 听江湖传闻' },
  billboard: { near: '点击这里查看悬赏', label: '📋 接取任务' },
  inn: { near: '点击这里和掌柜交谈', label: '🏨 入住客栈' },
  merchant: { near: '点击这里购买物品', label: '💰 神秘商贩' },
  enemy: { near: '点击这里进入战斗', label: '⚔️ 遭遇敌人' },
  encounter: { near: '点击这里查看', label: '❓ 未知遭遇' },
};

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

  // 当前场景立绘（3变体轮播）
  const sceneAssets = REGION_SCENE_MAP[currentRegion] || REGION_SCENE_MAP.zhongyuan;
  const [sceneVariant] = useState(0); // 后续可扩展为自动轮播
  const sceneBgVar = sceneAssets[sceneVariant % sceneAssets.length];

  // 玩家操作菜单
  const [contextMenu, setContextMenu] = useState<{ x: number; y: number } | null>(null);
  const worldSceneRef = useRef<HTMLDivElement>(null);
  const playerRef = useRef<HTMLDivElement>(null);
  const [isMobileDevice] = useState(isMobile());

  // 检测附近发牌员
  const checkNearbyDealers = useCallback((pos: { x: number; y: number }) => {
    const interactRange = 70;
    const found = mockDealers.find(dealer => {
      const dx = dealer.position.x - pos.x;
      const dy = dealer.position.y - pos.y;
      return Math.sqrt(dx * dx + dy * dy) < interactRange;
    });
    setNearbyDealer(found || null);
  }, []);

  // 移动玩家
  const handleMapClick = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    // 忽略玩家头像点击
    if ((e.target as HTMLElement).closest('.player')) return;
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
        const mockCard: Card = {
          id: `card-${Date.now()}`,
          type: nearbyDealer.type === 'teahouse' ? 'side' : nearbyDealer.type === 'billboard' ? 'main' : 'growth',
          title: nearbyDealer.type === 'teahouse' ? '江湖传闻' : nearbyDealer.type === 'billboard' ? '悬赏任务' : '奇遇发现',
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

  // 移动端摇杆移动
  const handleMobileMove = useCallback((dx: number, dy: number) => {
    const newPos = {
      x: Math.max(20, Math.min(580, playerPos.x + dx)),
      y: Math.max(20, Math.min(380, playerPos.y + dy)),
    };
    setPlayerPos(newPos);
    checkNearbyDealers(newPos);
  }, [playerPos, checkNearbyDealers]);

  // 点击玩家头像打开操作菜单
  const handlePlayerClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    setContextMenu({
      x: e.clientX,
      y: e.clientY,
    });
  }, []);

  const contextMenuItems = [
    {
      id: 'profile',
      label: '查看角色',
      icon: '👤',
      onClick: () => console.log('Open profile'),
    },
    {
      id: 'stats',
      label: '角色属性',
      icon: '📊',
      onClick: () => console.log('Open stats'),
    },
    {
      id: 'deck',
      label: '我的卡组',
      icon: '🃏',
      onClick: () => console.log('Open deck'),
    },
    {
      id: 'settings',
      label: '游戏设置',
      icon: '⚙️',
      onClick: () => onSettings(),
    },
  ];

  // 更新发牌员的附近状态
  const getDealerClass = useCallback((dealer: Dealer) => {
    const classes = [`dealer dealer--${dealer.type}`];
    if (nearbyDealer?.id === dealer.id) {
      classes.push('dealer--nearby');
    }
    return classes.join(' ');
  }, [nearbyDealer]);

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
          <div className="world-scene world-scene--with-bg" onClick={handleMapClick} ref={worldSceneRef}>
            {/* 水墨山水背景 - 使用新场景立绘 */}
            <div className="world-scene__background" style={{ backgroundImage: `var(${sceneBgVar})`, backgroundSize: 'cover', backgroundPosition: 'center' }}>
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
            {mockDealers.map(dealer => {
              const hint = DEALER_HINTS[dealer.type] || DEALER_HINTS['encounter'];
              return (
                <div
                  key={dealer.id}
                  className={getDealerClass(dealer)}
                  style={{ left: dealer.position.x, top: dealer.position.y }}
                  onClick={(e) => {
                    e.stopPropagation();
                    if (nearbyDealer?.id === dealer.id) {
                      handleInteract();
                    }
                  }}
                >
                  {/* 交互提示标签 */}
                  <div className="dealer-hint-label">
                    {nearbyDealer?.id === dealer.id ? hint.near : hint.label}
                  </div>

                  <div className="dealer__sprite">
                    {dealer.type === 'enemy' ? '⚔️' : dealer.type === 'teahouse' ? '🍵' : dealer.type === 'billboard' ? '📜' : dealer.type === 'inn' ? '🏨' : '💰'}
                  </div>
                  <span className="dealer__name">{dealer.name}</span>
                </div>
              );
            })}

            {/* 玩家 */}
            <div
              className="player"
              style={{ left: playerPos.x, top: playerPos.y }}
              onClick={handlePlayerClick}
              ref={playerRef}
              title="点击查看角色信息"
            >
              <div className="player__sprite" style={{ backgroundImage: 'var(--asset-player-avatar)', backgroundSize: 'cover', backgroundPosition: 'center' }}>🧑</div>
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
          <span className="footer__hint">WASD/方向键移动 · E交互 · 点击头像查看菜单</span>
        </div>
      </footer>

      {/* 玩家操作菜单 */}
      {contextMenu && (
        <PlayerContextMenu
          x={contextMenu.x}
          y={contextMenu.y}
          items={contextMenuItems}
          onClose={() => setContextMenu(null)}
        />
      )}

      {/* 移动端虚拟控件 */}
      {isMobileDevice && (
        <MobileControls
          onMove={handleMobileMove}
          onInteract={handleInteract}
          showInteract={!!nearbyDealer}
        />
      )}
    </div>
  );
};

export default OpenWorld;
