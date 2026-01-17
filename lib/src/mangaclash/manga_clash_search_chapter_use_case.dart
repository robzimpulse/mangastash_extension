import 'package:entity_manga_external/entity_manga_external.dart';

class MangaClashSearchChapterUseCase implements SearchChapterExternalUseCase {
  @override
  Future<List<ChapterScrapped>> parse({required HtmlDocument root}) async {
    final List<ChapterScrapped> data = [];

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
        ChapterScrapped(
          title: title?.trim(),
          chapter: chapter != null ? '$chapter' : null,
          readableAt: releaseDate,
          webUrl: url,
        ),
      );
    }
    return data;
  }

  @override
  List<String> get scripts => [];
}
