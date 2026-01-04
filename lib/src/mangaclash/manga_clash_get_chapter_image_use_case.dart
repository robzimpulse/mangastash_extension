import 'package:collection/collection.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/dom.dart';

import '../base.dart';

class MangaClashGetChapterImageUseCase implements GetChapterImageUseCase {
  @override
  Future<List<String>> parse({
    required Document root,
    BaseCacheManager? cache,
  }) async {
    final region = root.querySelector('.reading-content');
    final containers = region?.querySelectorAll('img') ?? [];
    final List<(num, String)> data = [];
    for (final image in containers) {
      final id = image.attributes['id']?.split('-').lastOrNull;
      if (id == null) continue;
      final url = image.attributes['data-src'];
      final index = int.tryParse(id);
      if (index == null || url == null) continue;
      data.add((index, url.trim()));
    }
    return data.sortedBy((e) => e.$1).map((e) => e.$2).toList();
  }

  @override
  List<String> get scripts => [];
}
