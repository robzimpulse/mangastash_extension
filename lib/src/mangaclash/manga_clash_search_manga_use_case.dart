import 'package:entity_manga/entity_manga.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/dom.dart';
import 'package:manga_dex_api/manga_dex_api.dart';

import '../base.dart';

class MangaClashSearchMangaUseCase implements SearchMangaExternalUseCase {
  @override
  Future<List<Manga>> parse({
    required Document root,
    BaseCacheManager? cache,
  }) async {
    final List<Manga> mangas = [];
    for (final element in root.querySelectorAll('.c-tabs-item__content')) {
      final title = element.querySelector('div.post-title')?.text.trim();
      final webUrl = element
          .querySelector('div.post-title')
          ?.querySelector('a')
          ?.attributes['href']
          ?.trim();
      final coverUrl = element
          .querySelector('.tab-thumb')
          ?.querySelector('img')
          ?.attributes['data-src']
          ?.trim();
      final genres = element
          .querySelector('div.post-content_item.mg_genres')
          ?.querySelector('div.summary-content')
          ?.text
          .split(',')
          .map((e) => e.trim());
      final status = element
          .querySelector('div.post-content_item.mg_status')
          ?.querySelector('div.summary-content')
          ?.text
          .trim();

      mangas.add(
        Manga(
          title: title,
          coverUrl: coverUrl,
          webUrl: webUrl,
          status: status?.toLowerCase(),
          tags: genres?.map((e) => Tag(name: e.toLowerCase())).toList(),
        ),
      );
    }
    return mangas;
  }

  @override
  Future<bool?> haveNextPage({
    required Document root,
    BaseCacheManager? cache,
  }) async {
    final values = root
        .querySelector('.wp-pagenavi')
        ?.querySelector('.pages')
        ?.text
        .split(' ')
        .map((e) => int.tryParse(e))
        .nonNulls;

    return values?.firstOrNull != values?.lastOrNull;
  }

  @override
  List<String> get scripts => [];

  @override
  String url({required SearchMangaParameter parameter}) {
    return [
      ['https://toonclash.com', 'page', '${parameter.page}'].join('/'),
      [
        const MapEntry('post_type', 'wp-manga'),
        MapEntry('s', parameter.title ?? ''),
        if (parameter.orders?.containsKey(SearchOrders.rating) == true)
          const MapEntry('m_orderby', 'rating'),
        if (parameter.orders?.containsKey(SearchOrders.updatedAt) == true)
          const MapEntry('m_orderby', 'latest'),
        for (final status in parameter.status ?? <MangaStatus>[])
          MapEntry('status[]', switch (status) {
            MangaStatus.ongoing => 'on-going',
            MangaStatus.completed => 'end',
            MangaStatus.hiatus => 'on-hold',
            MangaStatus.cancelled => 'canceled',
          }),
        for (final tag in parameter.includedTags ?? <String>[])
          MapEntry('genre[]', tag),
        if (parameter.includedTags?.isNotEmpty == true)
          switch (parameter.includedTagsMode) {
            TagsMode.or => const MapEntry('op', ''),
            TagsMode.and => const MapEntry('op', '1'),
          },
      ].nonNulls.map((e) => '${e.key}=${e.value}').join('&'),
    ].join('?');
  }
}
