import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 存档数据结构
class GameSave {
  final String id;
  final String playerId;
  final String saveName;
  final int level;
  final DateTime savedAt;
  final String? thumbnailBase64;
  final Map<String, dynamic> metadata;

  const GameSave({
    required this.id,
    required this.playerId,
    required this.saveName,
    required this.level,
    required this.savedAt,
    this.thumbnailBase64,
    this.metadata = const {},
  });

  factory GameSave.fromJson(Map<String, dynamic> json) {
    return GameSave(
      id: json['id'] ?? '',
      playerId: json['player_id'] ?? '',
      saveName: json['save_name'] ?? '未命名存档',
      level: json['level'] ?? 1,
      savedAt: json['saved_at'] != null
          ? DateTime.parse(json['saved_at'])
          : DateTime.now(),
      thumbnailBase64: json['thumbnail_base64'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'save_name': saveName,
      'level': level,
      'saved_at': savedAt.toIso8601String(),
      'thumbnail_base64': thumbnailBase64,
      'metadata': metadata,
    };
  }
}

/// 存档操作结果
class SaveResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const SaveResult({
    required this.success,
    required this.message,
    this.data,
  });

  factory SaveResult.success(String message, [Map<String, dynamic>? data]) {
    return SaveResult(success: true, message: message, data: data);
  }

  factory SaveResult.failure(String message) {
    return SaveResult(success: false, message: message);
  }
}

/// SaveProvider - 云存档系统状态管理
/// 后端API:
/// - GET /api/v1/players/{player_id}/save — 获取存档
/// - POST /api/v1/players/{player_id}/load — 加载存档
/// - POST /api/v1/players/{player_id}/export — 导出存档
/// - POST /api/v1/players/{player_id}/import — 导入存档
/// - GET /api/v1/saves — 列出所有存档
/// - DELETE /api/v1/players/{player_id}/save — 删除存档
/// - POST /api/v1/players/{player_id}/backup — 备份存档
class SaveProvider extends ChangeNotifier {
  // 当前玩家ID
  String? _currentPlayerId;
  
  // 存档列表
  List<GameSave> _saves = [];
  
  // 当前选中的存档
  GameSave? _selectedSave;
  
  // 是否加载中
  bool _isLoading = false;
  
  // 导出字符串
  String? _exportString;
  
  // 导入状态
  bool _isImporting = false;
  
  // 错误信息
  String? _error;

  // API基础URL（可配置）
  String _apiBaseUrl = 'http://localhost:8080/api/v1';

  // Getters
  String? get currentPlayerId => _currentPlayerId;
  List<GameSave> get saves => _saves;
  GameSave? get selectedSave => _selectedSave;
  bool get isLoading => _isLoading;
  String? get exportString => _exportString;
  bool get isImporting => _isImporting;
  String? get error => _error;

  /// 设置API基础URL
  void setApiBaseUrl(String url) {
    _apiBaseUrl = url;
    notifyListeners();
  }

  /// 设置当前玩家ID
  void setCurrentPlayerId(String playerId) {
    _currentPlayerId = playerId;
    notifyListeners();
  }

  /// 选择存档
  void selectSave(GameSave save) {
    _selectedSave = save;
    _error = null;
    notifyListeners();
  }

  /// 清除选择
  void clearSelection() {
    _selectedSave = null;
    _error = null;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// ===== API Methods =====

  /// 获取玩家存档列表
  Future<SaveResult> fetchSaves() async {
    if (_currentPlayerId == null) {
      return SaveResult.failure('未设置玩家ID');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/players/$_currentPlayerId/saves'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> savesList = data['saves'] ?? [];
        _saves = savesList.map((s) => GameSave.fromJson(s)).toList();
        _isLoading = false;
        notifyListeners();
        return SaveResult.success('获取存档列表成功', {'count': _saves.length});
      } else {
        _error = '获取存档列表失败: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return SaveResult.failure(_error!);
      }
    } catch (e) {
      _error = '网络错误: $e';
      _isLoading = false;
      notifyListeners();
      return SaveResult.failure(_error!);
    }
  }

  /// 获取单个存档详情
  Future<SaveResult> fetchSave(String saveId) async {
    if (_currentPlayerId == null) {
      return SaveResult.failure('未设置玩家ID');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/players/$_currentPlayerId/save?save_id=$saveId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _selectedSave = GameSave.fromJson(data['save']);
        _isLoading = false;
        notifyListeners();
        return SaveResult.success('获取存档成功');
      } else {
        _error = '获取存档失败: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return SaveResult.failure(_error!);
      }
    } catch (e) {
      _error = '网络错误: $e';
      _isLoading = false;
      notifyListeners();
      return SaveResult.failure(_error!);
    }
  }

  /// 保存当前游戏
  Future<SaveResult> save(String saveName, {Map<String, dynamic>? metadata}) async {
    if (_currentPlayerId == null) {
      return SaveResult.failure('未设置玩家ID');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'save_name': saveName,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/players/$_currentPlayerId/save'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final newSave = GameSave.fromJson(data['save']);
        
        // 更新本地列表
        final index = _saves.indexWhere((s) => s.id == newSave.id);
        if (index >= 0) {
          _saves[index] = newSave;
        } else {
          _saves.insert(0, newSave);
        }
        
        _selectedSave = newSave;
        _isLoading = false;
        notifyListeners();
        return SaveResult.success('存档成功');
      } else {
        _error = '存档失败: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return SaveResult.failure(_error!);
      }
    } catch (e) {
      _error = '网络错误: $e';
      _isLoading = false;
      notifyListeners();
      return SaveResult.failure(_error!);
    }
  }

  /// 加载存档
  Future<SaveResult> load(String saveId) async {
    if (_currentPlayerId == null) {
      return SaveResult.failure('未设置玩家ID');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/players/$_currentPlayerId/load'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'save_id': saveId}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isLoading = false;
        notifyListeners();
        return SaveResult.success('加载存档成功', data);
      } else {
        _error = '加载存档失败: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return SaveResult.failure(_error!);
      }
    } catch (e) {
      _error = '网络错误: $e';
      _isLoading = false;
      notifyListeners();
      return SaveResult.failure(_error!);
    }
  }

  /// 导出存档为Base64字符串
  Future<SaveResult> export(String saveId) async {
    if (_currentPlayerId == null) {
      return SaveResult.failure('未设置玩家ID');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/players/$_currentPlayerId/export'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'save_id': saveId}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exportString = data['export_string'];
        _isLoading = false;
        notifyListeners();
        return SaveResult.success('导出成功', {'export_string': _exportString});
      } else {
        _error = '导出失败: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return SaveResult.failure(_error!);
      }
    } catch (e) {
      _error = '网络错误: $e';
      _isLoading = false;
      notifyListeners();
      return SaveResult.failure(_error!);
    }
  }

  /// 从Base64字符串导入存档
  Future<SaveResult> import(String exportString, {String? newSaveName}) async {
    if (_currentPlayerId == null) {
      return SaveResult.failure('未设置玩家ID');
    }

    _isImporting = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'export_string': exportString,
        if (newSaveName != null) 'save_name': newSaveName,
      };

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/players/$_currentPlayerId/import'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final newSave = GameSave.fromJson(data['save']);
        
        // 添加到本地列表
        _saves.insert(0, newSave);
        
        _isImporting = false;
        _isLoading = false;
        notifyListeners();
        return SaveResult.success('导入成功', {'save': newSave.toJson()});
      } else {
        _error = '导入失败: ${response.statusCode}';
        _isImporting = false;
        _isLoading = false;
        notifyListeners();
        return SaveResult.failure(_error!);
      }
    } catch (e) {
      _error = '网络错误: $e';
      _isImporting = false;
      _isLoading = false;
      notifyListeners();
      return SaveResult.failure(_error!);
    }
  }

  /// 删除存档
  Future<SaveResult> delete(String saveId) async {
    if (_currentPlayerId == null) {
      return SaveResult.failure('未设置玩家ID');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/players/$_currentPlayerId/save?save_id=$saveId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 从本地列表移除
        _saves.removeWhere((s) => s.id == saveId);
        if (_selectedSave?.id == saveId) {
          _selectedSave = null;
        }
        _isLoading = false;
        notifyListeners();
        return SaveResult.success('删除成功');
      } else {
        _error = '删除失败: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return SaveResult.failure(_error!);
      }
    } catch (e) {
      _error = '网络错误: $e';
      _isLoading = false;
      notifyListeners();
      return SaveResult.failure(_error!);
    }
  }

  /// 备份存档
  Future<SaveResult> backup(String saveId) async {
    if (_currentPlayerId == null) {
      return SaveResult.failure('未设置玩家ID');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/players/$_currentPlayerId/backup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'save_id': saveId}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _isLoading = false;
        notifyListeners();
        return SaveResult.success('备份成功', data);
      } else {
        _error = '备份失败: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return SaveResult.failure(_error!);
      }
    } catch (e) {
      _error = '网络错误: $e';
      _isLoading = false;
      notifyListeners();
      return SaveResult.failure(_error!);
    }
  }

  /// 清除导出字符串
  void clearExportString() {
    _exportString = null;
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _currentPlayerId = null;
    _saves = [];
    _selectedSave = null;
    _isLoading = false;
    _isImporting = false;
    _exportString = null;
    _error = null;
    notifyListeners();
  }
}
