// 移动端虚拟摇杆和交互按钮
import React, { useState, useEffect, useRef, useCallback } from 'react';
import './mobile.css';

interface MobileControlsProps {
  onMove: (dx: number, dy: number) => void;
  onInteract: () => void;
  showInteract?: boolean;
}

// 检测是否为移动端
export const isMobile = (): boolean => {
  return /Android|iPhone|iPad|iPod|Touch/i.test(navigator.userAgent) ||
    ('ontouchstart' in window) ||
    (navigator.maxTouchPoints > 0);
};

export const MobileControls: React.FC<MobileControlsProps> = ({
  onMove,
  onInteract,
  showInteract = false,
}) => {
  const [joystickActive, setJoystickActive] = useState(false);
  const [thumbPos, setThumbPos] = useState({ x: 0, y: 0 });
  const joystickRef = useRef<HTMLDivElement>(null);
  const baseRef = useRef<HTMLDivElement>(null);
  const moveIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const lastDirectionRef = useRef<{ dx: number; dy: number } | null>(null);

  const JOYSTICK_MAX = 38;

  const handleJoystickStart = useCallback((e: React.TouchEvent | MouseEvent) => {
    e.preventDefault();
    setJoystickActive(true);
  }, []);

  const handleJoystickMove = useCallback((e: TouchEvent | MouseEvent) => {
    if (!joystickActive || !baseRef.current) return;
    e.preventDefault();

    const rect = baseRef.current.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;

    let clientX: number, clientY: number;
    if ('touches' in e) {
      clientX = e.touches[0].clientX;
      clientY = e.touches[0].clientY;
    } else {
      clientX = e.clientX;
      clientY = e.clientY;
    }

    let dx = clientX - centerX;
    let dy = clientY - centerY;
    const dist = Math.sqrt(dx * dx + dy * dy);

    if (dist > JOYSTICK_MAX) {
      dx = (dx / dist) * JOYSTICK_MAX;
      dy = (dy / dist) * JOYSTICK_MAX;
    }

    setThumbPos({ x: dx, y: dy });

    // 转换为方向信号
    const nx = Math.abs(dx) > 12 ? Math.round(dx / JOYSTICK_MAX) : 0;
    const ny = Math.abs(dy) > 12 ? Math.round(dy / JOYSTICK_MAX) : 0;
    const dir = { dx: nx, dy: ny };

    if (dir.dx !== 0 || dir.dy !== 0) {
      if (!lastDirectionRef.current ||
          lastDirectionRef.current.dx !== dir.dx ||
          lastDirectionRef.current.dy !== dir.dy) {
        lastDirectionRef.current = dir;
        if (moveIntervalRef.current) clearInterval(moveIntervalRef.current);
        onMove(dir.dx * 20, dir.dy * 20);
        moveIntervalRef.current = setInterval(() => {
          onMove(dir.dx * 20, dir.dy * 20);
        }, 150);
      }
    } else {
      if (lastDirectionRef.current !== null) {
        lastDirectionRef.current = null;
        if (moveIntervalRef.current) {
          clearInterval(moveIntervalRef.current);
          moveIntervalRef.current = null;
        }
      }
    }
  }, [joystickActive, onMove]);

  const handleJoystickEnd = useCallback(() => {
    setJoystickActive(false);
    setThumbPos({ x: 0, y: 0 });
    lastDirectionRef.current = null;
    if (moveIntervalRef.current) {
      clearInterval(moveIntervalRef.current);
      moveIntervalRef.current = null;
    }
  }, []);

  useEffect(() => {
    return () => {
      if (moveIntervalRef.current) clearInterval(moveIntervalRef.current);
    };
  }, []);

  useEffect(() => {
    const el = baseRef.current;
    if (!el) return;

    const onTouchMove = (e: TouchEvent) => handleJoystickMove(e);
    const onTouchEnd = () => handleJoystickEnd();
    const onMouseMove = (e: MouseEvent) => handleJoystickMove(e);
    const onMouseUp = () => handleJoystickEnd();

    if (joystickActive) {
      document.addEventListener('touchmove', onTouchMove, { passive: false });
      document.addEventListener('touchend', onTouchEnd);
      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onMouseUp);
    }

    return () => {
      document.removeEventListener('touchmove', onTouchMove);
      document.removeEventListener('touchend', onTouchEnd);
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
    };
  }, [joystickActive, handleJoystickMove, handleJoystickEnd]);

  return (
    <div className="mobile-controls mobile-controls--active">
      {/* 虚拟摇杆 */}
      <div
        ref={joystickRef}
        className="virtual-joystick"
        onTouchStart={handleJoystickStart}
        onMouseDown={handleJoystickStart as unknown as React.MouseEventHandler<HTMLDivElement>}
      >
        <div ref={baseRef} className="joystick-base">
          <div
            className="joystick-thumb"
            style={{
              transform: `translate(${thumbPos.x}px, ${thumbPos.y}px)`,
            }}
          />
        </div>
      </div>

      {/* 交互按钮 */}
      <button
        className={`mobile-interact-btn ${showInteract ? 'mobile-interact-btn--visible' : ''}`}
        onTouchStart={(e) => { e.preventDefault(); e.stopPropagation(); onInteract(); }}
        onClick={(e) => { e.stopPropagation(); onInteract(); }}
      >
        E
      </button>
    </div>
  );
};

export default MobileControls;
