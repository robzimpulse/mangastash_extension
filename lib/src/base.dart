import 'package:entity_manga/entity_manga.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/dom.dart';
import 'package:manga_dex_api/manga_dex_api.dart';

abstract class Source {
  String get name;
  String get iconUrl;
  String get baseUrl;

  GetMangaUseCase get getMangaUseCase;
  GetChapterImageUseCase get getChapterImageUseCase;

  SearchMangaExternalUseCase get searchMangaUseCase;
  SearchChapterExternalUseCase get searchChapterUseCase;
}

abstract class GetMangaUseCase {
  List<String> get scripts;
  Future<Manga> parse({required Document root, BaseCacheManager? cache});
}

abstract class GetChapterImageUseCase {
  List<String> get scripts;
  Future<List<String>> parse({required Document root, BaseCacheManager? cache});
}

abstract class SearchMangaExternalUseCase {
  List<String> get scripts;
  String url({required SearchMangaParameter parameter});
  Future<List<Manga>> parse({required Document root, BaseCacheManager? cache});
  Future<bool?> haveNextPage({required Document root, BaseCacheManager? cache});
}

abstract class SearchChapterExternalUseCase {
  List<String> get scripts;
  Future<List<Chapter>> parse({
    required Document root,
    BaseCacheManager? cache,
  });
}
