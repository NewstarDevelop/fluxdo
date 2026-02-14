import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_riverpod/legacy.dart' show StateNotifierProvider, StateNotifier;
import 'topic_list_provider.dart';

/// 当前排序模式（不持久化，每次启动默认 latest）
class TopicSortNotifier extends Notifier<TopicListFilter> {
  @override
  TopicListFilter build() => TopicListFilter.latest;

  void set(TopicListFilter value) => state = value;
}

final topicSortProvider = NotifierProvider<TopicSortNotifier, TopicListFilter>(
  TopicSortNotifier.new,
);

/// 每个 tab 独立的标签筛选（categoryId -> tags）
/// null 表示"全部"tab
class TabTagsNotifier extends StateNotifier<List<String>> {
  TabTagsNotifier() : super([]);

  void set(List<String> value) => state = value;
}

final tabTagsProvider = StateNotifierProvider.family<TabTagsNotifier, List<String>, int?>(
  (ref, categoryId) => TabTagsNotifier(),
);

/// 当前选中 tab 对应的分类 ID（null 表示"全部"tab）
class CurrentTabCategoryIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) => state = value;
}

final currentTabCategoryIdProvider = NotifierProvider<CurrentTabCategoryIdNotifier, int?>(
  CurrentTabCategoryIdNotifier.new,
);
