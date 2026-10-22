import 'package:flutter/material.dart';

import 'address_editor.dart';
import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/widgets/app_info_note.dart';
import '../shared/widgets/app_snack_bar.dart';
import '../shared/widgets/error_state_view.dart';
import '../shared/widgets/skeleton_card_list.dart';

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
              : AppStrings.errorLoadAddresses;
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
        showAppErrorSnackBar(
          context,
          error,
          fallback: AppStrings.errorSaveAddress,
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
        showAppErrorSnackBar(
          context,
          error,
          fallback: AppStrings.errorDeleteAddress,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(AppStrings.deliveryAddressesTitle),
      actions: [
        IconButton(
          tooltip: AppStrings.tooltipAddAddress,
          onPressed: () => _editAddress(),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: _loading
        ? const SkeletonCardList()
        : _error != null
        ? ErrorStateView(message: _error!)
        : _addresses.isEmpty
        ? const Center(child: Text(AppStrings.addressesEmpty))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppInfoNote(
                text: AppStrings.mapSdkNotice,
                style: AppInfoNoteStyle.bordered,
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
                      AppStrings.addressWithDefault(
                        address.label,
                        address.isDefault,
                      ),
                    ),
                    subtitle: Text(
                      AppStrings.addressSummary(
                        address.recipientName,
                        address.phoneNumber,
                        address.fullAddress,
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () => _editAddress(address),
                    trailing: IconButton(
                      tooltip: AppStrings.tooltipDeleteAddress,
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
