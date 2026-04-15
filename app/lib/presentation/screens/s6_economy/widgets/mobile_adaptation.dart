import 'package:flutter/material.dart';

/// 移动端适配工具类
/// 提供响应式布局和触摸优化的辅助方法
class MobileAdaptation {
  /// 最小触摸目标尺寸 (44pt - 符合Apple HIG和Google Material设计规范)
  static const double minTouchTarget = 44.0;

  /// 判断是否为移动设备（基于屏幕宽度）
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  /// 判断是否为平板
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 600 && size.shortestSide < 900;
  }

  /// 判断是否为桌面设备
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 900;
  }

  /// 获取响应式字体大小
  static double responsiveFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize * 0.85;
    } else if (isTablet(context)) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  /// 获取响应式内边距
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// 安全区域适配（刘海屏等）
  static EdgeInsets safeAreaPadding(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return EdgeInsets.only(
      top: padding.top > 0 ? padding.top : 16,
      bottom: padding.bottom > 0 ? padding.bottom : 16,
      left: padding.left > 0 ? padding.left : 16,
      right: padding.right > 0 ? padding.right : 16,
    );
  }
}

/// 移动端优化的触摸目标包装器
/// 确保所有可交互元素至少44x44pt
class TouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minSize;

  const TouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minSize = MobileAdaptation.minTouchTarget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: minSize,
        height: minSize,
        child: Center(child: child),
      ),
    );
  }
}

/// 响应式网格视图
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int mobileCrossAxisCount;
  final int tabletCrossAxisCount;
  final int desktopCrossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileCrossAxisCount = 1,
    this.tabletCrossAxisCount = 2,
    this.desktopCrossAxisCount = 3,
    this.childAspectRatio = 2.5,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    int crossAxisCount;
    if (MobileAdaptation.isMobile(context)) {
      crossAxisCount = mobileCrossAxisCount;
    } else if (MobileAdaptation.isTablet(context)) {
      crossAxisCount = tabletCrossAxisCount;
    } else {
      crossAxisCount = desktopCrossAxisCount;
    }

    return GridView.builder(
      padding: MobileAdaptation.responsivePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// 响应式列布局
class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (MobileAdaptation.isMobile(context)) {
      // 移动端垂直排列
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }
    // 平板/桌面水平排列
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// 移动端优化的底部导航栏
class MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MobileNavItem> items;

  const MobileBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 移动端导航项
class MobileNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const MobileNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// 可滑动的Tab标签栏（移动端优化）
class SwipeableTabBar extends StatelessWidget {
  final TabController controller;
  final List<SwipeableTab> tabs;
  final Color? activeColor;
  final Color? inactiveColor;

  const SwipeableTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        indicatorColor: activeColor ?? theme.colorScheme.primary,
        labelColor: activeColor ?? theme.colorScheme.primary,
        unselectedLabelColor: inactiveColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: tabs.map((tab) => Tab(
          icon: Icon(tab.icon, size: 20),
          text: tab.label,
        )).toList(),
      ),
    );
  }
}

/// 可滑动Tab
class SwipeableTab {
  final IconData icon;
  final String label;

  const SwipeableTab({
    required this.icon,
    required this.label,
  });
}

/// 缩放友好的地图/图片查看器
class ZoomableView extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;

  const ZoomableView({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 3.0,
  });

  @override
  State<ZoomableView> createState() => _ZoomableViewState();
}

class _ZoomableViewState extends State<ZoomableView> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        // 双击缩放
        if (_transformationController.value != Matrix4.identity()) {
          _transformationController.value = Matrix4.identity();
        } else {
          _transformationController.value = Matrix4.identity()..scale(2.0);
        }
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        child: widget.child,
      ),
    );
  }
}

/// 触摸反馈组件
class TouchFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? highlightColor;

  const TouchFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.highlightColor,
  });

  @override
  State<TouchFeedback> createState() => _TouchFeedbackState();
}

class _TouchFeedbackState extends State<TouchFeedback> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed
            ? (widget.highlightColor ?? Colors.white.withOpacity(0.1))
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}
