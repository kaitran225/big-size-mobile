import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/widgets/skeleton_box.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  List<CustomerAddress> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final addresses = await widget.api.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is StoreApiException
              ? error.message
              : 'Could not load addresses.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _editAddress([CustomerAddress? address]) async {
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => AddressEditor(address: address),
    );
    if (result == null) return;
    try {
      await widget.api.saveAddress(result, id: address?.id);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StoreApiException
                  ? error.message
                  : 'Could not save the address.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await widget.api.deleteAddress(id);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StoreApiException
                  ? error.message
                  : 'Could not delete the address.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Delivery addresses'),
      actions: [
        IconButton(
          tooltip: 'Add address',
          onPressed: () => _editAddress(),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: _loading
        ? ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 130),
                    SizedBox(height: 10),
                    SkeletonBox(width: 180),
                    SizedBox(height: 8),
                    SkeletonBox(width: 220),
                  ],
                ),
              ),
            ),
          )
        : _error != null
        ? Center(child: Text(_error!, textAlign: TextAlign.center))
        : _addresses.isEmpty
        ? const Center(child: Text('No delivery addresses saved yet.'))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Map SDK is not configured. You can save optional coordinates manually; saved locations are sent to the backend.',
                  ),
                ),
              ),
              ..._addresses.map(
                (address) => Card(
                  child: ListTile(
                    leading: Icon(
                      address.isDefault
                          ? Icons.location_on
                          : Icons.place_outlined,
                    ),
                    title: Text(
                      '${address.label}${address.isDefault ? ' · Default' : ''}',
                    ),
                    subtitle: Text(
                      '${address.recipientName} · ${address.phoneNumber}\n${address.fullAddress}',
                    ),
                    isThreeLine: true,
                    onTap: () => _editAddress(address),
                    trailing: IconButton(
                      tooltip: 'Delete address',
                      onPressed: () => _deleteAddress(address.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              ),
            ],
          ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _editAddress(),
      child: const Icon(Icons.add),
    ),
  );
}

class AddressEditor extends StatefulWidget {
  const AddressEditor({super.key, this.address});

  final CustomerAddress? address;

  @override
  State<AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<AddressEditor> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _fields = {
      'label': TextEditingController(text: address?.label ?? 'Home'),
      'recipientName': TextEditingController(
        text: address?.recipientName ?? '',
      ),
      'phoneNumber': TextEditingController(text: address?.phoneNumber ?? ''),
      'addressLine': TextEditingController(text: address?.addressLine ?? ''),
      'city': TextEditingController(text: address?.city ?? ''),
      'province': TextEditingController(text: address?.province ?? ''),
      'postalCode': TextEditingController(text: address?.postalCode ?? ''),
      'countryCode': TextEditingController(text: address?.countryCode ?? 'VN'),
      'latitude': TextEditingController(
        text: address?.latitude?.toString() ?? '',
      ),
      'longitude': TextEditingController(
        text: address?.longitude?.toString() ?? '',
      ),
    };
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.address == null ? 'Add address' : 'Edit address'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in _fields.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: entry.value,
                    keyboardType: {'latitude', 'longitude'}.contains(entry.key)
                        ? const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          )
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _addressFieldLabel(entry.key),
                    ),
                    validator:
                        {
                              'label',
                              'recipientName',
                              'phoneNumber',
                              'addressLine',
                              'city',
                              'countryCode',
                            }.contains(entry.key) &&
                            entry.value.text.trim().isEmpty
                        ? (_) => 'Required'
                        : null,
                  ),
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default'),
                value: _isDefault,
                onChanged: (value) =>
                    setState(() => _isDefault = value ?? false),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          final latitude = double.tryParse(_fields['latitude']!.text.trim());
          final longitude = double.tryParse(_fields['longitude']!.text.trim());
          Navigator.pop(context, <String, Object?>{
            for (final entry in _fields.entries)
              if (!{'latitude', 'longitude'}.contains(entry.key))
                entry.key: entry.value.text.trim().isEmpty
                    ? null
                    : entry.value.text.trim(),
            'latitude': latitude,
            'longitude': longitude,
            'isDefault': _isDefault,
          });
        },
        child: const Text('Save'),
      ),
    ],
  );

  String _addressFieldLabel(String key) => switch (key) {
    'label' => 'Address label',
    'recipientName' => 'Recipient name',
    'phoneNumber' => 'Phone number',
    'addressLine' => 'Street address',
    'city' => 'City',
    'province' => 'Province / state',
    'postalCode' => 'Postal code',
    'countryCode' => 'Country code (2 letters)',
    'latitude' => 'Latitude (optional)',
    'longitude' => 'Longitude (optional)',
    _ => key,
  };
}
