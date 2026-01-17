import 'package:entity_manga_external/entity_manga_external.dart';

import 'manga_clash_get_chapter_image_use_case.dart';
import 'manga_clash_get_manga_use_case.dart';
import 'manga_clash_search_chapter_use_case.dart';
import 'manga_clash_search_manga_use_case.dart';

class MangaClashSource implements SourceExternal {
  @override
  String get baseUrl => 'https://toonclash.com';

  @override
  String get iconUrl {
    return 'https://toonclash.com/wp-content/uploads/2020/03/cropped-22.jpg';
  }

  @override
  String get name => 'Manga Clash';

  @override
  GetChapterImageUseCase get getChapterImageUseCase {
    return MangaClashGetChapterImageUseCase();
  }

  @override
  GetMangaUseCase get getMangaUseCase {
    return MangaClashGetMangaUseCase();
  }

  @override
  SearchChapterExternalUseCase get searchChapterUseCase {
    return MangaClashSearchChapterUseCase();
  }

  @override
  SearchMangaExternalUseCase get searchMangaUseCase {
    return MangaClashSearchMangaUseCase();
  }
}
