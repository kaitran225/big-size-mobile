import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/store_product.dart';
import '../shared/app_strings.dart';

class StoreApiException implements Exception {
  const StoreApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StoreApi {
  StoreApi({
    http.Client? client,
    FlutterSecureStorage? secureStorage,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _baseUri = _normalizeBaseUri(
         baseUrl ??
             (const String.fromEnvironment('API_BASE_URL').isNotEmpty
                 ? const String.fromEnvironment('API_BASE_URL')
                 : 'https://big-fit-pgm-store.onrender.com'),
       );

  static const _tokenKey = 'bigfit.accessToken';
  static const _emailKey = 'bigfit.email';
  static const _nameKey = 'bigfit.displayName';
  static const _rolesKey = 'bigfit.roles';
  static const _baseUrlKey = 'bigfit.apiBaseUrl';
  static const renderBaseUrl = 'https://big-fit-pgm-store.onrender.com';

  final http.Client _client;
  final FlutterSecureStorage _secureStorage;
  Uri _baseUri;
  String? _accessToken;

  String get baseUrl => _baseUri.toString().replaceFirst(RegExp(r'/$'), '');

  static Uri _normalizeBaseUri(String value) {
    final parsed = Uri.parse(value.trim());
    if ((parsed.scheme != 'http' && parsed.scheme != 'https') ||
        parsed.host.isEmpty) {
      throw FormatException(AppStrings.invalidBaseUrl);
    }
    var path = parsed.path.replaceFirst(RegExp(r'/+$'), '');
    if (!path.endsWith('/api')) path = '$path/api';
    return parsed.replace(path: '$path/', query: null, fragment: null);
  }

  static String get localBaseUrl {
    final host = kIsWeb || defaultTargetPlatform != TargetPlatform.android
        ? 'localhost'
        : '10.0.2.2';
    return 'http://$host:5047';
  }

  Future<void> loadSavedBaseUrl() async {
    final saved = await _secureStorage.read(key: _baseUrlKey);
    if (saved != null && saved.isNotEmpty) {
      _baseUri = _normalizeBaseUri(saved);
    }
  }

  Future<void> setBaseUrl(String value) async {
    final normalized = _normalizeBaseUri(value);
    if (normalized == _baseUri) return;
    await _secureStorage.write(key: _baseUrlKey, value: value.trim());
    await signOut();
    _baseUri = normalized;
  }

  Future<List<StoreCategory>> getCategories(String gender) async {
    final response = await _send(
      'GET',
      '/categories',
      query: {'gender': gender},
    );
    return (response as List<dynamic>)
        .map((item) => StoreCategory.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<StoreProductPage> getProducts({
    required String gender,
    String? categoryId,
    String? search,
    bool onSale = false,
    bool inStock = false,
    String sortBy = 'name',
    int page = 1,
    int pageSize = 24,
  }) async {
    final query = <String, String>{
      'gender': gender,
      'onSale': '$onSale',
      'inStock': '$inStock',
      'sortBy': sortBy,
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (categoryId != null) query['categoryId'] = categoryId;
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _send('GET', '/products', query: query);
    return StoreProductPage.fromJson(response as Map<String, dynamic>);
  }

  Future<Cart> getCart() async {
    final response = await _send('GET', '/cart');
    return Cart.fromJson(response as Map<String, dynamic>);
  }

  Future<Cart> addCartItem({
    required String productVariantId,
    int quantity = 1,
  }) async {
    final response = await _send(
      'POST',
      '/cart/items',
      body: {'productVariantId': productVariantId, 'quantity': quantity},
    );
    return Cart.fromJson(response as Map<String, dynamic>);
  }

  Future<Cart> updateCartItem(String itemId, int quantity) async {
    final response = await _send(
      'PUT',
      '/cart/items/$itemId',
      body: {'quantity': quantity},
    );
    return Cart.fromJson(response as Map<String, dynamic>);
  }

  Future<void> removeCartItem(String itemId) async {
    await _send('DELETE', '/cart/items/$itemId');
  }

  Future<List<FavoriteProduct>> getFavorites() async {
    final response = await _send('GET', '/favorites');
    return (response as List<dynamic>)
        .map((item) => FavoriteProduct.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> addFavorite(String productId) async {
    await _send('PUT', '/favorites/$productId');
  }

  Future<void> removeFavorite(String productId) async {
    await _send('DELETE', '/favorites/$productId');
  }

  Future<List<CustomerAddress>> getAddresses() async {
    final response = await _send('GET', '/addresses');
    return (response as List<dynamic>)
        .map((item) => CustomerAddress.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<CustomerAddress> saveAddress(
    Map<String, Object?> address, {
    String? id,
  }) async {
    final response = await _send(
      id == null ? 'POST' : 'PUT',
      id == null ? '/addresses' : '/addresses/$id',
      body: address,
    );
    return CustomerAddress.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    await _send('DELETE', '/addresses/$id');
  }

  Future<List<CustomerOrder>> getOrders({int page = 1}) async {
    final response = await _send(
      'GET',
      '/orders',
      query: {'page': '$page', 'pageSize': '50'},
    );
    final items = (response as Map<String, dynamic>)['items'] as List<dynamic>;
    return items
        .map((item) => CustomerOrder.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<CustomerOrder> createOrder({String? shippingAddressId}) async {
    final response = await _send(
      'POST',
      '/orders',
      body: {'shippingAddressId': shippingAddressId},
    );
    return CustomerOrder.fromJson(response as Map<String, dynamic>);
  }

  Future<List<StoreNotification>> getNotifications({int page = 1}) async {
    final response = await _send(
      'GET',
      '/notifications',
      query: {'page': '$page', 'pageSize': '50'},
    );
    final items = (response as Map<String, dynamic>)['items'] as List<dynamic>;
    return items
        .map((item) => StoreNotification.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> markNotificationRead(String id) async {
    await _send('PUT', '/notifications/$id/read');
  }

  Future<void> deleteNotification(String id) async {
    await _send('DELETE', '/notifications/$id');
  }

  Future<ChatReply> askAssistant({
    required String message,
    String? gender,
    String? category,
  }) async {
    final response = await _send(
      'POST',
      '/assistant/chat',
      body: {'message': message, 'gender': gender, 'category': category},
    );
    return ChatReply.fromJson(response as Map<String, dynamic>);
  }

  Future<AuthSession> login(String email, String password) async {
    final response = await _send(
      'POST',
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> registerCustomer({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final response = await _send(
      'POST',
      '/auth/register',
      body: {
        'email': email.trim(),
        'displayName': displayName.trim(),
        'password': password,
      },
    );
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    await _saveSession(session);
    return session;
  }

  Future<AuthSession?> loadSession() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null) return null;

    final email = await _secureStorage.read(key: _emailKey);
    final displayName = await _secureStorage.read(key: _nameKey);
    final roles = await _secureStorage.read(key: _rolesKey);
    if (email == null || displayName == null || roles == null) {
      await signOut();
      return null;
    }

    _accessToken = token;
    return AuthSession(
      accessToken: token,
      email: email,
      displayName: displayName,
      roles: (jsonDecode(roles) as List<dynamic>).cast<String>(),
    );
  }

  Future<void> signOut() async {
    _accessToken = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _nameKey);
    await _secureStorage.delete(key: _rolesKey);
  }

  Future<void> _saveSession(AuthSession session) async {
    _accessToken = session.accessToken;
    await _secureStorage.write(key: _tokenKey, value: session.accessToken);
    await _secureStorage.write(key: _emailKey, value: session.email);
    await _secureStorage.write(key: _nameKey, value: session.displayName);
    await _secureStorage.write(
      key: _rolesKey,
      value: jsonEncode(session.roles),
    );
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) async {
    final uri = _baseUri.resolve(path.replaceFirst(RegExp(r'^/'), ''));
    final request = http.Request(method, uri.replace(queryParameters: query));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoreApiException(_errorMessage(response));
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail'] ?? body['title'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } on FormatException {
      return AppStrings.requestFailed(response.statusCode);
    }
    return AppStrings.requestFailed(response.statusCode);
  }

  void close() => _client.close();
}
