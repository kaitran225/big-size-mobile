import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:app/services/store_api.dart';

void main() {
  group('StoreApi backend fallback', () {
    test('uses the configured local backend first', () async {
      final client = _QueueClient([_response(200, '[]')]);
      final api = StoreApi(client: client, baseUrl: 'http://localhost:5047');

      await api.getCategories('Men');

      expect(client.requests, hasLength(1));
      expect(client.requests.single.url.host, 'localhost');
    });

    test('uses the cloud backend when the local backend returns 5xx', () async {
      final client = _QueueClient([
        _response(503, '{"title":"Unavailable"}'),
        _response(200, '[]'),
      ]);
      final api = StoreApi(client: client, baseUrl: 'http://localhost:5047');

      await api.getCategories('Men');

      expect(client.requests, hasLength(2));
      expect(client.requests[0].url.host, 'localhost');
      expect(client.requests[1].url.host, 'big-fit-pgm-store.onrender.com');
    });

    test(
      'uses the cloud backend when the local request cannot connect',
      () async {
        final client = _QueueClient([
          (_) => throw http.ClientException('Connection failed'),
          _response(200, '[]'),
        ]);
        final api = StoreApi(client: client, baseUrl: 'http://localhost:5047');

        await api.getCategories('Men');

        expect(client.requests, hasLength(2));
        expect(client.requests[0].url.host, 'localhost');
        expect(client.requests[1].url.host, 'big-fit-pgm-store.onrender.com');
      },
    );

    test('uses the cloud backend when the local request times out', () async {
      final client = _QueueClient([
        (_) => Completer<http.StreamedResponse>().future,
        _response(200, '[]'),
      ]);
      final api = StoreApi(client: client, baseUrl: 'http://localhost:5047');

      await api.getCategories('Men');

      expect(client.requests, hasLength(2));
      expect(client.requests[0].url.host, 'localhost');
      expect(client.requests[1].url.host, 'big-fit-pgm-store.onrender.com');
    });

    test('does not use cloud fallback for local 4xx responses', () async {
      final client = _QueueClient([
        _response(404, '{"title":"Not found"}'),
        _response(200, '[]'),
      ]);
      final api = StoreApi(client: client, baseUrl: 'http://localhost:5047');

      await expectLater(
        api.getCategories('Men'),
        throwsA(isA<StoreApiException>()),
      );

      expect(client.requests, hasLength(1));
    });

    test('does not retry the cloud backend after its 5xx response', () async {
      final client = _QueueClient([
        _response(503, '{"title":"Local unavailable"}'),
        _response(503, '{"title":"Cloud unavailable"}'),
      ]);
      final api = StoreApi(client: client, baseUrl: 'http://localhost:5047');

      await expectLater(
        api.getCategories('Men'),
        throwsA(isA<StoreApiException>()),
      );

      expect(client.requests, hasLength(2));
    });
  });
}

class _QueueClient extends http.BaseClient {
  _QueueClient(this._responses);

  final List<Future<http.StreamedResponse> Function(http.BaseRequest)>
  _responses;
  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return _responses.removeAt(0)(request);
  }
}

Future<http.StreamedResponse> Function(http.BaseRequest) _response(
  int statusCode,
  String body,
) =>
    (_) async =>
        http.StreamedResponse(Stream.value(utf8.encode(body)), statusCode);
