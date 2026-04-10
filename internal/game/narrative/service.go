package narrative

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"
)

// TriggerType 叙事触发类型
type TriggerType string

const (
	TriggerDealerInteract TriggerType = "dealer_interact"
	TriggerCardDrawn      TriggerType = "card_drawn"
	TriggerBattleStart   TriggerType = "battle_start"
	TriggerBattleEnd     TriggerType = "battle_end"
	TriggerLocationEnter TriggerType = "location_enter"
	TriggerNPCMet        TriggerType = "npc_met"
	TriggerCustom        TriggerType = "custom"
)

// NarrativeContext 叙事上下文
type NarrativeContext struct {
	WorldState       string   `json:"world_state"`
	FactionRelations map[string]int `json:"faction_relations"`
	RecentEvents     []string `json:"recent_events"`
	PlayerBackground string   `json:"player_background"`
	Tone             string   `json:"tone"` // epic/intimate/mysterious/tense/peaceful
}

// NarrativeConstraints 叙事约束
type NarrativeConstraints struct {
	MaxLength        int  `json:"max_length"`
	DialogueRequired bool `json:"dialogue_required"`
	NPCName          string `json:"npc_name,omitempty"`
}

// TriggerRequest AI叙事触发请求
type TriggerRequest struct {
	TriggerType  TriggerType         `json:"trigger_type"`
	PlayerID     string              `json:"player_id,omitempty"`
	DealerID     string              `json:"dealer_id,omitempty"`
	CardID       string              `json:"card_id,omitempty"`
	CardType     string              `json:"card_type,omitempty"`
	CardTitle    string              `json:"card_title,omitempty"`
	Location     string              `json:"location,omitempty"`
	Context      NarrativeContext    `json:"context"`
	Constraints  NarrativeConstraints `json:"constraints"`
}

// NarrativeContent AI生成的叙事内容
type NarrativeContent struct {
	Title     string              `json:"title"`
	Narrative string              `json:"narrative"`
	Dialogue  []DialogueLine      `json:"dialogue,omitempty"`
	Choices   []Choice            `json:"choices,omitempty"`
	Rewards   []RewardPreview     `json:"rewards,omitempty"`
	Metadata  NarrativeMetadata   `json:"metadata"`
}

// DialogueLine 对话行
type DialogueLine struct {
	Speaker string `json:"speaker"`
	Text    string `json:"text"`
	Tone    string `json:"tone,omitempty"`
}

// Choice 玩家选项
type Choice struct {
	ID         string `json:"id"`
	Text       string `json:"text"`
	EffectHint string `json:"effect_hint,omitempty"`
}

// RewardPreview 奖励预览
type RewardPreview struct {
	Type  string `json:"type"`
	Value string `json:"value"`
}

// NarrativeMetadata 叙事元数据
type NarrativeMetadata struct {
	CardID      string `json:"card_id,omitempty"`
	TriggerType string `json:"trigger_type"`
	AIModel     string `json:"ai_model"`
	TokensUsed  int    `json:"tokens_used,omitempty"`
}

// Service AI叙事服务
type Service struct {
	apiKey       string
	apiURL       string
	model        string
	fallbackMode bool // 无API Key时使用本地生成
}

// NewService 创建AI叙事服务
func NewService() *Service {
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		apiKey = os.Getenv("DEEPSEEK_API_KEY")
	}
	apiURL := os.Getenv("AI_API_URL")
	if apiURL == "" {
		apiURL = "https://api.deepseek.com/chat/completions"
	}
	model := os.Getenv("AI_MODEL")
	if model == "" {
		model = "deepseek-chat"
	}

	return &Service{
		apiKey:       apiKey,
		apiURL:       apiURL,
		model:        model,
		fallbackMode: apiKey == "",
	}
}

// Generate 生成叙事内容
func (s *Service) Generate(req *TriggerRequest) (*NarrativeContent, error) {
	if s.fallbackMode {
		return s.generateLocal(req)
	}
	return s.generateWithAI(req)
}

// generateWithAI 调用AI生成叙事
func (s *Service) generateWithAI(req *TriggerRequest) (*NarrativeContent, error) {
	systemPrompt := `你是ChronoCards游戏的AI叙事引擎。
游戏设定：中国武侠架空世界"九州江湖"，明教正在崛起，江湖即将大乱。
叙事风格：古风武侠，文言白话结合，氛围感强。
每次叙事需要包含：标题、叙事正文、NPC对话（如果有）、玩家选项（2-3个）。

输出格式为JSON：
{
  "title": "事件标题",
  "narrative": "叙事正文（100-300字）",
  "dialogue": [{"speaker": "角色名", "text": "对话内容", "tone": "语气"}],
  "choices": [{"id": "choice1", "text": "选项文字", "effect_hint": "效果提示"}]
}`

	userPrompt := s.buildUserPrompt(req)

	payload := map[string]interface{}{
		"model": s.model,
		"messages": []map[string]string{
			{"role": "system", "content": systemPrompt},
			{"role": "user", "content": userPrompt},
		},
		"temperature": 0.8,
		"max_tokens": 1000,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequest("POST", s.apiURL, bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+s.apiKey)

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to call AI API: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
		Usage struct {
			TotalTokens int `json:"total_tokens"`
		} `json:"usage"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode AI response: %w", err)
	}

	if len(result.Choices) == 0 {
		return nil, fmt.Errorf("AI returned no content")
	}

	content := result.Choices[0].Message.Content

	// 尝试解析JSON
	var narrative NarrativeContent
	if err := json.Unmarshal([]byte(content), &narrative); err != nil {
		// 如果不是JSON格式，直接作为叙事文本
		narrative = NarrativeContent{
			Title:     req.CardTitle,
			Narrative: content,
			Metadata: NarrativeMetadata{
				TriggerType: string(req.TriggerType),
				AIModel:     s.model,
				TokensUsed:  result.Usage.TotalTokens,
			},
		}
	} else {
		narrative.Metadata = NarrativeMetadata{
			CardID:      req.CardID,
			TriggerType: string(req.TriggerType),
			AIModel:     s.model,
			TokensUsed:  result.Usage.TotalTokens,
		}
	}

	return &narrative, nil
}

// buildUserPrompt 构建用户提示词
func (s *Service) buildUserPrompt(req *TriggerRequest) string {
	tone := req.Context.Tone
	if tone == "" {
		tone = "mysterious"
	}

	location := req.Location
	if location == "" {
		location = "江湖某处"
	}

	cardInfo := ""
	if req.CardTitle != "" {
		cardInfo = fmt.Sprintf("当前卡牌：「%s」(%s)", req.CardTitle, req.CardType)
	}

	dealerInfo := ""
	if req.DealerID != "" {
		dealerInfo = fmt.Sprintf("发牌员ID: %s", req.DealerID)
	}

	return fmt.Sprintf(`
触发类型：%s
%s
%s
当前位置：%s
天下大势：%s
近期事件：%s
叙事基调：%s
玩家背景：%s
约束条件：最多%d字，%s

请生成符合武侠风格的叙事内容。`,
		req.TriggerType,
		cardInfo,
		dealerInfo,
		location,
		req.Context.WorldState,
		joinStrings(req.Context.RecentEvents, " → "),
		tone,
		req.Context.PlayerBackground,
		req.Constraints.MaxLength,
		boolToCN(req.Constraints.DialogueRequired, "需要包含NPC对话", "不需要NPC对话"),
	)
}

// generateLocal 本地生成（无API Key时使用模板）
func (s *Service) generateLocal(req *TriggerRequest) (*NarrativeContent, error) {
	// 本地模板生成，作为降级方案
	templates := map[string]*NarrativeContent{
		"main_story": {
			Title:     "江湖风云起",
			Narrative: "风云突变，江湖之上暗流涌动。消息传来，明教势力已在各地蠢蠢欲动，正派六大门派人心惶惶。天下将乱，你身为江湖中人，该如何抉择？",
			Dialogue: []DialogueLine{
				{Speaker: "神秘人", Text: "天下将乱，明教崛起...你可看到了？", Tone: "神秘"},
			},
			Choices: []Choice{
				{ID: "A", Text: "追查明教动向", EffectHint: "主线进度+1"},
				{ID: "B", Text: "静观其变", EffectHint: "保持中立"},
			},
		},
		"side_story": {
			Title:     "江湖轶事",
			Narrative: "茶余饭后，江湖人士议论纷纷。据说附近有奇人异事，你是否感兴趣？",
			Dialogue: []DialogueLine{
				{Speaker: "茶馆说书人", Text: "客官，可想听一段江湖旧事？", Tone: "热情"},
			},
			Choices: []Choice{
				{ID: "A", Text: "洗耳恭听", EffectHint: "获得情报"},
				{ID: "B", Text: "另有要事", EffectHint: "错过此事"},
			},
		},
		"blank": {
			Title:     "江湖无事",
			Narrative: "匹马江湖，孤身行走在夜色中。远处传来几声犬吠，炊烟袅袅。江湖之大，何处是归途？",
			Dialogue:  []DialogueLine{},
			Choices: []Choice{
				{ID: "A", Text: "继续前行", EffectHint: "自由探索"},
				{ID: "B", Text: "寻一处歇脚", EffectHint: "可能触发客栈事件"},
			},
		},
	}

	cardType := req.CardType
	if cardType == "" {
		cardType = "blank"
	}

	narrative, ok := templates[cardType]
	if !ok {
		narrative = templates["blank"]
	}

	nc := *narrative
	nc.Metadata = NarrativeMetadata{
		CardID:      req.CardID,
		TriggerType: string(req.TriggerType),
		AIModel:     "local-template",
	}
	return &nc, nil
}

func joinStrings(strs []string, sep string) string {
	if len(strs) == 0 {
		return "无"
	}
	result := ""
	for i, s := range strs {
		if i > 0 {
			result += sep
		}
		result += s
	}
	return result
}

func boolToCN(b bool, trueStr, falseStr string) string {
	if b {
		return trueStr
	}
	return falseStr
}
