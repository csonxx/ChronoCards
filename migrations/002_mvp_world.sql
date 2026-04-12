-- Migration 002: MVP World Map - 6 Core Scenes
-- 无影手文档 v1.0
-- 场景：平阳城 / 武当山 / 少林寺 / 中原野外 / 客栈锚点 / 光明顶

-- ============================================================
-- 1. 地区表 (MVP用一个主区域：中原武林)
-- ============================================================
CREATE TABLE IF NOT EXISTS regions (
    id               VARCHAR(64) PRIMARY KEY,
    name             VARCHAR(64) NOT NULL,
    display_order    INTEGER NOT NULL DEFAULT 0,
    description      TEXT,
    climate          VARCHAR(32),    -- 温带/亚热带/高原等
    terrain          VARCHAR(32),    -- 山地/平原/沙漠等
    danger_level     INTEGER DEFAULT 1,
    tags             TEXT,           -- JSON数组
    connected_regions TEXT,          -- JSON数组，相邻大区ID
    parent_world     VARCHAR(64) DEFAULT 'jiuzhou',
    story_intro      TEXT,           -- 大区剧情介绍
    created_at       TIMESTAMP DEFAULT NOW()
);

INSERT INTO regions (id, name, display_order, description, climate, terrain, danger_level, tags, connected_regions, parent_world, story_intro) VALUES
('region-central-plains', '中原武林', 1,
 '大唐天下的核心区域，群雄割据之地。少林、武当名门正派坐落于此，明教势力暗中崛起，天下将乱。',
 '温带', '平原+山地', 3,
 '["武侠","正邪对峙","明教崛起"]',
 '[]',
 'jiuzhou',
 '大明洪武年间，少林、武当执武林牛耳。然而明教教主野心勃勃，欲一统天下。江湖风云，暗流涌动。'
);

-- ============================================================
-- 2. 场景表 (MVP 6个核心场景)
-- ============================================================
CREATE TABLE IF NOT EXISTS locations (
    id                  VARCHAR(64) PRIMARY KEY,
    name                VARCHAR(64) NOT NULL,
    display_order       INTEGER NOT NULL DEFAULT 0,
    region_id           VARCHAR(64) NOT NULL REFERENCES regions(id),
    location_type       VARCHAR(32) NOT NULL,   -- city/town/village/wilderness/dungeon/special/inn
    location_type_ext   VARCHAR(64),            -- 扩展类型
    description         TEXT,
    atmosphere          TEXT,            -- 场景氛围描述
    danger_level        INTEGER DEFAULT 1, -- 1-5
    npc_count           INTEGER DEFAULT 0,
    available_dealers   TEXT,            -- JSON数组，该场景可用的发牌员类型
    story_chapters      TEXT,            -- JSON数组，关联主线章节
    tags                TEXT,            -- JSON数组
    unlocked            BOOLEAN DEFAULT TRUE,
    unlock_condition    TEXT,            -- 解锁条件
    scene_bg            VARCHAR(128),    -- 背景图资源路径
    music_track         VARCHAR(64),     -- 背景音乐
    created_at          TIMESTAMP DEFAULT NOW()
);

INSERT INTO locations (id, name, display_order, region_id, location_type, location_type_ext, description, atmosphere, danger_level, npc_count, available_dealers, story_chapters, tags, unlocked, scene_bg, music_track) VALUES

-- 场景1：平阳城
-- 用途：玩家主城/出生点/客栈锚点/新手引导
('loc-pingyang', '平阳城', 1, 'region-central-plains', 'city', 'spawn_city',
 '中原繁华小城，商贾云集，市井热闹。城门旁有告示榜，客栈二楼是江湖消息集散地。',
 '繁华热闹，市井烟火',
 1, 80,
 '["teahouse","bounty_board","inn","merchant","training_grounds"]',
 '["ch0","ch1"]',
 '["新手城","主城","商贾云集"]',
 TRUE,
 '/assets/scenes/pingyang_city.webp',
 'pingyang_ambient'
),

-- 场景2：武当山
-- 用途：主线剧情推进/武当派场景
('loc-wudang', '武当山', 2, 'region-central-plains', 'mountain', 'sect_headquarters',
 '道教名山，云雾缭绕，石阶万级。武当派总坛位于山顶，弟子数千，剑法闻名天下。',
 '道骨仙风，云雾飘渺',
 2, 60,
 '["teahouse","bounty_board","inn"]',
 '["ch1","ch2"]',
 '["武当派","道教","名山"]',
 FALSE,
 'unlock_ch1_complete',
 '/assets/scenes/wudang_mountain.webp',
 'wudang_mountain'
),

-- 场景3：少林寺
-- 用途：主线/武学修炼/挑战
('loc-shaolin', '少林寺', 3, 'region-central-plains', 'dungeon', 'sect_headquarters',
 '禅宗祖庭，千年古刹。七十二绝技名震武林，少林武学独步天下。寺中戒备森严，外人禁入后山。',
 '禅意幽深，古木参天',
 3, 120,
 '["teahouse","bounty_board"]',
 '["ch2","ch3"]',
 '["少林派","禅宗","武学圣地"]',
 FALSE,
 'unlock_ch2_complete',
 '/assets/scenes/shaolin_temple.webp',
 'shaolin_temple'
),

-- 场景4：中原野外
-- 用途：野外探索/遭遇战/支线事件
('loc-zhongyuan-wilds', '中原野外', 4, 'region-central-plains', 'wilderness', 'open_world',
 '中原平原边缘，荒草丛生，盗匪出没。北接武当山道，南临少林寺后山小路。',
 '荒凉萧瑟，暗藏杀机',
 4, 5,
 '["bounty_board","dynamic_encounter","environment"]',
 '["ch1","ch2","ch3"]',
 '["野外","危险","盗匪","随机事件"]',
 TRUE,
 '/assets/scenes/central_plains_wilds.webp',
 'wilds_ambient'
),

-- 场景5：客栈锚点
-- 用途：休息/社交/情报/快速旅行
('loc-inn-anchor', '平阳客栈', 5, 'region-central-plains', 'inn', 'social_hub',
 '平阳城中最热闹的客栈，三教九流汇聚之地。掌柜消息灵通，江湖动态尽在掌握。玩家可在此休整、交情报、快速传送到其他客栈。',
 '灯火通明，人声鼎沸',
 1, 30,
 '["teahouse","merchant","inn","information_broker"]',
 '["ch0","ch1","ch2","ch3"]',
 '["客栈","休整","情报","快速旅行"]',
 TRUE,
 '/assets/scenes/inn_anchor.webp',
 'inn_ambient'
),

-- 场景6：光明顶
-- 用途：最终战/主线高潮
('loc-guangming', '光明顶', 6, 'region-central-plains', 'dungeon', 'final_boss',
 '明教总坛，天下至高的山峰之巅。日出时分金光万丈，故名光明顶。教主坐镇于此，野心勃勃欲吞并武林。',
 '气势磅礴，压迫感十足',
 5, 10,
 '["enemy","dynamic_encounter"]',
 '["ch3","final"]',
 '["明教","教主","最终战"]',
 FALSE,
 'unlock_final_battle',
 '/assets/scenes/guangming_summit.webp',
 'boss_battle'
);

-- ============================================================
-- 3. 场景连通性 (场景之间的路径)
-- ============================================================
CREATE TABLE IF NOT EXISTS location_connections (
    id              VARCHAR(64) PRIMARY KEY,
    from_location   VARCHAR(64) NOT NULL REFERENCES locations(id),
    to_location     VARCHAR(64) NOT NULL REFERENCES locations(id),
    connection_type VARCHAR(32) NOT NULL,    -- road/trekking/teleport/story_locked
    travel_time_min INTEGER DEFAULT 15,       -- 旅行时间（分钟）
    danger_level    INTEGER DEFAULT 1,       -- 路上危险等级
    encounter_rate  DECIMAL(4,3) DEFAULT 0.100, -- 遭遇概率 0.000-1.000
    description     TEXT,                    -- 路线描述
    required_items  TEXT,                    -- JSON数组，需要的物品
    unlock_condition TEXT,                   -- 解锁条件
    is bidirectional BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(from_location, to_location)
);

INSERT INTO location_connections (id, from_location, to_location, connection_type, travel_time_min, danger_level, encounter_rate, description, is_bidirectional, unlock_condition) VALUES

-- 平阳城 <-> 武当山 (石阶山道)
('conn-pingyang-wudang', 'loc-pingyang', 'loc-wudang', 'trekking', 30, 2, 0.200,
 '从平阳城西门出发，沿官道向北，步行约两个时辰可达武当山脚。', TRUE, NULL),

-- 平阳城 <-> 中原野外 (城郊荒道)
('conn-pingyang-wilds', 'loc-pingyang', 'loc-zhongyuan-wilds', 'road', 15, 3, 0.400,
 '平阳城北门外即是荒野边缘，荒草丛生，人迹罕至。', TRUE, NULL),

-- 平阳城 <-> 客栈锚点 (城内)
('conn-pingyang-inn', 'loc-pingyang', 'loc-inn-anchor', 'road', 5, 0, 0.000,
 '客栈就在城中心，步行即可到达。', TRUE, NULL),

-- 武当山 <-> 少林寺 (官道)
('conn-wudang-shaolin', 'loc-wudang', 'loc-shaolin', 'road', 45, 3, 0.300,
 '武当少林，相距不远。沿官道一日可至。', TRUE, 'unlock_ch1_complete'),

-- 中原野外 <-> 武当山 (山道)
('conn-wilds-wudang', 'loc-zhongyuan-wilds', 'loc-wudang', 'trekking', 20, 3, 0.350,
 '荒野边缘有小路通往武当山脚，需穿过一片树林。', TRUE, NULL),

-- 中原野外 <-> 少林寺 (后山小路)
('conn-wilds-shaolin', 'loc-zhongyuan-wilds', 'loc-shaolin', 'trekking', 25, 4, 0.400,
 '少林后山小路，荆棘丛生，极少有人通行。', TRUE, 'unlock_ch2_complete'),

-- 少林寺 -> 光明顶 (剧情锁定)
('conn-shaolin-guangming', 'loc-shaolin', 'loc-guangming', 'story_locked', 60, 5, 0.800,
 '少林至光明顶，需穿越明教外围防线。', FALSE, 'unlock_final_battle'),

-- 武当山 -> 光明顶 (剧情锁定)
('conn-wudang-guangming', 'loc-wudang', 'loc-guangming', 'story_locked', 60, 5, 0.800,
 '武当至光明顶，需穿越明教外围防线。', FALSE, 'unlock_final_battle'),

-- 客栈锚点 -> 其他客栈 (快速旅行)
('conn-inn-network', 'loc-inn-anchor', 'loc-inn-anchor', 'teleport', 0, 0, 0.000,
 '客栈网络可实现快速旅行（跨场景传送）。', FALSE, NULL);

-- ============================================================
-- 4. 玩家位置追踪
-- ============================================================
CREATE TABLE IF NOT EXISTS player_locations (
    player_id           VARCHAR(36) PRIMARY KEY REFERENCES players(id),
    current_location    VARCHAR(64) NOT NULL REFERENCES locations(id),
    current_region     VARCHAR(64) NOT NULL REFERENCES regions(id),
    in_battle          BOOLEAN DEFAULT FALSE,
    visited_locations   TEXT,   -- JSON数组，已访问的场景ID
    visited_regions     TEXT,   -- JSON数组，已访问的大区ID
    total_travel_count INTEGER DEFAULT 0,  -- 总旅行次数
    unlocked_locations  TEXT,   -- JSON数组，已解锁的场景ID
    story_progress      TEXT,   -- JSON对象，章节进度
    updated_at         TIMESTAMP DEFAULT NOW(),
    created_at         TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 5. 场景叙事内容（AI生成缓存）
-- ============================================================
CREATE TABLE IF NOT EXISTS location_narratives (
    id              VARCHAR(64) PRIMARY KEY,
    location_id     VARCHAR(64) NOT NULL REFERENCES locations(id),
    scene_type      VARCHAR(32) NOT NULL,   -- arrival/departure/battle/encounter/special
    trigger_type    VARCHAR(32),             -- first_visit/return/seasonal/event
    title           VARCHAR(128),
    narrative       TEXT,                   -- AI生成的叙事内容
    choices_count   INTEGER DEFAULT 0,
    rewards_preview TEXT,                   -- JSON数组，预览奖励
    metadata        TEXT,                   -- JSON对象，元数据
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at       TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 6. 世界状态（全局）
-- ============================================================
CREATE TABLE IF NOT EXISTS world_state (
    key             VARCHAR(64) PRIMARY KEY,
    value           TEXT,
    description     TEXT,
    updated_at      TIMESTAMP DEFAULT NOW()
);

INSERT INTO world_state (key, value, description) VALUES
('world_arc', 'mingjiao_rising', '当前世界剧情线：明教崛起'),
('active_events', '[]', '当前激活的世界事件'),
('npc_roster_version', '1', 'NPC名册版本号');