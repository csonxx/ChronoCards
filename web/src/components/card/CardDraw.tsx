// S3: 抽牌界面 - 核心交互

import React, { useState, useEffect, useCallback } from 'react';
import { CardPaper, Bookmark } from '../ui';
import type { Card, CardOption, CardType } from '../../types';
import './card.css';

interface CardDrawProps {
  card: Card;
  onSelect: (option: CardOption, card: Card) => void;
  onClose: () => void;
}

// 卡牌类型显示配置
const cardTypeConfig: Record<CardType, { label: string; color: string }> = {
  main: { label: '主线', color: 'var(--color-accent)' },
  side: { label: '支线', color: 'var(--color-secondary)' },
  growth: { label: '成长', color: 'var(--color-success)' },
  emotion: { label: '情感', color: 'var(--color-danger)' },
  economy: { label: '经济', color: 'var(--color-secondary)' },
  blank: { label: '空白', color: 'var(--color-text-muted)' },
};

export const CardDraw: React.FC<CardDrawProps> = ({ card, onSelect, onClose }) => {
  const [isAnimating, setIsAnimating] = useState(true);
  const [isClosing, setIsClosing] = useState(false);
  const [selectedOption, setSelectedOption] = useState<CardOption | null>(null);
  const [visibleOptions, setVisibleOptions] = useState<number[]>([]);

  // 入场动画
  useEffect(() => {
    // 卷轴展开动画
    setTimeout(() => {
      setIsAnimating(false);
      // 选项依次出现
      if (card.options) {
        card.options.forEach((_, index) => {
          setTimeout(() => {
            setVisibleOptions(prev => [...prev, index]);
          }, 300 + index * 150);
        });
      }
    }, 800);
  }, [card]);

  // 处理选择
  const handleSelect = useCallback((option: CardOption) => {
    if (isClosing) return;
    setSelectedOption(option);
    
    // 选中动画
    setTimeout(() => {
      setIsClosing(true);
      setTimeout(() => {
        onSelect(option, card);
      }, 600);
    }, 200);
  }, [isClosing, onSelect, card]);

  // 关闭/跳过
  const handleClose = useCallback(() => {
    if (isClosing || isAnimating) return;
    setIsClosing(true);
    setTimeout(onClose, 600);
  }, [isClosing, isAnimating, onClose]);

  const config = cardTypeConfig[card.type];

  return (
    <div className={`card-draw-overlay ${isClosing ? 'card-draw-overlay--closing' : ''}`}>
      <div className="card-draw-backdrop" onClick={handleClose} />
      
      <div className={`card-draw-container ${isAnimating ? 'card-draw-container--expanding' : ''} ${isClosing ? 'card-draw-container--collapsing' : ''}`}>
        {/* 卷轴顶饰 */}
        <div className="scroll-ornament scroll-ornament--top">
          <div className="scroll-rod" />
        </div>

        {/* 卡牌内容 */}
        <CardPaper cardType={card.type} className="card-draw__card">
          {/* 卡牌类型角标 */}
          <div 
            className="card-type-badge"
            style={{ borderColor: config.color, color: config.color }}
          >
            {config.label}
          </div>

          {/* 卡牌标题 */}
          <h2 className="card-title">{card.title}</h2>

          {/* 分隔线 */}
          <div className="card-divider">
            <span className="card-divider__line" />
            <span className="card-divider__icon">☙</span>
            <span className="card-divider__line" />
          </div>

          {/* 卡牌描述 */}
          <p className="card-description">{card.description}</p>

          {/* 选项区域 */}
          {card.options && (
            <div className="card-options">
              {card.options.map((option, index) => {
                const isVisible = visibleOptions.includes(index);
                const isSelected = selectedOption?.id === option.id;
                
                return (
                  <div
                    key={option.id}
                    className={`option-wrapper ${isVisible ? 'option-wrapper--visible' : ''} ${isSelected ? 'option-wrapper--selected' : ''}`}
                  >
                    <Bookmark
                      text={option.text}
                      onClick={() => handleSelect(option)}
                      isSelected={isSelected}
                    />
                  </div>
                );
              })}
            </div>
          )}

          {/* 空选项（空白卡） */}
          {!card.options && (
            <div className="card-no-options">
              <span className="no-options-text">此处留白...</span>
              <button className="continue-btn" onClick={handleClose}>
                继续前行
              </button>
            </div>
          )}
        </CardPaper>

        {/* 卷轴底饰 */}
        <div className="scroll-ornament scroll-ornament--bottom">
          <div className="scroll-rod" />
        </div>
      </div>

      {/* 跳过提示 */}
      <button 
        className="skip-hint"
        onClick={handleClose}
        disabled={isAnimating}
      >
        点击任意处跳过
      </button>
    </div>
  );
};

// 抽牌动画组件
export const CardDrawAnimator: React.FC<{ children: React.ReactNode; isActive: boolean }> = ({ 
  children, 
  isActive 
}) => {
  return (
    <div className={`card-animator ${isActive ? 'card-animator--active' : ''}`}>
      {children}
    </div>
  );
};

export default CardDraw;
