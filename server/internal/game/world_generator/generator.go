package world_generator

import (
	"fmt"
	"math/rand"
	"strings"
	"time"

)

// Generator 世界事件生成器
type Generator struct {
	factionRelations map[string]map[string]string // 阵营关系矩阵
	regionProfiles  map[string]*RegionProfile
}

// RegionProfile 区域设定
type RegionProfile struct {
	Name        string
	Description string
	Factions    []string // 主要势力
	Climate     string
	Culture     string
}

// NewGenerator 创建生成器
func NewGenerator() *Generator {
	return &Generator{
		factionRelations: map[string]map[string]string{
			"mingjiao": {"shaolin": "对立", "wudang": "对立", "jinyiwei": "对立", "wudu": "合作", "gaibang": "合作"},
			"shaolin":  {"mingjiao": "对立", "wudang": "联盟", "jinyiwei": "对立", "wudu": "对立", "gaibang": "中立"},
			"wudang":   {"mingjiao": "对立", "shaolin": "联盟", "jinyiwei": "对立", "wudu": "对立", "gaibang": "中立"},
			"jinyiwei": {"mingjiao": "对立", "shaolin": "对立", "wudang": "对立", "wudu": "中立", "gaibang": "对立"},
			"wudu":     {"mingjiao": "合作", "shaolin": "对立", "wudang": "对立", "jinyiwei": "中立", "gaibang": "中立"},
			"gaibang":  {"mingjiao": "合作", "shaolin": "中立", "wudang": "中立", "jinyiwei": "对立", "wudu": "中立"},
		},
		regionProfiles: map[string]*RegionProfile{
			"suzhou": {
				Name:        "苏州城",
				Description: "江南水乡，繁华富庶，丐帮势力庞大",
				Factions:    []string{"gaibang", "wudang"},
				Climate:     "温润多雨",
				Culture:     "文人雅士，江湖商会",
			},
			"jiangnan": {
				Name:        "江南地区",
				Description: "鱼米之乡，门派林立，正道根基深厚",
				Factions:    []string{"shaolin", "wudang", "gaibang"},
				Climate:     "温和",
				Culture:     "正道，武侠正道联盟核心",
			},
			"gaibang": {
				Name:        "丐帮总舵",
				Description: "隐秘山谷，乞丐聚集，草根江湖代表",
				Factions:    []string{"gaibang", "mingjiao"},
				Climate:     "干燥",
				Culture:     "草根，义气，实用主义",
			},
			"mingjiao": {
				Name:        "光明顶",
				Description: "西域明教总坛，圣火燃烧，革命根据地",
				Factions:    []string{"mingjiao", "wudu"},
				Climate:     "严寒",
				Culture:     "圣火，革命，异端",
			},
		},
	}
}

// WorldEvent 世界事件
type WorldEvent struct {
	ID          string
	Title       string
	Description string
	Region      string
	Faction     string
	EventType   string // encounter/tales/reputation/plot
	Options     []EventOption
	Rewards     []string
}

// EventOption 事件选项
type EventOption struct {
	Text        string
	Outcome     string
	Reputation  map[string]int // 声望变化
	KillIntent  map[string]int // 杀意值变化
	Items       []string
}

// GenerateEvent 生成随机世界事件
func (g *Generator) GenerateEvent(region string, playerFaction string, playerReputation map[string]int) *WorldEvent {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	eventTypes := []string{"encounter", "tales", "reputation", "plot"}
	eventType := eventTypes[r.Intn(len(eventTypes))]

	_, ok := g.regionProfiles[region]
	if !ok {
		region = "jiangnan"
	}

	// 基于玩家阵营和声望生成事件
	events := g.buildEventPool(region, playerFaction, playerReputation, eventType)
	if len(events) == 0 {
		return g.generateDefaultEvent(region, eventType)
	}

	return events[r.Intn(len(events))]
}

// buildEventPool 构建事件池
func (g *Generator) buildEventPool(region, playerFaction string, reputation map[string]int, eventType string) []*WorldEvent {
	var events []*WorldEvent
	for _, faction := range g.regionProfiles[region].Factions {
		relation := g.getRelation(playerFaction, faction)

		switch eventType {
		case "encounter":
			events = append(events, g.generateEncounterEvent(faction, relation))
		case "reputation":
			events = append(events, g.generateReputationEvent(faction, relation))
		case "tales":
			events = append(events, g.generateTalesEvent(faction))
		case "plot":
			events = append(events, g.generatePlotEvent(faction, relation, reputation))
		}
	}

	return events
}

// generateEncounterEvent 生成遭遇事件
func (g *Generator) generateEncounterEvent(faction, relation string) *WorldEvent {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	npcTemplates := map[string][]string{
		"mingjiao": {"明教弟子", "烈火旗武士", "风云三使"},
		"shaolin":  {"少林武僧", "罗汉堂弟子", "扫地僧"},
		"wudang":   {"武当弟子", "太极道长", "武当七侠"},
		"jinyiwei": {"锦衣卫", "百户", "指挥使"},
		"wudu":     {"五毒教徒", "蛊师", "毒娘"},
		"gaibang":  {"丐帮弟子", "九袋长老", "帮主"},
	}

	npcs := npcTemplates[faction]
	npc := npcs[r.Intn(len(npcs))]

	titles := map[string][]string{
		"联盟":    {fmt.Sprintf("%s向你点头致意", npc), fmt.Sprintf("%s邀请你共饮", npc)},
		"合作":    {fmt.Sprintf("%s寻求合作", npc), fmt.Sprintf("%s带来消息", npc)},
		"中立":    {fmt.Sprintf("%s擦肩而过", npc), fmt.Sprintf("%s在街边休息", npc)},
		"对立":    {fmt.Sprintf("%s拔刀相向", npc), fmt.Sprintf("%s发出威胁", npc)},
	}

	relationTitles := titles[relation]
	title := relationTitles[r.Intn(len(relationTitles))]

	return &WorldEvent{
		ID:          fmt.Sprintf("enc_%s_%d", faction, r.Intn(10000)),
		Title:       title,
		Description: g.buildEncounterDescription(faction, relation, npc),
		Region:      "",
		Faction:     faction,
		EventType:   "encounter",
		Options:     g.buildEncounterOptions(faction, relation),
		Rewards:     []string{},
	}
}

// buildEncounterDescription 构建遭遇描述
func (g *Generator) buildEncounterDescription(faction, relation, npc string) string {
	templates := map[string]string{
		"联盟":    fmt.Sprintf("你遇到了%v，对方以%v礼相待。作为同道的你们，可以互相扶持。", npc, g.getFactionName(faction)),
		"合作":    fmt.Sprintf("%v向你走来，似乎有事相求。%v虽非盟友，但利益一致时也能合作。", npc, g.getFactionName(faction)),
		"中立":    fmt.Sprintf("街道上，%v与你擦肩而过。%v目前对你没有特别态度。", npc, g.getFactionName(faction)),
		"对立":    fmt.Sprintf("%v挡在你面前，眼中满是敌意！%v的追杀令似乎已经生效。", npc, g.getFactionName(faction)),
	}
	return templates[relation]
}

// buildEncounterOptions 构建遭遇选项
func (g *Generator) buildEncounterOptions(faction, relation string) []EventOption {
	baseOptions := []EventOption{
		{Text: "主动问候", Outcome: "你上前打招呼"},
		{Text: "保持警惕", Outcome: "你保持距离观察"},
	}

	switch relation {
	case "联盟":
		return append(baseOptions, EventOption{
			Text:        "深入交谈",
			Outcome:     "你们进行了深入交流",
			Reputation:  map[string]int{faction: 5},
		})
	case "合作":
		return append(baseOptions, EventOption{
			Text:        "接受合作",
			Outcome:     "你们达成了合作协议",
			Reputation:  map[string]int{faction: 3},
		})
	case "中立":
		return append(baseOptions, EventOption{
			Text:        "交换情报",
			Outcome:     "你们交换了一些江湖消息",
		})
	case "对立":
		return append(baseOptions,
			EventOption{
				Text:        "正面对抗",
				Outcome:     "你选择先发制人",
				Reputation:  map[string]int{faction: -10},
				KillIntent:  map[string]int{faction: 20},
			},
			EventOption{
				Text:        "暂时退避",
				Outcome:     "你选择避其锋芒",
				Reputation:  map[string]int{faction: 0},
			},
		)
	}
	return baseOptions
}

// generateReputationEvent 生成声望事件
func (g *Generator) generateReputationEvent(faction, relation string) *WorldEvent {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	factionName := g.getFactionName(faction)

	events := []*WorldEvent{
		{
			ID:          fmt.Sprintf("rep_%s_1_%d", faction, r.Intn(10000)),
			Title:       fmt.Sprintf("%v的传闻", factionName),
			Description: fmt.Sprintf("你听到江湖上有人在议论%v的事迹...", factionName),
			Faction:     faction,
			EventType:   "reputation",
			Options: []EventOption{
				{Text: "打探更多消息", Outcome: "你收集了更多情报", Reputation: map[string]int{faction: 2}},
				{Text: "不闻不问", Outcome: "你继续赶路"},
			},
		},
		{
			ID:          fmt.Sprintf("rep_%s_2_%d", faction, r.Intn(10000)),
			Title:       fmt.Sprintf("遇到%v的仇敌", factionName),
			Description: fmt.Sprintf("有人正在说%v的坏话，这人与%v有旧怨", factionName, factionName),
			Faction:     faction,
			EventType:   "reputation",
			Options: []EventOption{
				{Text: "附和批评", Outcome: "你同意对方的看法", Reputation: map[string]int{faction: -5}},
				{Text: "为%v说话", Outcome: "你为%v辩护", Reputation: map[string]int{faction: 5}},
			},
		},
	}

	return events[r.Intn(len(events))]
}

// generateTalesEvent 生成江湖轶事
func (g *Generator) generateTalesEvent(faction string) *WorldEvent {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	factionName := g.getFactionName(faction)

	tales := []struct{ title, desc string }{
		{fmt.Sprintf("%v的秘宝传说", factionName), fmt.Sprintf("传说%v藏有一件神秘的宝物，吸引无数江湖人前去探寻", factionName)},
		{fmt.Sprintf("%v的门规变化", factionName), fmt.Sprintf("近日%v更改了门规，对江湖人士的态度似乎有了微妙变化", factionName)},
		{fmt.Sprintf("%v招收新弟子", factionName), fmt.Sprintf("%v正在公开招收新弟子，要求各有不同", factionName)},
	}

	t := tales[r.Intn(len(tales))]
	return &WorldEvent{
		ID:          fmt.Sprintf("tales_%s_%d", faction, r.Intn(10000)),
		Title:       t.title,
		Description: t.desc,
		Faction:     faction,
		EventType:   "tales",
		Options: []EventOption{
			{Text: "深入调查", Outcome: "你决定深入了解此事"},
			{Text: "保持距离", Outcome: "你不想卷入是非"},
		},
	}
}

// generatePlotEvent 生成剧情事件
func (g *Generator) generatePlotEvent(faction, relation string, playerReputation map[string]int) *WorldEvent {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	factionName := g.getFactionName(faction)

	rep := playerReputation[faction]
	var severity string
	if rep <= -50 {
		severity = "深仇大恨"
	} else if rep <= -20 {
		severity = "敌意明显"
	} else if rep <= 20 {
		severity = "互不相干"
	} else {
		severity = "友好相处"
	}

	return &WorldEvent{
		ID:          fmt.Sprintf("plot_%s_%d", faction, r.Intn(10000)),
		Title:       fmt.Sprintf("%v的%v", factionName, severity),
		Description: fmt.Sprintf("%v对你当前的关系状态触发了剧情事件。这是江湖命运的重要转折点。", factionName),
		Faction:     faction,
		EventType:   "plot",
		Options: []EventOption{
			{Text: "主动接触", Outcome: "你迈出了改变命运的一步", Reputation: map[string]int{faction: 10}},
			{Text: "静观其变", Outcome: "你选择谨慎观望"},
			{Text: "刻意回避", Outcome: "你决定暂时避开", Reputation: map[string]int{faction: -5}},
		},
	}
}

// generateDefaultEvent 生成默认事件
func (g *Generator) generateDefaultEvent(region, eventType string) *WorldEvent {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	return &WorldEvent{
		ID:          fmt.Sprintf("default_%s_%d", region, r.Intn(10000)),
		Title:       "江湖路遇",
		Description: "你在江湖中偶然遇到了一件事...",
		Region:      region,
		Faction:     "",
		EventType:   eventType,
		Options: []EventOption{
			{Text: "欣然参与", Outcome: "你决定参与其中"},
			{Text: "婉拒离开", Outcome: "你选择离开"},
		},
	}
}

// getRelation 获取阵营关系
func (g *Generator) getRelation(f1, f2 string) string {
	if rel, ok := g.factionRelations[f1]; ok {
		if r, ok := rel[f2]; ok {
			return r
		}
	}
	return "中立"
}

// getFactionName 获取阵营名称
func (g *Generator) getFactionName(faction string) string {
	names := map[string]string{
		"mingjiao": "明教",
		"shaolin":  "少林寺",
		"wudang":   "武当派",
		"jinyiwei": "锦衣卫",
		"wudu":     "五毒教",
		"gaibang":  "丐帮",
	}
	if name, ok := names[faction]; ok {
		return name
	}
	return faction
}

// BuildNarrativePrompt 构建LLM叙事Prompt
func (g *Generator) BuildNarrativePrompt(event *WorldEvent, playerName string, playerFaction string) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("你是一个武侠世界的叙事AI。请为以下事件生成生动的叙事文本。\n\n"))
	sb.WriteString(fmt.Sprintf("事件：%s\n", event.Title))
	sb.WriteString(fmt.Sprintf("描述：%s\n", event.Description))
	sb.WriteString(fmt.Sprintf("类型：%s\n", event.EventType))
	sb.WriteString(fmt.Sprintf("涉及阵营：%s\n", g.getFactionName(event.Faction)))
	sb.WriteString(fmt.Sprintf("玩家：%s（%s）\n\n", playerName, g.getFactionName(playerFaction)))
	sb.WriteString(fmt.Sprintf("请生成一段50-100字的武侠风格叙事，描述事件的发展和结果。\n"))
	sb.WriteString(fmt.Sprintf("输出格式：\n[叙事]: <叙事文本>\n[结局]: <结局概要>"))
	return sb.String()
}
