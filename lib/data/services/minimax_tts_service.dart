import 'dart:convert';
import 'package:http/http.dart' as http;

/// MiniMax TTS Service
/// 文档: https://www.minimaxi.com/document/Guides/TTS/V2-TTS
class MiniMaxTtsService {
  final String apiKey;
  final String baseUrl = 'https://api.minimax.chat/v1/t2a_v2';

  MiniMaxTtsService({required this.apiKey});

  /// 文字转语音
  /// [text] 要转换的文字
  /// [model] 模型选择: 'speech-02-hd', 'speech-02', 'speech-01'
  /// [voiceId] 音色ID，默认 'male-qn-qingse'
  Future<Uint8List?> synthesize({
    required String text,
    String model = 'speech-02-hd',
    String voiceId = 'male-qn-qingse',
    int speed = 1.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'text': text,
          'stream': false,
          'voice_setting': {
            'voice_id': voiceId,
            'speed': speed,
            'volume': 1.0,
            'pitch': 0,
            'emotion': 'neutral',
          },
          'audio_setting': {
            'format': 'mp3',
            'sample_rate': 32000,
            'bitrate': 128000,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioFile = data['data']?['audio_file'];
        if (audioFile == null) return null;

        // audio_file 可能是 base64 字符串或 URL
        if (audioFile is String) {
          // 判断是 URL 还是 base64
          if (audioFile.startsWith('http://') || audioFile.startsWith('https://')) {
            // 下载音频文件
            final audioResponse = await http.get(Uri.parse(audioFile));
            if (audioResponse.statusCode == 200) {
              return audioResponse.bodyBytes;
            }
          } else {
            // base64 解码
            try {
              return base64Decode(audioFile);
            } catch (_) {
              return null;
            }
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取可用音色列表
  static List<Map<String, String>> get availableVoices => [
    {'id': 'male-qn-qingse', 'name': '清涩少年', 'lang': '中文'},
    {'id': 'male-tianmei', 'name': '甜美女友', 'lang': '中文'},
    {'id': 'female-yujie', 'name': '御姐', 'lang': '中文'},
  ];
}
