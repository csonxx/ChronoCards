// 新手引导 - 水墨武侠卷轴风
import React, { useState, useCallback } from 'react';
import './tutorial.css';

interface TutorialStep {
  id: string;
  title: string;
  content: string;
  highlight?: string;
  action?: string;
  audio?: string;
}

const TUTORIAL_STEPS: TutorialStep[] = [
  {
    id: 'welcome',
    title: '欢迎来到 ChronoCards',
    content: '你将扮演一位江湖游侠，在武林中冒险、抽卡、战斗。\n准备好开始了吗？',
    audio: '/assets/audio/tutorial_narration.mp3',
    action: 'next',
  },
  {
    id: 'move',
    title: '移动操作',
    content: '使用 WASD 或方向键在地图上移动。\n靠近NPC或发牌员时，按 E 键与其交互。',
    action: 'next',
  },
  {
    id: 'dealers',
    title: '地图上的交互点',
    content: '地图上散布着各种NPC：说书人、悬赏栏、掌柜、商贩…\n靠近后按 E 与他们对话获取卡牌！',
    action: 'next',
  },
  {
    id: 'cards',
    title: '卡牌选择',
    content: '与NPC对话后会获得卡牌。\n选择卡牌上的选项将影响你的故事走向。谨慎选择！',
    action: 'next',
  },
  {
    id: 'mobile',
    title: '移动端操作',
    content: '移动端可在左下角使用虚拟摇杆移动，\n右下角出现交互按钮时点击即可交互。请保持横屏体验最佳！',
    action: 'done',
  },
];

const TUTORIAL_KEY = 'chronocards_tutorial_done';

interface TutorialOverlayProps {
  onComplete: () => void;
}

export const TutorialOverlay: React.FC<TutorialOverlayProps> = ({ onComplete }) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [isVisible, setIsVisible] = useState(true);
  const [isClosing, setIsClosing] = useState(false);

  const step = TUTORIAL_STEPS[currentStep];

  const handleNext = useCallback(() => {
    // Play step audio
    if (TUTORIAL_STEPS[currentStep]?.audio) {
      const audio = new Audio(TUTORIAL_STEPS[currentStep].audio!);
      audio.volume = 0.7;
      audio.play().catch(() => {});
    }
    if (currentStep < TUTORIAL_STEPS.length - 1) {
      setCurrentStep(prev => prev + 1);
    } else {
      try {
        localStorage.setItem(TUTORIAL_KEY, 'true');
      } catch (_e) {}
      setIsClosing(true);
      setTimeout(() => {
        setIsVisible(false);
        onComplete();
      }, 600);
    }
  }, [currentStep, onComplete]);

  const handleSkip = useCallback(() => {
    try {
      localStorage.setItem(TUTORIAL_KEY, 'true');
    } catch (_e) {}
    setIsClosing(true);
    setTimeout(() => {
      setIsVisible(false);
      onComplete();
    }, 600);
  }, [onComplete]);

  if (!isVisible) return null;

  return (
    <div className={`tutorial-overlay ${isClosing ? 'tutorial-overlay--closing' : ''}`}>
      <div className="tutorial-backdrop" />
      <div className="tutorial-modal">
        {/* 卷轴顶部装饰 */}
        <div className="tutorial-modal__scroll-rod tutorial-modal__scroll-rod--top" />
        
        {/* 顶部区域 */}
        <div className="tutorial-modal__header">
          <div className="tutorial-modal__step-badge">
            {currentStep + 1} / {TUTORIAL_STEPS.length}
          </div>
          <button className="tutorial-modal__skip" onClick={handleSkip}>
            跳过教程
          </button>
        </div>

        {/* 标题 - 毛笔书法 */}
        <h2 className="tutorial-modal__title">{step.title}</h2>

        {/* 水墨分隔线 */}
        <div className="tutorial-divider">
          <span className="tutorial-divider__line" />
          <span className="tutorial-divider__icon">❧</span>
          <span className="tutorial-divider__line" />
        </div>

        {/* 内容 - 宣纸风格 */}
        <p className="tutorial-modal__content">{step.content}</p>

        {/* 步骤指示器 */}
        <div className="tutorial-steps-indicator">
          {TUTORIAL_STEPS.map((_, index) => (
            <div
              key={index}
              className={`tutorial-step-dot ${index === currentStep ? 'tutorial-step-dot--active' : ''} ${index < currentStep ? 'tutorial-step-dot--done' : ''}`}
            />
          ))}
        </div>

        {/* 按钮 - 古风木质 */}
        <div className="tutorial-modal__actions">
          {step.action === 'done' ? (
            <button className="scroll-button scroll-button--lg tutorial-btn tutorial-btn--primary" onClick={handleNext}>
              我学会了，开始冒险！
            </button>
          ) : (
            <button className="scroll-button scroll-button--lg tutorial-btn tutorial-btn--primary" onClick={handleNext}>
              下一条 ❧
            </button>
          )}
        </div>

        {/* 卷轴底部装饰 */}
        <div className="tutorial-modal__scroll-rod tutorial-modal__scroll-rod--bottom" />
      </div>
    </div>
  );
};

// 检查是否应该显示教程
export const shouldShowTutorial = (): boolean => {
  try {
    return localStorage.getItem(TUTORIAL_KEY) !== 'true';
  } catch (_e) {
    return true;
  }
};

// 重置教程
export const resetTutorial = (): void => {
  try {
    localStorage.removeItem(TUTORIAL_KEY);
  } catch (_e) {}
};

export default TutorialOverlay;
