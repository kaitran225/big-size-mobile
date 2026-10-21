import 'package:flutter/material.dart';

import 'models/store_product.dart';
import 'services/store_api.dart';

void main() {
  runApp(BigFitApp(api: StoreApi()));
}

class BigFitApp extends StatelessWidget {
  const BigFitApp({super.key, required this.api});

  final StoreApi api;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BigFit',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF174C3C),
        surface: const Color(0xFFF8F7F3),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F7F3),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F7F3),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: StorefrontPage(api: api),
  );
}

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
        if (mounted) setState(() => _session = null);
      }
      return;
    }

    final session = await showModalBottomSheet<AuthSession>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AuthSheet(api: widget.api),
    );
    if (session != null && mounted) setState(() => _session = session);
  }

  void _openProduct(StoreProduct product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ProductDetailsSheet(
        product: product,
        onAddToBag: (variant) {
          setState(() => _cartCount++);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} · ${variant.size} added to bag'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
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
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
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
        ],
      ),
    );
  }

  String _totalCountLabel() => '$_totalCount products';

  Widget _buildHero(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF174C3C),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STYLE THAT\nMEETS YOU HERE.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Thoughtful fits. Your size. Your way.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 22),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'Women', label: Text('WOMEN')),
              ButtonSegment(value: 'Men', label: Text('MEN')),
            ],
            selected: {_gender},
            onSelectionChanged: (selection) =>
                _selectDepartment(selection.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : const Color(0xFF2B6252),
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Color(0xFF174C3C)
                    : Colors.white,
              ),
              side: const WidgetStatePropertyAll(BorderSide.none),
            ),
          ),
        ],
      ),
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

  void _showBag(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shopping bag',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _cartCount == 0
                    ? 'Your bag is empty.'
                    : '$_cartCount item(s) added during this browsing session.',
              ),
              const SizedBox(height: 10),
              const Text(
                'Checkout and order APIs are not connected yet.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, required this.onTap});

  final StoreProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = product.variants.any(
      (variant) => variant.stockQuantity > 0,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: product.imageUrl == null
                      ? _imagePlaceholder()
                      : Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _imagePlaceholder(),
                        ),
                ),
                if (product.isOnSale)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB43B31),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${product.discountPercent}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (!available)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SOLD OUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                _formatPrice(product.currentPrice, product.currencyCode),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: product.isOnSale
                      ? const Color(0xFFB43B31)
                      : Colors.black87,
                ),
              ),
              if (product.isOnSale) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _formatPrice(product.price, product.currencyCode),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFE8E7E2),
    child: const Center(
      child: Icon(Icons.checkroom_outlined, size: 38, color: Colors.black38),
    ),
  );
}

class ProductDetailsSheet extends StatefulWidget {
  const ProductDetailsSheet({
    super.key,
    required this.product,
    required this.onAddToBag,
  });

  final StoreProduct product;
  final void Function(StoreVariant variant) onAddToBag;

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  StoreVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    final availableVariants = widget.product.variants.where(
      (variant) => variant.stockQuantity > 0,
    );
    if (availableVariants.isNotEmpty) {
      _selectedVariant = availableVariants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final sizes = product.variants
        .map((variant) => variant.size)
        .toSet()
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    product.imageUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(height: 40),
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _PriceLine(product: product),
              if (product.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(product.description!),
              ],
              if (sizes.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Size & colour',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.variants.map((variant) {
                    final selected = _selectedVariant?.id == variant.id;
                    return ChoiceChip(
                      label: Text('${variant.size} · ${variant.color}'),
                      selected: selected,
                      onSelected: variant.stockQuantity == 0
                          ? null
                          : (_) => setState(() => _selectedVariant = variant),
                      avatar: variant.stockQuantity == 0
                          ? const Icon(Icons.block, size: 14)
                          : null,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedVariant == null
                      ? null
                      : () {
                          widget.onAddToBag(_selectedVariant!);
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    _selectedVariant == null
                        ? 'Currently unavailable'
                        : 'Add to bag',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        _formatPrice(product.currentPrice, product.currencyCode),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: product.isOnSale ? const Color(0xFFB43B31) : Colors.black87,
        ),
      ),
      if (product.isOnSale) ...[
        const SizedBox(width: 8),
        Text(
          _formatPrice(product.price, product.currencyCode),
          style: const TextStyle(
            color: Colors.black54,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${product.discountPercent}% off',
          style: const TextStyle(
            color: Color(0xFFB43B31),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ],
  );
}

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.api});

  final StoreApi api;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = _register
          ? await widget.api.registerCustomer(
              email: _emailController.text,
              displayName: _nameController.text,
              password: _passwordController.text,
            )
          : await widget.api.login(
              _emailController.text,
              _passwordController.text,
            );
      if (mounted) Navigator.pop(context, session);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is StoreApiException
            ? error.message
            : 'Could not sign in. Check your connection and try again.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _register ? 'Join BigFit' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _register
                    ? 'Create a customer account to get started.'
                    : 'Sign in with your BigFit account.',
              ),
              const SizedBox(height: 20),
              if (_register) ...[
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Enter at least 2 characters.'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                    ? 'Enter a valid email address.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                    value == null || value.length < (_register ? 12 : 1)
                    ? _register
                          ? 'Use at least 12 characters.'
                          : 'Enter your password.'
                    : null,
              ),
              if (_register) ...[
                const SizedBox(height: 8),
                const Text(
                  'Use 12+ characters with uppercase, lowercase, number, and symbol.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFB43B31))),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_register ? 'Create customer account' : 'Sign in'),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _register = !_register;
                        _error = null;
                      }),
                child: Text(
                  _register
                      ? 'Already have an account? Sign in'
                      : 'New to BigFit? Create an account',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatPrice(double amount, String currencyCode) {
  final symbol = switch (currencyCode) {
    'EUR' => '€',
    'USD' => '\$',
    'VND' => '₫',
    _ => '$currencyCode ',
  };
  final decimals = currencyCode == 'VND' ? 0 : 2;
  return '$symbol${amount.toStringAsFixed(decimals)}';
}
