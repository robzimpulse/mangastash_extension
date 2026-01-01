import 'package:entity_manga/entity_manga.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/dom.dart';

import '../base.dart';

class MangaClashGetMangaUseCase implements GetDataUseCase<Manga> {
  @override
  Future<Manga> parse({required Document root, BaseCacheManager? cache}) async {
    final description = root
        .querySelector('div.description-summary')
        ?.querySelectorAll('p')
        .map((e) => e.text.trim())
        .join('\n\n');

    final title = root.querySelector('div.post-title')?.text.trim();

    final authors = root.querySelector('div.author-content')?.text.trim();

    final coverUrl = root
        .querySelector('div.summary_image')
        ?.querySelector('img')
        ?.attributes['src'];

    final tags = root
        .querySelector('div.genres-content')
        ?.text
        .trim()
        .split(',');

    return Manga(
      title: title,
      author: authors,
      coverUrl: coverUrl,
      description: description,
      tags: [
        ...?tags?.map(
          (e) => Tag(
            name: e.trim(),
            // TODO: remove source enum
            source: SourceEnum.mangaclash.name,
          ),
        ),
      ],
    );
  }

  @override
  List<String> get scripts => [];
}
