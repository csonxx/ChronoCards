-- Migration 003: Character Cards (Phase 1 - Luzhe Character Arc)
-- 陆喆角色主导卡事件线基础设施
-- 创建日期：2026-04-14

-- ============================================================
-- 1. 玩家角色状态表
-- 记录玩家在角色主导事件线中的进度
-- ============================================================
CREATE TABLE IF NOT EXISTS player_character_states (
    player_id       VARCHAR(64) NOT NULL,
    character_id    VARCHAR(32) NOT NULL,
    current_phase   VARCHAR(32) NOT NULL DEFAULT 'idle',
    trial_count     INTEGER NOT NULL DEFAULT 0,
    trust_level     INTEGER NOT NULL DEFAULT 0,
    trial_scores    TEXT,                            -- JSON: {yiqi, yongqi, zhihui}
    choices         TEXT,                            -- JSON数组，记录关键选择
    card_history    TEXT,                            -- JSON数组，已触发卡ID序列
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (player_id, character_id)
);

-- ============================================================
-- 2. 角色卡注册表
-- 存储所有角色主导卡的定义
-- ============================================================
CREATE TABLE IF NOT EXISTS character_cards (
    id               VARCHAR(64) PRIMARY KEY,
    character_id     VARCHAR(32) NOT NULL,
    sub_type         VARCHAR(32) NOT NULL,
    title            VARCHAR(128) NOT NULL,
    description      TEXT,
    trigger_conditions TEXT,                        -- JSON数组
    rewards          TEXT,                           -- JSON对象
    ai_prompt_hints  TEXT,                           -- TEXT数组
    priority         INTEGER NOT NULL DEFAULT 5,
    created_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. 初始化陆喆专属卡组
-- ============================================================
INSERT INTO character_cards (id, character_id, sub_type, title, description, trigger_conditions, rewards, ai_prompt_hints, priority) VALUES
(
    'char-luzhe-001',
    'luzhe',
    'encounter',
    '丐帮九袋',
    '江南水乡，平阳客栈外，一个衣衫褴褛的老者正靠在墙角，看似随意，眼神却扫过每一个路过之人。',
    '["first_jiangnan_entry"]',
    '{"reputation": {"zhengpai": 5}}',
    '["陆喆", "丐帮", "九袋帮主", "草根正义"]',
    10
),
(
    'char-luzhe-002',
    'luzhe',
    'trial',
    '江湖试炼',
    '陆喆提出三个江湖考验：义气、勇气、智谋。玩家必须通过至少两项才能获得丐帮认可。',
    '["state:encountered"]',
    '{"exp": 100}',
    '["陆喆", "考验", "江湖道义", "丐帮入门"]',
    9
),
(
    'char-luzhe-003',
    'luzhe',
    'background',
    '身世之谜',
    '通过考验后，陆喆私下透露：你父亲当年与丐帮有一段渊源……此事牵涉三十年前一桩旧案。',
    '["state:trial_passed"]',
    '{"exp": 200, "reputation": {"zhengpai": 10}}',
    '["陆喆", "镖局", "父亲", "三十年前", "身世"]',
    8
),
(
    'char-luzhe-004',
    'luzhe',
    'uprising',
    '丐帮内乱',
    '丐帮内部两派分裂：保守派欲与明教暗中交易，激进派则要正面对抗。陆喆被架空，玩家必须选边站。',
    '["state:background", "main_progress>=30"]',
    '{"reputation": {"zhengpai": -5}}',
    '["丐帮内乱", "明教渗透", "帮派分裂", "陆喆危机"]',
    7
),
(
    'char-luzhe-005a',
    'luzhe',
    'resolution',
    '正道结局：丐帮团结',
    '玩家协助陆喆稳住帮主之位，丐帮成为正派联盟核心，明教势力被压制。',
    '["state:uprising", "choice:support_luzhe"]',
    '{"reputation": {"zhengpai": 50}, "skill_id": "skill-luzhe-stick"}',
    '["正道结局", "丐帮团结", "陆喆胜利"]',
    6
),
(
    'char-luzhe-005b',
    'luzhe',
    'resolution',
    '暗流结局：丐帮分裂',
    '帮内分裂不可挽回，丐帮元气大伤，陆喆远遁江湖。玩家独木难支，正派联盟摇摇欲坠。',
    '["state:uprising", "choice:abandon_luzhe"]',
    '{"reputation": {"zhengpai": -20, "mingjiao": 10}}',
    '["悲剧结局", "丐帮分裂", "陆喆远遁"]',
    5
);

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_character_cards_char ON character_cards(character_id);
CREATE INDEX IF NOT EXISTS idx_player_char_state ON player_character_states(player_id, character_id);
CREATE INDEX IF NOT EXISTS idx_character_cards_priority ON character_cards(priority DESC);
