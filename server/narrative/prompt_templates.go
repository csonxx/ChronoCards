package narrative

import (
	"fmt"
	"strings"
)

// PromptTemplates provides ancient Chinese literary style prompts for narrative generation.
// All prompts produce 古白话文 (classical vernacular Chinese) style output.

// CardDrawPrompt generates a prompt for card draw narrative.
func CardDrawPrompt(card CardInfo, player PlayerContext, seed string) string {
	styleHints := map[string]string{
		"attack":  "豪迈激昂，江湖快意，刀光剑影，字里行间透着杀气",
		"defense": "沉稳内敛，以静制动，旁白如古卷徐徐展开",
		"skill":   "神秘悠远，道法自然，带有一丝禅意和仙气",
		"event":   "跌宕起伏，命数轮回，带有因果宿命的厚重感",
	}
	style := styleHints[card.Type]
	if style == "" {
		style = "叙事沉稳，画面感强"
	}

	effects := ""
	if len(card.Effects) > 0 {
		effects = strings.Join(card.Effects, "、")
	} else {
		effects = "无"
	}

	return fmt.Sprintf(`你是 ChronoCards 武侠叙事引擎。

当前场景：%s，说书人「%s」正在发牌。
玩家「%s」抽到了：

【%s】%s
类型：%s | 元素：%s | 伤害：%.0f | 消耗：%d MP
效果：%s

请生成一段 %s 风格的抽卡叙事，包含：

1. **氛围描写**（30-60字）：渲染抽牌瞬间的视觉效果和情绪
2. **说书人旁白**（可选，20-40字）：说书人风格的口吻，带有评书韵味
3. **卡牌故事**（50-100字）：这张卡背后的江湖往事或武学渊源

输出格式（JSON，不要包含任何 markdown 标记）：
{
  "atmosphere": "氛围描写",
  "dialogue": "说书人旁白（可为空）",
  "card_story": "卡牌故事",
  "audio_cue": "背景音建议（如：古琴独奏、刀剑相击声、风声）"
}

要求：
- 武侠题材，使用古白话文风格
- 氛围描写需贴合卡牌的元素属性（火系用热烈、土系用厚重）
- 不要输出任何解释性文字，直接输出 JSON

随机种子：%s（保持变化，每小时不同）`, card.DealerName, card.DealerName,
		player.Name, card.Title, card.Description, card.Type,
		card.Element, card.Damage, card.MPCost,
		effects, style, seed)
}

// NPCDialoguePrompt generates a prompt for NPC dialogue.
func NPCDialoguePrompt(npc NPCInfo, scene SceneContext, seed string) string {
	return fmt.Sprintf(`你是 ChronoCards NPC 对话引擎。

NPC：「%s」（%s）
当前场景：%s
情绪基调：%s

请生成一段 NPC 台词，要求：

1. **台词**（30-100字）：符合 NPC 性格和当前场景的第一人称对白
2. **动作描写**（10-30字）：NPC 的肢体语言或表情变化
3. **内话/心理**（可选，20-40字）：NPC 内心独白，玩家不可见（可作为后续剧情伏笔）

输出格式（JSON，不要包含任何 markdown 标记）：
{
  "dialogue": "NPC 对话内容",
  "action": "动作描写",
  "inner_thought": "内心独白（可为空）",
  "emotion_hint": "情绪提示（angry/happy/sad/mysterious/calm 等）",
  "audio_cue": "语音提示（如：冷笑、语气低沉、语速加快）"
}

要求：
- 对话风格与 NPC 人设高度一致
- 不输出任何解释，直接输出 JSON

随机种子：%s`, npc.Name, npc.Personality,
		scene.Description, scene.Emotion, seed)
}

// EventDescPrompt generates a prompt for event description.
func EventDescPrompt(event EventContext, seed string) string {
	templates := map[string]string{
		"encounter":    "江湖险恶，迎面撞上了一场厮杀",
		"random_event": "天有不测风云，江湖中总有意外",
		"level_up":     "厚积薄发，武功修为突破新境界",
	}
	base := templates[event.Type]
	if base == "" {
		base = "江湖风云，变幻莫测"
	}

	return fmt.Sprintf(`你是 ChronoCards 事件叙事引擎。

事件类型：%s
发生地点：%s
玩家角色：%s

请生成一段 %s 的事件描述，要求：

1. **事件叙事**（80-150字）：以第三人称或第一人称叙述事件发生、发展
2. **氛围烘托**（20-50字）：环境描写、天气、声音等氛围元素
3. **玩家感受**（可选，20-40字）：玩家角色此刻的内心或身体感受

输出格式（JSON，不要包含任何 markdown 标记）：
{
  "narrative": "事件叙事",
  "atmosphere": "氛围烘托",
  "player_feeling": "玩家感受（可为空）",
  "audio_cue": "背景音建议"
}

要求：
- 叙事节奏感强，有起承转合
- 不输出任何解释，直接输出 JSON

随机种子：%s`, event.Type, event.LocationName,
		event.PlayerName, base, seed)
}
