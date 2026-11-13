import 'dart:convert';

import 'package:http/http.dart' as http;

/// One resolved address returned by the OpenStreetMap reverse geocoder.
class GeocodedAddress {
  const GeocodedAddress({
    this.addressLine,
    this.city,
    this.province,
    this.postalCode,
    this.countryCode,
    this.displayName,
  });

  final String? addressLine;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? countryCode;
  final String? displayName;
}

/// Reverse geocodes a map point with Nominatim so the address form fills itself.
///
/// Nominatim asks for at most one request per second and an identifying
/// user agent, so callers debounce and this service serialises its requests.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  static const _userAgent = 'BigFit/1.0 (university demo)';

  final http.Client _client;
  Future<void> _queue = Future<void>.value();

  /// Returns null when the point has no usable address or the lookup fails.
  Future<GeocodedAddress?> reverse(double latitude, double longitude) {
    final result = _queue.then((_) => _lookup(latitude, longitude));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<GeocodedAddress?> _lookup(double latitude, double longitude) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toStringAsFixed(6),
      'lon': longitude.toStringAsFixed(6),
      'addressdetails': '1',
      'accept-language': 'vi,en',
    });
    try {
      final response = await _client
          .get(uri, headers: const {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final address = body['address'];
      if (address is! Map<String, dynamic>) return null;
      return GeocodedAddress(
        addressLine: _line(address),
        city: _first(address, const ['city', 'town', 'village', 'municipality', 'county']),
        province: _first(address, const ['state', 'province', 'region']),
        postalCode: _text(address['postcode']),
        countryCode: _text(address['country_code'])?.toUpperCase(),
        displayName: _text(body['display_name']),
      );
    } on Object {
      return null;
    }
  }

  String? _line(Map<String, dynamic> address) {
    final road = _first(address, const [
      'road',
      'pedestrian',
      'residential',
      'footway',
      'path',
      'neighbourhood',
      'suburb',
    ]);
    final houseNumber = _text(address['house_number']);
    if (road == null) return null;
    return houseNumber == null ? road : '$houseNumber $road';
  }

  String? _first(Map<String, dynamic> address, List<String> keys) {
    for (final key in keys) {
      final value = _text(address[key]);
      if (value != null) return value;
    }
    return null;
  }

  String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
