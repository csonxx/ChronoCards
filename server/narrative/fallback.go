package narrative

import (
	ws "github.com/csonxx/ChronoCards/server/ws"
)

// FallbackProvider provides static fallback content when LLM fails.
type FallbackProvider struct{}

// NewFallbackProvider creates a new FallbackProvider.
func NewFallbackProvider() *FallbackProvider {
	return &FallbackProvider{}
}

// GetCardDrawFallback returns static narrative content for card draw.
func (f *FallbackProvider) GetCardDrawFallback(cardType string) string {
	switch cardType {
	case "attack":
		return `{"atmosphere":"肃杀之气弥漫，刀光剑影交错","dialogue":"说书人轻敲桌面，道：此剑一出，江湖再无安宁！","card_story":"剑光一闪，寒芒乍现。江湖恩怨，在这一招间尽数展现。此剑名为破天，乃百年前剑魔独孤求败所铸，剑成之日，天地失色。","audio_cue":"刀剑相击金属声"}`
	case "defense":
		return `{"atmosphere":"气息沉稳，如山岳般不可撼动","dialogue":"","card_story":"以静制动，后发先至。防守之道，乃武者根基。此功法名为金刚罩，乃少林秘传，历代护寺武僧必修。","audio_cue":"沉稳鼓点"}`
	case "skill":
		return `{"atmosphere":"灵气环绕，若隐若现","dialogue":"","card_story":"内息运转，真气流转。技能释放，天地为之变色。此技源自道家秘法，修炼至深处，可引天地之力为己用。","audio_cue":"空灵的风铃声"}`
	case "event":
		return `{"atmosphere":"神秘而悠远，命运感强烈","dialogue":"说书人叹道：命数轮回，因果自有定数。","card_story":"江湖风云变幻，命运齿轮悄然转动。此事件牵涉三十年前的江湖秘闻，当年一战，改变了整个武林的格局。","audio_cue":"低沉的弦乐"}`
	default:
		return `{"atmosphere":"江湖险恶，风云莫测","dialogue":"","card_story":"刀光剑影，江湖路远。武者征程，正式开启。","audio_cue":"风声"}`
	}
}

// GetNPCDialogueFallback returns static content for NPC dialogue.
func (f *FallbackProvider) GetNPCDialogueFallback() string {
	return `{"dialogue":"（NPC沉默不语，似乎在思考着什么）","action":"眉头微皱，目光深邃","inner_thought":"这少年……竟有几分当年他的影子。","emotion_hint":"mysterious","audio_cue":"静谧中的远处鸟鸣"}`
}

// GetEventFallback returns static content for event description.
func (f *FallbackProvider) GetEventFallback(eventType string) string {
	switch eventType {
	case "encounter":
		return `{"narrative":"江湖险恶，一场遭遇在所难免。忽见前方黑影闪动，似有人埋伏。剑已出鞘，寒光乍现！","atmosphere":"紧张压抑，危机四伏","player_feeling":"心跳加速，手心渗出冷汗","audio_cue":"紧张鼓点"}`
	case "level_up":
		return `{"narrative":"厚积薄发，修炼突破！体内真气汹涌澎湃，任督二脉豁然贯通，武功更上一层楼！","atmosphere":"光芒四射，精神焕发","player_feeling":"浑身舒泰，神清气爽","audio_cue":"激昂的铜管乐"}`
	case "random_event":
		return `{"narrative":"天有不测风云，江湖中总有意外。忽然天空变色，一阵奇风袭来，似乎预示着什么。","atmosphere":"风云突变，神秘莫测","player_feeling":"心中升起一股莫名的预感","audio_cue":"风声渐起"}`
	default:
		return `{"narrative":"江湖风云，变幻莫测。一切尽在未定之天。","atmosphere":"气氛微妙，悬念重重","player_feeling":"屏息凝神，静待变化","audio_cue":"低沉的环境音"}`
	}
}

// GetFallbackNarrativeContent parses fallback JSON into NarrativeContent.
func (f *FallbackProvider) GetFallbackNarrativeContent(cardType string) *ws.NarrativeContent {
	switch cardType {
	case "attack":
		return &ws.NarrativeContent{
			Text:       "剑光一闪，寒芒乍现。江湖恩怨，在这一招间尽数展现。",
			Dialogue:   "说书人轻敲桌面，道：此剑一出，江湖再无安宁！",
			Atmosphere: "肃杀之气弥漫，刀光剑影交错",
			AudioCue:   "刀剑相击金属声",
		}
	case "defense":
		return &ws.NarrativeContent{
			Text:       "以静制动，后发先至。防守之道，乃武者根基。",
			Dialogue:   "",
			Atmosphere: "气息沉稳，如山岳般不可撼动",
			AudioCue:   "沉稳鼓点",
		}
	case "skill":
		return &ws.NarrativeContent{
			Text:       "内息运转，真气流转。技能释放，天地为之变色。",
			Dialogue:   "",
			Atmosphere: "灵气环绕，若隐若现",
			AudioCue:   "空灵的风铃声",
		}
	case "event":
		return &ws.NarrativeContent{
			Text:       "江湖风云变幻，命运齿轮悄然转动。",
			Dialogue:   "说书人叹道：命数轮回，因果自有定数。",
			Atmosphere: "神秘而悠远，命运感强烈",
			AudioCue:   "低沉的弦乐",
		}
	default:
		return &ws.NarrativeContent{
			Text:       "刀光剑影，江湖路远。武者征程，正式开启。",
			Dialogue:   "",
			Atmosphere: "江湖险恶，风云莫测",
			AudioCue:   "风声",
		}
	}
}
