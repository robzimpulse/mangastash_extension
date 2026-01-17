import 'package:entity_manga_external/entity_manga_external.dart';
import 'package:html/dom.dart';
import 'package:manga_dex_api/manga_dex_api.dart';

class AsuraScanSearchMangaUseCase implements SearchMangaExternalUseCase {
  @override
  Future<bool?> haveNextPage({required HtmlDocument root}) async {
    final queries = [
      'a',
      'flex',
      'items-center',
      'bg-themecolor',
      'text-white',
      'px-8',
      'text-center',
      'cursor-pointer',
    ].join('.');

    final region = root.querySelector(queries);

    return region?.attributes['style'] == 'pointer-events:auto';
  }

  @override
  Future<List<MangaScrapped>> parse({required HtmlDocument root}) async {
    final queries = ['div', 'grid', 'grid-cols-2', 'gap-3', 'p-4'].join('.');
    final region = root.querySelector(queries)?.querySelectorAll('a') ?? [];
    return [
      ...region.map((e) {
        final status = e.querySelector('span.status.bg-blue-700')?.text.trim();
        return MangaScrapped(
          title: e.querySelector('span.block.font-bold')?.text.trim(),
          coverUrl: e.querySelector('img.rounded-md')?.attributes['src'],
          webUrl: ['https://asuracomic.net', e.attributes['href']].join('/'),
          status: status?.toLowerCase(),
        );
      }),
    ];
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

  @override
  String url({required SearchMangaParameter parameter}) {
    return [
      ['https://asuracomic.net', 'series'].join('/'),
      [
        MapEntry('name', parameter.title ?? ''),
        MapEntry('page', parameter.page),
        if (parameter.orders?.containsKey(SearchOrders.rating) == true)
          const MapEntry('order', 'rating'),
        if (parameter.orders?.containsKey(SearchOrders.updatedAt) == true)
          const MapEntry('order', 'update'),
        if (parameter.includedTags?.isNotEmpty == true)
          MapEntry('genres', [...?parameter.includedTags].join(',')),
      ].map((e) => '${e.key}=${e.value}').join('&'),
    ].join('?');
  }
}
