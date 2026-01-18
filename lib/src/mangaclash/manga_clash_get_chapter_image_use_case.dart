import 'package:entity_manga_external/entity_manga_external.dart';

class MangaClashGetChapterImageUseCase implements GetChapterImageUseCase {
  @override
  Future<List<String>> parse({required HtmlDocument root}) async {
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
    data.sort((a, b) => a.$1.compareTo(b.$1));
    return data.map((e) => e.$2).toList();
  }

  @override
  List<String> get scripts => [];
}
