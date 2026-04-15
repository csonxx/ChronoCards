import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/save_provider.dart';
import 'export_import_screen.dart';

/// 存档详情/操作页面
/// 展示存档信息，提供加载/导出/备份/删除操作
class SaveDetailScreen extends StatelessWidget {
  final GameSave save;

  const SaveDetailScreen({super.key, required this.save});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          save.saveName,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Consumer<SaveProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 存档信息卡片
                _buildInfoCard(context, provider),
                const SizedBox(height: 24),

                // 操作按钮区
                _buildActionButtons(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, SaveProvider provider) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm:ss');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // 缩略图
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentGold, width: 2),
            ),
            child: save.thumbnailBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      Uri.parse('data:image/png;base64,${save.thumbnailBase64}')
                          .data!.contentAsBytes(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.save,
                        color: AppTheme.accentGold,
                        size: 64,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.save,
                    color: AppTheme.accentGold,
                    size: 64,
                  ),
          ),
          const SizedBox(height: 20),

          // 存档名称
          Text(
            save.saveName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 信息网格
          _buildInfoGrid(dateFormat),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('📋 存档ID', save.id, isId: true),
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow('👤 玩家ID', save.playerId, isId: true),
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow('⭐ 等级', 'Lv. ${save.level}'),
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow('📅 创建时间', dateFormat.format(save.savedAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isId = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isId ? Colors.white38 : Colors.white,
              fontSize: 14,
              fontFamily: isId ? 'monospace' : null,
            ),
            maxLines: isId ? 1 : 2,
            overflow: isId ? TextOverflow.ellipsis : TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, SaveProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 加载按钮（主要操作）
        _ActionButton(
          icon: Icons.play_arrow,
          label: '加载存档',
          description: '将存档数据加载到当前游戏',
          color: AppTheme.accentGold,
          textColor: AppTheme.primaryDark,
          isLoading: provider.isLoading,
          onPressed: () => _handleLoad(context, provider),
        ),
        const SizedBox(height: 12),

        // 导出按钮
        _ActionButton(
          icon: Icons.upload,
          label: '导出存档',
          description: '将存档导出为Base64字符串',
          color: Colors.blue,
          textColor: Colors.white,
          isLoading: provider.isLoading,
          onPressed: () => _handleExport(context, provider),
        ),
        const SizedBox(height: 12),

        // 备份按钮
        _ActionButton(
          icon: Icons.backup,
          label: '备份存档',
          description: '创建存档云端备份',
          color: Colors.green,
          textColor: Colors.white,
          isLoading: provider.isLoading,
          onPressed: () => _handleBackup(context, provider),
        ),
        const SizedBox(height: 12),

        // 删除按钮
        _ActionButton(
          icon: Icons.delete,
          label: '删除存档',
          description: '永久删除此存档（不可恢复）',
          color: Colors.red,
          textColor: Colors.white,
          isLoading: provider.isLoading,
          onPressed: () => _handleDelete(context, provider),
        ),
      ],
    );
  }

  Future<void> _handleLoad(BuildContext context, SaveProvider provider) async {
    final confirmed = await _showConfirmDialog(
      context,
      '加载存档',
      '确定要加载 "${save.saveName}" 吗？\n当前未保存的进度将会丢失。',
      confirmText: '加载',
      confirmColor: AppTheme.accentGold,
    );

    if (confirmed == true && context.mounted) {
      final result = await provider.load(save.id);
      if (context.mounted) {
        _showResultSnackBar(context, result);
        if (result.success) {
          // 加载成功后可以跳转或更新游戏状态
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  Future<void> _handleExport(BuildContext context, SaveProvider provider) async {
    final result = await provider.export(save.id);
    if (context.mounted) {
      if (result.success && provider.exportString != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: ExportImportScreen(initialExportString: provider.exportString),
            ),
          ),
        );
      } else {
        _showResultSnackBar(context, result);
      }
    }
  }

  Future<void> _handleBackup(BuildContext context, SaveProvider provider) async {
    final confirmed = await _showConfirmDialog(
      context,
      '备份存档',
      '确定要为 "${save.saveName}" 创建云端备份吗？',
      confirmText: '备份',
      confirmColor: Colors.green,
    );

    if (confirmed == true && context.mounted) {
      final result = await provider.backup(save.id);
      if (context.mounted) {
        _showResultSnackBar(context, result);
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, SaveProvider provider) async {
    final confirmed = await _showConfirmDialog(
      context,
      '删除存档',
      '⚠️ 确定要永久删除 "${save.saveName}" 吗？\n此操作不可恢复！',
      confirmText: '删除',
      confirmColor: Colors.red,
    );

    if (confirmed == true && context.mounted) {
      final result = await provider.delete(save.id);
      if (context.mounted) {
        _showResultSnackBar(context, result);
        if (result.success) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String content, {
    String confirmText = '确认',
    Color? confirmColor,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppTheme.accentGold,
              foregroundColor: confirmColor == AppTheme.accentGold
                  ? AppTheme.primaryDark
                  : Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showResultSnackBar(BuildContext context, SaveResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }
}

/// 操作按钮组件
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.textColor,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, color: textColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
