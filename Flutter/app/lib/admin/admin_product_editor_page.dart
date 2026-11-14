import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_snack_bar.dart';

/// Create or edit one catalogue product together with its variants.
class AdminProductEditorPage extends StatefulWidget {
  const AdminProductEditorPage({super.key, required this.api, this.product});

  final StoreApi api;
  final StoreProduct? product;

  @override
  State<AdminProductEditorPage> createState() => _AdminProductEditorPageState();
}

class _VariantDraft {
  _VariantDraft({
    required this.sku,
    required this.size,
    required this.color,
    required this.stockQuantity,
  });

  final String sku;
  String size;
  String color;
  int stockQuantity;
}

class _AdminProductEditorPageState extends State<AdminProductEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _salePrice;
  late final TextEditingController _currency;
  late final TextEditingController _imageUrl;

  late List<_VariantDraft> _variants;
  List<StoreCategory> _categories = const [];
  String? _categoryId;
  bool _isActive = true;
  bool _busy = false;
  bool _loading = true;
  String? _error;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _price = TextEditingController(text: product?.price.toString() ?? '');
    _salePrice = TextEditingController(
      text: product?.isOnSale == true ? product!.currentPrice.toString() : '',
    );
    _currency = TextEditingController(text: product?.currencyCode ?? 'EUR');
    _imageUrl = TextEditingController(text: product?.imageUrl ?? '');
    _categoryId = product?.categoryId;
    _isActive = product?.isActive ?? true;
    _variants = [
      for (final variant in product?.variants ?? const <StoreVariant>[])
        _VariantDraft(
          sku: variant.sku,
          size: variant.size,
          color: variant.color,
          stockQuantity: variant.stockQuantity,
        ),
    ];
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _salePrice.dispose();
    _currency.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.api.getAllCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoryId ??= categories.isNotEmpty ? categories.first.id : null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = appErrorMessage(error, fallback: AppStrings.errorRequestFailed);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = AppStrings.categoryFieldLabel);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final salePriceText = _salePrice.text.trim();
      await widget.api.saveProduct(
        id: widget.product?.id,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        price: double.parse(_price.text.trim()),
        salePrice: salePriceText.isEmpty ? null : double.parse(salePriceText),
        currencyCode: _currency.text.trim().toUpperCase(),
        imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
        categoryId: _categoryId!,
        isActive: _isActive,
        variants: [
          for (final variant in _variants)
            {
              'sku': variant.sku,
              'size': variant.size,
              'color': variant.color,
              'stockQuantity': variant.stockQuantity,
            },
        ],
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = appErrorMessage(error, fallback: AppStrings.errorRequestFailed);
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.deleteProductTitle),
        content: Text(AppStrings.deleteProductBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.api.deleteProduct(widget.product!.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppErrorSnackBar(
        context,
        error,
        fallback: AppStrings.errorRequestFailed,
      );
    }
  }

  Future<void> _editVariant({_VariantDraft? variant}) async {
    final result = await showDialog<_VariantDraft>(
      context: context,
      builder: (_) => _VariantDialog(variant: variant),
    );
    if (result == null) return;
    setState(() {
      if (variant == null) {
        _variants.add(result);
      } else {
        variant
          ..size = result.size
          ..color = result.color
          ..stockQuantity = result.stockQuantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? AppStrings.editProduct : AppStrings.newProduct),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: AppStrings.delete,
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: AppStrings.productNameLabel,
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: AppStrings.productDescriptionLabel,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: AppStrings.priceLabel,
                          ),
                          validator: _positiveNumber,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _salePrice,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: AppStrings.salePriceLabel,
                          ),
                          validator: _optionalNumber,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          controller: _currency,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: AppStrings.currencyLabel,
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            return RegExp(r'^[A-Za-z]{3}$').hasMatch(text)
                                ? null
                                : AppStrings.currencyLabel;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: InputDecoration(
                      labelText: AppStrings.categoryFieldLabel,
                    ),
                    items: [
                      for (final category in _categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text('${category.gender} · ${category.name}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) => value == null ? _required(null) : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _imageUrl,
                    decoration: InputDecoration(
                      labelText: AppStrings.imageUrlLabel,
                    ),
                    validator: _optionalUrl,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppStrings.activeLabel),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.variantsLabel,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _editVariant(),
                        icon: const Icon(Icons.add),
                        label: Text(AppStrings.addVariant),
                      ),
                    ],
                  ),
                  if (_variants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppStrings.noVariants,
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  else
                    for (final variant in _variants)
                      Card(
                        child: ListTile(
                          title: Text(
                            '${variant.size} · ${variant.color}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${variant.sku} · ${AppStrings.stockLabel}: '
                            '${variant.stockQuantity}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: AppStrings.editVariant,
                                onPressed: () => _editVariant(variant: variant),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: AppStrings.delete,
                                onPressed: () => setState(
                                  () => _variants.remove(variant),
                                ),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(
                      _busy ? AppStrings.pleaseWait : AppStrings.save,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? AppStrings.required : null;

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || parsed <= 0 ? AppStrings.priceLabel : null;
  }

  String? _optionalNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) return AppStrings.salePriceLabel;
    final price = double.tryParse(_price.text.trim());
    if (price != null && parsed > price) return AppStrings.salePriceLabel;
    return null;
  }

  String? _optionalUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'))
        ? null
        : AppStrings.imageUrlLabel;
  }
}

class _VariantDialog extends StatefulWidget {
  const _VariantDialog({this.variant});

  final _VariantDraft? variant;

  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sku;
  late final TextEditingController _size;
  late final TextEditingController _color;
  late final TextEditingController _stock;

  @override
  void initState() {
    super.initState();
    _sku = TextEditingController(text: widget.variant?.sku ?? '');
    _size = TextEditingController(text: widget.variant?.size ?? '');
    _color = TextEditingController(text: widget.variant?.color ?? '');
    _stock = TextEditingController(
      text: widget.variant?.stockQuantity.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _sku.dispose();
    _size.dispose();
    _color.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.variant != null;
    return AlertDialog(
      title: Text(editing ? AppStrings.editVariant : AppStrings.addVariant),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _sku,
                enabled: !editing,
                decoration: InputDecoration(labelText: AppStrings.skuLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? AppStrings.required
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _size,
                      decoration: InputDecoration(
                        labelText: AppStrings.sizeLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? AppStrings.required
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _color,
                      decoration: InputDecoration(
                        labelText: AppStrings.colorLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? AppStrings.required
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.stockLabel,
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  return parsed == null || parsed < 0
                      ? AppStrings.stockLabel
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _VariantDraft(
                sku: _sku.text.trim(),
                size: _size.text.trim(),
                color: _color.text.trim(),
                stockQuantity: int.parse(_stock.text.trim()),
              ),
            );
          },
          child: Text(AppStrings.save),
        ),
      ],
    );
  }
}
