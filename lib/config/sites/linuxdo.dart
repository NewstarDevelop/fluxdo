import 'package:flutter/material.dart';
import '../site_customization.dart';
import '../../widgets/common/holographic_text.dart';

/// linux.do 站点自定义配置
final linuxdoCustomization = SiteCustomization(
  avatarGlowRules: [
    AvatarGlowRule(
      primaryGroupName: 'g-merchant',
      glowColor: Color(0xFFF5BF03),
    ),
    AvatarGlowRule(
      username: 'neo',
      glowColor: Color(0xFF00AEFF),
    ),
  ],
  userTitleStyleRules: [
    UserTitleStyleRule(
      title: '种子用户',
      builder: (title, fontSize) =>
          HolographicText(text: title, fontSize: fontSize),
    ),
  ],
);
