import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/save_provider.dart';
import 'save_detail_screen.dart';
import 'export_import_screen.dart';

/// 存档列表页面
/// 列出玩家所有存档（存档名/等级/时间）
class SaveListScreen extends StatefulWidget {
  final String playerId;

  const SaveListScreen({super.key, required this.playerId});

  @override
  State<SaveListScreen> createState() => _SaveListScreenState();
}

class _SaveListScreenState extends State<SaveListScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化时获取存档列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SaveProvider>();
      provider.setCurrentPlayerId(widget.playerId);
      provider.fetchSaves();
    });
  }

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
        title: const Text(
          '📦 云存档',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<SaveProvider>().fetchSaves();
            },
          ),
          // 导出/导入按钮
          IconButton(
            icon: const Icon(Icons.import_export, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<SaveProvider>(),
                    child: const ExportImportScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SaveProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.saves.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentGold),
                  SizedBox(height: 16),
                  Text(
                    '加载存档中...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          if (provider.error != null && provider.saves.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchSaves(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.saves.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, color: Colors.white38, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无存档',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showSaveDialog(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text('创建新存档'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchSaves(),
            color: AppTheme.accentGold,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.saves.length,
              itemBuilder: (context, index) {
                final save = provider.saves[index];
                return _SaveCard(
                  save: save,
                  onTap: () => _navigateToDetail(context, save),
                  onDelete: () => _confirmDelete(context, provider, save),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSaveDialog(context, context.read<SaveProvider>()),
        backgroundColor: AppTheme.accentGold,
        child: const Icon(Icons.add, color: AppTheme.primaryDark),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, GameSave save) {
    context.read<SaveProvider>().selectSave(save);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<SaveProvider>(),
          child: SaveDetailScreen(save: save),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SaveProvider provider,
    GameSave save,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除存档 "${save.saveName}" 吗？\n此操作不可恢复！',
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await provider.delete(save.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showSaveDialog(BuildContext context, SaveProvider provider) async {
    final saveNameController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        title: const Text('创建新存档', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: saveNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '输入存档名称',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.primaryDark,
            ),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (saved == true && saveNameController.text.isNotEmpty && context.mounted) {
      final result = await provider.save(saveNameController.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

/// 存档卡片组件
class _SaveCard extends StatelessWidget {
  final GameSave save;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SaveCard({
    required this.save,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final timeAgo = _getTimeAgo(save.savedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.accentGold, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 缩略图或图标
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
                ),
                child: save.thumbnailBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          Uri.parse('data:image/png;base64,${save.thumbnailBase64}')
                              .data!.contentAsBytes(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.save,
                            color: AppTheme.accentGold,
                            size: 32,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.save,
                        color: AppTheme.accentGold,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 16),
              // 存档信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      save.saveName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppTheme.accentGold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Lv.${save.level}',
                          style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(save.savedAt),
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
