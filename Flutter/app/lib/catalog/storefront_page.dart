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

      if (mounted) {
        setState(() => _session = session);
      }

      if (session != null) {
        await _refreshCartCount();
      }
    } catch (error) {
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

      if (index == 2) {
        _ordersRevision++;
      }

      if (index == 3) {
        _profileRevision++;
      }
    });
  }

  void _syncSession(AuthSession? session) {
    if (!mounted) return;

    setState(() {
      _session = session;

      if (session == null) {
        _cartCount = 0;
      }
    });

    if (session != null) {
      _refreshCartCount();
    }
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

      if (mounted) {
        setState(() => _cartCount = cart.itemCount);
      }
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

  void _selectCategory(String? categoryId) {
    setState(() {
      _categoryId = categoryId;
    });

    _loadStore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _selectedTab == 0
          ? AppBar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              scrolledUnderElevation: 0,

              // Keep the logo aligned to the left side of the header.
              centerTitle: false,
              titleSpacing: 16,

              title: const Align(
                alignment: Alignment.centerLeft,
                child: _BigfitAnimatedLogo(),
              ),

              actions: [
                IconButton(
                  tooltip: AppStrings.shoppingBagTooltip(_cartCount),
                  onPressed: () => _showBag(context),
                  icon: Badge(
                    isLabelVisible: _cartCount > 0,
                    label: Text('$_cartCount'),
                    child: const Icon(Icons.shopping_bag_outlined, size: 22),
                  ),
                ),
                IconButton(
                  tooltip: _session == null
                      ? AppStrings.signIn
                      : AppStrings.account,
                  onPressed: () => _selectTab(3),
                  icon: Icon(
                    _session == null ? Icons.person_outline : Icons.person,
                    size: 22,
                  ),
                ),
                PopupMenuButton<AppLanguage>(
                  tooltip: AppStrings.languageTitle,
                  onSelected: AppStrings.setLanguage,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: AppLanguage.english,
                      child: Text(AppStrings.languageEnglish),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.vietnamese,
                      child: Text(AppStrings.languageVietnamese),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        AppStrings.languageCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
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
        destinations: [
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

  Widget _buildShopBody(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadStore,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Keep the category navigation directly below the app bar.
          SliverToBoxAdapter(child: _buildTopCategoryBar()),

          SliverToBoxAdapter(child: _buildHero(theme)),

          SliverToBoxAdapter(child: _buildControls(theme)),

          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: 0.62,
                children: List.generate(6, (_) => const ProductSkeletonCard()),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(hasScrollBody: false, child: _buildError())
          else if (_products.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                          letterSpacing: 1,
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
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              sliver: SliverGrid.builder(
                itemCount: _products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 1200
                      ? 4
                      : MediaQuery.sizeOf(context).width >= 800
                      ? 3
                      : 2,
                  mainAxisSpacing: 22,
                  crossAxisSpacing: 12,
                  childAspectRatio: MediaQuery.sizeOf(context).width < 600
                      ? 0.62
                      : MediaQuery.sizeOf(context).width < 1200
                      ? 0.70
                      : 0.78,
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
                          : Text(AppStrings.loadMore),
                    ),
                  ),
                ),
              ),

            SliverToBoxAdapter(child: _buildFooter()),
          ],
        ],
      ),
    );
  }

  // Keep the category strip visible at the top of the storefront.
  Widget _buildTopCategoryBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: _buildCategoryNavigation(),
    );
  }

  Widget _buildHero(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/bigfit_her.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.85),
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: Color(0xFF111111),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                );
              },
            ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xCC000000),
                    Color(0x66000000),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.heroBrandCaption,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    AppStrings.heroFindYourFit,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    AppStrings.heroStreetwearCaption,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                return states.contains(WidgetState.selected)
                                    ? Colors.white
                                    : Colors.transparent;
                              }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                return states.contains(WidgetState.selected)
                                    ? Colors.black
                                    : Colors.white;
                              }),
                          side: const WidgetStatePropertyAll(
                            BorderSide(color: Colors.white54),
                          ),
                          shape: const WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          textStyle: const WidgetStatePropertyAll(
                            TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                        segments: [
                          ButtonSegment<String>(
                            value: 'Women',
                            label: Text(AppStrings.womenSegment),
                          ),
                          ButtonSegment<String>(
                            value: 'Men',
                            label: Text(AppStrings.menSegment),
                          ),
                        ],
                        selected: {_gender},
                        onSelectionChanged: (selection) {
                          _selectDepartment(selection.first);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
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

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(AppStrings.filterOnSale),
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
                  label: Text(AppStrings.filterInStock),
                  selected: _inStock,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (selected) {
                    setState(() => _inStock = selected);
                    _loadStore();
                  },
                ),

                const SizedBox(width: 12),

                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: const Icon(Icons.sort, size: 20),
                    items: [
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
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNavigation() {
    final categories = <StoreCategory?>[null, ..._categories];

    return LayoutBuilder(
      builder: (context, constraints) {
        final canSpread = constraints.maxWidth >= categories.length * 95;

        final children = categories.map((category) {
          final selected = category == null
              ? _categoryId == null
              : _categoryId == category.id;

          final label = category == null
              ? AppStrings.categoryAll
              : AppStrings.categoryLabel(category.name).toUpperCase();

          return _CategoryNavigationItem(
            label: label,
            selected: selected,
            onTap: () {
              final id = category?.id;

              if (_categoryId == id) return;

              _selectCategory(id);
            },
          );
        }).toList();

        if (canSpread) {
          return Row(
            children: children
                .map((child) => Expanded(child: Center(child: child)))
                .toList(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: children),
        );
      },
    );
  }

  Widget _buildError() {
    return ErrorStateView(
      message: _error!,
      icon: Icons.cloud_off_outlined,
      onRetry: _loadStore,
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateView(
      icon: Icons.checkroom_outlined,
      title: AppStrings.catalogEmptyTitle,
      message: AppStrings.catalogEmptySubtitle,
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      color: const Color(0xFF111111),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.brandName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            AppStrings.footerStreetwear,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              const headingStyle = TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              );

              const bodyStyle = TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.6,
              );

              final aboutSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.footerAboutHeading, style: headingStyle),

                  SizedBox(height: 10),

                  Text(AppStrings.footerAboutBody, style: bodyStyle),
                ],
              );

              final exchangeSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.footerExchangeHeading, style: headingStyle),

                  SizedBox(height: 10),

                  Text(
                    AppStrings.footerExchangeConditions,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(AppStrings.footerExchangeRequirements, style: bodyStyle),

                  SizedBox(height: 12),

                  Text(
                    AppStrings.footerExchangeHowTo,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(AppStrings.footerExchangeInstructions, style: bodyStyle),

                  SizedBox(height: 10),

                  Text(
                    AppStrings.footerExchangeDisclaimer,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ],
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    aboutSection,
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    exchangeSection,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: aboutSection,
                    ),
                  ),

                  Container(width: 1, height: 220, color: Colors.white24),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: exchangeSection,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          const Divider(color: Colors.white24),

          const SizedBox(height: 12),

          Center(
            child: Text(
              AppStrings.footerCopyright,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBag(BuildContext context) async {
    if (!await _ensureSignedIn()) return;

    await _openFeature(CartPage(api: widget.api));
  }
}

class _CategoryNavigationItem extends StatelessWidget {
  const _CategoryNavigationItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.black : Colors.black54,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 7),

            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width: selected ? 24 : 0,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

class _BigfitAnimatedLogo extends StatefulWidget {
  const _BigfitAnimatedLogo({super.key});

  @override
  State<_BigfitAnimatedLogo> createState() => _BigfitAnimatedLogoState();
}

class _BigfitAnimatedLogoState extends State<_BigfitAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glow = Tween<double>(
      begin: 0,
      end: 16,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));

      if (!mounted) return;

      await _controller.forward();

      if (!mounted) return;

      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Text(
            AppStrings.brandName,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Colors.black,
              shadows: [
                Shadow(
                  color: const Color(0xFF14432F)
                      .withOpacity(_controller.value * 0.5),
                  blurRadius: _glow.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
