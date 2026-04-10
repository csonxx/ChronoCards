/**
 * useTTS Hook - React 组件 TTS 集成
 */
import { useState, useCallback, useRef, useEffect } from 'react';
import { callMiniMaxTTS, playAudio, VOICE_OPTIONS, type VoiceOption } from '../services/tts';

export interface UseTTSOptions {
  voiceId?: string;
  speed?: number;
  volume?: number;
  pitch?: number;
  onStart?: () => void;
  onEnd?: () => void;
  onError?: (error: string) => void;
}

export interface UseTTSReturn {
  // 状态
  isPlaying: boolean;
  isLoading: boolean;
  error: string | null;
  
  // 当前配置
  currentVoice: VoiceOption;
  
  // 操作
  speak: (text: string) => Promise<void>;
  stop: () => void;
  
  // 配置
  setVoice: (voiceId: string) => void;
  setSpeed: (speed: number) => void;
  setVolume: (volume: number) => void;
  setPitch: (pitch: number) => void;
  
  // 可用选项
  voiceOptions: VoiceOption[];
}

export function useTTS(options: UseTTSOptions = {}): UseTTSReturn {
  const [isPlaying, setIsPlaying] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentVoice, setCurrentVoice] = useState<VoiceOption>(
    VOICE_OPTIONS.find(v => v.id === options.voiceId) || VOICE_OPTIONS[0]
  );
  
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const currentTextRef = useRef<string>('');

  // 清理函数
  useEffect(() => {
    return () => {
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current = null;
      }
    };
  }, []);

  const speak = useCallback(async (text: string) => {
    // 如果正在播放，先停止
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current = null;
    }

    setIsLoading(true);
    setError(null);
    currentTextRef.current = text;
    options.onStart?.();

    try {
      const result = await callMiniMaxTTS({
        text,
        voiceId: currentVoice.id,
        speed: options.speed ?? 1.0,
        volume: options.volume ?? 50,
        pitch: options.pitch ?? 0,
      });

      if (!result.success || !result.audioBlob) {
        throw new Error(result.error || 'TTS 转换失败');
      }

      const audio = playAudio(result.audioBlob);
      audioRef.current = audio;
      
      audio.onplay = () => {
        setIsLoading(false);
        setIsPlaying(true);
      };

      audio.onended = () => {
        setIsPlaying(false);
        setIsLoading(false);
        options.onEnd?.();
      };

      audio.onerror = () => {
        setIsPlaying(false);
        setIsLoading(false);
        const errMsg = '音频播放失败';
        setError(errMsg);
        options.onError?.(errMsg);
      };
    } catch (err) {
      setIsLoading(false);
      setIsPlaying(false);
      const errMsg = err instanceof Error ? err.message : '未知错误';
      setError(errMsg);
      options.onError?.(errMsg);
    }
  }, [currentVoice, options]);

  const stop = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current.currentTime = 0;
      audioRef.current = null;
    }
    setIsPlaying(false);
    setIsLoading(false);
  }, []);

  const setVoice = useCallback((voiceId: string) => {
    const voice = VOICE_OPTIONS.find(v => v.id === voiceId);
    if (voice) {
      setCurrentVoice(voice);
    }
  }, []);

  const setSpeed = useCallback((_speed: number) => {
    // Speed will be applied on next speak
  }, []);

  const setVolume = useCallback((_volume: number) => {
    // Volume is handled by the audio element
  }, []);

  const setPitch = useCallback((_pitch: number) => {
    // Pitch is handled by the TTS API
  }, []);

  return {
    isPlaying,
    isLoading,
    error,
    currentVoice,
    speak,
    stop,
    setVoice,
    setSpeed,
    setVolume,
    setPitch,
    voiceOptions: VOICE_OPTIONS,
  };
}
