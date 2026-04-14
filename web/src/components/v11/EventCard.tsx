// 事件卡牌组件 v1.1
// 规范来源：ChronoCards_UI_Design_v1.md §2

import React, { useState, useEffect, useCallback } from 'react';
import type { CardType } from './CompatibilityMatrix';
import { CARD_TYPE_LIST } from './CompatibilityMatrix';
import './event-card.css';

// ========== 卡牌类型 → 视觉配置 ==========
export const CARD_TYPE_CONFIG: Record<CardType, {
  icon: string;
  label: string;
  bgColor: string;
  borderColor: string;
  accentColor: string;
}> = {
  main_story: { icon: '🐉', label: '主线', bgColor: '#1A0A0A', borderColor: '#D4AF37', accentColor: '#C23A2B' },
  emotion:    { icon: '🔗', label: '情感', bgColor: '#1A0A0F', borderColor: '#8B7355', accentColor: '#D4606A' },
  side_story: { icon: '📜', label: '支线', bgColor: '#0A1214', borderColor: '#A9A9A9', accentColor: '#2D5A5A' },
  fate:       { icon: '⚡', label: '命运', bgColor: '#0D0A14', borderColor: '#6B4C7A', accentColor: '#4A3A5C' },
  era:        { icon: '🏮', label: '时代', bgColor: '#14100A', borderColor: '#8B6914', accentColor: '#D4A017' },
  mechanic:   { icon: '⚙️', label: '机制', bgColor: '#0A0F14', borderColor: '#5C7DA3', accentColor: '#4A6FA5' },
  stat_up:    { icon: '📈', label: '数值', bgColor: '#0A1410', borderColor: '#2D6B4F', accentColor: '#3D8B5F' },
  economy:    { icon: '💰', label: '经济', bgColor: '#14100A', borderColor: '#A67C00', accentColor: '#8B6914' },
  blank:      { icon: '🎭', label: '空白', bgColor: '#141210', borderColor: '#C0C0C0', accentColor: '#E8E4DC' },
};

// ========== 事件卡数据接口 ==========
export interface EventCardData {
  id: string;
  type: CardType;
  title: string;
  description: string;
  positiveEffect?: string;   // 正面效果文案
  negativeVariant?: string;   // 负面变奏文案
  rewards?: {
    exp?: number;
    hpUp?: number;
    mpUp?: number;
    reputation?: Record<string, number>;
    skillId?: string;
  };
}

// ========== 选项接口 ==========
export interface CardOption {
  id: string;
  text: string;
  isPositive: boolean;
}

// ========== EventCard Props ==========
interface EventCardProps {
  card: EventCardData;
  options?: CardOption[];
  onSelect?: (option: CardOption) => void;
  onClose?: () => void;
  isAnimating?: boolean;  // 是否播放入场动画
  compatibilityResult?: 'compatible' | 'exclusive' | 'forced' | null;
}

export const EventCard: React.FC<EventCardProps> = ({
  card,
  options = [],
  onSelect,
  onClose,
  isAnimating = false,
  compatibilityResult = null,
}) => {
  const [visible, setVisible] = useState(!isAnimating);
  const [flipped, setFlipped] = useState(false);
  const [selectedOption, setSelectedOption] = useState<CardOption | null>(null);
  const [closing, setClosing] = useState(false);

  const config = CARD_TYPE_CONFIG[card.type];

  // 入场动画序列（review#4修复：timer以card.id为key，每次换卡重置）
  useEffect(() => {
    if (!isAnimating) return;
    setVisible(false);
    setFlipped(false);
    // 抽卡动画：烟雾 → 飞入 → 翻面 → 展开
    const timer1 = setTimeout(() => setVisible(true), 100);
    const timer2 = setTimeout(() => setFlipped(true), 800);
    const timer3 = setTimeout(() => setFlipped(false), 1400);
    return () => {
      clearTimeout(timer1); clearTimeout(timer2); clearTimeout(timer3);
    };
  }, [isAnimating, card.id]); // card.id 变化时重置动画

  const handleOptionSelect = useCallback((option: CardOption) => {
    setSelectedOption(option);
    setClosing(true);
    setTimeout(() => onSelect?.(option), 600);
  }, [onSelect]);

  const handleClose = useCallback(() => {
    setClosing(true);
    setTimeout(() => onClose?.(), 600);
  }, [onClose]);

  return (
    <div className={`event-card-overlay ${closing ? 'event-card-overlay--closing' : ''}`}>
      <div className="event-card-backdrop" onClick={handleClose} />

      <div
        className={[
          'event-card',
          visible ? 'event-card--visible' : '',
          flipped ? 'event-card--flipped' : '',
          `event-card--${card.type}`,
          compatibilityResult ? `event-card--result-${compatibilityResult}` : '',
        ].join(' ')}
      >
        {/* 外框装饰 */}
        <div className="event-card__frame" style={{ borderColor: config.borderColor }}>
          {/* 顶部卷轴装饰 */}
          <div className="event-card__scroll-top">
            <div className="scroll-rod" style={{ background: `linear-gradient(180deg, ${config.borderColor} 0%, transparent 100%)` }} />
          </div>

          {/* 类型角标 */}
          <div
            className="event-card__type-badge"
            style={{ borderColor: config.accentColor, color: config.accentColor }}
          >
            <span className="type-badge-icon">{config.icon}</span>
            <span className="type-badge-label">{config.label}</span>
          </div>

          {/* 标题栏 */}
          <div className="event-card__header" style={{ backgroundColor: `${config.accentColor}22` }}>
            <h2 className="event-card__title" style={{ color: config.accentColor }}>
              {card.title}
            </h2>
          </div>

          {/* 分隔线 */}
          <div className="event-card__divider">
            <span className="divider-line" style={{ background: `linear-gradient(90deg, transparent, ${config.borderColor}, transparent)` }} />
            <span className="divider-icon" style={{ color: config.borderColor }}>☙</span>
            <span className="divider-line" style={{ background: `linear-gradient(90deg, transparent, ${config.borderColor}, transparent)` }} />
          </div>

          {/* 主视觉区（占位，用背景纹理） */}
          <div
            className="event-card__artwork"
            style={{ background: `linear-gradient(135deg, ${config.bgColor} 0%, ${config.accentColor}22 50%, ${config.bgColor} 100%)` }}
          >
            <div className="artwork-mist" />
          </div>

          {/* 描述文案 */}
          <div className="event-card__description-wrapper">
            <p className="event-card__description">{card.description}</p>
          </div>

          {/* 正面/负面效果展示 */}
          {(card.positiveEffect || card.negativeVariant) && (
            <div className="event-card__effects">
              {card.positiveEffect && (
                <div className="effect-box effect-box--positive">
                  <div className="effect-box__header">
                    <span className="effect-icon">✓</span>
                    <span className="effect-label">正面解读</span>
                  </div>
                  <p className="effect-text">{card.positiveEffect}</p>
                </div>
              )}
              {card.negativeVariant && (
                <div className="effect-box effect-box--negative">
                  <div className="effect-box__header">
                    <span className="effect-icon">✗</span>
                    <span className="effect-label">负面变奏</span>
                  </div>
                  <p className="effect-text">{card.negativeVariant}</p>
                </div>
              )}
            </div>
          )}

          {/* 底部卷轴装饰 */}
          <div className="event-card__scroll-bottom">
            <div className="scroll-rod" style={{ background: `linear-gradient(0deg, ${config.borderColor} 0%, transparent 100%)` }} />
          </div>
        </div>

        {/* 选项按钮 */}
        {options.length > 0 && (
          <div className="event-card__options">
            {options.map(option => (
              <button
                key={option.id}
                className={[
                  'event-option-btn',
                  option.isPositive ? 'event-option-btn--positive' : 'event-option-btn--negative',
                  selectedOption?.id === option.id ? 'event-option-btn--selected' : '',
                ].join(' ')}
                onClick={() => handleOptionSelect(option)}
              >
                <span className="option-marker">{option.isPositive ? '✓' : '✗'}</span>
                <span className="option-text">{option.text}</span>
              </button>
            ))}
          </div>
        )}

        {/* 兼容判定特效 */}
        {compatibilityResult && (
          <div className={`compatibility-effect compatibility-effect--${compatibilityResult}`}>
            {compatibilityResult === 'compatible' && <span className="ce-text">兼容触发 ✓</span>}
            {compatibilityResult === 'exclusive' && <span className="ce-text">互斥冲突 ✗</span>}
            {compatibilityResult === 'forced' && <span className="ce-text">强制触发 ⚡</span>}
          </div>
        )}
      </div>

      {/* 跳过提示 */}
      <button className="event-card-skip" onClick={handleClose}>
        点击任意处跳过
      </button>
    </div>
  );
};

export default EventCard;
