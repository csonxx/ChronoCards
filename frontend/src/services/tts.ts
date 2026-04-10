/**
 * MiniMax TTS 服务
 * 文档: https://www.minimaxi.com/document/Text-To-Audio
 */

// MiniMax TTS API 配置
const TTS_API_URL = 'https://api.minimax.chat/v1/t2a_v2';

// 声音选项（古风武侠风格）
export interface VoiceOption {
  id: string;
  name: string;
  description: string;
}

export const VOICE_OPTIONS: VoiceOption[] = [
  { id: 'male-qingyun', name: '清云', description: '青年剑客，清朗有力' },
  { id: 'male-young', name: '少侠', description: '少年侠士，活力充沛' },
  { id: 'female-ningwoo', name: '凝眸', description: '江湖女侠，柔中带刚' },
  { id: 'female-xian', name: '仙子', description: '超凡脱俗，空灵飘逸' },
  { id: 'male-old', name: '老者', description: '武林前辈，沉稳厚重' },
  { id: 'male-shaonian', name: '少年', description: '少年弟子，青涩稚嫩' },
];

// TTS 请求参数
export interface TTSRequest {
  text: string;
  voiceId?: string;
  speed?: number; // 0.5 - 2.0
  volume?: number; // 0 - 100
  pitch?: number; // -12 - 12
}

// TTS 响应
export interface TTSResponse {
  success: boolean;
  audioUrl?: string;
  audioBlob?: Blob;
  error?: string;
}

// API Key 获取
const getApiKey = (): string | undefined => {
  return import.meta.env.VITE_MINIMAX_API_KEY;
};

/**
 * 调用 MiniMax TTS API
 * @param request TTS请求参数
 * @returns TTS响应，包含音频Blob
 */
export async function callMiniMaxTTS(request: TTSRequest): Promise<TTSResponse> {
  const apiKey = getApiKey();
  
  if (!apiKey) {
    return {
      success: false,
      error: '未配置 MiniMax API Key，请在 .env 中设置 VITE_MINIMAX_API_KEY'
    };
  }

  try {
    const response = await fetch(TTS_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'speech-02-hd', // 使用高清语音模型
        text: request.text,
        stream: false,
        voice_setting: {
          voice_id: request.voiceId || 'male-qingyun',
          speed: request.speed ?? 1.0,
          volume: request.volume ?? 50,
          pitch: request.pitch ?? 0,
        },
        audio_setting: {
          sample_rate: 32000,
          format: 'mp3',
          bitrate: 128000,
        },
      }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.base_resp?.status_msg || `HTTP ${response.status}`);
    }

    // TTS API 返回的是音频二进制数据
    const audioBlob = await response.blob();
    
    return {
      success: true,
      audioBlob,
    };
  } catch (error) {
    console.error('MiniMax TTS Error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'TTS 请求失败',
    };
  }
}

/**
 * 播放 TTS 音频
 * @param audioBlob 音频Blob
 */
export function playAudio(audioBlob: Blob): HTMLAudioElement {
  const audioUrl = URL.createObjectURL(audioBlob);
  const audio = new Audio(audioUrl);
  audio.play();
  
  // 播放完毕后清理 URL
  audio.onended = () => {
    URL.revokeObjectURL(audioUrl);
  };
  
  return audio;
}

/**
 * 完整的 TTS 播放流程
 */
export async function speak(
  text: string,
  options: Partial<Omit<TTSRequest, 'text'>> = {}
): Promise<{ success: boolean; error?: string }> {
  const result = await callMiniMaxTTS({ text, ...options });
  
  if (!result.success || !result.audioBlob) {
    return { success: false, error: result.error };
  }
  
  playAudio(result.audioBlob);
  return { success: true };
}
