import 'package:flutter/material.dart';

import '../assistant/assistant_page.dart';
import '../auth/auth_page.dart';
import '../cart/cart_page.dart';
import '../models/store_product.dart';
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
  int _selectedTab = 0;
  int _ordersRevision = 0;
  int _profileRevision = 0;
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

  void _openProduct(StoreProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsPage(api: widget.api, product: product),
      ),
    );
  }

  Future<void> _openFeature(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    await _refreshCartCount();
  }

  Future<void> _selectTab(int index) async {
    if (index == 1 || index == 2) {
      if (!await _ensureSignedIn()) return;
    }
    if (!mounted) return;
    setState(() {
      _selectedTab = index;
      if (index == 2) _ordersRevision++;
      if (index == 3) _profileRevision++;
    });
  }

  void _syncSession(AuthSession? session) {
    if (!mounted) return;
    setState(() {
      _session = session;
      if (session == null) _cartCount = 0;
    });
    if (session != null) _refreshCartCount();
  }

  Future<bool> _ensureSignedIn() async {
    if (_session != null) return true;
    final session = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(builder: (_) => AuthPage(api: widget.api)),
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
      appBar: _selectedTab == 0
          ? AppBar(
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
                  tooltip: _session == null
                      ? AppStrings.signIn
                      : AppStrings.account,
                  onPressed: () => _selectTab(3),
                  icon: Icon(
                    _session == null ? Icons.person_outline : Icons.person,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: switch (_selectedTab) {
        0 => _buildShopBody(theme),
        1 => AssistantPage(api: widget.api, gender: _gender),
        2 => OrdersPage(key: ValueKey(_ordersRevision), api: widget.api),
        _ => ProfilePage(
          key: ValueKey(_profileRevision),
          api: widget.api,
          onSessionChanged: _syncSession,
        ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: AppStrings.navShop,
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: AppStrings.stylistTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: AppStrings.ordersTitle,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: AppStrings.account,
          ),
        ],
      ),
    );
  }

  Widget _buildShopBody(ThemeData theme) => RefreshIndicator(
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
              children: List.generate(6, (_) => const ProductSkeletonCard()),
            ),
          )
        else if (_error != null)
          SliverFillRemaining(hasScrollBody: false, child: _buildError())
        else if (_products.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
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
                    AppStrings.productCountLabel(_products.length, _totalCount),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.loadMore),
                  ),
                ),
              ),
            ),
        ],
      ],
    ),
  );

  Widget _buildHero(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            AppStrings.heroTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SegmentedButton<String>(
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity(horizontal: -3, vertical: -3),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            textStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
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
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _loadStore(),
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: AppStrings.searchHint,
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: IconButton(
              tooltip: AppStrings.tooltipSearch,
              onPressed: _loadStore,
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text(AppStrings.filterAll),
                selected: _categoryId == null,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        const SizedBox(height: 2),
        Row(
          children: [
            FilterChip(
              label: const Text(AppStrings.filterOnSale),
              selected: _onSale,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (selected) {
                setState(() => _onSale = selected);
                _loadStore();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text(AppStrings.filterInStock),
              selected: _inStock,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
