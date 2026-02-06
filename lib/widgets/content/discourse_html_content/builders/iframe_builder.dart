import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../constants.dart';
import '../../../../utils/layout_lock.dart';

/// 是否需要交互遮罩（macOS 上 WebView 会捕获滚动事件）
bool get _needsInteractionMask => !kIsWeb && Platform.isMacOS;

/// iframe 属性解析结果
class IframeAttributes {
  final String src;
  final double? width;
  final double? height;
  final Set<String>? sandbox;
  final Set<String> allow;
  final bool allowFullscreen;
  final String? referrerPolicy;
  final bool lazyLoad;
  final String? title;

  IframeAttributes({
    required this.src,
    this.width,
    this.height,
    this.sandbox,
    this.allow = const {},
    this.allowFullscreen = false,
    this.referrerPolicy,
    this.lazyLoad = false,
    this.title,
  });

  /// 从 HTML element 解析 iframe 属性
  factory IframeAttributes.fromElement(dynamic element) {
    final attrs = element.attributes;

    // src 属性
    final src = (attrs['src'] as String?) ??
        (attrs['data-src'] as String?) ??
        '';

    // 宽高属性
    final width = double.tryParse(attrs['width'] as String? ?? '');
    final height = double.tryParse(attrs['height'] as String? ?? '');

    // sandbox 属性
    final sandboxAttr = attrs['sandbox'] as String?;
    final sandbox = sandboxAttr?.split(RegExp(r'\s+')).toSet();

    // allow 属性 (Permissions Policy)
    final allowAttr = attrs['allow'] as String?;
    final allow = allowAttr
            ?.split(';')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet() ??
        {};

    // allowfullscreen 属性
    final allowFullscreen = attrs.containsKey('allowfullscreen') ||
        attrs['allowfullscreen'] == 'true' ||
        attrs['allowfullscreen'] == '' ||
        allow.any((p) => p.startsWith('fullscreen'));

    // referrerpolicy 属性
    final referrerPolicy = attrs['referrerpolicy'] as String?;

    // loading 属性
    final loadingAttr = attrs['loading'] as String?;
    final lazyLoad = loadingAttr == 'lazy';

    // title 属性
    final title = attrs['title'] as String?;

    return IframeAttributes(
      src: src,
      width: width,
      height: height,
      sandbox: sandbox,
      allow: allow,
      allowFullscreen: allowFullscreen,
      referrerPolicy: referrerPolicy,
      lazyLoad: lazyLoad,
      title: title,
    );
  }

  /// 是否允许脚本执行
  bool get allowScripts => sandbox == null || sandbox!.contains('allow-scripts');

  /// 是否允许自动播放
  bool get allowAutoplay => allow.any((p) => p.startsWith('autoplay'));

  /// 是否允许加密媒体
  bool get allowEncryptedMedia =>
      allow.any((p) => p.startsWith('encrypted-media'));

  /// 计算宽高比
  double get aspectRatio {
    if (width != null && width! > 0 && height != null && height! > 0) {
      return width! / height!;
    }
    return 16 / 9; // 默认 16:9
  }

  /// 获取完整 URL
  String get fullUrl {
    if (src.startsWith('/') && !src.startsWith('//')) {
      return '${AppConstants.baseUrl}$src';
    }
    return src;
  }
}

/// 构建 iframe Widget
Widget? buildIframe({
  required BuildContext context,
  required dynamic element,
}) {
  // Web 平台不处理，让 flutter_widget_from_html 处理
  if (kIsWeb) return null;

  final attrs = IframeAttributes.fromElement(element);

  if (attrs.src.isEmpty) {
    return const SizedBox.shrink();
  }

  return IframeWidget(attributes: attrs);
}

/// iframe Widget
class IframeWidget extends StatefulWidget {
  final IframeAttributes attributes;

  const IframeWidget({
    super.key,
    required this.attributes,
  });

  @override
  State<IframeWidget> createState() => _IframeWidgetState();
}

class _IframeWidgetState extends State<IframeWidget> {
  bool _isLoaded = false;
  bool _hasError = false;
  bool _didLockLayout = false;

  /// 桌面平台：是否进入交互模式
  bool _interacting = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _removeOverlay();
    _unlockLayoutIfNeeded();
    super.dispose();
  }

  void _enterInteractMode() {
    setState(() => _interacting = true);
    _showOverlay();
  }

  void _exitInteractMode() {
    _removeOverlay();
    setState(() => _interacting = false);
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _exitInteractMode,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      '退出交互',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final attrs = widget.attributes;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AspectRatio(
        aspectRatio: attrs.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // WebView - 始终渲染
              InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _buildHtml(attrs),
                  baseUrl: WebUri(AppConstants.baseUrl),
                ),
                initialSettings: _buildSettings(attrs),
                onEnterFullscreen: (controller) {
                  _lockLayout();
                },
                onExitFullscreen: (controller) {
                  _unlockLayoutIfNeeded();
                },
                onLoadStart: (controller, url) {
                  if (mounted) {
                    setState(() {
                      _isLoaded = false;
                      _hasError = false;
                    });
                  }
                },
                onLoadStop: (controller, url) {
                  if (mounted) {
                    setState(() => _isLoaded = true);
                  }
                },
                onReceivedError: (controller, request, error) {
                  // 只有主框架加载失败才显示错误
                  // 忽略子资源（JS、图片、视频海报等）的加载错误
                  if (mounted && request.isForMainFrame == true) {
                    setState(() => _hasError = true);
                  }
                },
              ),
              // 加载指示器
              if (!_isLoaded && !_hasError)
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              // 错误状态
              if (_hasError)
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '加载失败',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // 桌面平台：交互遮罩
              if (_needsInteractionMask && !_interacting && _isLoaded && !_hasError)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _enterInteractMode,
                    child: Container(
                      color: Colors.black38,
                      child: const Center(
                        child: Icon(
                          Icons.touch_app,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建包装 iframe 的 HTML（解决 YouTube 等平台的 origin 问题）
  String _buildHtml(IframeAttributes attrs) {
    final src = attrs.fullUrl;

    // 构建 allow 属性，默认添加常用权限
    final allowAttrs = <String>{
      'fullscreen',
      'autoplay',
      'encrypted-media',
      'picture-in-picture',
      'web-share',
      ...attrs.allow,
    };

    final allowAttr = 'allow="${allowAttrs.join('; ')}"';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: transparent; }
    iframe {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      border: none;
      overflow: hidden;
    }
  </style>
</head>
<body>
  <iframe
    src="$src"
    $allowAttr
    allowfullscreen
    referrerpolicy="no-referrer-when-downgrade"
  ></iframe>
</body>
</html>
''';
  }

  InAppWebViewSettings _buildSettings(IframeAttributes attrs) {
    return InAppWebViewSettings(
      // User-Agent
      userAgent: AppConstants.userAgent,

      // JavaScript
      javaScriptEnabled: true,

      // 媒体播放
      mediaPlaybackRequiresUserGesture: !attrs.allowAutoplay,
      allowsInlineMediaPlayback: true,

      // 全屏
      iframeAllowFullscreen: true,

      // 外观
      transparentBackground: true,

      // 安全
      javaScriptCanOpenWindowsAutomatically: false,

      // 性能
      useHybridComposition: true,

      // 内容模式
      preferredContentMode: UserPreferredContentMode.RECOMMENDED,

      // 允许混合内容和第三方 cookies
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      thirdPartyCookiesEnabled: true,
    );
  }

  void _lockLayout() {
    if (_didLockLayout) return;
    _didLockLayout = true;
    LayoutLock.acquire();
  }

  void _unlockLayoutIfNeeded() {
    if (!_didLockLayout) return;
    _didLockLayout = false;
    LayoutLock.release();
  }
}
