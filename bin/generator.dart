import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:entity_manga_external/entity_manga_external.dart';

void main() async {
  final compiler = Compiler()..addPlugin(EntityMangaExternalPlugin());

  final imports = '''
  import 'package:entity_manga_external/src/chapter_scrapped.dart';
  import 'package:entity_manga_external/src/html_document.dart';
  import 'package:entity_manga_external/src/manga_scrapped.dart';
  ''';

  final package = MapEntry('asurascan', {
    'base_url.dart': '''
      $imports
          
      String main() { return 'https://asuracomic.net'; }
    ''',
    'icon_url.dart': '''
      $imports
      
      String main() { return 'https://asuracomic.net/images/logo.webp'; }
    ''',
    'name.dart': '''
      $imports
      
      String main() { return 'Asura Scans'; }
    ''',
    'identifier.dart': '''
      $imports
      
      String main() { return 'asurascan'; }
    ''',
    'version.dart': '''
      $imports
      
      String main() { return '0.1.0'; }
    ''',
    'parse_chapter_image_script.dart': '''
      $imports
    
      List<String> main() {
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

        final script = [
          'window',
          'document',
          r'querySelectorAll("' + selector + r'")[0]',
          'click()',
        ].join('.');
    
        return [script];
      }
    ''',
    'parse_chapter_image.dart': '''
      $imports
      
      Future<List<String>> main(HtmlDocument root) {
        final region = root.querySelector(
          'div.py-8.-mx-5.flex.flex-col.items-center.justify-center',
        );
        final containers = region?.querySelectorAll('img') ?? [];
        final data = SplayTreeMap<num, String>();
        for (final image in containers) {
          final id = image.attributes['alt']?.split(' ').lastOrNull;
          if (id == null) continue;
          final url = image.attributes['src'];
          final index = int.tryParse(id);
          if (index == null || url == null) continue;
          data[index] = url.trim();
        }
        return Future.value(data.keys.map((e) => data[e]).nonNulls.toList());
      }
    '''
  });

  for (final script in package.value.entries) {
    compiler.entrypoints.add('package:${package.key}/${script.key}');
  }

  final program = compiler.compile(Map.fromEntries([package]));

  final file = await File('${package.key}.evc').writeAsBytes(program.write());

  final bytecode = file.readAsBytes().then((e) => e.buffer.asByteData());

  final runtime = Runtime(await bytecode);

  for (final script in package.value.entries) {
    final result = runtime.executeLib(
      'package:${package.key}/${script.key}',
      'main',
    );

    print('Type: ${result.runtimeType}');
    if (result is $String) {
      print('Result: ${result.$value}');
    }
    if (result is List) {
      for (final e in result) {
        if (e is $String) {
          print('Result: ${e.$value}');
        }
      }
    }

  }
}
