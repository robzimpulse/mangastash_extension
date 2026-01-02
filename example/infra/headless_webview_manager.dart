import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:log_box/log_box.dart';
import 'package:log_box_in_app_webview_logger/log_box_in_app_webview_logger.dart';

import 'extension.dart';

class HeadlessWebviewManager {
  final LogBox _log;

  final Map<(String, List<String>), Future<Document>> _cDocument = {};
  final Map<(String, Map<String, String>?), Future<String>> _cImage = {};
  final Map<int, HeadlessInAppWebView> _instances = {};

  final _imgExt = ['jpeg', 'jpg', 'gif', 'webp', 'png', 'ico', 'bmp', 'wbmp'];
  final userAgent =
      'Mozilla/5.0 '
      '(Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/127.0.0.0 '
      'Safari/537.36';

  HeadlessWebviewManager({required LogBox log}) : _log = log;

  Future<void> dispose() async {
    await Future.wait([
      for (final instance in _instances.values) instance.dispose(),
    ]);
  }

  Future<Document> open(String url, {List<String> scripts = const []}) {
    return _cDocument.putIfAbsent(
      (url, scripts),
      () => _open(url, scripts: scripts).whenComplete(() {
        _cDocument.remove((url, scripts));
      }),
    );
  }

  Future<String> image(String url, {Map<String, String>? headers}) {
    return _cImage.putIfAbsent(
      (url, headers),
      () => _image(url, headers: headers).whenComplete(() {
        _cImage.remove((url, headers));
      }),
    );
  }

  Future<Document> _open(String url, {List<String> scripts = const []}) async {
    return parse(
      await _fetch(
        uri: WebUri(url),
        scripts: scripts,
        delegate: _log.inAppWebviewObserver,
      ),
      sourceUrl: url,
    );
  }

  Future<String> _image(String url, {Map<String, String>? headers}) async {
    final Completer<String> completer = Completer();

    String stringHeaders = '';

    if (headers != null) {
      stringHeaders = ', {headers: ${headers.toString()}}';
    }

    await _fetch(
      uri: WebUri(url),
      delegate: _log.inAppWebviewObserver,
      scripts: [
        '''
        const toDataURL = url => fetch(url $stringHeaders)
          .then(response => response.blob())
          .then(blob => new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () => resolve(reader.result);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
          }));
        
        toDataURL('$url').then(
          e => window.flutter_inappwebview.callHandler('resolved', e),
          e => window.flutter_inappwebview.callHandler('reject', e),
        );
        ''',
      ],
      javascriptHandlers: {
        'resolved': (args) {
          if (args.isEmpty) return;
          final data = args.first;
          if (data is! String) {
            _log.log(
              'Failed to download image [$url]',
              extra: {'url': url, 'args': args},
              name: runtimeType.toString(),
            );
            return;
          }

          final values = data.split(RegExp(r'[:;,]+'));
          final ext = values[1].split('/').lastOrNull;

          if (_imgExt.contains(ext)) {
            _log.log(
              'Success download image [$url]',
              name: runtimeType.toString(),
              extra: {'url': url, 'data': data},
            );
            completer.safeComplete(data);
          } else {
            _log.log(
              'Failed download image [$url]',
              name: runtimeType.toString(),
              error: Exception('Image format $ext not supported'),
              extra: {'url': url, 'args': args},
            );
            completer.safeCompleteError(
              Exception('Image format $ext not supported'),
            );
          }
        },
        'reject': (args) {
          _log.log(
            'Failed to download image [$url]',
            name: runtimeType.toString(),
            extra: {'url': url, 'error': args.toString()},
          );
          completer.safeCompleteError(Exception('Error fetch image'));
        },
      },
      signalComplete: completer.future,
    );

    return completer.future;
  }

  Future<String> _fetch({
    required WebUri uri,
    required InAppWebviewObserver delegate,
    UnmodifiableListView<UserScript>? initialUserScripts,
    Map<String, JavaScriptHandlerCallback>? javascriptHandlers,
    List<String> scripts = const [],
    Future? signalComplete,
  }) async {
    delegate.set(uri: uri, loading: true);

    final onLoadStartCompleter = Completer();
    final onLoadStopCompleter = Completer();
    final onLoadErrorCompleter = Completer();

    final webview = HeadlessInAppWebView(
      initialUserScripts: initialUserScripts,
      initialUrlRequest: URLRequest(
        url: uri,
        headers: {HttpHeaders.userAgentHeader: userAgent},
      ),
      initialSettings: InAppWebViewSettings(
        isInspectable: true,
        javaScriptEnabled: true,
        supportZoom: false,
      ),
      onWebViewCreated: (controller) {
        delegate.onWebViewCreated(uri: uri, scripts: scripts);
        final handlers = javascriptHandlers?.entries ?? [];
        if (handlers.isEmpty) return;
        for (final handler in handlers) {
          controller.addJavaScriptHandler(
            handlerName: handler.key,
            callback: handler.value,
          );
        }
      },
      onTitleChanged: (_, name) {
        delegate.onTitleChanged(title: name);
      },
      onLoadStart: (_, uri) {
        delegate.onLoadStart(uri: uri?.uriValue);
        onLoadStartCompleter.safeComplete();
      },
      onLoadStop: (_, uri) {
        delegate.onLoadStop(uri: uri?.uriValue);
        onLoadStopCompleter.safeComplete();
      },
      onProgressChanged: (controller, progress) {
        delegate.onProgressChanged(progress: progress);
      },
      onReceivedError: (_, request, error) {
        delegate.onReceivedError(
          request: request.toMap(),
          error: error.toMap(),
        );
        onLoadErrorCompleter.safeComplete();
      },
      onContentSizeChanged: (_, prev, curr) {
        delegate.onContentSizeChanged(previous: prev, current: curr);
      },
      onReceivedHttpError: (_, request, response) {
        delegate.onReceivedHttpError(
          request: request.toMap(),
          response: response.toMap(),
        );
      },
      onLoadResource: (_, resource) {
        delegate.onLoadResource(resource: resource.toMap());
      },
      onConsoleMessage: (controller, message) {
        delegate.onConsoleMessage(message: message.toMap());
      },
      shouldOverrideUrlLoading: (_, action) async {
        final destination = action.request.url;
        final isCloudFlare = action.isCloudFlare(uri);
        delegate.shouldOverrideUrlLoading(
          action: action.toMap(),
          extra: {'is_cloudflare': isCloudFlare},
        );

        if (destination == null) {
          return NavigationActionPolicy.CANCEL;
        }

        final isSame = [
          destination.scheme == uri.scheme,
          destination.host == uri.host,
        ].every((e) => e);

        if (isCloudFlare) {
          return NavigationActionPolicy.ALLOW;
        }

        return isSame
            ? NavigationActionPolicy.ALLOW
            : NavigationActionPolicy.CANCEL;
      },
    );

    _instances[webview.hashCode] = webview;

    await Future.wait([
      webview.run(),
      onLoadStartCompleter.future,
      Future.any([onLoadStopCompleter.future, onLoadErrorCompleter.future]),
    ]).timeout(const Duration(seconds: 15));

    for (final script in scripts) {
      if (script.isEmpty) continue;
      await Future.delayed(const Duration(seconds: 1));
      await webview.webViewController?.evaluateJavascript(source: script);
      delegate.onRunJavascript(script: script);
    }

    if (signalComplete != null) {
      await signalComplete.timeout(const Duration(seconds: 15));
    }

    final html = await webview.webViewController?.getHtml();

    final title = await webview.webViewController?.getTitle();

    await webview.dispose();

    _instances.remove(webview.hashCode);

    if (html == null) {
      delegate.set(error: Exception('Null Html on url: $uri'), loading: false);
      throw Exception('Null Html on url: $uri');
    }

    if (title == 'Just a moment...') {
      delegate.set(error: Exception('Cloudflare Challenge'), loading: false);
      throw Exception('Cloudflare Challenge');
    }

    delegate.set(html: html, loading: false);
    return html;
  }
}
