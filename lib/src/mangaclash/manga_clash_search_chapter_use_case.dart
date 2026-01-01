import 'package:entity_manga/entity_manga.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/dom.dart';

import '../base.dart';
import '../extension.dart';

class MangaClashSearchChapterUseCase extends SearchChapterExternalUseCase {

  @override
  Future<List<Chapter>> parse({
    required Document root,
    BaseCacheManager? cache,
  }) async {
    final List<Chapter> data = [];

    for (final element in root.querySelectorAll('li.wp-manga-chapter')) {
      final url = element.querySelector('a')?.attributes['href'];
      final title = element.querySelector('a')?.text.split('-').lastOrNull;
      final text = element.querySelector('a')?.text.split(' ').map((text) {
        final value = double.tryParse(text);

        if (value != null) {
          final fraction = value - value.truncate();
          if (fraction > 0.0) return value;
        }

        return int.tryParse(text);
      });

      final releaseDate = element
          .querySelector('.chapter-release-date')
          ?.text
          .trim();
      final chapter = text?.nonNulls.firstOrNull;

      data.add(
        Chapter(
          title: title?.trim(),
          chapter: chapter != null ? '$chapter' : null,
          readableAt: await releaseDate?.asDateTime(manager: cache),
          webUrl: url,
        ),
      );
    }
    return data;
  }

  @override
  List<String> get scripts => [];
}
