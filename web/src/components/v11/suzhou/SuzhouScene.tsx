// 苏州城场景组件 v1.0
// 集成区域导航 + 事件卡触发器 + 事件卡展示

import React, { useState, useCallback } from 'react';
import {
  SuzhouEventCard,
  SuzhouZoneNav,
  SuzhouEventTrigger,
  SUZHOU_EVENT_CARDS,
  SUZHOU_CARD_OPTIONS,
  SUZHOU_ZONES,
  type SuzhouCardId,
} from './index';
import './suzhouCards.css';

interface SuzhouSceneProps {
  onCardTriggered?: (cardId: string) => void;
  onBack?: () => void;
}

export const SuzhouScene: React.FC<SuzhouSceneProps> = ({ onCardTriggered, onBack }) => {
  const [activeCard, setActiveCard] = useState<SuzhouCardId | null>(null);
  const [currentZone, setCurrentZone] = useState<keyof typeof SUZHOU_ZONES>('guaniqian');

  const handleCardTrigger = useCallback((cardId: SuzhouCardId) => {
    setActiveCard(cardId);
    onCardTriggered?.(cardId);
  }, [onCardTriggered]);

  const handleCardClose = useCallback(() => {
    setActiveCard(null);
  }, []);

  const handleOptionSelect = useCallback((optionId: string, cardId: SuzhouCardId) => {
    const cardOptions = SUZHOU_CARD_OPTIONS[cardId];
    if (cardOptions?.optionOutcomes?.[optionId]) {
      console.log(`[Suzhou] 选择了「${cardOptions.options.find(o => o.id === optionId)?.text}」:`, cardOptions.optionOutcomes[optionId]);
    }
    onCardTriggered?.(cardId);
  }, [onCardTriggered]);

  const handleZoneSelect = useCallback((zone: keyof typeof SUZHOU_ZONES) => {
    setCurrentZone(zone);
  }, []);

  // 获取当前区域触发点位置
  const getTriggerLocations = (zone: keyof typeof SUZHOU_ZONES): Record<SuzhouCardId, string | undefined> => {
    const locationMap: Record<keyof typeof SUZHOU_ZONES, Record<SuzhouCardId, string | undefined>> = {
      guaniqian: {
        sz_main_shangmi: '观前街·总商会门口',
        sz_side_sichou: '观前街·绸缎庄',
        sz_emotion_wupeng: undefined,
        sz_emotion_lengxiang: undefined,
        sz_side_huqiu: undefined,
        sz_fate_zhuozheng: undefined,
        sz_era_chengyun: undefined,
      },
      zhuozheng: {
        sz_main_shangmi: undefined,
        sz_side_sichou: undefined,
        sz_emotion_wupeng: undefined,
        sz_emotion_lengxiang: undefined,
        sz_side_huqiu: undefined,
        sz_fate_zhuozheng: '拙政园入口',
        sz_era_chengyun: undefined,
      },
      changmen: {
        sz_main_shangmi: undefined,
        sz_side_sichou: undefined,
        sz_emotion_wupeng: '阊门外·码头（夜间）',
        sz_emotion_lengxiang: undefined,
        sz_side_huqiu: undefined,
        sz_fate_zhuozheng: undefined,
        sz_era_chengyun: '阊门外·码头（第二日清晨）',
      },
      huqiu: {
        sz_main_shangmi: undefined,
        sz_side_sichou: undefined,
        sz_emotion_wupeng: undefined,
        sz_emotion_lengxiang: '虎丘山·冷香阁',
        sz_side_huqiu: '虎丘山·剑冢石碑',
        sz_fate_zhuozheng: undefined,
        sz_era_chengyun: undefined,
      },
    };
    return locationMap[zone];
  };

  const triggerLocs = getTriggerLocations(currentZone);

  return (
    <div className="suzhou-scene">
      {/* 顶部标题栏 */}
      <div className="suzhou-scene-header">
        <button className="suzhou-back-btn" onClick={onBack}>← 返回</button>
        <h1 className="suzhou-scene-title">🏮 苏州城</h1>
        <div className="suzhou-scene-subtitle">
          <span>江南水乡 · 商帮重镇</span>
        </div>
      </div>

      {/* 主视觉区 */}
      <div className="suzhou-scene-artwork">
        <div className="suzhou-scene-bg" data-zone={currentZone} />
        <div className="suzhou-scene-overlay" />
        {/* 当前区域名称 */}
        <div className="suzhou-zone-label">
          {currentZone === 'guaniqian' && '观前街'}
          {currentZone === 'zhuozheng' && '拙政园'}
          {currentZone === 'changmen' && '阊门外'}
          {currentZone === 'huqiu' && '虎丘山'}
        </div>
      </div>

      {/* 区域导航 */}
      <SuzhouZoneNav currentZone={currentZone} onZoneSelect={handleZoneSelect} />

      {/* 事件触发器列表 */}
      <div className="suzhou-scene-triggers">
        <h3 className="triggers-title">📜 当前区域事件</h3>
        <div className="triggers-list">
          {(Object.keys(SUZHOU_EVENT_CARDS) as SuzhouCardId[]).map(cardId => {
            const loc = triggerLocs[cardId];
            if (!loc) return null;
            const card = SUZHOU_EVENT_CARDS[cardId];
            return (
              <SuzhouEventTrigger
                key={cardId}
                cardId={cardId}
                location={loc}
                onTrigger={handleCardTrigger}
              />
            );
          })}
        </div>
      </div>

      {/* 事件卡弹窗 */}
      {activeCard && (
        <SuzhouEventCard
          cardId={activeCard}
          visible={true}
          onClose={handleCardClose}
          onOptionSelect={handleOptionSelect}
          triggerLocation={triggerLocs[activeCard]}
        />
      )}
    </div>
  );
};

export default SuzhouScene;
