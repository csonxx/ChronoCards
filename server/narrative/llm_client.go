package narrative

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// LLMClient wraps MiniMax Chat V2 API calls with retry and timeout support.
type LLMClient struct {
	apiKey     string
	apiHost    string
	model      string
	maxTokens  int
	temperature float64
	httpClient *http.Client
}

// LLMResponse represents the parsed MiniMax chat completion response.
type LLMResponse struct {
	ID      string `json:"id"`
	Choices []struct {
		FinishReason string `json:"finish_reason"`
		Messages     []struct {
			Role    string `json:"role"`
			Content string `json:"content"`
		} `json:"messages"`
	} `json:"choices"`
	Usage struct {
		TotalTokens int `json:"total_tokens"`
	} `json:"usage"`
}

// ChatRequest is the MiniMax Chat V2 request body.
type ChatRequest struct {
	Model       string        `json:"model"`
	Messages    []ChatMessage  `json:"messages"`
	Temperature float64       `json:"temperature,omitempty"`
	MaxTokens   int            `json:"max_tokens,omitempty"`
}

// ChatMessage is a single message in the chat.
type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// NewLLMClient creates a new LLM client with the given API key.
// Falls back to defaults for optional parameters.
func NewLLMClient(apiKey string) *LLMClient {
	return &LLMClient{
		apiKey:     apiKey,
		apiHost:    "https://api.minimaxi.com",
		model:      "abab7-chat",
		maxTokens:  512,
		temperature: 0.7,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// SetModel sets the model name.
func (c *LLMClient) SetModel(model string) *LLMClient {
	c.model = model
	return c
}

// SetMaxTokens sets the max tokens limit.
func (c *LLMClient) SetMaxTokens(maxTokens int) *LLMClient {
	c.maxTokens = maxTokens
	return c
}

// Chat sends a chat request to MiniMax and returns the assistant's content.
// It retries up to maxRetries times with exponential backoff on failure.
func (c *LLMClient) Chat(ctx context.Context, messages []ChatMessage, maxRetries int) (*LLMResponse, error) {
	reqBody := ChatRequest{
		Model:       c.model,
		Messages:    messages,
		Temperature: c.temperature,
		MaxTokens:   c.maxTokens,
	}

	var lastErr error
	backoffs := []time.Duration{500 * time.Millisecond, 1000 * time.Millisecond}

	for attempt := 0; attempt <= maxRetries; attempt++ {
		if attempt > 0 && attempt-1 < len(backoffs) {
			time.Sleep(backoffs[attempt-1])
		}

		resp, err := c.doRequest(ctx, reqBody)
		if err == nil {
			return resp, nil
		}

		lastErr = err

		// Don't retry on context cancellation or permanent errors
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		//判断是否是可重试的错误（暂时都重试，429/5xx 在 doRequest 里已经处理）
	}

	return nil, fmt.Errorf("LLM chat failed after %d retries: %w", maxRetries, lastErr)
}

func (c *LLMClient) doRequest(ctx context.Context, reqBody ChatRequest) (*LLMResponse, error) {
	bodyBytes, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}

	url := c.apiHost + "/v1/text/chatcompletion_v2"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request error: %w", err)
	}
	defer resp.Body.Close()

	// Read body
	respBody, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	if err != nil {
		return nil, fmt.Errorf("read body: %w", err)
	}

	// Handle HTTP errors
	if resp.StatusCode == http.StatusTooManyRequests {
		return nil, fmt.Errorf("rate limited (429)")
	}
	if resp.StatusCode >= 500 {
		return nil, fmt.Errorf("server error %d: %s", resp.StatusCode, string(respBody))
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status %d: %s", resp.StatusCode, string(respBody))
	}

	var llmResp LLMResponse
	if err := json.Unmarshal(respBody, &llmResp); err != nil {
		return nil, fmt.Errorf("unmarshal response: %w, body: %s", err, string(respBody))
	}

	if len(llmResp.Choices) == 0 || len(llmResp.Choices[0].Messages) == 0 {
		return nil, fmt.Errorf("empty response from LLM")
	}

	return &llmResp, nil
}

// ExtractContent returns the assistant's text content from the response.
func (r *LLMResponse) ExtractContent() string {
	if len(r.Choices) == 0 {
		return ""
	}
	return r.Choices[0].Messages[0].Content
}
