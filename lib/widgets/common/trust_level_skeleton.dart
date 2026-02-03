import 'package:flutter/material.dart';
import '../common/skeleton.dart';

/// 信任级别要求页骨架屏
class TrustLevelSkeleton extends StatelessWidget {
  const TrustLevelSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Skeleton(
      child: CustomScrollView(
        slivers: [
          // AppBar 骨架
          SliverAppBar.large(
            title: const Text('信任要求'),
            centerTitle: false,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surface,
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SkeletonBox(width: 200, height: 24),
                          const SizedBox(height: 8),
                          SkeletonBox(width: double.infinity, height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 内容骨架
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 标题
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: SkeletonBox(width: 80, height: 18),
                ),
                // 表格骨架
                _buildTableSkeleton(context),
                const SizedBox(height: 24),
                // 状态列表标题
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: SkeletonBox(width: 80, height: 18),
                ),
                // 状态列表骨架
                _buildStatusItemSkeleton(context),
                _buildStatusItemSkeleton(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          // 表头
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 4, child: SkeletonBox(width: 60, height: 14)),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: SkeletonBox(width: 60, height: 14)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: SkeletonBox(width: 40, height: 14)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // 表格行
          ...List.generate(6, (index) => _buildTableRowSkeleton(context, index == 5)),
        ],
      ),
    );
  }

  Widget _buildTableRowSkeleton(BuildContext context, bool isLast) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: SkeletonBox(width: 80, height: 14)),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: SkeletonBox(width: 50, height: 22, borderRadius: 6)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: SkeletonBox(width: 30, height: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusItemSkeleton(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SkeletonCircle(size: 20),
          const SizedBox(width: 12),
          Expanded(child: SkeletonBox(width: double.infinity, height: 16)),
        ],
      ),
    );
  }
}
