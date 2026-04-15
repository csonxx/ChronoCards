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

// NPC立绘数据：type → { emoji, name, color, charEmoji }
const NPC_PORTRAITS: Record<string, { avatar: string; color: string; accent: string; title: string }> = {
  teahouse: { avatar: '🧙‍♂️', color: '#8B6914', accent: '#D4A843', title: '说书人' },
  billboard: { avatar: '🎯', color: '#1a5c3a', accent: '#3db87a', title: '赏金猎人' },
  inn: { avatar: '🏪', color: '#6b3a8c', accent: '#a76dd4', title: '客栈掌柜' },
  merchant: { avatar: '🧞', color: '#8B6914', accent: '#FFD700', title: '神秘商贩' },
  enemy: { avatar: '👹', color: '#8B1A1A', accent: '#FF4444', title: '江湖恶徒' },
  encounter: { avatar: '❓', color: '#3a5c8B', accent: '#6ba3ff', title: '奇遇' },
};

// 模拟发牌员数据
const mockDealers: Dealer[] = [
  { id: 'd1', name: '茶馆说书人', type: 'teahouse', position: { x: 180, y: 160 }, avatar: '/assets/characters/shen_moyuan_1.png' },
  { id: 'd2', name: '悬赏公告栏', type: 'billboard', position: { x: 420, y: 280 }, avatar: '/assets/scenes/battle_bg_1.png' },
  { id: 'd3', name: '客栈掌柜', type: 'inn', position: { x: 320, y: 400 }, avatar: '/assets/characters/liao_chen_1.png' },
  { id: 'd4', name: '神秘商贩', type: 'merchant', position: { x: 540, y: 180 }, avatar: '/assets/characters/mowentian_1.png' },
  { id: 'd5', name: '江湖恶徒', type: 'enemy', position: { x: 120, y: 340 }, avatar: '/assets/characters/yin_wuhen_1.png' },
  { id: 'd6', name: '神秘奇遇', type: 'encounter', position: { x: 480, y: 120 }, avatar: '/assets/characters/lan_ruodie_1.png' },
];

const mockRecentCards = ['支线', '成长', '主线'];

// 发牌员交互提示文案
const DEALER_HINTS: Record<string, { label: string; action: string }> = {
  teahouse:   { label: '🍵 茶馆说书人', action: '点击 [E] 听江湖传闻' },
  billboard:  { label: '📋 悬赏公告栏', action: '点击 [E] 接取任务' },
  inn:        { label: '🏪 客栈掌柜',   action: '点击 [E] 入住客栈' },
  merchant:   { label: '💰 神秘商贩',   action: '点击 [E] 购买物品' },
  enemy:      { label: '⚔️ 江湖恶徒',    action: '点击 [E] 进入战斗' },
  encounter:  { label: '❓ 未知奇遇',    action: '点击 [E] 触发奇遇' },
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
  const [sceneVariant] = useState(0);
  const sceneBgVar = sceneAssets[sceneVariant % sceneAssets.length];

  // 玩家操作菜单
  const [contextMenu, setContextMenu] = useState<{ x: number; y: number } | null>(null);
  const worldSceneRef = useRef<HTMLDivElement>(null);
  const playerRef = useRef<HTMLDivElement>(null);
  const [isMobileDevice] = useState(isMobile());

  // 检测附近发牌员
  const checkNearbyDealers = useCallback((pos: { x: number; y: number }) => {
    const interactRange = 80;
    const found = mockDealers.find(dealer => {
      const dx = dealer.position.x - pos.x;
      const dy = dealer.position.y - pos.y;
      return Math.sqrt(dx * dx + dy * dy) < interactRange;
    });
    setNearbyDealer(found || null);
  }, []);

  // 移动玩家
  const handleMapClick = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
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
      case 'ArrowUp': case 'w': case 'W': dy = -step; break;
      case 'ArrowDown': case 's': case 'S': dy = step; break;
      case 'ArrowLeft': case 'a': case 'A': dx = -step; break;
      case 'ArrowRight': case 'd': case 'D': dx = step; break;
      case 'e': case 'E': if (nearbyDealer) handleInteract(); return;
      default: return;
    }

    e.preventDefault();
    const newPos = {
      x: Math.max(30, Math.min(570, playerPos.x + dx)),
      y: Math.max(30, Math.min(370, playerPos.y + dy)),
    };
    setPlayerPos(newPos);
    checkNearbyDealers(newPos);
  }, [playerPos, nearbyDealer, handleInteract, checkNearbyDealers]);

  // 移动端摇杆移动
  const handleMobileMove = useCallback((dx: number, dy: number) => {
    const newPos = {
      x: Math.max(30, Math.min(570, playerPos.x + dx)),
      y: Math.max(30, Math.min(370, playerPos.y + dy)),
    };
    setPlayerPos(newPos);
    checkNearbyDealers(newPos);
  }, [playerPos, checkNearbyDealers]);

  // 点击玩家头像打开操作菜单
  const handlePlayerClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    setContextMenu({ x: e.clientX, y: e.clientY });
  }, []);

  const contextMenuItems = [
    { id: 'profile', label: '查看角色', icon: '👤', onClick: () => console.log('Open profile') },
    { id: 'stats', label: '角色属性', icon: '📊', onClick: () => console.log('Open stats') },
    { id: 'deck', label: '我的卡组', icon: '🃏', onClick: () => console.log('Open deck') },
    { id: 'settings', label: '游戏设置', icon: '⚙️', onClick: () => onSettings() },
  ];

  const getDealerClass = useCallback((dealer: Dealer) => {
    const classes = [`dealer dealer--${dealer.type}`];
    if (nearbyDealer?.id === dealer.id) classes.push('dealer--nearby');
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
    <div className="open-world" tabIndex={0} onKeyDown={handleKeyDown} style={{
      backgroundImage: `linear-gradient(to bottom, rgba(15,25,45,0.82) 0%, rgba(10,15,30,0.88) 100%), url("/assets/scenes/map_bg_1.png")`,
      backgroundSize: "cover, cover",
      backgroundPosition: "center, center",
      minHeight: "100vh",
    }}>
      <TopBar title="ChronoCards" subtitle={`${playerName} · ${currentChapter}`} onSettingsClick={onSettings} />

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
                  <img
                    key={dealer.id}
                    src={dealer.avatar || '/assets/characters/shen_moyuan_1.png'}
                    alt={dealer.name}
                    className={`location-marker location-marker--${dealer.type}`}
                    style={{ left: `${(dealer.position.x / 600) * 100}%`, top: `${(dealer.position.y / 400) * 100}%` }}
                    title={dealer.name}
                    onClick={() => handleInteractWith(dealer)}
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

            {/* ===== 水墨山水背景 ===== */}
            <div className="world-bg" style={{ backgroundImage: `var(${sceneBgVar})` }}>
              {/* 远景山峦 */}
              <div className="bg-layer bg-layer--far" />
              {/* 中景山峦 */}
              <div className="bg-layer bg-layer--mid" />
              {/* 近景云雾 */}
              <div className="bg-layer bg-layer--mist" />
              {/* 水墨树 */}
              <div className="ink-trees">
                {[...Array(10)].map((_, i) => (
                  <div key={i} className="ink-tree" style={{ left: `${5 + i * 10}%`, animationDelay: `${i * 0.3}s` }} />
                ))}
              </div>
              {/* 云雾飘渺 */}
              <div className="bg-mist bg-mist--1" />
              <div className="bg-mist bg-mist--2" />
              <div className="bg-mist bg-mist--3" />
              {/* 地面/水面 */}
              <div className="bg-ground" />
            </div>

            {/* ===== 地图装饰元素 ===== */}
            <div className="world-decorations">
              {/* 远景小路 */}
              <svg className="decor-path" viewBox="0 0 600 400" preserveAspectRatio="none">
                <path d="M 0 350 Q 150 300 300 320 Q 450 340 600 300" stroke="rgba(139,105,20,0.15)" strokeWidth="8" fill="none" strokeDasharray="12,8"/>
              </svg>
            </div>

            {/* ===== NPC交互点 ===== */}
            {mockDealers.map(dealer => {
              const portrait = NPC_PORTRAITS[dealer.type] || NPC_PORTRAITS.encounter;
              const isNearby = nearbyDealer?.id === dealer.id;
              return (
                <div
                  key={dealer.id}
                  className={getDealerClass(dealer)}
                  style={{ left: dealer.position.x, top: dealer.position.y }}
                  onClick={(e) => {
                    e.stopPropagation();
                    if (isNearby) handleInteract();
                  }}
                >
                  {/* 常驻标签（始终显示） */}
                  <div className="dealer-badge">
                    <div className="dealer-badge__portrait" style={{ background: `linear-gradient(135deg, ${portrait.color}22, ${portrait.color}44)`, borderColor: isNearby ? portrait.accent : `${portrait.color}88` }}>
                      <span className="dealer-badge__emoji">{portrait.avatar}</span>
                    </div>
                    <div className="dealer-badge__info">
                      <span className="dealer-badge__name">{dealer.name}</span>
                      <span className="dealer-badge__title">{portrait.title}</span>
                    </div>
                  </div>

                  {/* 交互提示（始终显示，大小随距离变化） */}
                  <div className={`dealer-hint ${isNearby ? 'dealer-hint--active' : ''}`}>
                    {isNearby ? (
                      <div className="dealer-hint__content dealer-hint__content--active">
                        <span className="hint-text">{DEALER_HINTS[dealer.type]?.action || '点击交互'}</span>
                        <div className="hint-key">E</div>
                      </div>
                    ) : (
                      <div className="dealer-hint__idle">
                        <span className="hint-dot" />
                      </div>
                    )}
                  </div>

                  {/* 交互范围圆圈（始终可见） */}
                  <div className={`dealer-range-ring ${isNearby ? 'dealer-range-ring--active' : ''}`} />
                </div>
              );
            })}

            {/* ===== 玩家 ===== */}
            <div
              className="player"
              style={{ left: playerPos.x, top: playerPos.y }}
              onClick={handlePlayerClick}
              ref={playerRef}
              title="点击查看角色信息"
            >
              {/* 外层光环 */}
              <div className="player-aura" />
              {/* 头像框 */}
              <div className="player-avatar-frame">
                <div className="player-avatar-inner">
                  <span className="player-avatar-emoji">🧑‍🎤</span>
                </div>
                <div className="player-avatar-ring" />
              </div>
              {/* 玩家名 */}
              <div className="player-name-tag">{playerName}</div>
              {/* 脚下阴影 */}
              <div className="player-shadow" />
            </div>

            {/* ===== 中央交互提示（靠近时） ===== */}
            {nearbyDealer && (
              <div className="interaction-banner">
                <div className="interaction-banner__scroll">
                  <div className="scroll-ornament scroll-ornament--left" />
                  <div className="scroll-content">
                    <span className="scroll-icon">
                      {nearbyDealer.type === 'enemy' ? '⚔️' : nearbyDealer.type === 'merchant' ? '💰' : '📜'}
                    </span>
                    <span className="scroll-title">
                      {nearbyDealer.type === 'enemy'
                        ? `⚔️ 遭遇 ${nearbyDealer.name}！准备战斗！`
                        : `与 ${nearbyDealer.name} 交谈中`}
                    </span>
                    <span className="scroll-key">[ E ] 确认</span>
                  </div>
                  <div className="scroll-ornament scroll-ornament--right" />
                </div>
              </div>
            )}

            {/* ===== 区域名称 ===== */}
            <div className="world-region-label">
              <span className="region-ink-decoration" />
              <span className="region-text">{regionNames[currentRegion]}</span>
              <span className="region-ink-decoration" />
            </div>
          </div>
        </main>
      </div>

      {/* 底部卡组预览条 */}
      <footer className="open-world__footer">
        <div className="footer__scroll-decoration footer__scroll-decoration--left" />
        <div className="footer__card-progress">
          <span className="footer__label">📜 卡牌进度</span>
          <CardProgress current={cardProgress.current} total={cardProgress.total} recentCards={mockRecentCards} />
        </div>
        <div className="footer__controls">
          <div className="footer__key-hints">
            <span className="key-hint"><kbd>WASD</kbd> 移动</span>
            <span className="key-hint"><kbd>E</kbd> 交互</span>
            <span className="key-hint">🖱 点击头像 菜单</span>
          </div>
        </div>
        <div className="footer__scroll-decoration footer__scroll-decoration--right" />
      </footer>

      {contextMenu && (
        <PlayerContextMenu x={contextMenu.x} y={contextMenu.y} items={contextMenuItems} onClose={() => setContextMenu(null)} />
      )}

      {isMobileDevice && (
        <MobileControls onMove={handleMobileMove} onInteract={handleInteract} showInteract={!!nearbyDealer} />
      )}
    </div>
  );
};

export default OpenWorld;
