// 古卷风 UI 组件库

import React from 'react';
import './ui.css';

// ========== 古卷按钮 ==========

interface ScrollButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  className?: string;
}

export const ScrollButton: React.FC<ScrollButtonProps> = ({
  children,
  onClick,
  variant = 'primary',
  size = 'md',
  disabled = false,
  className = '',
}) => {
  return (
    <button
      className={`scroll-button scroll-button--${variant} scroll-button--${size} ${className}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
};

// ========== 卷轴书签 ==========

interface BookmarkProps {
  text: string;
  onClick?: () => void;
  isActive?: boolean;
  isSelected?: boolean;
  disabled?: boolean;
}

export const Bookmark: React.FC<BookmarkProps> = ({
  text,
  onClick,
  isActive = false,
  isSelected = false,
  disabled = false,
}) => {
  return (
    <button
      className={`bookmark ${isActive ? 'bookmark--active' : ''} ${isSelected ? 'bookmark--selected' : ''}`}
      onClick={onClick}
      disabled={disabled}
    >
      <span className="bookmark__text">{text}</span>
    </button>
  );
};

// ========== 墨水进度条 ==========

interface InkProgressBarProps {
  value: number;
  max: number;
  color?: 'hp' | 'stamina' | 'qi' | 'sword-intent' | 'progress';
  showLabel?: boolean;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export const InkProgressBar: React.FC<InkProgressBarProps> = ({
  value,
  max,
  color = 'progress',
  showLabel = false,
  size = 'md',
  className = '',
}) => {
  const percentage = Math.min(100, Math.max(0, (value / max) * 100));
  const isLow = color === 'hp' && percentage < 30;

  return (
    <div className={`ink-bar ink-bar--${size} ${className}`}>
      <div className="ink-bar__track">
        <div 
          className={`ink-bar__fill ink-bar__fill--${color} ${isLow ? 'ink-bar__fill--low' : ''}`}
          style={{ width: `${percentage}%` }}
        />
      </div>
      {showLabel && (
        <span className="ink-bar__label">
          {value}/{max}
        </span>
      )}
    </div>
  );
};

// ========== 古卷面板 ==========

interface ScrollPanelProps {
  children: React.ReactNode;
  title?: string;
  variant?: 'paper' | 'scroll' | 'wood';
  className?: string;
}

export const ScrollPanel: React.FC<ScrollPanelProps> = ({
  children,
  title,
  variant = 'paper',
  className = '',
}) => {
  return (
    <div className={`scroll-panel scroll-panel--${variant} ${className}`}>
      {title && <div className="scroll-panel__title">{title}</div>}
      <div className="scroll-panel__content">{children}</div>
    </div>
  );
};

// ========== 宣纸卡片 ==========

interface CardPaperProps {
  children: React.ReactNode;
  cardType?: 'main' | 'side' | 'growth' | 'emotion' | 'economy' | 'blank';
  className?: string;
}

export const CardPaper: React.FC<CardPaperProps> = ({
  children,
  cardType,
  className = '',
}) => {
  return (
    <div className={`card-paper ${cardType ? `card-paper--${cardType}` : ''} ${className}`}>
      {cardType && <div className="card-paper__corner" />}
      {children}
    </div>
  );
};

// ========== 元素图标 ==========

interface ElementIconProps {
  element: 'fire' | 'water' | 'thunder' | 'ice' | 'wind' | 'poison';
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
}

const elementLabels: Record<string, string> = {
  fire: '火',
  water: '水',
  thunder: '雷',
  ice: '冰',
  wind: '风',
  poison: '毒',
};

export const ElementIcon: React.FC<ElementIconProps> = ({
  element,
  size = 'md',
  showLabel = false,
}) => {
  return (
    <div className={`element-icon element-icon--${element} element-icon--${size}`}>
      <span className="element-icon__symbol">{elementLabels[element]}</span>
      {showLabel && <span className="element-icon__label">{elementLabels[element]}</span>}
    </div>
  );
};

// ========== 印章图标 ==========

interface SealIconProps {
  type: string;
  size?: 'sm' | 'md' | 'lg';
  color?: 'primary' | 'danger' | 'success';
}

export const SealIcon: React.FC<SealIconProps> = ({
  type,
  size = 'md',
  color = 'primary',
}) => {
  return (
    <div className={`seal-icon seal-icon--${size} seal-icon--${color}`}>
      {type}
    </div>
  );
};

// ========== 抽牌进度条 ==========

interface CardProgressProps {
  current: number;
  total: number;
  recentCards?: string[];
}

export const CardProgress: React.FC<CardProgressProps> = ({
  current,
  total,
  recentCards = [],
}) => {
  const progress = total > 0 ? (current / total) * 100 : 0;

  return (
    <div className="card-progress">
      <div className="card-progress__track">
        <div 
          className="card-progress__fill"
          style={{ width: `${progress}%` }}
        />
        <div 
          className="card-progress__marker"
          style={{ left: `${progress}%` }}
        />
      </div>
      <div className="card-progress__cards">
        {recentCards.slice(0, 3).map((card, index) => (
          <div key={index} className="card-progress__card-mini">
            {card}
          </div>
        ))}
      </div>
    </div>
  );
};

// ========== 古卷顶栏 ==========

interface TopBarProps {
  title?: string;
  subtitle?: string;
  showSettings?: boolean;
  onSettingsClick?: () => void;
}

export const TopBar: React.FC<TopBarProps> = ({
  title = 'ChronoCards',
  subtitle,
  showSettings = true,
  onSettingsClick,
}) => {
  return (
    <header className="top-bar">
      <div className="top-bar__title">
        <h1 className="top-bar__h1">{title}</h1>
        {subtitle && <span className="top-bar__subtitle">{subtitle}</span>}
      </div>
      {showSettings && (
        <button className="top-bar__settings" onClick={onSettingsClick}>
          ⚙️
        </button>
      )}
    </header>
  );
};

// ========== 导出组件列表 ==========

export const UIComponents = {
  ScrollButton,
  Bookmark,
  InkProgressBar,
  ScrollPanel,
  CardPaper,
  ElementIcon,
  SealIcon,
  CardProgress,
  TopBar,
};
