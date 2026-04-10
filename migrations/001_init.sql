-- ChronoCards 数据库 Schema v1.0
-- 文档版本：World Bible v1.5
-- 更新日期：2026-04-10

-- ============================================================
-- 玩家表
-- ============================================================
CREATE TABLE IF NOT EXISTS players (
    id              VARCHAR(36) PRIMARY KEY,
    name            VARCHAR(32) NOT NULL,
    level           INTEGER NOT NULL DEFAULT 1,
    exp             INTEGER NOT NULL DEFAULT 0,
    hp              INTEGER NOT NULL DEFAULT 100,
    max_hp          INTEGER NOT NULL DEFAULT 100,
    mp              INTEGER NOT NULL DEFAULT 100,
    max_mp          INTEGER NOT NULL DEFAULT 100,
    sword_intent    INTEGER NOT NULL DEFAULT 0,     -- 0-100
    stamina         INTEGER NOT NULL DEFAULT 100,
    max_stamina     INTEGER NOT NULL DEFAULT 100,
    -- 六元素精通
    elem_wind       INTEGER NOT NULL DEFAULT 0,
    elem_fire       INTEGER NOT NULL DEFAULT 0,
    elem_water      INTEGER NOT NULL DEFAULT 0,
    elem_thunder    INTEGER NOT NULL DEFAULT 0,
    elem_ice        INTEGER NOT NULL DEFAULT 0,
    elem_poison     INTEGER NOT NULL DEFAULT 0,
    -- 阵营
    faction         VARCHAR(32) NOT NULL DEFAULT 'none',
    rep_mingjiao    INTEGER NOT NULL DEFAULT 0,
    rep_zhengpai    INTEGER NOT NULL DEFAULT 0,
    rep_jinyiwei    INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 玩家技能表
CREATE TABLE IF NOT EXISTS player_skills (
    player_id   VARCHAR(36) NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    skill_id    VARCHAR(64) NOT NULL,
    acquired_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (player_id, skill_id)
);

-- 玩家卡组关联表
CREATE TABLE IF NOT EXISTS player_decks (
    player_id   VARCHAR(36) NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    deck_id     VARCHAR(36) NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (player_id, deck_id)
);

-- ============================================================
-- 卡组表
-- ============================================================
CREATE TABLE IF NOT EXISTS decks (
    id              VARCHAR(36) PRIMARY KEY,
    player_id       VARCHAR(36) NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    name            VARCHAR(64) NOT NULL DEFAULT '默认卡组',
    current_index   INTEGER NOT NULL DEFAULT 0,   -- 抽牌指针
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 卡组卡牌表（有序）
CREATE TABLE IF NOT EXISTS deck_cards (
    deck_id     VARCHAR(36) NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    card_id     VARCHAR(36) NOT NULL,
    position    INTEGER NOT NULL,                   -- 卡牌在卡组中的位置
    card_type   VARCHAR(32) NOT NULL,                -- main_story/side_story/skill_unlock/stat_up/emotion/economy/blank
    title       VARCHAR(128) NOT NULL,
    description TEXT,
    priority    INTEGER NOT NULL DEFAULT 0,
    ai_hints    TEXT,                                -- JSON数组
    rewards     TEXT,                                -- JSON对象
    PRIMARY KEY (deck_id, card_id)
);

-- 已抽手牌表
CREATE TABLE IF NOT EXISTS drawn_hand (
    deck_id     VARCHAR(36) NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    card_id     VARCHAR(36) NOT NULL,
    draw_order  INTEGER NOT NULL,
    drawn_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (deck_id, card_id)
);

-- 弃牌堆表
CREATE TABLE IF NOT EXISTS discard_pile (
    deck_id     VARCHAR(36) NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    card_id     VARCHAR(36) NOT NULL,
    discarded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (deck_id, card_id)
);

-- ============================================================
-- 发牌员表
-- ============================================================
CREATE TABLE IF NOT EXISTS dealers (
    id                  VARCHAR(64) PRIMARY KEY,
    type                VARCHAR(32) NOT NULL,  -- teahouse/bounty_board/enemy/inn/merchant/dynamic_encounter/environment
    name                VARCHAR(64) NOT NULL,
    location            VARCHAR(128) NOT NULL,
    description         TEXT,
    interaction_prompt  TEXT,
    weight              INTEGER NOT NULL DEFAULT 1,  -- 触发权重
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 默认发牌员数据
INSERT INTO dealers (id, type, name, location, description, interaction_prompt, weight) VALUES
    ('teahouse-1', 'teahouse', '茶馆说书人', '中原武林-长安城', '茶馆中的老说书人，知晓无数江湖秘闻', '说书人轻敲桌面：客官，可想听一段江湖旧事？', 2),
    ('bounty-1', 'bounty_board', '悬赏公告栏', '中原武林-洛阳城', '江湖悬赏告示板，张贴着各类悬赏任务', '悬赏公告栏上贴满了江湖悬赏令', 2),
    ('inn-1', 'inn', '悦来客栈', '江南水乡-苏州城', '江湖著名的连锁客栈', '客栈掌柜笑迎：客官，楼上雅间请', 3),
    ('merchant-1', 'merchant', '神秘商贩', '随机', '行踪不定的神秘商人', '商贩神秘兮兮：客官，我这有些稀罕物件...', 1),
    ('enemy-1', 'enemy', '山道匪帮', '西北边塞', '山道上的匪徒', '匪徒跪地求饶：饶命！我说！', 1),
    ('dynamic-1', 'dynamic_encounter', '动态遭遇', '随机', '开放世界中随机生成的遭遇', '前方似乎有什么动静...', 2)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 战斗状态表（用于持久化/存档）
-- ============================================================
CREATE TABLE IF NOT EXISTS battle_states (
    player_id           VARCHAR(36) PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
    current_hp          INTEGER NOT NULL,
    current_mp          INTEGER NOT NULL,
    current_stamina     INTEGER NOT NULL,
    current_sword_intent INTEGER NOT NULL,
    last_updated        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 元素附着状态
CREATE TABLE IF NOT EXISTS element_attachments (
    id          VARCHAR(36) PRIMARY KEY,
    target_id   VARCHAR(36) NOT NULL,           -- player_id or enemy_id
    target_type VARCHAR(16) NOT NULL,            -- 'player' or 'enemy'
    element     VARCHAR(16) NOT NULL,            -- wind/fire/water/thunder/ice/poison
    stacks      INTEGER NOT NULL DEFAULT 1,      -- 1-5层
    expires_at  TIMESTAMP NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 状态效果（燃烧/冻结/中毒等）
CREATE TABLE IF NOT EXISTS status_effects (
    id          VARCHAR(36) PRIMARY KEY,
    target_id   VARCHAR(36) NOT NULL,
    target_type VARCHAR(16) NOT NULL,
    effect_type VARCHAR(16) NOT NULL,            -- burn/freeze/poison/paralyze/slow
    stacks      INTEGER NOT NULL DEFAULT 1,
    dps         REAL NOT NULL DEFAULT 0,         -- 每秒伤害
    duration_sec REAL NOT NULL,
    effects_json TEXT,                            -- JSON存储特殊效果
    expires_at  TIMESTAMP NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 叙事记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS narrative_logs (
    id              VARCHAR(36) PRIMARY KEY,
    player_id       VARCHAR(36) NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    trigger_type    VARCHAR(32) NOT NULL,        -- dealer_interact/card_drawn/battle_start/...
    card_id         VARCHAR(36),
    dealer_id       VARCHAR(64),
    location        VARCHAR(128),
    ai_model        VARCHAR(64),
    tokens_used     INTEGER,
    title           VARCHAR(256),
    narrative_text  TEXT,
    choices_json    TEXT,                         -- JSON数组
    rewards_json    TEXT,                         -- JSON数组
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_players_faction ON players(faction);
CREATE INDEX IF NOT EXISTS idx_decks_player ON decks(player_id);
CREATE INDEX IF NOT EXISTS idx_deck_cards_deck ON deck_cards(deck_id);
CREATE INDEX IF NOT EXISTS idx_dealers_type ON dealers(type);
CREATE INDEX IF NOT EXISTS idx_element_attachments_target ON element_attachments(target_id, target_type);
CREATE INDEX IF NOT EXISTS idx_narrative_logs_player ON narrative_logs(player_id);

-- ============================================================
-- 变更记录
-- ============================================================
-- v1.0 (2026-04-10): 初始版本
--   - players: 玩家核心属性
--   - decks: 事件卡组
--   - dealers: 发牌员
--   - battle_states: 战斗状态快照
--   - element_attachments: 元素附着
--   - status_effects: 状态效果
--   - narrative_logs: AI叙事记录
