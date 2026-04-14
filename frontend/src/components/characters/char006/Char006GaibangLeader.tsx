// #006 丐帮帮主 · 角色UI组件
// 规范来源：/root/.openclaw/workspace-ui/docs/characters/UI_006_丐帮帮主_v1.md
// 情绪6套：常态/豪爽/愤怒/算计/感伤/威严

import React, { useState, useCallback } from 'react';
import './char-006.css';

// ========== 色彩系统 ==========
export const CHAR006_COLORS = {
  // 服装主色
  bodyMain:    '#C4A35A', // 土黄褐
  bodySecond:  '#8B7355', // 深土黄
  bodyAccent:  '#4A5568', // 暗青灰
  bodyBase:    '#2D3748', // 深暗青
  // 信物/武器
  staffGreen:  '#5D8A66', // 竹青绿（打狗棒）
  gourdPurple: '#7B5EA7', // 紫漆葫芦
  stonGray:    '#9CA3AF', // 飞蝗石灰白
  // 对话气泡
  bubbleBg:    '#E8D5A3', // 气泡土黄底
  bubbleBorder:'#3D4A5C', // 气泡暗青边框
} as const;

// ========== 情绪状态类型 ==========
export type EmotionState = 'normal' | 'hearty' | 'angry' | 'scheming' | 'sorrowful' | 'solemn';

// 情绪配置：主色调 + 辅色 + 说明 + 图标
export const EMOTION_CONFIG: Record<EmotionState, {
  label:      string;
  icon:       string;
  primary:    string;
  secondary:  string;
  textColor:  string;
  bubbleBorder: string;
}> = {
  normal:    { label: '常态', icon: '',   primary: '#C4A35A', secondary: '#4A5568', textColor: '#2D3748', bubbleBorder: '#3D4A5C' },
  hearty:    { label: '豪爽', icon: '☀', primary: '#D4A843', secondary: '#C9A86C', textColor: '#5C3A0A', bubbleBorder: '#D4A843' },
  angry:     { label: '愤怒', icon: '⚡', primary: '#2D3748', secondary: '#1A202C', textColor: '#E2E8F0', bubbleBorder: '#1A202C' },
  scheming:  { label: '算计', icon: '',   primary: '#718096', secondary: '#4A5568', textColor: '#E2E8F0', bubbleBorder: '#4A5568' },
  sorrowful: { label: '感伤', icon: '',   primary: '#B8956A', secondary: '#A0845C', textColor: '#4A3728', bubbleBorder: '#A0845C' },
  solemn:    { label: '威严', icon: '',   primary: '#1A202C', secondary: '#2C3E50', textColor: '#D4B896', bubbleBorder: '#2C3E50' },
};

// ========== 接口定义 ==========
export interface Char006AvatarProps {
  emotion?: EmotionState;
  selected?: boolean;
  disabled?: boolean;
  size?: 'sm' | 'md' | 'lg';  // 128 / 256 / 512
  onClick?: () => void;
}

export interface Char006CardProps {
  emotion?: EmotionState;
  hp?: number;
  maxHp?: number;
  rage?: number;
  maxRage?: number;
  inBattle?: boolean;
  expanded?: boolean;
  onToggleExpand?: () => void;
  onAttack?: (weapon: 'staff' | 'stone') => void;
}

export interface Char006DialogueBubbleProps {
  text: string;
  emotion?: EmotionState;
  showName?: boolean;
}

export interface Char006WeaponIconProps {
  weapon: 'staff' | 'stone';
  state?: 'idle' | 'attacking' | 'flying' | 'parry';
}

// ========== 头像组件 ==========
export const Char006Avatar: React.FC<Char006AvatarProps> = ({
  emotion = 'normal',
  selected = false,
  disabled = false,
  size = 'md',
  onClick,
}) => {
  const [hovered, setHovered] = useState(false);
  const cfg = EMOTION_CONFIG[emotion];

  const sizeMap = { sm: 64, md: 128, lg: 256 };
  const px = sizeMap[size];

  const avatarStyle: React.CSSProperties = {
    width:  px,
    height: px,
    backgroundColor: cfg.primary,
    borderColor: selected ? '#D4A843' : cfg.secondary,
    borderWidth: selected ? 2 : 1,
    opacity: disabled ? 0.4 : 1,
    filter:  disabled ? 'grayscale(80%)' : 'none',
    boxShadow: hovered && !disabled ? `0 0 12px ${cfg.primary}80` : undefined,
    transition: 'all 0.3s ease',
  };

  return (
    <div
      className={[
        'char006-avatar',
        `char006-avatar--${size}`,
        `char006-avatar--${emotion}`,
        selected  ? 'char006-avatar--selected'  : '',
        disabled  ? 'char006-avatar--disabled'  : '',
        hovered   ? 'char006-avatar--hovered'   : '',
      ].filter(Boolean).join(' ')}
      style={avatarStyle}
      onClick={disabled ? undefined : onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      role={onClick ? 'button' : undefined}
      aria-label={`丐帮帮主 · ${cfg.label}${selected ? ' · 已选中' : ''}${disabled ? ' · 禁用' : ''}`}
      tabIndex={onClick && !disabled ? 0 : undefined}
      onKeyDown={e => { if (e.key === 'Enter' && onClick && !disabled) onClick(); }}
    >
      {/* 面部描绘区域（占位，待美术资源） */}
      <div className="char006-avatar__face-area">
        {/* 旧疤标记（左眉眉尾） */}
        <div className="char006-avatar__scar" style={{ opacity: size === 'sm' ? 0 : 1 }} />
        {/* 情绪图标 */}
        {cfg.icon && <span className="char006-avatar__emotion-icon">{cfg.icon}</span>}
      </div>
      {/* 打狗棒图标：选中时显示 */}
      {selected && (
        <div className="char006-avatar__staff-badge">
          <Char006WeaponIcon weapon="staff" state="idle" />
        </div>
      )}
      {/* 愤怒时青筋纹理叠加 */}
      {emotion === 'angry' && <div className="char006-avatar__vein-overlay" />}
    </div>
  );
};

// ========== 武器图标 ==========
export const Char006WeaponIcon: React.FC<Char006WeaponIconProps> = ({
  weapon,
  state = 'idle',
}) => {
  const isStaff = weapon === 'staff';
  const isAttacking = state === 'attacking';
  const isFlying   = state === 'flying';
  const isParry    = state === 'parry';

  return (
    <div
      className={[
        'char006-weapon',
        `char006-weapon--${weapon}`,
        `char006-weapon--${state}`,
      ].join(' ')}
      aria-label={isStaff ? '打狗棒' : '飞蝗石'}
      role="img"
    >
      {isStaff ? (
        // 打狗棒：竹节棒 SVG
        <svg
          width={isAttacking ? 56 : 32}
          height={isAttacking ? 56 : 32}
          viewBox="0 0 32 32"
          fill="none"
          className={['char006-weapon__staff-svg', isAttacking ? 'char006-weapon__staff-svg--attack' : ''].join(' ')}
        >
          {/* 竹节主体 */}
          <line x1="6" y1="28" x2="26" y2="4" stroke={CHAR006_COLORS.staffGreen} strokeWidth="3" strokeLinecap="round"/>
          {/* 竹节分节线 */}
          {[8, 14, 20].map(y => (
            <line key={y} x1={6 + (26-6)*(y/32) - 2} y1={28 - (28-4)*(y/32) - 2}
                          x2={6 + (26-6)*(y/32) + 2} y2={28 - (28-4)*(y/32) + 2}
                  stroke="#3D6B47" strokeWidth="1.5" strokeLinecap="round"/>
          ))}
          {/* 攻击时发光效果 */}
          {isAttacking && (
            <line x1="6" y1="28" x2="26" y2="4"
                  stroke={CHAR006_COLORS.staffGreen} strokeWidth="6"
                  strokeLinecap="round" opacity="0.35"/>
          )}
          {/* 格挡闪光 */}
          {isParry && (
            <circle cx="16" cy="16" r="12" fill="#D4A843" opacity="0.6">
              <animate attributeName="opacity" from="0.6" to="0" dur="0.4s" fill="freeze"/>
              <animate attributeName="r" from="8" to="16" dur="0.4s" fill="freeze"/>
            </circle>
          )}
        </svg>
      ) : (
        // 飞蝗石：不规则扁平石块
        <svg
          width={state === 'flying' ? 32 : 24}
          height={state === 'flying' ? 32 : 24}
          viewBox="0 0 24 24"
          fill="none"
          className={['char006-weapon__stone-svg', isFlying ? 'char006-weapon__stone-svg--fly' : ''].join(' ')}
        >
          {/* 不规则扁平石形 */}
          <polygon points="5,14 3,9 8,5 16,4 21,8 20,14 14,18 7,17"
                   fill={CHAR006_COLORS.stonGray} stroke="#6B7280" strokeWidth="1"/>
          {/* 石纹 */}
          <line x1="8" y1="10" x2="14" y2="8" stroke="#9CA3AF" strokeWidth="0.8" opacity="0.6"/>
          <line x1="10" y1="14" x2="17" y2="11" stroke="#9CA3AF" strokeWidth="0.8" opacity="0.6"/>
          {/* 飞行残影 */}
          {isFlying && <>
            <polygon points="3,14 1,9 6,5 14,4 19,8 18,14 12,18 5,17"
                     fill={CHAR006_COLORS.stonGray} opacity="0.3" transform="translate(-4, 1)"/>
            <polygon points="1,14 -1,9 4,5 12,4 17,8 16,14 10,18 3,17"
                     fill={CHAR006_COLORS.stonGray} opacity="0.1" transform="translate(-8, 2)"/>
          </>}
        </svg>
      )}
    </div>
  );
};

// ========== 对话气泡 ==========
export const Char006DialogueBubble: React.FC<Char006DialogueBubbleProps> = ({
  text,
  emotion = 'normal',
  showName = true,
}) => {
  const cfg = EMOTION_CONFIG[emotion];

  return (
    <div
      className={['char006-bubble', `char006-bubble--${emotion}`].join(' ')}
      style={{
        '--bubble-bg':       CHAR006_COLORS.bubbleBg,
        '--bubble-border':   cfg.bubbleBorder,
        '--bubble-text':     cfg.textColor,
        '--bubble-primary':  cfg.primary,
        transition: 'border-color 0.3s ease, box-shadow 0.3s ease',
      } as React.CSSProperties}
    >
      {/* 气泡主体 */}
      <div className="char006-bubble__body">
        {/* 人名标签 */}
        {showName && (
          <div className="char006-bubble__nameplate" style={{ color: '#D4A843' }}>
            <span className="char006-bubble__gourd-icon">🏺</span>
            <span className="char006-bubble__name">丐帮帮主</span>
            {cfg.icon && <span className="char006-bubble__emotion-badge">{cfg.icon}</span>}
          </div>
        )}
        {/* 台词 */}
        <p className="char006-bubble__text"
           style={{ fontWeight: emotion === 'angry' ? 700 : 400 }}>
          {text}
        </p>
      </div>
    </div>
  );
};

// ========== 角色卡片 ==========
export const Char006Card: React.FC<Char006CardProps> = ({
  emotion = 'normal',
  hp = 100,
  maxHp = 100,
  rage = 0,
  maxRage = 100,
  inBattle = false,
  expanded = false,
  onToggleExpand,
  onAttack,
}) => {
  const cfg = EMOTION_CONFIG[emotion];
  const hpPct   = Math.max(0, Math.min(100, (hp   / (maxHp   || 1)) * 100));
  const ragePct = Math.max(0, Math.min(100, (rage / (maxRage || 1)) * 100));

  return (
    <div
      className={[
        'char006-card',
        `char006-card--${emotion}`,
        inBattle  ? 'char006-card--battle'   : '',
        expanded  ? 'char006-card--expanded'  : '',
      ].filter(Boolean).join(' ')}
      style={{
        '--card-primary':   cfg.primary,
        '--card-secondary': cfg.secondary,
        '--card-text':      cfg.textColor,
        transition: 'all 0.3s ease',
      } as React.CSSProperties}
    >
      {/* 卡片头部：头像区 + 姓名 + 九袋葫芦 */}
      <div className="char006-card__header">
        <Char006Avatar emotion={emotion} size="sm" />
        <div className="char006-card__header-info">
          <div className="char006-card__title">
            <span className="char006-card__gourd-badge">🏺</span>
            <span className="char006-card__name">丐帮帮主</span>
            <span className="char006-card__id">#006</span>
          </div>
          <div className="char006-card__faction">丐帮 · 九袋帮主</div>
          <div className="char006-card__emotion-tag" style={{ color: cfg.primary }}>
            {cfg.icon} {cfg.label}
          </div>
        </div>
        {/* 展开/收起 */}
        {onToggleExpand && (
          <button className="char006-card__expand-btn" onClick={onToggleExpand}
                  aria-label={expanded ? '收起' : '展开'}>
            {expanded ? '▲' : '▼'}
          </button>
        )}
      </div>

      {/* 战斗状态：HP + 怒气 */}
      {inBattle && (
        <div className="char006-card__battle-bars">
          <div className="char006-card__bar-row">
            <span className="char006-card__bar-label">HP</span>
            <div className="char006-card__bar-track">
              <div className="char006-card__bar-fill char006-card__bar-fill--hp"
                   style={{ width: `${hpPct}%`, backgroundColor: hpPct < 30 ? '#E53E3E' : '#48BB78' }} />
            </div>
            <span className="char006-card__bar-value">{hp}/{maxHp}</span>
          </div>
          <div className="char006-card__bar-row">
            <span className="char006-card__bar-label" style={{ color: CHAR006_COLORS.bodyMain }}>资源</span>
            <div className="char006-card__bar-track">
              <div className="char006-card__bar-fill char006-card__bar-fill--rage"
                   style={{ width: `${ragePct}%`, backgroundColor: CHAR006_COLORS.bodyMain }} />
            </div>
            <span className="char006-card__bar-value">{rage}/{maxRage}</span>
          </div>
        </div>
      )}

      {/* 展开详情 */}
      {expanded && (
        <div className="char006-card__detail">
          {/* 基本档案 */}
          <table className="char006-card__spec-table">
            <tbody>
              <tr><td className="spec-key">年龄</td><td>约五十岁</td></tr>
              <tr><td className="spec-key">定位</td><td>正派 · 精神领袖</td></tr>
              <tr><td className="spec-key">身高</td><td>176 cm（精瘦）</td></tr>
              <tr><td className="spec-key">特征</td><td>左眉疤 · 左手缺小指</td></tr>
            </tbody>
          </table>
          {/* 武器图例 */}
          <div className="char006-card__weapons">
            <div className="char006-card__weapon-item">
              <Char006WeaponIcon weapon="staff" state={inBattle ? 'attacking' : 'idle'} />
              <div>
                <div className="weapon-name">打狗棒</div>
                <div className="weapon-desc">竹制·刻"仁者无敌"·棒长120cm</div>
              </div>
            </div>
            <div className="char006-card__weapon-item">
              <Char006WeaponIcon weapon="stone" state="idle" />
              <div>
                <div className="weapon-name">飞蝗石</div>
                <div className="weapon-desc">灰白花岗岩·腰间布袋常备5-8枚</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 战斗按钮 */}
      {inBattle && onAttack && (
        <div className="char006-card__attack-row">
          <button className="char006-btn char006-btn--staff"
                  onClick={() => onAttack('staff')}
                  style={{ borderColor: CHAR006_COLORS.staffGreen, color: CHAR006_COLORS.staffGreen }}>
            <Char006WeaponIcon weapon="staff" state="idle" /> 打狗棒法
          </button>
          <button className="char006-btn char006-btn--stone"
                  onClick={() => onAttack('stone')}
                  style={{ borderColor: CHAR006_COLORS.stonGray, color: CHAR006_COLORS.stonGray }}>
            <Char006WeaponIcon weapon="stone" state="idle" /> 飞蝗石
          </button>
        </div>
      )}
    </div>
  );
};

// ========== 情绪切换演示面板（开发/调试用）==========
export const Char006EmotionShowcase: React.FC = () => {
  const [activeEmotion, setActiveEmotion] = useState<EmotionState>('normal');
  const emotions = Object.keys(EMOTION_CONFIG) as EmotionState[];

  const dialogueSamples: Record<EmotionState, string> = {
    normal:    '江湖路远，且行且珍重。',
    hearty:    '哈哈哈！好汉子！且随老夫喝一碗！',
    angry:     '欺我丐帮无人？！',
    scheming:  '此事……尚需从长计议。',
    sorrowful: '老朽年迈，力不从心……',
    solemn:    '丐帮规矩，绝不可废。',
  };

  return (
    <div className="char006-showcase">
      {/* 情绪选择器 */}
      <div className="char006-showcase__tabs">
        {emotions.map(e => {
          const cfg = EMOTION_CONFIG[e];
          return (
            <button
              key={e}
              className={['char006-showcase__tab', activeEmotion === e ? 'char006-showcase__tab--active' : ''].join(' ')}
              onClick={() => setActiveEmotion(e)}
              style={{
                borderColor: activeEmotion === e ? cfg.primary : 'transparent',
                color: activeEmotion === e ? cfg.primary : '#718096',
              }}
            >
              {cfg.icon} {cfg.label}
            </button>
          );
        })}
      </div>

      {/* 角色展示 */}
      <div className="char006-showcase__stage">
        {/* 立绘区域 */}
        <div className="char006-showcase__portrait-zone">
          <Char006Avatar emotion={activeEmotion} size="lg" />
          <div className="char006-showcase__emotion-label"
               style={{ color: EMOTION_CONFIG[activeEmotion].primary }}>
            {EMOTION_CONFIG[activeEmotion].icon} {EMOTION_CONFIG[activeEmotion].label}
          </div>
        </div>

        {/* 对话气泡 */}
        <div className="char006-showcase__bubble-zone">
          <Char006DialogueBubble
            text={dialogueSamples[activeEmotion]}
            emotion={activeEmotion}
            showName
          />
        </div>

        {/* 角色卡片 */}
        <Char006Card
          emotion={activeEmotion}
          hp={80}
          maxHp={100}
          rage={40}
          maxRage={100}
          inBattle
          expanded
        />
      </div>
    </div>
  );
};

export default Char006EmotionShowcase;
