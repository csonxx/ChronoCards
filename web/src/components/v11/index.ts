// v1.1 事件卡组 UI 组件库导出
// 规范来源：ChronoCards_UI_Design_v1.md (v1.1 审核通过版)

export { CompatibilityMatrix, CARD_TYPE_LIST, getCompatibility, areAllCompatible } from './CompatibilityMatrix';
export type { CardType, CardTypeInfo } from './CompatibilityMatrix';

export { EventCard, CARD_TYPE_CONFIG } from './EventCard';
export type { EventCardData, CardOption } from './EventCard';

export { ExitConditionPanel } from './ExitConditionPanel';
export type { ExitCondition, ExitConditionStatus } from './ExitConditionPanel';

export { AdjustmentPanel, PRESET_LAYERS, PRESET_CONTENT_INDICATORS, PRESET_NUMERIC_INDICATORS } from './AdjustmentPanel';
export type { AdjustmentIndicator, AdjustmentLayer, IndicatorStatus } from './AdjustmentPanel';

export { CardDrawScene } from './CardDrawScene';
