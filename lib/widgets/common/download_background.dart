import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 下载进度背景动画组件
///
/// 重新设计 V10 (Color Harmony)：Elegant Aurora
/// 改进点：
/// 1. **和谐配色**：移除杂乱的撞色（如Amber/Pink），统一为“冷色调+极光绿”的和谐体系。
/// 2. **色彩减法**：全屏同时出现的主要色相控制在 3 种以内，通过明度变化体现层次。
/// 3. **中和观感**：降低饱和度，避免深色模式下的荧光刺眼感。
class DownloadBackground extends StatefulWidget {
  final Widget? child;

  const DownloadBackground({
    super.key,
    this.child,
  });

  @override
  State<DownloadBackground> createState() => _DownloadBackgroundState();
}

class _DownloadBackgroundState extends State<DownloadBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _time = 0.0;
  
  final List<_NebulaBlob> _blobs = [];
  final math.Random _random = math.Random();

  // 极光配色 (Dark) - 更加和谐、幽深
  // 核心三角：蓝(空灵)-青(透亮)-紫(深邃)
  static const _darkColors = [
    Color(0xFF1e3a8a), // Blue 900 (深邃基调)
    Color(0xFF0e7490), // Cyan 700 (清冷极光)
    Color(0xFF5b21b6), // Violet 800 (神秘氛围)
    Color(0xFF1d4ed8), // Blue 700 (过渡)
    // 移除 Emerald/Pink/Amber，保持冷色统一性
  ];

  // 晨雾配色 (Light) - 清新、通透
  static const _lightColors = [
    Color(0xFFbacfa2), // Sage (柔和绿灰)
    Color(0xFF93c5fd), // Blue 300
    Color(0xFFc4b5fd), // Violet 300
    Color(0xFF67e8f9), // Cyan 300
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _time = elapsed.inMicroseconds / 1000000.0;
        });
      }
    })..start();

    _initBlobs();
  }

  void _initBlobs() {
    _blobs.clear();
    // 3个背景氛围层 (与背景色融合度高)
    for (int i = 0; i < 3; i++) {
      _blobs.add(_NebulaBlob(
        colorIndex: i % _darkColors.length,
        xSpeed: 0.05 + _random.nextDouble() * 0.05, // 极慢
        ySpeed: 0.05 + _random.nextDouble() * 0.05,
        xPhase: _random.nextDouble() * 10,
        yPhase: _random.nextDouble() * 10,
        radiusScale: 1.5, // 极大，铺满
        opacityScale: 0.3, // 很淡
        isForeground: false,
      ));
    }
    
    // 3个前景活跃层 (数量减少1个，避免杂乱)
    for (int i = 0; i < 3; i++) {
      _blobs.add(_NebulaBlob(
        colorIndex: (i + 1) % _darkColors.length,
        xSpeed: 0.1 + _random.nextDouble() * 0.15,
        ySpeed: 0.1 + _random.nextDouble() * 0.15,
        xPhase: _random.nextDouble() * 10,
        yPhase: _random.nextDouble() * 10,
        radiusScale: 0.6 + _random.nextDouble() * 0.4,
        opacityScale: 0.5,
        isForeground: true,
      ));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: CustomPaint(
        painter: _NebulaPainter(
          time: _time,
          isDark: isDark,
          blobs: _blobs,
          colors: isDark ? _darkColors : _lightColors,
        ),
        child: widget.child,
      ),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final double time;
  final bool isDark;
  final List<_NebulaBlob> blobs;
  final List<Color> colors;

  _NebulaPainter({
    required this.time,
    required this.isDark,
    required this.blobs,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. 纯净底色
    final bgColor = isDark ? const Color(0xFF020617) : const Color(0xFFffffff);
    canvas.drawRect(rect, Paint()..color = bgColor);

    final blendMode = isDark ? BlendMode.screen : BlendMode.srcOver;

    for (var blob in blobs) {
      _drawBlob(canvas, size, blob, blendMode);
    }
  }

  void _drawBlob(Canvas canvas, Size size, _NebulaBlob blob, BlendMode blendMode) {
    // 运动轨迹：Lissajous
    final x = size.width * (0.5 + 0.35 * math.sin(time * blob.xSpeed + blob.xPhase));
    final y = size.height * (0.5 + 0.35 * math.cos(time * blob.ySpeed + blob.yPhase));

    // 动态呼吸 (幅度减小，更平稳)
    final breathe = 1.0 + 0.1 * math.sin(time * (blob.isForeground ? 0.8 : 0.4) + blob.colorIndex);
    final radius = size.shortestSide * blob.radiusScale * breathe;

    final color = colors[blob.colorIndex % colors.length];

    // 透明度调整
    final opacity = blob.opacityScale * (isDark ? 0.6 : 0.4); 

    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: opacity),
        color.withValues(alpha: 0),
      ],
      stops: const [0.0, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset(x, y), radius: radius))
      ..blendMode = blendMode;

    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter oldDelegate) {
    return time != oldDelegate.time || isDark != oldDelegate.isDark;
  }
}

class _NebulaBlob {
  final int colorIndex;
  final double xSpeed;
  final double ySpeed;
  final double xPhase;
  final double yPhase;
  final double radiusScale;
  final double opacityScale;
  final bool isForeground;

  _NebulaBlob({
    required this.colorIndex,
    required this.xSpeed,
    required this.ySpeed,
    required this.xPhase,
    required this.yPhase,
    required this.radiusScale,
    required this.opacityScale,
    required this.isForeground,
  });
}
