import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/widgets/async_content_view.dart';
import '../shared/widgets/app_snack_bar.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteProduct>> _favorites;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _favorites = widget.api.getFavorites();
  }

  Future<void> _remove(FavoriteProduct product) async {
    try {
      await widget.api.removeFavorite(product.productId);
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted) {
        showAppErrorSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(AppStrings.favoritesTitle),
      actions: [
        IconButton(
          onPressed: () => setState(_load),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: AsyncContentView<List<FavoriteProduct>>(
      future: _favorites,
      isEmpty: (items) => items.isEmpty,
      emptyMessage: AppStrings.favoritesEmpty,
      builder: (context, products) => ListView(
        padding: const EdgeInsets.all(16),
        children: products
            .map(
              (product) => Card(
                child: ListTile(
                  leading: product.imageUrl == null
                      ? const Icon(Icons.checkroom_outlined)
                      : Image.network(
                          product.imageUrl!,
                          width: 52,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy:
                              WebHtmlElementStrategy.fallback,
                        ),
                  title: Text(product.name),
                  subtitle: Text(
                    formatPrice(product.currentPrice, product.currencyCode),
                  ),
                  trailing: IconButton(
                    onPressed: () => _remove(product),
                    icon: const Icon(Icons.favorite, color: Color(0xFFB43B31)),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}
