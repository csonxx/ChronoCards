// 苏州城事件卡组件 v1.0
// UI规范：苏州专属卡背（运河水波+苏绣纹样）、折扇选项、灯笼触发提示

import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  SUZHOU_EVENT_CARDS,
  SUZHOU_CARD_OPTIONS,
  SUZHOU_UI_CONFIG,
  SUZHOU_ZONES,
  type SuzhouCardId,
} from './suzhouCards';
import type { EventCardData, CardOption } from '../EventCard';
import { CARD_TYPE_CONFIG } from '../EventCard';
import './suzhouCards.css';

// ========== Props ==========
interface SuzhouEventCardProps {
  cardId: SuzhouCardId;
  visible: boolean;
  onClose: () => void;
  onOptionSelect?: (optionId: string, cardId: SuzhouCardId) => void;
  triggerLocation?: string;
}

// ========== 灯笼触发提示组件 ==========
const TriggerIndicator: React.FC<{ location: string }> = ({ location }) => (
  <div className="suzhou-trigger-indicator">
    <span className="trigger-icon">{SUZHOU_UI_CONFIG.triggerIndicator.icon}</span>
    <span className="trigger-text">苏州城事件</span>
    <span className="trigger-location">{location}</span>
  </div>
);

// ========== 苏州城折扇选项组件 ==========
const SuzhouOptionFan: React.FC<{
  options: CardOption[];
  onSelect: (option: CardOption) => void;
  borderColor: string;
}> = ({ options, onSelect, borderColor }) => {
  const [fanOpen, setFanOpen] = useState(false);

  useEffect(() => {
    // 折扇展开动画延迟
    const timer = setTimeout(() => setFanOpen(true), 400);
    return () => clearTimeout(timer);
  }, []);

  return (
    <div className={`suzhou-option-fan ${fanOpen ? 'suzhou-option-fan--open' : ''}`}>
      <div className="fan-ribs">
        {options.map((opt, idx) => (
          <button
            key={opt.id}
            className={`fan-rib fan-rib--${idx}`}
            style={{
              '--rib-angle': `${((idx - (options.length - 1) / 2) * 12)}deg`,
              borderColor: borderColor,
            } as React.CSSProperties}
            onClick={() => onSelect(opt)}
          >
            <span className="fan-rib-marker">{opt.isPositive ? '✓' : '✗'}</span>
            <span className="fan-rib-text">{opt.text}</span>
          </button>
        ))}
      </div>
      <div className="fan-pivot" style={{ backgroundColor: borderColor }} />
    </div>
  );
};

// ========== 好感度头像组件 ==========
const AffectionAvatar: React.FC<{ cardType: string; cardId: SuzhouCardId }> = ({ cardType, cardId }) => {
  if (cardType !== 'emotion') return null;

  const avatarMap: Record<string, string> = {
    sz_emotion_wupeng: '神秘女子',
    sz_emotion_lengxiang: '隐居老侠客',
  };

  const name = avatarMap[cardId];
  if (!name) return null;

  return (
    <div className="suzhou-affection-avatar">
      <div className="avatar-frame">
        <div className="avatar-placeholder">{name[0]}</div>
      </div>
      <span className="avatar-name">{name}</span>
    </div>
  );
};

// ========== 运河水波卡背装饰 ==========
const CanalWaveDecoration: React.FC<{ config: typeof SUZHOU_UI_CONFIG.cardBackPattern }> = ({ config }) => (
  <div className="suzhou-canal-waves">
    <svg className="wave-svg" viewBox="0 0 200 60" preserveAspectRatio="none">
      <path className="wave wave-1" d="M0,30 Q25,10 50,30 T100,30 T150,30 T200,30 V60 H0 Z" fill={config.primaryColor} opacity="0.3" />
      <path className="wave wave-2" d="M0,35 Q25,15 50,35 T100,35 T150,35 T200,35 V60 H0 Z" fill={config.secondaryColor} opacity="0.2" />
      <path className="wave wave-3" d="M0,40 Q25,20 50,40 T100,40 T150,40 T200,40 V60 H0 Z" fill={config.primaryColor} opacity="0.15" />
    </svg>
    <div className="embroidery-corner embroidery-corner--tl" />
    <div className="embroidery-corner embroidery-corner--tr" />
    <div className="embroidery-corner embroidery-corner--bl" />
    <div className="embroidery-corner embroidery-corner--br" />
  </div>
);

// ========== 主组件 ==========
export const SuzhouEventCard: React.FC<SuzhouEventCardProps> = ({
  cardId,
  visible,
  onClose,
  onOptionSelect,
  triggerLocation,
}) => {
  const card = SUZHOU_EVENT_CARDS[cardId];
  const cardOptions = SUZHOU_CARD_OPTIONS[cardId];
  const config = CARD_TYPE_CONFIG[card.type];

  const [closing, setClosing] = useState(false);
  const [optionSelected, setOptionSelected] = useState<CardOption | null>(null);
  const overlayRef = useRef<HTMLDivElement>(null);

  // 关闭处理
  const handleClose = useCallback(() => {
    setClosing(true);
    setTimeout(onClose, 500);
  }, [onClose]);

  // 选项选择
  const handleOptionSelect = useCallback((option: CardOption) => {
    setOptionSelected(option);
    setClosing(true);
    setTimeout(() => {
      onOptionSelect?.(option.id, cardId);
      onClose();
    }, 500);
  }, [onOptionSelect, onOptionSelect, cardId, onClose]);

  if (!card) return null;

  return (
    <div
      ref={overlayRef}
      className={`suzhou-event-card-overlay ${visible ? 'suzhou-event-card-overlay--visible' : ''} ${closing ? 'suzhou-event-card-overlay--closing' : ''}`}
      onClick={(e) => e.target === overlayRef.current && handleClose()}
    >
      {/* 运河水波背景 */}
      <CanalWaveDecoration config={SUZHOU_UI_CONFIG.cardBackPattern} />

      {/* 触发位置提示 */}
      {triggerLocation && <TriggerIndicator location={triggerLocation} />}

      {/* 好感度头像 */}
      <AffectionAvatar cardType={card.type} cardId={cardId} />

      {/* 卡牌主体 */}
      <div className={`suzhou-event-card suzhou-event-card--${card.type}`}>
        {/* 外框 */}
        <div className="suzhou-card-frame" style={{ borderColor: config.borderColor }}>
          {/* 顶部装饰：苏州纹样 */}
          <div className="suzhou-card-scroll-top">
            <div className="scroll-rod" style={{ background: `linear-gradient(180deg, ${config.borderColor} 0%, transparent 100%)` }} />
            <span className="scroll-ornament" style={{ color: config.borderColor }}>☙</span>
          </div>

          {/* 类型角标 */}
          <div
            className="suzhou-card-type-badge"
            style={{ borderColor: config.accentColor, color: config.accentColor }}
          >
            <span className="type-badge-icon">{config.icon}</span>
            <span className="type-badge-label">{config.label}</span>
          </div>

          {/* 标题栏 */}
          <div className="suzhou-card-header" style={{ backgroundColor: `${config.accentColor}22` }}>
            <h2 className="suzhou-card-title" style={{ color: config.accentColor }}>
              {card.title}
            </h2>
          </div>

          {/* 分隔线 */}
          <div className="suzhou-card-divider">
            <span className="divider-line" style={{ background: `linear-gradient(90deg, transparent, ${config.borderColor}, transparent)` }} />
            <span className="divider-icon" style={{ color: config.borderColor }}>❧</span>
            <span className="divider-line" style={{ background: `linear-gradient(90deg, transparent, ${config.borderColor}, transparent)` }} />
          </div>

          {/* 触发点提示 */}
          {cardOptions && (
            <div className="suzhou-card-trigger">
              <span className="trigger-pin">📍</span>
              <span className="trigger-location-text">{cardOptions.trigger}</span>
            </div>
          )}

          {/* 主视觉区：苏州水墨渐变 */}
          <div
            className="suzhou-card-artwork"
            style={{
              background: `linear-gradient(135deg, ${config.bgColor} 0%, ${config.accentColor}22 50%, ${config.bgColor} 100%)`,
            }}
          >
            <div className="artwork-mist suzhou-artwork-mist" />
            {/* 苏州元素水墨装饰 */}
            <div className="suzhou-water-ink" />
          </div>

          {/* 描述文案 */}
          <div className="suzhou-card-description-wrapper">
            <p className="suzhou-card-description">{card.description}</p>
          </div>

          {/* 正面/负面效果 */}
          {(card.positiveEffect || card.negativeVariant) && (
            <div className="suzhou-card-effects">
              {card.positiveEffect && (
                <div className="suzhou-effect-box suzhou-effect-box--positive">
                  <div className="effect-box__header">
                    <span className="effect-icon">✓</span>
                    <span className="effect-label">正面解读</span>
                  </div>
                  <p className="effect-text">{card.positiveEffect}</p>
                </div>
              )}
              {card.negativeVariant && (
                <div className="suzhou-effect-box suzhou-effect-box--negative">
                  <div className="effect-box__header">
                    <span className="effect-icon">✗</span>
                    <span className="effect-label">负面变奏</span>
                  </div>
                  <p className="effect-text">{card.negativeVariant}</p>
                </div>
              )}
            </div>
          )}

          {/* 底部装饰 */}
          <div className="suzhou-card-scroll-bottom">
            <div className="scroll-rod" style={{ background: `linear-gradient(0deg, ${config.borderColor} 0%, transparent 100%)` }} />
            <span className="scroll-ornament" style={{ color: config.borderColor }}>❧</span>
          </div>
        </div>

        {/* 折扇选项（苏州特色） */}
        {cardOptions && cardOptions.options.length > 0 && (
          <SuzhouOptionFan
            options={cardOptions.options}
            onSelect={handleOptionSelect}
            borderColor={config.borderColor}
          />
        )}

        {/* 关闭提示 */}
        <button className="suzhou-card-skip" onClick={handleClose}>
          点击任意处关闭
        </button>
      </div>
    </div>
  );
};

// ========== 苏州城场景导航组件 ==========
interface SuzhouZoneNavProps {
  currentZone?: keyof typeof SUZHOU_ZONES;
  onZoneSelect: (zone: keyof typeof SUZHOU_ZONES) => void;
}

export const SuzhouZoneNav: React.FC<SuzhouZoneNavProps> = ({ currentZone, onZoneSelect }) => (
  <div className="suzhou-zone-nav">
    <h3 className="zone-nav-title">🏮 苏州城</h3>
    <div className="zone-nav-list">
      {(Object.keys(SUZHOU_ZONES) as Array<keyof typeof SUZHOU_ZONES>).map(zoneKey => {
        const zone = SUZHOU_ZONES[zoneKey];
        const isActive = zoneKey === currentZone;
        return (
          <button
            key={zoneKey}
            className={`zone-nav-btn ${isActive ? 'zone-nav-btn--active' : ''}`}
            onClick={() => onZoneSelect(zoneKey)}
          >
            <span className="zone-name">{zone.name}</span>
            <span className="zone-desc">{zone.description.split('，')[0]}</span>
          </button>
        );
      })}
    </div>
  </div>
);

// ========== 灯笼触发器组件 ==========
interface SuzhouEventTriggerProps {
  cardId: SuzhouCardId;
  onTrigger: (cardId: SuzhouCardId) => void;
  location?: string;
}

export const SuzhouEventTrigger: React.FC<SuzhouEventTriggerProps> = ({
  cardId,
  onTrigger,
  location,
}) => {
  const card = SUZHOU_EVENT_CARDS[cardId];
  if (!card) return null;

  const config = CARD_TYPE_CONFIG[card.type];

  return (
    <button
      className="suzhou-event-trigger"
      onClick={() => onTrigger(cardId)}
      style={{ '--trigger-color': config.accentColor } as React.CSSProperties}
    >
      <span className="trigger-lantern">{SUZHOU_UI_CONFIG.triggerIndicator.icon}</span>
      {location && <span className="trigger-location-tag">{location}</span>}
    </button>
  );
};

export default SuzhouEventCard;
