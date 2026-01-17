import 'package:entity_manga_external/entity_manga_external.dart';

import 'asura_scan_get_chapter_image_use_case.dart';
import 'asura_scan_get_manga_use_case.dart';
import 'asura_scan_search_chapter_use_case.dart';
import 'asura_scan_search_manga_use_case.dart';


class AsuraScanSource implements SourceExternal {
  @override
  String get baseUrl => 'https://asuracomic.net';

  @override
  String get iconUrl => 'https://asuracomic.net/images/logo.webp';

  @override
  String get name => 'Asura Scans';

  @override
  GetChapterImageUseCase get getChapterImageUseCase {
    return AsuraScanGetChapterImageUseCase();
  }

  @override
  GetMangaUseCase get getMangaUseCase {
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
