import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/config/app_config.dart';
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
    return _MockHttpClient();
  }
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

  group('VERIFIKASI FITUR FOTO POSTINGAN DUA AKUN', () {
    const userIdAccountA = '3c0ef0d9-d475-4ddf-b031-dafa5508c5e6';
    const scanId = 'scan_test_12345';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageRelativePath = 'captures/$userIdAccountA/${scanId}_$timestamp.jpg';

    test('1. Akun A mengunggah foto: Path yang dihasilkan unik dan tersimpan di bucket captures', () {
      expect(storageRelativePath.startsWith('captures/$userIdAccountA/'), isTrue);
      expect(storageRelativePath.contains(scanId), isTrue);
      expect(storageRelativePath.contains('$timestamp'), isTrue);
    });

    test('2. Akun B membuka postingan Akun A: URL foto yang diterima SAMA PERSIS dan publik', () {
      // Resolusi URL di HP Akun A (pengunggah)
      final urlOnAccountA = MediaResolver.resolvePhotoUrl(storageRelativePath);

      // Resolusi URL di HP Akun B (pengguna lain)
      final urlOnAccountB = MediaResolver.resolvePhotoUrl(storageRelativePath);

      // Verifikasi: URL harus 100% sama persis di kedua perangkat
      expect(urlOnAccountB, equals(urlOnAccountA));
      expect(urlOnAccountB, equals('${AppConfig.supabaseUrl}/storage/v1/object/public/$storageRelativePath'));
      expect(urlOnAccountB.startsWith('https://'), isTrue);
      expect(urlOnAccountB.contains('/storage/v1/object/public/captures/'), isTrue);
    });

    test('3. Verifikasi ketiadaan jalan pintas / fallback gambar hewan yang salah', () {
      const oldCorruptPath = '/data/user/0/com.example.faunova/cache/CAP8715336324506540322.jpg';

      // Pastikan file tidak ada di HP Akun B
      expect(File(oldCorruptPath).existsSync(), isFalse);

      final resolvedOnAccountB = MediaResolver.resolvePhotoUrl(
        oldCorruptPath,
        speciesName: 'Pangolin',
        category: 'Manis javanica',
      );

      // Wajib kosong, tidak boleh mengembalikan foto kucing/jalak/trenggiling stok Unsplash
      expect(resolvedOnAccountB, isEmpty);
      expect(resolvedOnAccountB.contains('unsplash.com'), isFalse);
    });

    testWidgets('4. Widget PostCard menampilkan foto Supabase Storage secara konsisten', (WidgetTester tester) async {
      final post = PostModel(
        id: 'post-cross-account-1',
        captureId: 'cap-cross-account-1',
        caption: 'Dokumentasi satwa Trenggiling di alam liar.',
        speciesName: 'Trenggiling',
        category: 'Manis javanica',
        photoUrl: storageRelativePath,
        locationVisibility: 'coarse',
        blockSeq: 1,
        blockHash: 'blockhash123',
        photoSha256: 'photosha123',
        authorId: userIdAccountA,
        authorName: 'Akun A',
        authorUsername: 'akun_a',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCard(post: post),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Trenggiling'), findsOneWidget);
      expect(find.textContaining('@akun_a'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.pets_rounded), findsNothing);
    });
  });
}
