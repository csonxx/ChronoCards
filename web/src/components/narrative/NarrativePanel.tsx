// NarrativePanel - AI叙事内容展示组件
// 显示 event_narrative 事件推送的水墨风格叙事内容

import React, { useState, useEffect, useCallback } from 'react';
import './narrative.css';

export interface NarrativeData {
  trigger_type: string;
  player_id: string;
  card_id?: string;
  card_title?: string;
  dealer_id?: string;
  location?: string;
  content: {
    text: string;
    dialogue?: string;
    atmosphere?: string;
    audio_cue?: string;
  };
  display_duration_ms: number;
}

interface NarrativePanelProps {
  data: NarrativeData | null;
  onDismiss?: () => void;
}

export const NarrativePanel: React.FC<NarrativePanelProps> = ({ data, onDismiss }) => {
  const [visible, setVisible] = useState(false);
  const [isAnimating, setIsAnimating] = useState(false);
  const [displayText, setDisplayText] = useState('');

  useEffect(() => {
    if (data) {
      setVisible(true);
      setIsAnimating(true);
      setDisplayText('');

      // 文字逐字显示效果
      const fullText = data.content.text;
      let index = 0;
      const speed = Math.max(20, Math.min(80, fullText.length / (data.display_duration_ms / 1000) * 1000));

      const interval = setInterval(() => {
        if (index < fullText.length) {
          setDisplayText(fullText.slice(0, index + 1));
          index++;
        } else {
          clearInterval(interval);
        }
      }, speed);

      // 自动关闭
      const timer = setTimeout(() => {
        setIsAnimating(false);
        setTimeout(() => {
          setVisible(false);
          onDismiss?.();
        }, 800);
      }, data.display_duration_ms);

      return () => {
        clearInterval(interval);
        clearTimeout(timer);
      };
    }
  }, [data, onDismiss]);

  const handleSkip = useCallback(() => {
    if (data) {
      setDisplayText(data.content.text);
      setIsAnimating(false);
      setTimeout(() => {
        setVisible(false);
        onDismiss?.();
      }, 300);
    }
  }, [data, onDismiss]);

  if (!visible && !data) return null;

  return (
    <div className={`narrative-overlay ${visible ? 'narrative-overlay--visible' : ''}`}>
      <div className={`narrative-panel ${isAnimating ? 'narrative-panel--animating' : ''}`} onClick={handleSkip}>
        {/* 水墨装饰边框 */}
        <div className="narrative-border narrative-border--top" />
        
        {/* 标题区 */}
        {data?.card_title && (
          <div className="narrative-header">
            <span className="narrative-card-title">{data.card_title}</span>
          </div>
        )}

        {/* 主要叙事文本 */}
        <div className="narrative-content">
          <p className="narrative-text">{displayText}</p>
          
          {/* 对话气泡（如果AI生成了对话） */}
          {data?.content.dialogue && (
            <div className="narrative-dialogue">
              <span className="dialogue-quote">"</span>
              <span className="dialogue-text">{data.content.dialogue}</span>
              <span className="dialogue-quote">"</span>
            </div>
          )}
        </div>

        {/* 氛围标签 */}
        {data?.content.atmosphere && (
          <div className="narrative-atmosphere">
            <span className="atmosphere-tag">{data.content.atmosphere}</span>
          </div>
        )}

        {/* 跳过提示 */}
        {isAnimating && (
          <div className="narrative-skip-hint">点击任意处跳过</div>
        )}

        <div className="narrative-border narrative-border--bottom" />
      </div>
    </div>
  );
};

export default NarrativePanel;