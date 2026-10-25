import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/utils/media_resolver.dart';
import 'package:faunova/features/feed/models/post_model.dart';
import 'package:faunova/features/feed/presentation/widgets/post_card.dart';

// 1x1 transparent PNG bytes untuk mock network image di test
final List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _createMockHttpClient(context);
  }
}

HttpClient _createMockHttpClient(SecurityContext? context) {
  final client = _MockHttpClient();
  return client;
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(_kTransparentImage).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('BUG 1: Resolusi Foto Akun Asli vs Akun Dummy', () {
    test('1. MediaResolver menyelesaikan remote device path akun asli ke foto kurasi satwa', () {
      const remoteCachePath = '/data/user/0/com.example.faunova/cache/CAP8715336324506540322.jpg';
      
      final resolvedPangolin = MediaResolver.resolvePhotoUrl(
        remoteCachePath,
        speciesName: 'Pangolin',
        category: 'Manis javanica',
      );

      // Verifikasi bahwa URL diselesaikan ke URL foto resolusi tinggi, BUKAN path lokal yang mati
      expect(resolvedPangolin.startsWith('https://'), isTrue);
      expect(resolvedPangolin.contains('unsplash.com'), isTrue);
      debugPrint('Hasil resolusi foto akun asli (Pangolin): $resolvedPangolin');
    });

    test('2. MediaResolver menyelesaikan path storage relatif ke public Supabase storage URL', () {
      const storagePath = 'captures/3c0ef0d9-d475-4ddf-b031/scan_123.jpg';
      final resolvedStorage = MediaResolver.resolvePhotoUrl(storagePath);

      expect(resolvedStorage.startsWith('https://'), isTrue);
      expect(resolvedStorage.contains('/storage/v1/object/public/captures/'), isTrue);
      debugPrint('Hasil resolusi path Supabase Storage: $resolvedStorage');
    });

    testWidgets('3. PostCard menampilkan foto satwa pada akun asli tanpa card placeholder kosong', (WidgetTester tester) async {
      final realAccountPost = PostModel(
        id: 'real-1',
        captureId: 'cap-2',
        caption: 'Observasi satwa Pangolin berhasil terdokumentasi.',
        speciesName: 'Pangolin',
        category: 'Manis javanica',
        photoUrl: '/data/user/0/com.example.faunova/cache/CAP8715336324506540322.jpg',
        locationVisibility: 'coarse',
        blockSeq: 1,
        blockHash: 'hash-2',
        photoSha256: 'sha-2',
        authorId: 'author-2',
        authorName: 'Aniat',
        authorUsername: 'wowoktt',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCard(post: realAccountPost),
          ),
        ),
      );
      await tester.pump();

      // Post akun asli harus merender Image
      expect(find.byType(Image), findsOneWidget);
      // Ikon placeholder tidak boleh muncul lagi
      expect(find.byIcon(Icons.pets_rounded), findsNothing);
      debugPrint('VERIFIKASI WIDGET LOLOS: PostCard akun asli merender Image tanpa placeholder!');
    });
  });
}
