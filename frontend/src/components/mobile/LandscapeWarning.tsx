// 横屏锁定提示组件
import React, { useState, useEffect } from 'react';

interface LandscapeWarningProps {
  enabled?: boolean;
}

export const LandscapeWarning: React.FC<LandscapeWarningProps> = ({ enabled = true }) => {
  const [isLandscape, setIsLandscape] = useState(false);
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkMobile = /Android|iPhone|iPad|iPod|Touch/i.test(navigator.userAgent) ||
      ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);
    setIsMobile(checkMobile);

    if (!checkMobile || !enabled) return;

    const checkOrientation = () => {
      setIsLandscape(window.innerWidth > window.innerHeight);
    };

    // 初始检测
    checkOrientation();

    // 监听变化
    window.addEventListener('resize', checkOrientation);
    window.addEventListener('orientationchange', checkOrientation);

    return () => {
      window.removeEventListener('resize', checkOrientation);
      window.removeEventListener('orientationchange', checkOrientation);
    };
  }, [enabled]);

  if (!isMobile || !isLandscape) return null;

  return (
    <div className="landscape-warning landscape-warning--visible">
      <div className="landscape-warning__icon">📱</div>
      <h2 className="landscape-warning__title">请旋转至横屏</h2>
      <p className="landscape-warning__text">
        为了获得最佳游戏体验<br />
        请将设备横向放置
      </p>
    </div>
  );
};

export default LandscapeWarning;
