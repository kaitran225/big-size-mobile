import 'package:flutter/material.dart';

import '../addresses/addresses_page.dart';
import '../assistant/assistant_page.dart';
import '../auth/auth_sheet.dart';
import '../cart/cart_page.dart';
import '../favorites/favorites_page.dart';
import '../features/feature_hub_page.dart';
import '../models/store_product.dart';
import '../notifications/notifications_page.dart';
import '../orders/orders_page.dart';
import '../profile/profile_page.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/widgets/app_snack_bar.dart';
import '../shared/widgets/empty_state_view.dart';
import '../shared/widgets/error_state_view.dart';
import 'product_details_page.dart';
import 'product_skeleton_card.dart';
import 'product_tile.dart';

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

  bool get _isAdmin => (_session?.roles ?? const <String>[]).any(
        (role) => role.toLowerCase().contains('admin'),
      );

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
        setState(() => _error = AppStrings.errorSession);
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
        _error = error is StoreApiException
            ? error.message
            : AppStrings.errorStoreApi;
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
            : AppStrings.errorLoadMore;
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
                Text(AppStrings.roleLabel(_session!.roles.join(', '))),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _accountAction(
                      context,
                      AppStrings.ordersTitle,
                      Icons.receipt_long_outlined,
                      () => _openFeature(OrdersPage(api: widget.api)),
                    ),
                    _accountAction(
                      context,
                      AppStrings.favoritesTitle,
                      Icons.favorite_border,
                      () => _openFeature(FavoritesPage(api: widget.api)),
                    ),
                    _accountAction(
                      context,
                      AppStrings.addressesTitle,
                      Icons.location_on_outlined,
                      () => _openFeature(AddressesPage(api: widget.api)),
                    ),
                    _accountAction(
                      context,
                      AppStrings.notificationsTitle,
                      Icons.notifications_outlined,
                      () => _openFeature(NotificationsPage(api: widget.api)),
                    ),
                    _accountAction(
                      context,
                      AppStrings.aiStylist,
                      Icons.auto_awesome_outlined,
                      () => _openFeature(
                        AssistantPage(api: widget.api, gender: _gender),
                      ),
                    ),
                    _accountAction(
                      context,
                      AppStrings.moreFeatures,
                      Icons.grid_view_outlined,
                      () => _openFeature(FeatureHubPage(session: _session!)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.logout),
                  label: const Text(AppStrings.signOut),
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

  Future<void> _chooseApiBaseUrl() async {
    final selectedUrl = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.storeConnectionTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(AppStrings.currentApi(widget.api.baseUrl)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text(AppStrings.renderDeployment),
                subtitle: const Text(StoreApi.renderBaseUrl),
                onTap: () => Navigator.pop(context, StoreApi.renderBaseUrl),
              ),
              ListTile(
                leading: const Icon(Icons.computer_outlined),
                title: const Text(AppStrings.localDevelopmentServer),
                subtitle: Text(StoreApi.localBaseUrl),
                onTap: () => Navigator.pop(context, StoreApi.localBaseUrl),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.apiPathNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
    if (selectedUrl == null || !mounted) return;

    try {
      await widget.api.setBaseUrl(selectedUrl);
      if (!mounted) return;
      setState(() {
        _session = null;
        _cartCount = 0;
      });
      await _loadStore();
      if (mounted) {
        showAppSnackBar(context, AppStrings.connectedTo(widget.api.baseUrl));
      }
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnackBar(
        context,
        error,
        fallback: AppStrings.changeServerFailed(error),
      );
    }
  }

  void _openProduct(StoreProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsPage(api: widget.api, product: product),
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
      showAppErrorSnackBar(context, error, fallback: AppStrings.errorLoadBag);
    }
  }

  Future<void> _addToCart(StoreProduct product, StoreVariant variant) async {
    if (!await _ensureSignedIn()) return;
    try {
      final cart = await widget.api.addCartItem(productVariantId: variant.id);
      if (!mounted) return;
      setState(() => _cartCount = cart.itemCount);
      showAppSnackBar(
        context,
        AppStrings.addedToBag(product.name, variant.size),
        behavior: SnackBarBehavior.floating,
      );
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnackBar(context, error, fallback: AppStrings.errorAddToBag);
    }
  }

  Future<void> _toggleFavorite(StoreProduct product) async {
    if (!await _ensureSignedIn()) return;
    try {
      await widget.api.addFavorite(product.id);
      if (mounted) {
        showAppSnackBar(context, AppStrings.addedToFavorites);
      }
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnackBar(
        context,
        error,
        fallback: AppStrings.errorSaveFavorite,
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
          AppStrings.brandName,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              tooltip: AppStrings.tooltipChooseServer,
              onPressed: _chooseApiBaseUrl,
              icon: const Icon(Icons.dns_outlined),
            ),
          IconButton(
            tooltip: AppStrings.aiStylist,
            onPressed: () => _ensureSignedIn().then((ready) {
              if (ready && mounted) {
                _openFeature(AssistantPage(api: widget.api, gender: _gender));
              }
            }),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          if (_session != null)
            IconButton(
              tooltip: AppStrings.notificationsTitle,
              onPressed: () => _openFeature(NotificationsPage(api: widget.api)),
              icon: const Icon(Icons.notifications_outlined),
            ),
          IconButton(
            tooltip: AppStrings.shoppingBagTooltip(_cartCount),
            onPressed: () => _showBag(context),
            icon: Badge(
              isLabelVisible: _cartCount > 0,
              label: Text('$_cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          IconButton(
            tooltip: _session == null ? AppStrings.signIn : AppStrings.account,
            onPressed: () => _openFeature(ProfilePage(api: widget.api)),
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
              SliverFillRemaining(hasScrollBody: false, child: _buildError())
            else if (_products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _onSale
                              ? AppStrings.onSaleHeading
                              : AppStrings.collectionHeading,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Text(
                        AppStrings.productCountLabel(
                          _products.length,
                          _totalCount,
                        ),
                      ),
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
                            : const Text(AppStrings.loadMore),
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
            _openFeature(ProfilePage(api: widget.api));
          } else if (index == 3) {
            _openFeature(FeatureHubPage(session: _session));
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: AppStrings.navShop,
          ),
          NavigationDestination(
            icon: Icon(_onSale ? Icons.sell : Icons.sell_outlined),
            label: AppStrings.navSale,
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            label: AppStrings.account,
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: AppStrings.navMore,
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.heroTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(AppStrings.heroSubtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'Women', label: Text(AppStrings.womenSegment)),
            ButtonSegment(value: 'Men', label: Text(AppStrings.menSegment)),
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
            hintText: AppStrings.searchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: AppStrings.tooltipSearch,
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
                label: const Text(AppStrings.filterAll),
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
              label: const Text(AppStrings.filterOnSale),
              selected: _onSale,
              onSelected: (selected) {
                setState(() => _onSale = selected);
                _loadStore();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text(AppStrings.filterInStock),
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
                  DropdownMenuItem(
                    value: 'name',
                    child: Text(AppStrings.sortName),
                  ),
                  DropdownMenuItem(
                    value: 'price_asc',
                    child: Text(AppStrings.sortPriceAsc),
                  ),
                  DropdownMenuItem(
                    value: 'price_desc',
                    child: Text(AppStrings.sortPriceDesc),
                  ),
                  DropdownMenuItem(
                    value: 'newest',
                    child: Text(AppStrings.sortNewest),
                  ),
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

  Widget _buildError() => ErrorStateView(
    message: _error!,
    icon: Icons.cloud_off_outlined,
    onRetry: _loadStore,
  );

  Widget _buildEmptyState() => const EmptyStateView(
    icon: Icons.checkroom_outlined,
    title: AppStrings.catalogEmptyTitle,
    message: AppStrings.catalogEmptySubtitle,
  );

  Future<void> _showBag(BuildContext context) async {
    if (!await _ensureSignedIn()) return;
    await _openFeature(CartPage(api: widget.api));
  }
}
