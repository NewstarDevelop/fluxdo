import 'package:flutter/material.dart';
import '../../models/topic.dart';

enum TopicNotificationButtonStyle {
  icon,
  chip,
}

/// 显示订阅级别选择面板
void showNotificationLevelSheet(
  BuildContext context,
  TopicNotificationLevel currentLevel,
  ValueChanged<TopicNotificationLevel> onSelected,
) {
  showModalBottomSheet(
    context: context,
    builder: (context) => _NotificationLevelSheet(
      currentLevel: currentLevel,
      onSelected: (newLevel) {
        Navigator.pop(context);
        onSelected(newLevel);
      },
    ),
  );
}

class TopicNotificationButton extends StatelessWidget {
  final TopicNotificationLevel level;
  final ValueChanged<TopicNotificationLevel>? onChanged;
  final TopicNotificationButtonStyle style;

  const TopicNotificationButton({
    super.key,
    required this.level,
    this.onChanged,
    this.style = TopicNotificationButtonStyle.icon,
  });

  static IconData getIcon(TopicNotificationLevel level) {
    switch (level) {
      case TopicNotificationLevel.muted:
        return Icons.notifications_off_outlined;
      case TopicNotificationLevel.regular:
        return Icons.notifications_none_outlined;
      case TopicNotificationLevel.tracking:
        return Icons.notifications_outlined;
      case TopicNotificationLevel.watching:
        return Icons.notifications_active;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (style == TopicNotificationButtonStyle.chip) {
      return _buildChip(context);
    }
    return _buildIconButton(context);
  }

  Widget _buildChip(BuildContext context) {
    final theme = Theme.of(context);
    final isWatching = level == TopicNotificationLevel.watching || 
                       level == TopicNotificationLevel.tracking;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null ? () => _showSheet(context) : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isWatching 
                ? theme.colorScheme.primaryContainer 
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isWatching 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                getIcon(level),
                size: 16,
                color: isWatching 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                level.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isWatching 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context) {
    return IconButton(
      onPressed: onChanged != null ? () => _showSheet(context) : null,
      icon: Icon(getIcon(level)),
      tooltip: level.label,
    );
  }

  void _showSheet(BuildContext context) {
    if (onChanged == null) return;
    showNotificationLevelSheet(context, level, onChanged!);
  }
}

class _NotificationLevelSheet extends StatelessWidget {
  final TopicNotificationLevel currentLevel;
  final ValueChanged<TopicNotificationLevel> onSelected;

  const _NotificationLevelSheet({
    required this.currentLevel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '订阅设置',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...TopicNotificationLevel.values.map((level) {
            final isSelected = level == currentLevel;
            return ListTile(
              leading: Icon(
                TopicNotificationButton.getIcon(level),
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              title: Text(
                level.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
              subtitle: Text(
                level.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => onSelected(level),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
