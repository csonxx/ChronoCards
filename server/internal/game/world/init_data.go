package world

// MVPRegions MVP大区数据
var MVPRegions = []*Region{
	{
		ID: "region-central-plains", Name: "中原武林", DisplayOrder: 1,
		Description: "大唐天下的核心区域，群雄割据之地。少林、武当名门正派坐落于此，明教势力暗中崛起，天下将乱。",
		Climate: "温带", Terrain: "平原+山地", DangerLevel: 3,
		Tags: []string{"武侠", "正邪对峙", "明教崛起"},
		StoryIntro: "大明洪武年间，少林、武当执武林牛耳。然而明教教主野心勃勃，欲一统天下。江湖风云，暗流涌动。",
	},
}

// MVPLocations MVP场景数据（6个核心场景）
var MVPLocations = []*Location{
	{ID: "loc-pingyang", Name: "平阳城", DisplayOrder: 1, RegionID: "region-central-plains",
		LocationType: "city", LocationTypeExt: "spawn_city",
		Description: "中原繁华小城，商贾云集，市井热闹。城门旁有告示榜，客栈二楼是江湖消息集散地。",
		Atmosphere: "繁华热闹，市井烟火", DangerLevel: 1, NPCCount: 80,
		AvailableDealers: []string{"teahouse", "bounty_board", "inn", "merchant", "training_grounds"},
		StoryChapters: []string{"ch0", "ch1"}, Tags: []string{"新手城", "主城", "商贾云集"},
		Unlocked: true, SceneBG: "/assets/scenes/pingyang_city.webp", MusicTrack: "pingyang_ambient"},
	{ID: "loc-wudang", Name: "武当山", DisplayOrder: 2, RegionID: "region-central-plains",
		LocationType: "mountain", LocationTypeExt: "sect_headquarters",
		Description: "道教名山，云雾缭绕，石阶万级。武当派总坛位于山顶，弟子数千，剑法闻名天下。",
		Atmosphere: "道骨仙风，云雾飘渺", DangerLevel: 2, NPCCount: 60,
		AvailableDealers: []string{"teahouse", "bounty_board", "inn"},
		StoryChapters: []string{"ch1", "ch2"}, Tags: []string{"武当派", "道教", "名山"},
		Unlocked: false, UnlockCondition: "unlock_ch1_complete", SceneBG: "/assets/scenes/wudang_mountain.webp", MusicTrack: "wudang_mountain"},
	{ID: "loc-shaolin", Name: "少林寺", DisplayOrder: 3, RegionID: "region-central-plains",
		LocationType: "dungeon", LocationTypeExt: "sect_headquarters",
		Description: "禅宗祖庭，千年古刹。七十二绝技名震武林，少林武学独步天下。寺中戒备森严，外人禁入后山。",
		Atmosphere: "禅意幽深，古木参天", DangerLevel: 3, NPCCount: 120,
		AvailableDealers: []string{"teahouse", "bounty_board"},
		StoryChapters: []string{"ch2", "ch3"}, Tags: []string{"少林派", "禅宗", "武学圣地"},
		Unlocked: false, UnlockCondition: "unlock_ch2_complete", SceneBG: "/assets/scenes/shaolin_temple.webp", MusicTrack: "shaolin_temple"},
	{ID: "loc-zhongyuan-wilds", Name: "中原野外", DisplayOrder: 4, RegionID: "region-central-plains",
		LocationType: "wilderness", LocationTypeExt: "open_world",
		Description: "中原平原边缘，荒草丛生，盗匪出没。北接武当山道，南临少林寺后山小路。",
		Atmosphere: "荒凉萧瑟，暗藏杀机", DangerLevel: 4, NPCCount: 5,
		AvailableDealers: []string{"bounty_board", "dynamic_encounter", "environment"},
		StoryChapters: []string{"ch1", "ch2", "ch3"}, Tags: []string{"野外", "危险", "盗匪", "随机事件"},
		Unlocked: true, SceneBG: "/assets/scenes/central_plains_wilds.webp", MusicTrack: "wilds_ambient"},
	{ID: "loc-inn-anchor", Name: "平阳客栈", DisplayOrder: 5, RegionID: "region-central-plains",
		LocationType: "inn", LocationTypeExt: "social_hub",
		Description: "平阳城中最热闹的客栈，三教九流汇聚之地。掌柜消息灵通，江湖动态尽在掌握。可休整、交情报、快速传送。",
		Atmosphere: "灯火通明，人声鼎沸", DangerLevel: 1, NPCCount: 30,
		AvailableDealers: []string{"teahouse", "merchant", "inn", "information_broker"},
		StoryChapters: []string{"ch0", "ch1", "ch2", "ch3"}, Tags: []string{"客栈", "休整", "情报", "快速旅行"},
		Unlocked: true, SceneBG: "/assets/scenes/inn_anchor.webp", MusicTrack: "inn_ambient"},
	{ID: "loc-guangming", Name: "光明顶", DisplayOrder: 6, RegionID: "region-central-plains",
		LocationType: "dungeon", LocationTypeExt: "final_boss",
		Description: "明教总坛，天下至高的山峰之巅。日出时分金光万丈，故名光明顶。教主坐镇于此，野心勃勃欲吞并武林。",
		Atmosphere: "气势磅礴，压迫感十足", DangerLevel: 5, NPCCount: 10,
		AvailableDealers: []string{"enemy", "dynamic_encounter"},
		StoryChapters: []string{"ch3", "final"}, Tags: []string{"明教", "教主", "最终战"},
		Unlocked: false, UnlockCondition: "unlock_final_battle", SceneBG: "/assets/scenes/guangming_summit.webp", MusicTrack: "boss_battle"},

	// 场景7：苏州城（丐帮江南据点，陆喆事件线触发地）
	{ID: "loc-suzhou", Name: "苏州城", DisplayOrder: 7, RegionID: "region-central-plains",
		LocationType: "city", LocationTypeExt: "faction_headquarters",
		Description: "园林之城，小桥流水。丝绸之府，江南繁华代表。丐帮江南分舵在此扎根，陆喆偶尔现身于此。",
		Atmosphere: "烟雨江南，暗流涌动", DangerLevel: 2, NPCCount: 50,
		AvailableDealers: []string{"teahouse", "inn", "merchant", "gaibang_informant"},
		StoryChapters: []string{"ch2", "ch3"}, Tags: []string{"园林", "丐帮", "江南", "陆喆"},
		Unlocked: true, SceneBG: "/assets/scenes/suzhou_city.webp", MusicTrack: "suzhou_ambient"},
}

// MVPConnections MVP连通性数据（9条）
var MVPConnections = []*LocationConnection{
	{ID: "conn-pingyang-wudang", FromLocation: "loc-pingyang", ToLocation: "loc-wudang", ConnectionType: "trekking", TravelTimeMin: 30, DangerLevel: 2, EncounterRate: 0.200, Description: "从平阳城西门出发，沿官道向北可达武当山脚。", Unlocked: true},
	{ID: "conn-pingyang-wilds", FromLocation: "loc-pingyang", ToLocation: "loc-zhongyuan-wilds", ConnectionType: "road", TravelTimeMin: 15, DangerLevel: 3, EncounterRate: 0.400, Description: "平阳城北门外即是荒野边缘。", Unlocked: true},
	{ID: "conn-pingyang-inn", FromLocation: "loc-pingyang", ToLocation: "loc-inn-anchor", ConnectionType: "road", TravelTimeMin: 5, DangerLevel: 0, EncounterRate: 0.000, Description: "客栈就在城中心，步行即可到达。", Unlocked: true},
	{ID: "conn-wudang-shaolin", FromLocation: "loc-wudang", ToLocation: "loc-shaolin", ConnectionType: "road", TravelTimeMin: 45, DangerLevel: 3, EncounterRate: 0.300, Description: "武当少林，相距不远。沿官道一日可至。", Unlocked: false},
	{ID: "conn-wilds-wudang", FromLocation: "loc-zhongyuan-wilds", ToLocation: "loc-wudang", ConnectionType: "trekking", TravelTimeMin: 20, DangerLevel: 3, EncounterRate: 0.350, Description: "荒野边缘有小路通往武当山脚。", Unlocked: true},
	{ID: "conn-wilds-shaolin", FromLocation: "loc-zhongyuan-wilds", ToLocation: "loc-shaolin", ConnectionType: "trekking", TravelTimeMin: 25, DangerLevel: 4, EncounterRate: 0.400, Description: "少林后山小路，荆棘丛生，极少有人通行。", Unlocked: false},
	{ID: "conn-shaolin-guangming", FromLocation: "loc-shaolin", ToLocation: "loc-guangming", ConnectionType: "story_locked", TravelTimeMin: 60, DangerLevel: 5, EncounterRate: 0.800, Description: "少林至光明顶，需穿越明教外围防线。", Unlocked: false},
	{ID: "conn-wudang-guangming", FromLocation: "loc-wudang", ToLocation: "loc-guangming", ConnectionType: "story_locked", TravelTimeMin: 60, DangerLevel: 5, EncounterRate: 0.800, Description: "武当至光明顶，需穿越明教外围防线。", Unlocked: false},
	{ID: "conn-inn-network", FromLocation: "loc-inn-anchor", ToLocation: "loc-inn-anchor", ConnectionType: "teleport", TravelTimeMin: 0, DangerLevel: 0, EncounterRate: 0.000, Description: "客栈网络可实现快速旅行。", Unlocked: true},

	// 平阳城 <-> 苏州城 (京杭大运河)
	{ID: "conn-pingyang-suzhou", FromLocation: "loc-pingyang", ToLocation: "loc-suzhou", ConnectionType: "road", TravelTimeMin: 20, DangerLevel: 1, EncounterRate: 0.150, Description: "平阳城沿运河南下可达苏州城，水路便捷。", Unlocked: true},
}

// GetLocationByID 根据ID获取场景
func GetLocationByID(id string) *Location {
	for _, loc := range MVPLocations {
		if loc.ID == id {
			return loc
		}
	}
	return nil
}

// GetRegionByID 根据ID获取大区
func GetRegionByID(id string) *Region {
	for _, reg := range MVPRegions {
		if reg.ID == id {
			return reg
		}
	}
	return nil
}
