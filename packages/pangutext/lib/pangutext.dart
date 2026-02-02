class _PlaceholderReplacer {
  _PlaceholderReplacer(this._placeholder, this._startDelimiter, this._endDelimiter) {
    _pattern = RegExp(
      '${RegExp.escape(_startDelimiter)}$_placeholder(\\d+)${RegExp.escape(_endDelimiter)}',
    );
  }

  final String _placeholder;
  final String _startDelimiter;
  final String _endDelimiter;
  late final RegExp _pattern;
  final List<String> _items = <String>[];
  int _index = 0;

  String store(String item) {
    if (_items.length <= _index) {
      _items.add(item);
    } else {
      _items[_index] = item;
    }
    return '$_startDelimiter$_placeholder${_index++}$_endDelimiter';
  }

  String restore(String text) {
    return text.replaceAllMapped(_pattern, (match) {
      final index = int.tryParse(match.group(1) ?? '') ?? -1;
      if (index >= 0 && index < _items.length) {
        return _items[index];
      }
      return '';
    });
  }

  void reset() {
    _items.clear();
    _index = 0;
  }
}

/// Pangu - 极简中英文混排优化
///
/// 只处理最核心的中英文混排需求：
/// 1. 中文 + 英文字母 → 加空格
/// 2. 中文 + 数字 → 加空格
///
/// 不会破坏 Markdown 格式、表情、HTML 实体等。
class Pangu {
  Pangu();

  final String version = '8.0.0';

  // CJK 字符范围
  static const String _cjk =
      '\u2e80-\u2eff\u2f00-\u2fdf\u3040-\u309f\u30a0-\u30fa\u30fc-\u30ff\u3100-\u312f\u3200-\u32ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff';

  // 检测是否包含 CJK 字符
  static final RegExp _anyCjk = RegExp('[${_cjk}]');

  // 核心规则：只处理 CJK 和英文/数字的边界
  static final RegExp _cjkAn = RegExp('([${_cjk}])([A-Za-z0-9])');
  static final RegExp _anCjk = RegExp('([A-Za-z0-9])([${_cjk}])');

  String spacingText(String text) {
    if (text.length <= 1 || !_anyCjk.hasMatch(text)) {
      return text;
    }

    var newText = text;

    // 保护反引号代码块
    final backtickManager = _PlaceholderReplacer('BACKTICK_', '\uE004', '\uE005');
    newText = newText.replaceAllMapped(RegExp('`[^`]+`'), (match) {
      return backtickManager.store(match.group(0) ?? '');
    });

    // 保护 HTML 标签
    final htmlTagManager = _PlaceholderReplacer('HTML_TAG_', '\uE000', '\uE001');
    if (newText.contains('<')) {
      newText = newText.replaceAllMapped(
        RegExp('</?[a-zA-Z][a-zA-Z0-9]*(?:\\s+[^>]*)?>'),
        (match) => htmlTagManager.store(match.group(0) ?? ''),
      );
    }

    // 核心规则：CJK 和英文/数字之间加空格
    newText = newText.replaceAllMapped(_cjkAn, (m) => '${m.group(1)} ${m.group(2)}');
    newText = newText.replaceAllMapped(_anCjk, (m) => '${m.group(1)} ${m.group(2)}');

    // 恢复保护内容
    newText = htmlTagManager.restore(newText);
    newText = backtickManager.restore(newText);

    return newText;
  }

  bool hasProperSpacing(String text) {
    return spacingText(text) == text;
  }
}

final Pangu pangu = Pangu();

final RegExp anyCjk = Pangu._anyCjk;
