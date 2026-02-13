import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user.dart';
import '../../models/badge.dart' as badge_model;
import '../../widgets/common/smart_avatar.dart';
import '../../widgets/badge/badge_ui_utils.dart';
import '../../pages/topic_detail_page/topic_detail_page.dart';
import '../../pages/badge_page.dart';

/// 用户个人页 - 总结 Tab
class UserProfileSummaryTab extends StatelessWidget {
  final UserSummary summary;
  final void Function(String username) onUserTap;

  const UserProfileSummaryTab({
    super.key,
    required this.summary,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 热门话题
        if (summary.topics.isNotEmpty) ...[
          _buildSectionHeader(theme, Icons.article_rounded, '热门话题'),
          const SizedBox(height: 8),
          ...summary.topics.map((topic) => _buildSummaryTopicItem(context, theme, topic)),
          const SizedBox(height: 20),
        ],

        // 热门回复
        if (summary.replies.isNotEmpty) ...[
          _buildSectionHeader(theme, Icons.chat_bubble_rounded, '热门回复'),
          const SizedBox(height: 8),
          ...summary.replies.map((reply) => _buildSummaryReplyItem(context, theme, reply)),
          const SizedBox(height: 20),
        ],

        // 热门链接
        if (summary.links.isNotEmpty) ...[
          _buildSectionHeader(theme, Icons.link_rounded, '热门链接'),
          const SizedBox(height: 8),
          ...summary.links.map((link) => _buildSummaryLinkItem(context, theme, link)),
          const SizedBox(height: 20),
        ],

        // 最多回复至
        if (summary.mostRepliedToUsers.isNotEmpty) ...[
          _buildSectionHeader(theme, Icons.reply_rounded, '最多回复至'),
          const SizedBox(height: 8),
          _buildUserChips(context, theme, summary.mostRepliedToUsers),
          const SizedBox(height: 20),
        ],

        // 被谁赞的最多
        if (summary.mostLikedByUsers.isNotEmpty) ...[
          _buildSectionHeader(theme, Icons.favorite_rounded, '被谁赞的最多'),
          const SizedBox(height: 8),
          _buildUserChips(context, theme, summary.mostLikedByUsers),
          const SizedBox(height: 20),
        ],

        // 赞最多
        if (summary.mostLikedUsers.isNotEmpty) ...[
          _buildSectionHeader(theme, Icons.thumb_up_rounded, '赞最多'),
          const SizedBox(height: 8),
          _buildUserChips(context, theme, summary.mostLikedUsers),
          const SizedBox(height: 20),
        ],

        // 热门类别
        if (summary.topCategories.isNotEmpty) ...[
          _buildSectionHeader(theme, Icons.category_rounded, '热门类别'),
          const SizedBox(height: 8),
          ...summary.topCategories.map((cat) => _buildSummaryCategoryItem(theme, cat)),
          const SizedBox(height: 20),
        ],

        // 热门徽章
        if (summary.badges.isNotEmpty) ...[
          _buildSectionHeader(theme, Icons.military_tech_rounded, '热门徽章'),
          const SizedBox(height: 8),
          _buildBadgeChips(context, theme, summary.badges),
          const SizedBox(height: 20),
        ],

        // 若所有列表都为空
        if (summary.topics.isEmpty &&
            summary.replies.isEmpty &&
            summary.links.isEmpty &&
            summary.mostRepliedToUsers.isEmpty &&
            summary.mostLikedByUsers.isEmpty &&
            summary.mostLikedUsers.isEmpty &&
            summary.topCategories.isEmpty &&
            summary.badges.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  Icon(Icons.summarize_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('暂无总结数据', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTopicItem(BuildContext context, ThemeData theme, SummaryTopic topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TopicDetailPage(topicId: topic.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  topic.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (topic.likeCount > 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.favorite_rounded, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 2),
                Text(
                  '${topic.likeCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryReplyItem(BuildContext context, ThemeData theme, SummaryReply reply) {
    final topic = reply.topic;
    final targetTopicId = topic?.id ?? reply.topicId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: targetTopicId != null
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicDetailPage(
                      topicId: targetTopicId,
                      scrollToPostNumber: reply.postNumber,
                    ),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  topic?.title ?? '话题 #$targetTopicId',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (reply.likeCount > 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.favorite_rounded, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 2),
                Text(
                  '${reply.likeCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryLinkItem(BuildContext context, ThemeData theme, SummaryLink link) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (link.topic != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TopicDetailPage(
                  topicId: link.topic!.id,
                  scrollToPostNumber: link.postNumber,
                ),
              ),
            );
          } else {
            launchUrl(Uri.parse(link.url));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title ?? link.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (link.topic != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        link.topic!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (link.clicks > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${link.clicks} 次点击',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserChips(BuildContext context, ThemeData theme, List<SummaryUserWithCount> users) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: users.map((user) => InkWell(
        onTap: () => onUserTap(user.username),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SmartAvatar(
                imageUrl: user.getAvatarUrl(size: 48),
                radius: 12,
                fallbackText: user.username,
              ),
              const SizedBox(width: 6),
              Text(
                user.name?.isNotEmpty == true ? user.name! : user.username,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${user.count}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildSummaryCategoryItem(ThemeData theme, SummaryCategory cat) {
    final color = cat.color != null
        ? Color(int.parse('FF${cat.color}', radix: 16))
        : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cat.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${cat.topicCount} 话题',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${cat.postCount} 回复',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChips(BuildContext context, ThemeData theme, List<badge_model.Badge> badges) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges.map((badge) {
        final badgeType = badge.badgeType;
        final color = BadgeUIUtils.getBadgeColor(context, badgeType);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BadgePage(badgeId: badge.id),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: BadgeUIUtils.getBadgeGradient(context, badgeType),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  BadgeUIUtils.getBadgeIcon(badgeType),
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  badge.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
