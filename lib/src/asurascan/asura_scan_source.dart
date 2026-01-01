import 'package:entity_manga/entity_manga.dart';
import 'package:mangastash_extension/src/asurascan/asura_scan_get_chapter_image_use_case.dart';
import 'package:mangastash_extension/src/asurascan/asura_scan_get_manga_use_case.dart';
import 'package:mangastash_extension/src/asurascan/asura_scan_search_chapter_use_case.dart';
import 'package:mangastash_extension/src/asurascan/asura_scan_search_manga_use_case.dart';

import '../base.dart';

class AsuraScanSource implements Source {
  @override
  String get baseUrl => 'https://asuracomic.net';

  @override
  String get iconUrl => 'https://asuracomic.net/images/logo.webp';

  @override
  String get name => 'Asura Scans';

  @override
  GetDataUseCase<List<String>> get getChapterImageUseCase {
    return AsuraScanGetChapterImageUseCase();
  }

  @override
  GetDataUseCase<Manga> get getMangaUseCase {
    return AsuraScanGetMangaUseCase();
  }

  @override
  SearchChapterExternalUseCase get searchChapterUseCase {
    return AsuraScanSearchChapterUseCase();
  }

  @override
  SearchMangaExternalUseCase get searchMangaUseCase {
    return AsuraScanSearchMangaUseCase();
  }
}
