package faction

// FactionCardType 阵营卡牌类型
type FactionCardType string

const (
	FactionCardBurst     FactionCardType = "burst"      // 爆发型
	FactionCardDefensive FactionCardType = "defensive"  // 防御型
	FactionCardControl   FactionCardType = "control"    // 控制型
	FactionCardGain      FactionCardType = "gain"       // 增益型
	FactionCardSummon    FactionCardType = "summon"     // 召唤型
	FactionCardStrategy  FactionCardType = "strategy"  // 策略型
	FactionCardEnd       FactionCardType = "end"        // 终结型
	FactionCardChain     FactionCardType = "chain"     // 连击型
	FactionCardCounter   FactionCardType = "counter"   // 反制型
	FactionCardTrap      FactionCardType = "trap"       // 阵法型
	FactionCardStealth   FactionCardType = "stealth"    // 隐身型
	FactionCardRange     FactionCardType = "range"      // 范围型
	FactionCardInfo      FactionCardType = "info"       // 情报型
	FactionCardStore     FactionCardType = "store"      // 储存型
	FactionCardDebuff    FactionCardType = "debuff"     // 削弱型
	FactionCardMulti     FactionCardType = "multi"      // 多段型
	FactionCardDespair   FactionCardType = "despair"    // 绝境逆转型
	FactionCardTeach     FactionCardType = "teach"      // 增益传授型
	FactionCardTrapSize  FactionCardType = "trap_size"  // 困敌型
)

// FactionCardEffect 阵营卡牌效果
type FactionCardEffect struct {
	Type        FactionCardType `json:"type"`                  // 效果类型
	Description string         `json:"description"`           // 效果描述
	Damage      float64        `json:"damage,omitempty"`       // 伤害值（百分比）
	Heal        float64        `json:"heal,omitempty"`        // 治疗值（百分比）
	Shield      float64        `json:"shield,omitempty"`       // 护盾值（百分比）
	Duration    int            `json:"duration,omitempty"`     // 持续时间（秒）
	Stack       int            `json:"stack,omitempty"`        // 叠加层数
	Condition   string         `json:"condition,omitempty"`    // 触发条件
	Cooldown    int            `json:"cooldown,omitempty"`     // 冷却时间
	MPCost      int            `json:"mp_cost,omitempty"`     // 内力消耗
	StaminaCost int            `json:"stamina_cost,omitempty"` // 体力消耗
	Buffs       []string       `json:"buffs,omitempty"`       // 附加状态
	Debuffs     []string       `json:"debuffs,omitempty"`     // 附加debuff
}

// FactionCard 阵营卡牌定义
type FactionCardDef struct {
	ID          string           `json:"id"`
	FactionID   FactionID        `json:"faction_id"`
	Name        string           `json:"name"`
	Type        FactionCardType  `json:"type"`
	Effect      FactionCardEffect `json:"effect"`
	UnlockLevel int              `json:"unlock_level"` // 解锁等级要求
}

// AllFactionCards 所有阵营卡牌
var AllFactionCards = []FactionCardDef{
	// ===== 明教 (5张) =====
	{
		ID:        "MJ-001",
		FactionID: FactionMingjiao,
		Name:      "圣火焚身",
		Type:      FactionCardBurst,
		Effect: FactionCardEffect{
			Type:        FactionCardBurst,
			Description: "消耗30%当前生命值，转化为等额火元素伤害，无视护盾。自身每损失10%生命，伤害额外+15%",
			Damage:      1.0, // 100%消耗生命值转化为伤害
			Condition:   "hp_loss_bonus", // 生命损失加成
			Buffs:       []string{"fire_element"},
		},
		UnlockLevel: 1,
	},
	{
		ID:        "MJ-002",
		FactionID: FactionMingjiao,
		Name:      "明尊度化",
		Type:      FactionCardSummon,
		Effect: FactionCardEffect{
			Type:        FactionCardSummon,
			Description: "召唤2名明教弟子（基础战斗力）。击杀后为己方恢复15%最大生命值",
			Condition:   "on_kill_heal",
			Heal:        0.15,
			Buffs:       []string{"summon_mingjiao"},
		},
		UnlockLevel: 1,
	},
	{
		ID:        "MJ-003",
		FactionID: FactionMingjiao,
		Name:      "天火陨落",
		Type:      FactionCardRange,
		Effect: FactionCardEffect{
			Type:        FactionCardRange,
			Description: "对中等范围内所有敌人造成火元素伤害，附加「灼烧」状态（每秒5%生命值损伤，持续8秒）",
			Damage:      0.5,
			Duration:    8,
			Debuffs:     []string{"burn"},
			Buffs:       []string{"fire_element", "aoe"},
		},
		UnlockLevel: 3,
	},
	{
		ID:        "MJ-004",
		FactionID: FactionMingjiao,
		Name:      "圣火裁决",
		Type:      FactionCardEnd,
		Effect: FactionCardEffect{
			Type:        FactionCardEnd,
			Description: "对单一目标发动：对生命值低于50%的敌人造成300%伤害；对生命值高于50%的敌人造成150%伤害，但附加「圣火印记」持续掉血",
			Damage:      3.0,
			Condition:   "hp_below_50",
			Debuffs:     []string{"holy_fire_mark"},
		},
		UnlockLevel: 5,
	},
	{
		ID:        "MJ-005",
		FactionID: FactionMingjiao,
		Name:      "明教秘典",
		Type:      FactionCardStrategy,
		Effect: FactionCardEffect{
			Type:        FactionCardStrategy,
			Description: "每当己方角色死亡，恢复其他队友20%最大生命值并提升10%攻击力，持续15秒",
			Heal:        0.2,
			Damage:      0.1,
			Duration:    15,
			Condition:   "ally_death_trigger",
			Buffs:       []string{"attack_up"},
		},
		UnlockLevel: 7,
	},

	// ===== 少林 (5张) =====
	{
		ID:        "SL-001",
		FactionID: FactionShaolin,
		Name:      "金钟罩体",
		Type:      FactionCardDefensive,
		Effect: FactionCardEffect{
			Type:        FactionCardDefensive,
			Description: "获得护盾，吸收量=自身最大生命值的40%，持续12秒。护盾存在期间，被攻击时有25%几率完全格挡伤害",
			Shield:      0.4,
			Duration:    12,
			Buffs:       []string{"golden_bell"},
		},
		UnlockLevel: 1,
	},
	{
		ID:        "SL-002",
		FactionID: FactionShaolin,
		Name:      "罗汉阵",
		Type:      FactionCardSummon,
		Effect: FactionCardEffect{
			Type:        FactionCardSummon,
			Description: "召唤4名罗汉弟子（防御力极高但攻击力低）。阵亡时对周围敌人造成反弹伤害",
			Condition:   "on_death_damage",
			Damage:      0.3,
			Buffs:       []string{"summon_arhat", "high_defense"},
		},
		UnlockLevel: 1,
	},
	{
		ID:        "SL-003",
		FactionID: FactionShaolin,
		Name:      "狮子吼",
		Type:      FactionCardControl,
		Effect: FactionCardEffect{
			Type:        FactionCardControl,
			Description: "范围技能，击退所有范围内敌人并造成3秒「眩晕」。对已「眩晕」目标额外造成150%伤害",
			Damage:      1.0,
			Duration:    3,
			Debuffs:     []string{"stun"},
			Condition:   "stunned_target_150",
			Buffs:       []string{"knockback"},
		},
		UnlockLevel: 3,
	},
	{
		ID:        "SL-004",
		FactionID: FactionShaolin,
		Name:      "易筋伐髓",
		Type:      FactionCardGain,
		Effect: FactionCardEffect{
			Type:        FactionCardGain,
			Description: "自身及周围队友每3秒恢复5%最大生命值，同时提升5%移动速度，持续20秒",
			Heal:        0.05,
			Duration:    20,
			Condition:   "tick_3s",
			Buffs:       []string{"heal_over_time", "speed_up"},
		},
		UnlockLevel: 5,
	},
	{
		ID:        "SL-005",
		FactionID: FactionShaolin,
		Name:      "我佛慈悲",
		Type:      FactionCardDefensive,
		Effect: FactionCardEffect{
			Type:        FactionCardDefensive,
			Description: "当自身生命值低于20%时，触发：清除所有负面状态，恢复30%最大生命值，但接下来10秒内无法造成伤害",
			Heal:        0.3,
			Duration:    10,
			Condition:   "hp_below_20",
			Buffs:       []string{"cleanse", "silence_self"},
		},
		UnlockLevel: 7,
	},

	// ===== 武当 (5张) =====
	{
		ID:        "WD-001",
		FactionID: FactionWudang,
		Name:      "太极圆转",
		Type:      FactionCardCounter,
		Effect: FactionCardEffect{
			Type:        FactionCardCounter,
			Description: "受到攻击时，若生命值高于50%，将伤害的60%反弹给攻击者；若低于50%，则回复等额生命值",
			Condition:   "on_damaged",
			Damage:      0.6,
			Heal:        0.6,
			Buffs:       []string{"counter_attack", "lifesteal"},
		},
		UnlockLevel: 1,
	},
	{
		ID:        "WD-002",
		FactionID: FactionWudang,
		Name:      "太极剑·云手",
		Type:      FactionCardChain,
		Effect: FactionCardEffect{
			Type:        FactionCardChain,
			Description: "对同一目标连续攻击3次，每次伤害递增（100%→150%→200%），每次命中恢复5%内力",
			Damage:      1.0,
			Condition:   "combo_3_hits",
			Buffs:       []string{"combo", "mp_restore"},
			Stack:       3,
		},
		UnlockLevel: 1,
	},
	{
		ID:        "WD-003",
		FactionID: FactionWudang,
		Name:      "武当八卦阵",
		Type:      FactionCardTrap,
		Effect: FactionCardEffect{
			Type:        FactionCardTrap,
			Description: "在目标区域放置阵法陷阱，持续15秒。踏入的敌人减速40%，阵法内队友提升20%闪避率",
			Duration:    15,
			Debuffs:     []string{"slow"},
			Buffs:       []string{"trap", "dodge_up"},
		},
		UnlockLevel: 3,
	},
	{
		ID:        "WD-004",
		FactionID: FactionWudang,
		Name:      "天璇北斗",
		Type:      FactionCardStrategy,
		Effect: FactionCardEffect{
			Type:        FactionCardStrategy,
			Description: "瞬间传送到范围内任意队友身边，并为其提供30%护盾。触发后8秒内提升自身50%移动速度",
			Shield:      0.3,
			Duration:    8,
			Buffs:       []string{"teleport", "speed_up"},
		},
		UnlockLevel: 5,
	},
	{
		ID:        "WD-005",
		FactionID: FactionWudang,
		Name:      "以柔克刚",
		Type:      FactionCardEnd,
		Effect: FactionCardEffect{
			Type:        FactionCardEnd,
			Description: "对已「减速」「眩晕」的目标发动，造成伤害的200%转化为自身生命值；若目标生命值低于30%，直接斩杀",
			Damage:      2.0,
			Condition:   "slowed_or_stunned_target",
			Heal:        2.0,
			Buffs:       []string{"lifesteal", "execute"},
		},
		UnlockLevel: 7,
	},

	// ===== 锦衣卫 (6张) =====
	{
		ID:        "JW-001",
		FactionID: FactionJinyiwei,
		Name:      "影卫追踪",
		Type:      FactionCardInfo,
		Effect: FactionCardEffect{
			Type:        FactionCardInfo,
			Description: "标记任意一名敌人（不限阵营），持续获得其位置、当前生命值和正在释放的技能。对其造成的伤害+25%",
			Duration:    30,
			Condition:   "marked_target",
			Damage:      0.25,
			Buffs:       []string{"mark", "track"},
		},
		UnlockLevel: 1,
	},
	{
		ID:        "JW-002",
		FactionID: FactionJinyiwei,
		Name:      "绣春刀·连环",
		Type:      FactionCardChain,
		Effect: FactionCardEffect{
			Type:        FactionCardChain,
			Description: "对同一目标发动4次连续斩击，每次斩击叠加「伤口」效果（-5%护甲，可叠加5层）",
			Damage:      0.8,
			Condition:   "combo_4_hits",
			Debuffs:     []string{"wound"},
			Stack:       4,
		},
		UnlockLevel: 1,
	},
	{
		ID:        "JW-003",
		FactionID: FactionJinyiwei,
		Name:      "天罗地网",
		Type:      FactionCardControl,
		Effect: FactionCardEffect{
			Type:        FactionCardControl,
			Description: "释放铁索链，困住目标区域所有敌人，持续6秒，被困敌人无法移动但可以攻击和释放技能",
			Duration:    6,
			Debuffs:     []string{"immobilize"},
			Buffs:       []string{"cc"},
		},
		UnlockLevel: 3,
	},
	{
		ID:        "JW-004",
		FactionID: FactionJinyiwei,
		Name:      "诏书令",
		Type:      FactionCardStrategy,
		Effect: FactionCardEffect{
			Type:        FactionCardStrategy,
			Description: "颁布诏书：目标NPC或小型敌人有40%几率直接投降（成为己方临时单位），40%几率恐惧逃跑（离开战斗），20%几率誓死抵抗",
			Condition:   "chance_effect",
			Buffs:       []string{"intimidate", "convert"},
		},
		UnlockLevel: 5,
	},
	{
		ID:        "JW-005",
		FactionID: FactionJinyiwei,
		Name:      "生死贴",
		Type:      FactionCardEnd,
		Effect: FactionCardEffect{
			Type:        FactionCardEnd,
			Description: "标记一个目标，3秒后无论其生命值多少，直接处决。对「已受伤」（生命值低于80%）的目标必定成功，否则有50%成功率",
			Condition:   "marked_execute",
			Buffs:       []string{"execute"},
		},
		UnlockLevel: 7,
	},
	{
		ID:        "JW-006",
		FactionID: FactionJinyiwei,
		Name:      "铁血令牌",
		Type:      FactionCardGain,
		Effect: FactionCardEffect{
			Type:        FactionCardGain,
			Description: "吹响铁血令牌，召集2名锦衣卫护卫（战斗力中等）。护卫存在期间，自身周围敌方单位减速30%，且对试图逃跑的敌人自动追击",
			Duration:    20,
			Buffs:       []string{"summon_jinyiwei", "slow_aura", "chase"},
		},
		UnlockLevel: 5,
	},

	// ===== 五毒教 (6张) =====
	{
		ID:        "WU-001",
		FactionID: FactionWudu,
		Name:      "蛛蛊迷心",
		Type:      FactionCardControl,
		Effect: FactionCardEffect{
			Type:        FactionCardControl,
			Description: "释放迷心蛛蛊，目标被控制8秒，被控制期间会帮助我方攻击队友（等同玩家操控）。目标被攻击时自动解除控制",
			Duration:    8,
			Debuffs:     []string{"charm"},
			Buffs:       []string{"mind_control"},
		},
		UnlockLevel: 1,
	},
	{
		ID:        "WU-002",
		FactionID: FactionWudu,
		Name:      "蛇咬七伤",
		Type:      FactionCardDebuff,
		Effect: FactionCardEffect{
			Type:        FactionCardDebuff,
			Description: "对目标注入蛇毒：每3秒造成10%最大生命值的伤害，持续15秒。若目标在中毒期间使用技能，毒素扩散至周围所有敌人",
			Damage:      0.1,
			Duration:    15,
			Condition:   "skill_use_spread",
			Debuffs:     []string{"poison"},
			Buffs:       []string{"dot"},
		},
		UnlockLevel: 1,
	},
	{
		ID:        "WU-003",
		FactionID: FactionWudu,
		Name:      "蛊母噬魂",
		Type:      FactionCardStore,
		Effect: FactionCardEffect{
			Type:        FactionCardStore,
			Description: "吸收目标对自己的伤害（最高积累自身最大生命值的100%），30秒后或主动释放：释放所有积累的伤害，以真实伤害形式作用于目标",
			Duration:    30,
			Condition:   "absorb_damage",
			Damage:      1.0,
			Buffs:       []string{"damage_store"},
		},
		UnlockLevel: 3,
	},
	{
		ID:        "WU-004",
		FactionID: FactionWudu,
		Name:      "噬魂蛊",
		Type:      FactionCardDebuff,
		Effect: FactionCardEffect{
			Type:        FactionCardDebuff,
			Description: "对目标植入噬魂蛊：造成100%攻击力的即时伤害，同时削减目标50%治疗效果，持续20秒",
			Damage:      1.0,
			Duration:    20,
			Debuffs:     []string{"heal_reduction"},
			Buffs:       []string{"instant_damage"},
		},
		UnlockLevel: 3,
	},
	{
		ID:        "WU-005",
		FactionID: FactionWudu,
		Name:      "蝶影遁形",
		Type:      FactionCardStealth,
		Effect: FactionCardEffect{
			Type:        FactionCardStealth,
			Description: "进入隐身状态，持续6秒，隐身期间下次攻击必定暴击且附带「毒蛛」效果（禁止目标使用闪避技能，持续5秒）",
			Duration:    6,
			Buffs:       []string{"stealth", "guaranteed_crit", "poison_web"},
		},
		UnlockLevel: 5,
	},
	{
		ID:        "WU-006",
		FactionID: FactionWudu,
		Name:      "万蛊筒",
		Type:      FactionCardRange,
		Effect: FactionCardEffect{
			Type:        FactionCardRange,
			Description: "向扇形区域释放蛊虫云，所有被笼罩的敌人每秒受到8%最大生命值的毒伤害，持续6秒，并降低30%治疗效果",
			Damage:      0.08,
			Duration:    6,
			Debuffs:     []string{"poison_cloud", "heal_reduction"},
			Buffs:       []string{"aoe", "dot"},
		},
		UnlockLevel: 7,
	},

	// ===== 丐帮 (5张) =====
	{
		ID:        "GB-001",
		FactionID: FactionGaibang,
		Name:      "打狗阵法",
		Type:      FactionCardTrapSize,
		Effect: FactionCardEffect{
			Type:        FactionCardTrapSize,
			Description: "对单体目标发动：以打狗棒封住目标退路，使其所有位移技能失效8秒，同时每次目标试图移动会受到50%攻击力的反击伤害",
			Duration:    8,
			Damage:      0.5,
			Debuffs:     []string{"immobilize", "counter_move"},
			Buffs:       []string{"trap"},
		},
		UnlockLevel: 1,
	},
	{
		ID:        "GB-002",
		FactionID: FactionGaibang,
		Name:      "莲花落·连击",
		Type:      FactionCardMulti,
		Effect: FactionCardEffect{
			Type:        FactionCardMulti,
			Description: "对目标发动6次拳击，每次命中叠加一层「内伤」（-10%最大生命值，可叠加3层），最后一击触发所有「内伤」层数造成额外伤害",
			Damage:      0.6,
			Stack:       6,
			Debuffs:     []string{"internal_injury"},
			Condition:   "stack_trigger",
		},
		UnlockLevel: 1,
	},
	{
		ID:        "GB-003",
		FactionID: FactionGaibang,
		Name:      "降龙十八掌",
		Type:      FactionCardBurst,
		Effect: FactionCardEffect{
			Type:        FactionCardBurst,
			Description: "对单体造成400%攻击力的伤害，若目标已拥有「内伤」状态，额外附加3秒「眩晕」",
			Damage:      4.0,
			Condition:   "internal_injury_stun",
			Debuffs:     []string{"stun"},
			Buffs:       []string{"high_damage"},
		},
		UnlockLevel: 5,
	},
	{
		ID:        "GB-004",
		FactionID: FactionGaibang,
		Name:      "乞丐王图",
		Type:      FactionCardDespair,
		Effect: FactionCardEffect{
			Type:        FactionCardDespair,
			Description: "当己方角色生命值低于30%时，自动触发：接下来5秒内所有攻击+50%暴击率，击杀敌人后恢复15%最大生命值",
			Duration:    5,
			Condition:   "hp_below_30",
			Buffs:       []string{"crit_up", "kill_heal"},
		},
		UnlockLevel: 5,
	},
	{
		ID:        "GB-005",
		FactionID: FactionGaibang,
		Name:      "传功授业",
		Type:      FactionCardTeach,
		Effect: FactionCardEffect{
			Type:        FactionCardTeach,
			Description: "自身重伤（生命值低于30%）时，自动将10%攻击力分配给所有存活队友，持续到战斗结束",
			Condition:   "hp_below_30",
			Damage:      0.1,
			Buffs:       []string{"share_attack"},
		},
		UnlockLevel: 7,
	},
}

// GetFactionCards 获取指定阵营的所有卡牌
func GetFactionCards(factionID FactionID) []FactionCardDef {
	var cards []FactionCardDef
	for _, card := range AllFactionCards {
		if card.FactionID == factionID {
			cards = append(cards, card)
		}
	}
	return cards
}

// GetFactionCardByID 根据ID获取卡牌
func GetFactionCardByID(cardID string) *FactionCardDef {
	for _, card := range AllFactionCards {
		if card.ID == cardID {
			return &card
		}
	}
	return nil
}

// GetUnlockedCards 获取玩家已解锁的阵营卡牌
func GetUnlockedCards(factionID FactionID, playerLevel int) []FactionCardDef {
	var cards []FactionCardDef
	for _, card := range AllFactionCards {
		if card.FactionID == factionID && card.UnlockLevel <= playerLevel {
			cards = append(cards, card)
		}
	}
	return cards
}

// FactionCardToModelCard 阵营卡牌转换为通用卡牌模型
func FactionCardToModelCard(def *FactionCardDef) map[string]interface{} {
	cardType := map[FactionCardType]string{
		FactionCardBurst:     "main_story",
		FactionCardDefensive: "side_story",
		FactionCardControl:   "side_story",
		FactionCardGain:      "stat_up",
		FactionCardSummon:    "side_story",
		FactionCardStrategy:  "skill_unlock",
		FactionCardEnd:       "main_story",
		FactionCardChain:     "side_story",
		FactionCardCounter:   "side_story",
		FactionCardTrap:      "side_story",
		FactionCardStealth:   "side_story",
		FactionCardRange:     "side_story",
		FactionCardInfo:      "side_story",
		FactionCardStore:     "side_story",
		FactionCardDebuff:    "side_story",
		FactionCardMulti:     "side_story",
		FactionCardDespair:  "main_story",
		FactionCardTeach:     "skill_unlock",
		FactionCardTrapSize:  "side_story",
	}

	return map[string]interface{}{
		"id":          def.ID,
		"title":       def.Name,
		"type":        cardType[def.Type],
		"description": def.Effect.Description,
		"faction":     string(def.FactionID),
		"level":       def.UnlockLevel,
	}
}
