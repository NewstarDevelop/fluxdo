import 'package:flutter/material.dart';
import '../models/topic.dart';

/// 头像光晕匹配规则
class AvatarGlowRule {
  /// 按群组匹配
  final String? primaryGroupName;

  /// 按用户名匹配
  final String? username;

  /// 光晕颜色
  final Color glowColor;

  const AvatarGlowRule({
    this.primaryGroupName,
    this.username,
    required this.glowColor,
  });
}

/// 用户头衔特殊样式规则
class UserTitleStyleRule {
  /// 匹配的头衔文本
  final String title;

  /// 自定义 widget builder
  final Widget Function(String title, double fontSize) builder;

  const UserTitleStyleRule({
    required this.title,
    required this.builder,
  });
}

/// 站点自定义配置
class SiteCustomization {
  /// 头像光晕规则列表
  final List<AvatarGlowRule> avatarGlowRules;

  /// 用户头衔特殊渲染规则列表
  final List<UserTitleStyleRule> userTitleStyleRules;

  const SiteCustomization({
    this.avatarGlowRules = const [],
    this.userTitleStyleRules = const [],
  });

  /// 匹配头像光晕（返回光晕颜色，null 表示无光晕）
  Color? matchAvatarGlow(Post post) {
    for (final rule in avatarGlowRules) {
      if (rule.primaryGroupName != null &&
          post.primaryGroupName == rule.primaryGroupName) {
        return rule.glowColor;
      }
      if (rule.username != null && post.username == rule.username) {
        return rule.glowColor;
      }
    }
    return null;
  }

  /// 匹配用户头衔特殊样式（返回 widget builder，null 表示使用默认样式）
  Widget Function(String title, double fontSize)? matchTitleStyle(Post post) {
    if (post.userTitle == null) return null;
    for (final rule in userTitleStyleRules) {
      if (post.userTitle == rule.title) {
        return rule.builder;
      }
    }
    return null;
  }
}
