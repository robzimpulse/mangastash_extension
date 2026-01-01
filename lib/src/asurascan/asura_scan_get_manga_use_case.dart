import 'package:entity_manga/entity_manga.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/dom.dart';

import '../base.dart';
import '../extension.dart';

class AsuraScanGetMangaUseCase extends GetDataUseCase<Manga> {
  @override
  Future<Manga> parse({required Document root, BaseCacheManager? cache}) async {
    final query = ['div', 'float-left', 'relative', 'z-0'].join('.');
    final region = root.querySelector(query);

    final title = region?.querySelector('span.text-xl.font-bold')?.text.trim();

    final description = region
        ?.querySelector('span.font-medium.text-sm')
        ?.text
        .trim();

    final mQuery = ['div.grid', 'grid-cols-1', 'gap-5', 'mt-8'].join('.');
    final metas = region?.querySelector(mQuery)?.children.map((e) {
      final first = e.querySelector('h3.font-medium.text-sm');
      return MapEntry(
        first?.text.trim(),
        first?.nextElementSibling?.text.trim(),
      );
    });
    final metadata = Map.fromEntries(metas ?? <MapEntry<String?, String>>[]);
    final author = metadata['Author'];
    final genres = region
        ?.querySelector('div.space-y-1.pt-4')
        ?.querySelector('div.flex.flex-row.flex-wrap.gap-3')
        ?.children
        .map((e) => e.text.trim());

    final coverUrl = region
        ?.querySelector('div.relative.col-span-full.space-y-3.px-6')
        ?.querySelector('img')
        ?.attributes['src'];

    return Manga(
      title: title,
      author: author,
      description: description,
      coverUrl: coverUrl,
      tags: [
        ...?genres?.map(
          (e) => Tag(
            name: e.toLowerCase(),
            // TODO: remove source enum
            source: SourceEnum.mangaclash.label,
          ),
        ),
      ],
    );
  }

  @override
  List<String> get scripts {
    final selector = [
      'button',
      'inline-flex',
      'items-center',
      'whitespace-nowrap',
      'px-4',
      'py-2',
      'w-full',
      'justify-center',
      'font-normal',
      'align-middle',
      'border-solid',
    ].join('.');

    return ['window.document.querySelectorAll(\'$selector\')[0].click()'];
  }
}
