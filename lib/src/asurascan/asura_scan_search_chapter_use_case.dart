import 'package:entity_manga_external/entity_manga_external.dart';

class AsuraScanSearchChapterUseCase implements SearchChapterExternalUseCase {
  @override
  Future<List<ChapterScrapped>> parse({required HtmlDocument root}) async {
    final region = root.querySelector(
      [
        'div',
        'pl-4',
        'pr-2',
        'pb-4',
        'overflow-y-auto',
        'scrollbar-thumb-themecolor',
        'scrollbar-track-transparent',
        'scrollbar-thin',
        'mr-3',
      ].join('.'),
    );

    final elements = region?.children.map((e) {
      final url = e.querySelector('a')?.attributes['href'];
      final container = e.querySelector(
        [
          'h3',
          'text-sm',
          'text-white',
          'font-medium',
          'flex',
          'flex-row',
        ].join('.'),
      );

      final spans = container?.querySelectorAll('span');
      final title = spans?.firstOrNull?.text.trim();
      final isNotPublished = spans?.lastOrNull?.hasChildNodes() == true;

      if (isNotPublished) return null;

      final chapterData = container?.nodes.firstOrNull?.text?.trim().split(' ');
      final chapter = chapterData?.map((text) {
        final value = double.tryParse(text);
        if (value != null) {
          final fraction = value - value.truncate();
          if (fraction > 0.0) return value;
        }
        return int.tryParse(text);
      }).lastOrNull;

      final releaseDate = e
          .querySelector('h3.text-xs')
          ?.text
          .trim()
          .replaceAll('st', '')
          .replaceAll('nd', '')
          .replaceAll('rd', '')
          .replaceAll('th', '');

      return ChapterScrapped(
        title: title?.isNotEmpty == true ? title : null,
        chapter: '${chapter ?? url?.split('/').lastOrNull}',
        readableAt: releaseDate,
        webUrl: ['https://asuracomic.net', 'series', url].join('/'),
      );
    });

    return [...?elements?.nonNulls];
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
