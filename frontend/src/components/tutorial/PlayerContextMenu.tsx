// 玩家头像/角色右键菜单
import React, { useEffect, useRef } from 'react';

export interface ContextMenuItem {
  id: string;
  label: string;
  icon: string;
  onClick: () => void;
  danger?: boolean;
}

interface PlayerContextMenuProps {
  x: number;
  y: number;
  items: ContextMenuItem[];
  onClose: () => void;
}

export const PlayerContextMenu: React.FC<PlayerContextMenuProps> = ({
  x,
  y,
  items,
  onClose,
}) => {
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        onClose();
      }
    };
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('keydown', handleKey);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handleKey);
    };
  }, [onClose]);

  // 调整菜单位置避免超出屏幕
  const adjustedX = Math.min(x, window.innerWidth - 200);
  const adjustedY = Math.min(y, window.innerHeight - items.length * 48 - 20);

  return (
    <div
      ref={menuRef}
      className="player-context-menu"
      style={{ left: adjustedX, top: adjustedY }}
    >
      {items.map(item => (
        <button
          key={item.id}
          className={`player-context-menu__item ${item.danger ? 'player-context-menu__item--danger' : ''}`}
          onClick={() => { item.onClick(); onClose(); }}
        >
          <span className="player-context-menu__item-icon">{item.icon}</span>
          {item.label}
        </button>
      ))}
    </div>
  );
};

export default PlayerContextMenu;
