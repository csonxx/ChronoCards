-- ChronoCards 世界地图 Schema v2.0
-- 文档版本：World Bible v2.0
-- 更新日期：2026-04-11
-- 描述：九州江湖世界拓扑结构 — 大区、场景、玩家位置追踪

-- ============================================================
-- 大区表（Region）
-- 九州江湖分为5大区域
-- ============================================================
CREATE TABLE IF NOT EXISTS regions (
    id               VARCHAR(64) PRIMARY KEY,
    name             VARCHAR(64) NOT NULL,
    display_order    INTEGER NOT NULL DEFAULT 0,     -- 显示排序
    description      TEXT,
    climate          VARCHAR(32),                     -- 温带/亚热带/高原/沙漠/热带
    terrain          VARCHAR(32),                     -- 平原/山水/戈壁/丛林/高原
    danger_level     INTEGER NOT NULL DEFAULT 1,      -- 危险等级1-5
    tags             TEXT,                            -- JSON数组，如["武侠","中原","名门正派"]
    connected_regions TEXT,                           -- JSON数组，可到达的大区ID
    parent_world     VARCHAR(64) NOT NULL DEFAULT 'jiuzhou',
    meta_json        TEXT,                            -- 扩展元数据（图片、配色等）
    created_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 插入九州江湖5大区
INSERT INTO regions (id, name, display_order, description, climate, terrain, danger_level, tags, connected_regions, parent_world) VALUES
    -- 中原武林：天下武学正宗，门派林立
    ('region-central-plains', '中原武林', 1,
     '中原腹地，天下武学正宗所在。少林、武当、华山、嵩山等名门正派皆坐落于此。长安城为帝都，洛阳城为商城，江湖人士络绎不绝。',
     '温带季风', '平原', 2,
     '["武侠","中原","名门正派","帝都"]',
     '["region-jiangnan","region-northwest","region-western-desert"]',
     'jiuzhou'),

    -- 江南水乡：小桥流水，侠骨柔情
    ('region-jiangnan', '江南水乡', 2,
     '小桥流水，烟雨朦胧。苏州城的园林、杭州城的西湖、扬州城的运河，构成一幅诗意江湖。桃花岛神秘莫测，丐帮总舵位于此地。',
     '亚热带季风', '山水', 1,
     '["武侠","江南","水乡","诗酒风流"]',
     '["region-central-plains","region-southern-jungles"]',
     'jiuzhou'),

    -- 西北边塞：苍茫边塞，马革裹尸
    ('region-northwest', '西北边塞', 3,
     '黄沙漫漫，古城敦煌见证丝路辉煌。天山派独占雪山之巅，昆仑派隐于西极。兰州城是进入西域的门户，也是抵御外敌的前线。',
     '温带大陆性', '戈壁', 3,
     '["武侠","边塞","黄沙","塞外"]',
     '["region-central-plains","region-western-desert"]',
     'jiuzhou'),

    -- 西域大漠：神秘禁地，强者禁入
    ('region-western-desert', '西域大漠', 4,
     '沙海无垠，楼兰古城湮没于风沙之中。火焰山酷热难耐，昆仑山高耸入云。此地多有奇遇，亦多凶险，非高手不可深入。',
     '热带沙漠', '沙漠', 4,
     '["武侠","西域","禁地","奇遇"]',
     '["region-northwest","region-southern-jungles"]',
     'jiuzhou'),

    -- 南疆雨林：瘴气蛊毒，神秘莫测
    ('region-southern-jungles', '南疆雨林', 5,
     '热带雨林，瘴气弥漫。大理国皇室笃信佛教，苗疆蛊术神秘诡异。毒蟾蜍、五毒教令人闻风丧胆，但亦有珍贵草药灵丹。',
     '热带季风', '丛林', 4,
     '["武侠","南疆","蛊毒","秘境"]',
     '["region-jiangnan","region-western-desert"]',
     'jiuzhou')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 具体场景表（Location）
-- 每个大区下有多个具体地点
-- ============================================================
CREATE TABLE IF NOT EXISTS locations (
    id                 VARCHAR(64) PRIMARY KEY,
    name               VARCHAR(64) NOT NULL,
    display_order      INTEGER NOT NULL DEFAULT 0,
    region_id          VARCHAR(64) NOT NULL REFERENCES regions(id),
    location_type      VARCHAR(32) NOT NULL,         -- city/town/village/wilderness/dungeon/special
    location_type_ext  VARCHAR(32),                  -- 扩展类型：capital/port/trading_hub/stronghold/secret_realm
    description        TEXT,
    danger_level       INTEGER NOT NULL DEFAULT 1,   -- 1-5
    npc_count          INTEGER DEFAULT 0,            -- 驻留NPC数量（影响遭遇概率）
    available_dealers  TEXT,                         -- JSON数组，该地点可用的发牌员类型
    story_chapters     TEXT,                         -- JSON数组，关联的主线章节ID
    tags               TEXT,                         -- JSON数组
    unlocked           BOOLEAN NOT NULL DEFAULT TRUE,
    unlock_condition   TEXT,                         -- 解锁条件描述
    unlock_requirements TEXT,                        -- JSON对象，解锁所需具体条件
    meta_json          TEXT,                         -- 扩展元数据
    created_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 中原武林场景
INSERT INTO locations (id, name, display_order, region_id, location_type, location_type_ext, description, danger_level, npc_count, available_dealers, story_chapters, tags, unlocked) VALUES
    ('loc-changan', '长安城', 1, 'region-central-plains', 'city', 'capital',
     '十三朝古都，大唐帝国的心脏。城阙巍峨，街市繁华。武林盟主大会常在此召开，天下英雄汇聚。',
     2, 120, '["teahouse","bounty_board","merchant","inn","training grounds"]',
     '["ch1","ch2"]',
     '["帝都","繁华","武林中枢"]',
     TRUE),

    ('loc-luoyang', '洛阳城', 2, 'region-central-plains', 'city', 'trading_hub',
     '九州通衢，商业之都。牡丹花城，侠客与商贾云集。城中有黑市交易，亦有官方武馆。',
     2, 80, '["teahouse","bounty_board","merchant","inn"]',
     '["ch1"]',
     '["商城","黑市","牡丹"]',
     TRUE),

    ('loc-songshan', '嵩山少林', 3, 'region-central-plains', 'town', 'stronghold',
     '少林寺坐落于此，天下武学之源。金钟罩、易筋经名震江湖。寺中高手如云，非请勿入。',
     3, 30, '["teahouse","training grounds"]',
     '["ch3"]',
     '["少林","佛门","武学正宗"]',
     TRUE),

    ('loc-huashan', '华山派', 4, 'region-central-plains', 'town', 'stronghold',
     '西岳华山，剑宗圣地。华山论剑，天下瞩目。悬崖峭壁之上，剑意凛然。',
     3, 25, '["teahouse","training grounds","inn"]',
     '["ch2","ch3"]',
     '["华山","剑宗","险峻"]',
     TRUE),

    ('loc-wudang', '武当山', 5, 'region-central-plains', 'town', 'stronghold',
     '道教圣地，武当派总舵。太极拳剑以柔克刚，内家功夫登峰造极。',
     3, 20, '["teahouse","training grounds","inn"]',
     '["ch2","ch3"]',
     '["武当","道门","内家"]',
     TRUE),

    ('loc-henshan', '衡山派', 6, 'region-central-plains', 'town', 'stronghold',
     '南岳衡山，五岳剑派之一。剑法精妙，轻灵飘逸。山下有热闹的集市。',
     2, 15, '["teahouse","bounty_board","inn","merchant"]',
     '["ch2"]',
     '["衡山","剑派","集市"]',
     TRUE);

-- 江南水乡场景
INSERT INTO locations (id, name, display_order, region_id, location_type, location_type_ext, description, danger_level, npc_count, available_dealers, story_chapters, tags, unlocked) VALUES
    ('loc-suzhou', '苏州城', 1, 'region-jiangnan', 'city', 'trading_hub',
     '园林之城，小桥流水。丝绸之府，江南繁华代表。城中文人雅士众多，亦有隐秘的江湖势力。',
     1, 60, '["teahouse","inn","merchant","teahouse"]',
     '["ch2","ch4"]',
     '["园林","丝绸","文人"]',
     TRUE),

    ('loc-hangzhou', '杭州城', 2, 'region-jiangnan', 'city', 'port',
     '西湖美景，胜过天堂。临安故都，宋韵犹存。岳王庙祭祀岳飞，城中侠义之风盛行。',
     1, 70, '["teahouse","bounty_board","inn","merchant"]',
     '["ch2","ch4"]',
     '["西湖","繁华","侠义"]',
     TRUE),

    ('loc-yangzhou', '扬州城', 3, 'region-jiangnan', 'city', 'trading_hub',
     '淮左名都，盐商聚集。瘦西湖畔，烟花三月。扬州镖局名震天下，护镖生意兴隆。',
     1, 50, '["teahouse","inn","merchant","bounty_board"]',
     '["ch2"]',
     '["盐商","镖局","繁华"]',
     TRUE),

    ('loc-taohua', '桃花岛', 4, 'region-jiangnan', 'town', 'secret_realm',
     '东海桃花岛，黄药师隐居之地。岛上阵法玄奥，机关重重。珍奇药材、武学秘籍无数。',
     3, 10, '["teahouse","merchant","training grounds"]',
     '["ch5"]',
     '["桃花岛","东邪","秘境"]',
     TRUE),

    ('loc-gaibang', '丐帮总舵', 5, 'region-jiangnan', 'town', 'stronghold',
     '天下乞丐皆兄弟，丐帮总舵隐秘于临安城中。污衣派与净衣派之争从未停歇，帮众数以万计。',
     2, 40, '["teahouse","bounty_board","inn"]',
     '["ch3","ch4"]',
     '["丐帮","天下第一大帮"]',
     TRUE),

    ('loc-qingyun', '青云庄', 6, 'region-jiangnan', 'village', 'special',
     '太湖之畔的小村庄，宁静祥和。村民淳朴好客，常有落难侠客在此休养。',
     1, 20, '["inn","teahouse"]',
     '["ch1"]',
     '["村庄","宁静","休养"]',
     TRUE);

-- 西北边塞场景
INSERT INTO locations (id, name, display_order, region_id, location_type, location_type_ext, description, danger_level, npc_count, available_dealers, story_chapters, tags, unlocked) VALUES
    ('loc-lanzhou', '兰州城', 1, 'region-northwest', 'city', 'trading_hub',
     '黄河穿城而过，丝绸之路重镇。入疆门户，商旅必经之地。城中多元文化交融，胡汉杂居。',
     3, 40, '["teahouse","inn","merchant","bounty_board"]',
     '["ch4","ch5"]',
     '["边塞","黄河","丝路"]',
     TRUE),

    ('loc-dunhuang', '敦煌城', 2, 'region-northwest', 'city', 'port',
     '莫高窟佛光普照，敦煌古城见证丝路辉煌。壁画千佛，精美绝伦。此地亦是多路高手争夺秘宝之地。',
     3, 25, '["teahouse","inn","merchant","bounty_board"]',
     '["ch5"]',
     '["敦煌","莫高窟","丝路"]',
     TRUE),

    ('loc-tianshan', '天山派', 3, 'region-northwest', 'town', 'stronghold',
     '天山之巅，终年积雪。天山派剑法独步天下，童姥灵鹫宫威震西域。攀上绝壁，方见仙境。',
     4, 15, '["teahouse","training grounds","inn"]',
     '["ch5","ch6"]',
     '["天山","灵鹫宫","雪山"]',
     TRUE),

    ('loc-qilian', '祁连山', 4, 'region-northwest', 'wilderness', 'special',
     '祁连山脚下，水草丰美。游牧民族在此放牧，亦有马贼出没。偶有猎人发现珍贵药材。',
     3, 8, '["bounty_board","teahouse"]',
     '["ch4"]',
     '["雪山","游牧","马贼"]',
     TRUE),

    ('loc-yumen', '玉门关', 5, 'region-northwest', 'wilderness', 'special',
     '春风不度玉门关，古老关隘残垣断壁。边塞诗篇多出于此，是进入西域的北路要冲。',
     4, 5, '["bounty_board","inn"]',
     '["ch5"]',
     '["玉门关","边塞","古关"]',
     TRUE);

-- 西域大漠场景
INSERT INTO locations (id, name, display_order, region_id, location_type, location_type_ext, description, danger_level, npc_count, available_dealers, story_chapters, tags, unlocked) VALUES
    ('loc-loulan', '楼兰古城', 1, 'region-western-desert', 'dungeon', 'secret_realm',
     '湮没于沙漠的古老王国，神秘消失之谜至今未解。古城遗迹中藏有古代秘宝，亦有致命机关。',
     5, 3, '["bounty_board","merchant"]',
     '["ch6"]',
     '["楼兰","沙漠","秘境","危险"]',
     FALSE, '完成主线章节"楼兰遗迹"后方可进入'),

    ('loc-kunlun', '昆仑山', 2, 'region-western-desert', 'town', 'stronghold',
     '万山之祖，神话起源地。昆仑派超然物外，弟子稀少但皆为高手。山中多奇珍异兽。',
     4, 10, '["teahouse","training grounds","inn","merchant"]',
     '["ch5","ch6"]',
     '["昆仑","神话","仙山"]',
     TRUE),

    ('loc-huoyan', '火焰山', 3, 'region-western-desert', 'wilderness', 'special',
     '火焰滔滔，热浪滚滚。虽有夸大，但此地确为酷热难耐之所。红孩儿传说流传甚广。',
     4, 5, '["bounty_board","inn"]',
     '["ch6"]',
     '["火焰山","酷热","传说"]',
     TRUE),

    ('loc-shazhou', '沙洲镇', 4, 'region-western-desert', 'town', 'trading_hub',
     '沙漠边缘的绿洲小镇，商旅休憩之所。胡商云集，珍稀货物在此交易。酒馆中消息灵通。',
     3, 20, '["teahouse","inn","merchant","bounty_board"]',
     '["ch5","ch6"]',
     '["绿洲","商镇","胡商"]',
     TRUE),

    ('loc-hameng', '黑沙漠', 5, 'region-western-desert', 'wilderness', 'dungeon',
     '昼夜温差极大的黑色沙漠，指南针在此失灵。传闻有上古遗迹藏于沙下，迷路者九死一生。',
     5, 2, '["bounty_board"]',
     '["ch6"]',
     '["黑沙漠","危险","迷路"]',
     FALSE, '需获得"沙漠指南针"道具方可进入');

-- 南疆雨林场景
INSERT INTO locations (id, name, display_order, region_id, location_type, location_type_ext, description, danger_level, npc_count, available_dealers, story_chapters, tags, unlocked) VALUES
    ('loc-kunming', '昆明城', 1, 'region-southern-jungles', 'city', 'trading_hub',
     '春城，四季如春。南疆最大城市，多民族聚居。城外滇池碧波荡漾，城内茶马互市繁华。',
     3, 45, '["teahouse","inn","merchant","bounty_board"]',
     '["ch6","ch7"]',
     '["春城","多民族","互市"]',
     TRUE),

    ('loc-dali', '大理国', 2, 'region-southern-jungles', 'city', 'capital',
     '段氏皇族，佛光普照。天龙寺佛学、武学皆为巅峰。一阳指、六脉神剑名震江湖。',
     3, 35, '["teahouse","inn","merchant","training grounds"]',
     '["ch6","ch7"]',
     '["大理","段氏","佛门"]',
     TRUE),

    ('loc-miaojiang', '苗疆蛊地', 3, 'region-southern-jungles', 'town', 'secret_realm',
     '蛊术圣地，令江湖中人闻风丧胆。五毒教总坛所在，擅使蛊毒。来者若无防备，九死一生。',
     5, 15, '["teahouse","merchant","bounty_board"]',
     '["ch7"]',
     '["苗疆","蛊毒","五毒教","危险"]',
     FALSE, '需完成支线任务"化解苗疆恩怨"方可进入'),

    ('loc-yunnan-wild', '云南野林', 4, 'region-southern-jungles', 'wilderness', 'special',
     '原始森林，瘴气弥漫。珍稀草药多出于此，亦有猛兽毒虫出没。猎人常在此采药冒险。',
     4, 10, '["bounty_board","inn","teahouse"]',
     '["ch6"]',
     '["野林","瘴气","草药","危险"]',
     TRUE),

    ('loc-yongling', '永灵寨', 5, 'region-southern-jungles', 'village', 'special',
     '深山中的苗寨，与世隔绝。村民热情好客，保存着古老的巫术传统。寨中有珍贵的解毒秘方。',
     3, 25, '["inn","teahouse","merchant"]',
     '["ch6","ch7"]',
     '["苗寨","解毒","传统"]',
     TRUE);

-- ============================================================
-- 玩家当前位置表
-- 记录玩家当前所在的大区和场景，以及访问历史
-- ============================================================
CREATE TABLE IF NOT EXISTS player_locations (
    player_id          VARCHAR(36) PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
    current_location   VARCHAR(64) NOT NULL REFERENCES locations(id),
    current_region     VARCHAR(64) NOT NULL REFERENCES regions(id),
    visited_locations  TEXT NOT NULL DEFAULT '[]',    -- JSON数组，已访问的场景ID
    visited_regions    TEXT NOT NULL DEFAULT '[]',    -- JSON数组，已访问的大区ID
    travel_count       INTEGER NOT NULL DEFAULT 0,   -- 累计旅行次数
    total_distance     INTEGER NOT NULL DEFAULT 0,    -- 累计移动距离（简化计算）
    last_travel_at     TIMESTAMP,
    created_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 新玩家默认在苏州城（江南水乡）
-- 注意：此触发器仅在 player_locations 表有新记录时自动设置默认值
-- 实际游戏中，create_player 时应同时创建 player_locations 记录

-- ============================================================
-- 世界拓扑表（可选，用于复杂的连通性计算）
-- ============================================================
CREATE TABLE IF NOT EXISTS world_connections (
    id              VARCHAR(64) PRIMARY KEY,
    from_location   VARCHAR(64) NOT NULL REFERENCES locations(id),
    to_location     VARCHAR(64) NOT NULL REFERENCES locations(id),
    connection_type VARCHAR(32) NOT NULL,         -- road/river/mountain/teleport/special
    distance        INTEGER NOT NULL DEFAULT 1,   -- 距离（影响旅行时间）
    danger_level    INTEGER DEFAULT 1,             -- 路上危险等级
    required_items  TEXT,                          -- JSON数组，通过所需道具
    description     TEXT,
    blocked         BOOLEAN DEFAULT FALSE,        -- 是否被阻挡（如剧情锁）
    blocked_reason  TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 添加主要城市间连接
INSERT INTO world_connections (id, from_location, to_location, connection_type, distance, danger_level, description) VALUES
    -- 中原武林内部
    ('conn-cs-ly', 'loc-changan', 'loc-luoyang', 'road', 2, 1, '洛阳古道，官道平坦'),
    ('conn-cs-ss', 'loc-changan', 'loc-songshan', 'road', 1, 1, '嵩山山道，需半日路程'),
    ('conn-cs-hs', 'loc-changan', 'loc-huashan', 'road', 3, 2, '华山小路，较崎岖'),
    ('conn-cs-wd', 'loc-changan', 'loc-wudang', 'road', 4, 2, '武当方向，需翻山越岭'),
    ('conn-ly-ss', 'loc-luoyang', 'loc-songshan', 'road', 1, 1, '少林寺山脚'),
    ('conn-ly-hs', 'loc-luoyang', 'loc-huashan', 'road', 2, 1, '两城之间有小路'),
    ('conn-ss-wd', 'loc-songshan', 'loc-wudang', 'mountain', 3, 2, '两山之间，山路难行'),
    ('conn-hs-hn', 'loc-huashan', 'loc-henshan', 'road', 2, 2, '南岳方向'),

    -- 江南水乡内部
    ('conn-sz-hz', 'loc-suzhou', 'loc-hangzhou', 'river', 1, 1, '京杭大运河，水路便捷'),
    ('conn-sz-yz', 'loc-suzhou', 'loc-yangzhou', 'river', 2, 1, '运河水道'),
    ('conn-hz-yz', 'loc-hangzhou', 'loc-yangzhou', 'road', 2, 1, '陆路相通'),
    ('conn-sz-qy', 'loc-suzhou', 'loc-qingyun', 'road', 1, 1, '太湖方向'),
    ('conn-qy-hz', 'loc-qingyun', 'loc-hangzhou', 'river', 1, 1, '太湖水路'),

    -- 跨区域连接
    ('conn-cs-sz', 'loc-changan', 'loc-suzhou', 'road', 8, 2, '南北大通道，最繁忙的商路'),
    ('conn-cs-hz', 'loc-changan', 'loc-hangzhou', 'road', 10, 2, '京杭大道'),
    ('conn-ly-yz', 'loc-luoyang', 'loc-yangzhou', 'river', 3, 1, '汴河水道'),
    ('conn-lz-gb', 'loc-lanzhou', 'loc-gaibang', 'road', 2, 1, '进入临安前哨'),

    -- 西北边塞内部
    ('conn-lz-dh', 'loc-lanzhou', 'loc-dunhuang', 'road', 5, 3, '河西走廊'),
    ('conn-lz-ts', 'loc-lanzhou', 'loc-tianshan', 'mountain', 6, 4, '天山方向，路途遥远'),
    ('conn-lz-ym', 'loc-lanzhou', 'loc-yumen', 'road', 4, 3, '通往玉门关'),
    ('conn-dh-sz', 'loc-dunhuang', 'loc-shazhou', 'road', 3, 2, '沙洲方向'),
    ('conn-ts-ql', 'loc-tianshan', 'loc-qilian', 'mountain', 3, 3, '祁连山脚'),

    -- 西域大漠内部
    ('conn-sz-ll', 'loc-shazhou', 'loc-loulan', 'road', 7, 5, '深入沙漠，危险'),
    ('conn-sz-kl', 'loc-shazhou', 'loc-kunlun', 'mountain', 5, 4, '昆仑山脚'),
    ('conn-sz-hy', 'loc-shazhou', 'loc-huoyan', 'road', 3, 3, '火焰山方向'),
    ('conn-kl-hy', 'loc-kunlun', 'loc-huoyan', 'road', 2, 3, '山中相连'),
    ('conn-hy-hm', 'loc-huoyan', 'loc-hameng', 'wilderness', 4, 5, '黑沙漠边缘'),

    -- 南疆雨林内部
    ('conn-km-dl', 'loc-kunming', 'loc-dali', 'road', 3, 2, '滇池湖畔'),
    ('conn-km-yw', 'loc-kunming', 'loc-yunnan-wild', 'road', 2, 3, '野林方向'),
    ('conn-km-yl', 'loc-kunming', 'loc-yongling', 'road', 4, 3, '深山苗寨'),
    ('conn-dl-mj', 'loc-dali', 'loc-miaojiang', 'road', 5, 4, '通往蛊地'),
    ('conn-dl-yl', 'loc-dali', 'loc-yongling', 'road', 2, 2, '苗寨方向'),

    -- 跨区域大通道
    ('conn-sz-lz', 'loc-hangzhou', 'loc-lanzhou', 'road', 25, 3, '南北大动脉'),
    ('conn-lz-km', 'loc-lanzhou', 'loc-kunming', 'road', 15, 4, '西宁-拉萨-昆明线'),
    ('conn-dh-sz', 'loc-dunhuang', 'loc-shazhou', 'road', 3, 2, '进入西域'),
    ('conn-ts-kl', 'loc-tianshan', 'loc-kunlun', 'mountain', 4, 4, '两山之间')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 场景详细描述表（可选，用于AI生成叙事内容）
-- ============================================================
CREATE TABLE IF NOT EXISTS location_descriptions (
    id            VARCHAR(64) PRIMARY KEY,
    location_id   VARCHAR(64) NOT NULL REFERENCES locations(id),
    narrative_style VARCHAR(32),                   -- 武侠/恐怖/喜剧等
    base_description TEXT,                         -- 基础描述
    atmosphere    TEXT,                            -- 氛围描写
    notable_npcs  TEXT,                            -- 知名NPC列表
    secrets       TEXT,                            -- 隐藏秘密
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO location_descriptions (id, location_id, narrative_style, base_description, atmosphere, notable_npcs, secrets) VALUES
    ('ldesc-changan', 'loc-changan', '武侠',
     '长安城，十三朝古都，城墙高耸，护城河环绕。街道宽阔，朱雀大街直通皇宫。',
     '繁华热闹，商铺林立，酒旗招展。江湖人士与达官贵人摩肩接踵。',
     '武林盟主萧千秋、茶馆说书人张老、中书令大人',
     '皇城地下有密道通往城外，据说与波斯商人有关'),
    ('ldesc-taohua', 'loc-taohua', '武侠',
     '东海桃花岛，漫天桃花如霞。岛上布置精妙，按后天八卦排列，外人极易迷路。',
     '桃花纷飞，落英缤纷，美不胜收。然而阵中暗藏杀机，不可轻举妄动。',
     '桃花岛主黄药师（已离开）、哑仆阿祥',
     '岛中央有桃花阵眼，破阵需按特定顺序'),
    ('ldesc-loulan', 'loc-loulan', '恐怖',
     '湮没于沙漠的古城，残垣断壁间依稀可见昔日辉煌。狂风呼啸，沙粒打在脸上生疼。',
     '死寂笼罩，阴风阵阵。传闻深夜可闻古国哀嚎，迷路者往往有去无回。',
     '守陵人（身份不明）',
     '古城地下有密室，藏有古代秘宝与机关')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_regions_world ON regions(parent_world);
CREATE INDEX IF NOT EXISTS idx_regions_danger ON regions(danger_level);
CREATE INDEX IF NOT EXISTS idx_locations_region ON locations(region_id);
CREATE INDEX IF NOT EXISTS idx_locations_type ON locations(location_type);
CREATE INDEX IF NOT EXISTS idx_locations_unlocked ON locations(unlocked);
CREATE INDEX IF NOT EXISTS idx_player_locations_region ON player_locations(current_region);
CREATE INDEX IF NOT EXISTS idx_world_connections_from ON world_connections(from_location);
CREATE INDEX IF NOT EXISTS idx_world_connections_to ON world_connections(to_location);

-- ============================================================
-- 变更记录
-- ============================================================
-- v2.0 (2026-04-11): 新增世界地图功能
--   - regions: 九州江湖5大区
--   - locations: 35+具体场景
--   - player_locations: 玩家位置追踪
--   - world_connections: 场景间连通性
--   - location_descriptions: AI叙事扩展数据
