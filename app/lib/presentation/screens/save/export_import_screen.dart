import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/save_provider.dart';

/// 导出/导入页面
/// 显示base64导出字符串，支持粘贴导入
class ExportImportScreen extends StatefulWidget {
  /// 初始导出字符串（可选）
  final String? initialExportString;

  const ExportImportScreen({super.key, this.initialExportString});

  @override
  State<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends State<ExportImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _importController = TextEditingController();
  final _saveNameController = TextEditingController();
  bool _showExportString = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 如果有初始导出字符串，自动显示导出tab
    if (widget.initialExportString != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.index = 0; // 导出tab
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    _saveNameController.dispose();
    super.dispose();
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
          '📤 导出/导入',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: '导出', icon: Icon(Icons.upload, size: 20)),
            Tab(text: '导入', icon: Icon(Icons.download, size: 20)),
          ],
        ),
      ),
      body: Consumer<SaveProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // 导出Tab
              _buildExportTab(provider),
              // 导入Tab
              _buildImportTab(provider),
            ],
          );
        },
      ),
    );
  }

  /// 导出Tab
  Widget _buildExportTab(SaveProvider provider) {
    final exportString = widget.initialExportString ?? provider.exportString;

    if (exportString == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            const Text(
              '暂无导出数据',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '请先在存档详情页选择导出',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 提示信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '请妥善保存以下字符串，导入时需要用到',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 导出字符串显示区
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '导出字符串',
                      style: TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // 显示/隐藏切换
                        IconButton(
                          icon: Icon(
                            _showExportString
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _showExportString = !_showExportString;
                            });
                          },
                          tooltip: _showExportString ? '隐藏' : '显示',
                        ),
                        // 复制按钮
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () => _copyToClipboard(exportString),
                          tooltip: '复制',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _showExportString
                        ? exportString
                        : '${exportString.substring(0, exportString.length.clamp(0, 50))}...',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    maxLines: _showExportString ? null : 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 复制按钮
          ElevatedButton.icon(
            onPressed: () => _copyToClipboard(exportString),
            icon: const Icon(Icons.copy),
            label: const Text('复制到剪贴板'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          // 分享提示
          const Center(
            child: Text(
              '💡 建议：将字符串保存到云笔记或备忘录',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// 导入Tab
  Widget _buildImportTab(SaveProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 提示信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '请粘贴之前导出的Base64字符串',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 粘贴区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '粘贴导出字符串',
                      style: TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _pasteFromClipboard(),
                      icon: const Icon(Icons.paste, size: 16),
                      label: const Text('粘贴'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _importController,
                  maxLines: 8,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: '在此粘贴Base64导出字符串...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: AppTheme.primaryDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 存档名称（可选）
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '新存档名称（可选）',
                  style: TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _saveNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '留空则使用原存档名称',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: AppTheme.primaryDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 导入按钮
          ElevatedButton.icon(
            onPressed: provider.isImporting
                ? null
                : () => _handleImport(provider),
            icon: provider.isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryDark,
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(provider.isImporting ? '导入中...' : '开始导入'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          // 错误提示
          if (provider.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // 注意事项
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 导入注意事项',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                _NoteItem(text: '• 确保字符串完整，无遗漏字符'),
                _NoteItem(text: '• 导入的存档会添加到列表中'),
                _NoteItem(text: '• 可以指定新的存档名称'),
                _NoteItem(text: '• 导入失败请联系技术支持'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 复制到剪贴板
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制到剪贴板'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 从剪贴板粘贴
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _importController.text = data!.text!;
    }
  }

  /// 处理导入
  Future<void> _handleImport(SaveProvider provider) async {
    final importString = _importController.text.trim();
    if (importString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先粘贴导出字符串'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final saveName = _saveNameController.text.trim();
    final result = await provider.import(
      importString,
      newSaveName: saveName.isNotEmpty ? saveName : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        // 导入成功后切换到导出tab显示新的导出字符串
        _importController.clear();
        _saveNameController.clear();
        _tabController.index = 0;
      }
    }
  }
}

/// 注意事项项
class _NoteItem extends StatelessWidget {
  final String text;

  const _NoteItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }
}
