import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

/// 搜索排序方式
enum SearchSortOrder {
  relevance('相关性', null),
  latest('最新帖子', 'latest'),
  likes('最受欢迎', 'likes'),
  views('最多浏览', 'views'),
  latestTopic('最新话题', 'latest_topic');

  final String label;
  final String? value;
  const SearchSortOrder(this.label, this.value);
}

/// 搜索设置数据类
class SearchSettings {
  final SearchSortOrder sortOrder;
  // 未来可扩展：
  // final bool showUsers;
  // final int resultsPerPage;
  // ...

  const SearchSettings({required this.sortOrder});

  SearchSettings copyWith({SearchSortOrder? sortOrder}) =>
      SearchSettings(sortOrder: sortOrder ?? this.sortOrder);
}

/// 搜索设置 StateNotifier，管理状态和持久化
class SearchSettingsNotifier extends Notifier<SearchSettings> {
  static const String _sortOrderKey = 'search_sort_order';

  late final SharedPreferences _prefs;

  @override
  SearchSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadFromPrefs(_prefs);
  }

  static SearchSettings _loadFromPrefs(SharedPreferences prefs) {
    final sortOrderValue = prefs.getString(_sortOrderKey);
    final sortOrder = SearchSortOrder.values.firstWhere(
      (e) => e.value == sortOrderValue,
      orElse: () => SearchSortOrder.relevance,
    );
    return SearchSettings(sortOrder: sortOrder);
  }

  Future<void> setSortOrder(SearchSortOrder order) async {
    state = state.copyWith(sortOrder: order);
    if (order.value == null) {
      await _prefs.remove(_sortOrderKey);
    } else {
      await _prefs.setString(_sortOrderKey, order.value!);
    }
  }
}

/// 搜索设置 Provider
final searchSettingsProvider = NotifierProvider<SearchSettingsNotifier, SearchSettings>(
  SearchSettingsNotifier.new,
);
