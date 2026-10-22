import 'package:flutter/material.dart';

import '../addresses/addresses_page.dart';
import '../assistant/assistant_page.dart';
import '../auth/auth_sheet.dart';
import '../cart/cart_page.dart';
import '../catalog/product_components.dart';
import '../favorites/favorites_page.dart';
import '../features/feature_hub_page.dart';
import '../models/store_product.dart';
import '../notifications/notifications_page.dart';
import '../orders/orders_page.dart';
import '../services/store_api.dart';

class StorefrontPage extends StatefulWidget {
  const StorefrontPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<StorefrontPage> createState() => _StorefrontPageState();
}

class _StorefrontPageState extends State<StorefrontPage> {
  final _searchController = TextEditingController();
  List<StoreCategory> _categories = [];
  List<StoreProduct> _products = [];
  AuthSession? _session;
  String _gender = 'Women';
  String? _categoryId;
  String? _error;
  String _sortBy = 'name';
  int _page = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  int _cartCount = 0;
  bool _onSale = false;
  bool _inStock = false;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _loadStore();
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.api.close();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    try {
      final session = await widget.api.loadSession();
      if (mounted) setState(() => _session = session);
      if (session != null) await _refreshCartCount();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not read the saved sign-in session.');
      }
    }
  }

  Future<void> _loadStore() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
      _page = 1;
      _products = [];
    });
    try {
      final results = await Future.wait<dynamic>([
        widget.api.getCategories(_gender),
        widget.api.getProducts(
          gender: _gender,
          categoryId: _categoryId,
          search: _searchController.text,
          onSale: _onSale,
          inStock: _inStock,
          sortBy: _sortBy,
        ),
      ]);
      if (!mounted) return;
      final page = results[1] as StoreProductPage;
      setState(() {
        _categories = results[0] as List<StoreCategory>;
        _products = page.items;
        _page = page.page;
        _totalPages = page.totalPages;
        _totalCount = page.totalCount;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is StoreApiException ? error.message : 'Could not reach the BigFit store API. Check the server and API_BASE_URL.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final result = await widget.api.getProducts(
        gender: _gender,
        categoryId: _categoryId,
        search: _searchController.text,
        onSale: _onSale,
        inStock: _inStock,
        sortBy: _sortBy,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(result.items);
        _page = result.page;
        _totalPages = result.totalPages;
        _totalCount = result.totalCount;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is StoreApiException
            ? error.message
            : 'Could not load more products.';
        _loadingMore = false;
      });
    }
  }

  Future<void> _openAccount() async {
    if (_session != null) {
      final shouldSignOut = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _session!.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(_session!.email),
                const SizedBox(height: 6),
                Text('Role: ${_session!.roles.join(', ')}'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _accountAction(
                      context,
                      'Orders',
                      Icons.receipt_long_outlined,
                      () => _openFeature(OrdersPage(api: widget.api)),
                    ),
                    _accountAction(
                      context,
                      'Favorites',
                      Icons.favorite_border,
                      () => _openFeature(FavoritesPage(api: widget.api)),
                    ),
                    _accountAction(
                      context,
                      'Addresses',
                      Icons.location_on_outlined,
                      () => _openFeature(AddressesPage(api: widget.api)),
                    ),
                    _accountAction(
                      context,
                      'Notifications',
                      Icons.notifications_outlined,
                      () => _openFeature(NotificationsPage(api: widget.api)),
                    ),
                    _accountAction(
                      context,
                      'AI stylist',
                      Icons.auto_awesome_outlined,
                      () => _openFeature(
                        AssistantPage(api: widget.api, gender: _gender),
                      ),
                    ),
                    _accountAction(
                      context,
                      'More features',
                      Icons.grid_view_outlined,
                      () => _openFeature(FeatureHubPage(session: _session!)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
      if (shouldSignOut == true) {
        await widget.api.signOut();
        if (mounted) {
          setState(() {
            _session = null;
            _cartCount = 0;
          });
        }
      }
      return;
    }

    final session = await showModalBottomSheet<AuthSession>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AuthSheet(api: widget.api),
    );
    if (session != null && mounted) {
      setState(() => _session = session);
      await _refreshCartCount();
    }
  }

  void _openProduct(StoreProduct product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ProductDetailsSheet(
        product: product,
        onAddToBag: (variant) => _addToCart(product, variant),
        onToggleFavorite: () => _toggleFavorite(product),
      ),
    );
  }

  Widget _accountAction(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) => ActionChip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    onPressed: () {
      Navigator.pop(context);
      onTap();
    },
  );

  Future<void> _openFeature(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    await _refreshCartCount();
  }

  Future<bool> _ensureSignedIn() async {
    if (_session != null) return true;
    final session = await showModalBottomSheet<AuthSession>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AuthSheet(api: widget.api),
    );
    if (session == null || !mounted) return false;
    setState(() => _session = session);
    return true;
  }

  Future<void> _refreshCartCount() async {
    if (_session == null) return;
    try {
      final cart = await widget.api.getCart();
      if (mounted) setState(() => _cartCount = cart.itemCount);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StoreApiException
                ? error.message
                : 'Could not load your bag.',
          ),
        ),
      );
    }
  }

  Future<void> _addToCart(StoreProduct product, StoreVariant variant) async {
    if (!await _ensureSignedIn()) return;
    try {
      final cart = await widget.api.addCartItem(productVariantId: variant.id);
      if (!mounted) return;
      setState(() => _cartCount = cart.itemCount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} · ${variant.size} added to bag'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StoreApiException
                ? error.message
                : 'Could not add this item to your bag.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleFavorite(StoreProduct product) async {
    if (!await _ensureSignedIn()) return;
    try {
      await widget.api.addFavorite(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to your favorites.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StoreApiException
                ? error.message
                : 'Could not save this favorite.',
          ),
        ),
      );
    }
  }

  void _selectDepartment(String gender) {
    if (_gender == gender) return;
    setState(() {
      _gender = gender;
      _categoryId = null;
    });
    _loadStore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text(
          'BIGFIT',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'AI stylist',
            onPressed: () => _ensureSignedIn().then((ready) {
              if (ready && mounted) {
                _openFeature(AssistantPage(api: widget.api, gender: _gender));
              }
            }),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          if (_session != null)
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => _openFeature(NotificationsPage(api: widget.api)),
              icon: const Icon(Icons.notifications_outlined),
            ),
          IconButton(
            tooltip: 'Shopping bag ($_cartCount)',
            onPressed: () => _showBag(context),
            icon: Badge(
              isLabelVisible: _cartCount > 0,
              label: Text('$_cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          IconButton(
            tooltip: _session == null ? 'Sign in' : 'Account',
            onPressed: _openAccount,
            icon: Icon(_session == null ? Icons.person_outline : Icons.person),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStore,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero(theme)),
            SliverToBoxAdapter(child: _buildControls(theme)),
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.55,
                  children: List.generate(
                    6,
                    (_) => const ProductSkeletonCard(),
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildError(theme),
              )
            else if (_products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(theme),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _onSale ? 'ON SALE' : 'THE COLLECTION',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Text('${_products.length} of ${_totalCountLabel()}'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverGrid.builder(
                  itemCount: _products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.55,
                  ),
                  itemBuilder: (context, index) => ProductTile(
                    product: _products[index],
                    onTap: () => _openProduct(_products[index]),
                  ),
                ),
              ),
              if (_page < _totalPages)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: OutlinedButton(
                        onPressed: _loadingMore ? null : _loadMore,
                        child: _loadingMore
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Load more'),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            setState(() => _onSale = !_onSale);
            _loadStore();
          } else if (index == 2) {
            _openAccount();
          } else if (index == 3) {
            _openFeature(FeatureHubPage(session: _session));
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(_onSale ? Icons.sell : Icons.sell_outlined),
            label: 'Sale',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Account',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'More',
          ),
        ],
      ),
    );
  }

  String _totalCountLabel() => '$_totalCount products';

  Widget _buildHero(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clothing that fits', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Explore the BigFit collection',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'Women', label: Text('WOMEN')),
            ButtonSegment(value: 'Men', label: Text('MEN')),
          ],
          selected: {_gender},
          onSelectionChanged: (selection) => _selectDepartment(selection.first),
        ),
      ],
    ),
  );

  Widget _buildControls(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _loadStore(),
          decoration: InputDecoration(
            hintText: 'Search clothes, styles, and sizes',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Search',
              onPressed: _loadStore,
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _categoryId == null,
                onSelected: (_) {
                  setState(() => _categoryId = null);
                  _loadStore();
                },
              ),
              const SizedBox(width: 8),
              ..._categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: _categoryId == category.id,
                    onSelected: (_) {
                      setState(
                        () => _categoryId = _categoryId == category.id
                            ? null
                            : category.id,
                      );
                      _loadStore();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilterChip(
              avatar: const Icon(Icons.sell_outlined, size: 17),
              label: const Text('On sale'),
              selected: _onSale,
              onSelected: (selected) {
                setState(() => _onSale = selected);
                _loadStore();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('In stock'),
              selected: _inStock,
              onSelected: (selected) {
                setState(() => _inStock = selected);
                _loadStore();
              },
            ),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                icon: const Icon(Icons.sort, size: 20),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'price_asc', child: Text('Price ↑')),
                  DropdownMenuItem(value: 'price_desc', child: Text('Price ↓')),
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sortBy = value);
                  _loadStore();
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildError(ThemeData theme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadStore,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmptyState(ThemeData theme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.checkroom_outlined, size: 46),
          const SizedBox(height: 14),
          Text(
            'Your next favourite fit is on its way.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The cleaned catalogue is ready for review. Products will appear here after you approve and import the CSV.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Future<void> _showBag(BuildContext context) async {
    if (!await _ensureSignedIn()) return;
    await _openFeature(CartPage(api: widget.api));
  }
}
