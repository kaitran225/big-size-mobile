import 'package:flutter/material.dart';

import '../map/map_point_picker.dart';
import '../models/store_product.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_dialog.dart';

/// Dialog that creates or edits one delivery address.
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
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _fields = {
      'label': TextEditingController(
        text: address?.label ?? AppStrings.defaultAddressLabel,
      ),
      'recipientName': TextEditingController(
        text: address?.recipientName ?? '',
      ),
      'phoneNumber': TextEditingController(text: address?.phoneNumber ?? ''),
      'addressLine': TextEditingController(text: address?.addressLine ?? ''),
      'city': TextEditingController(text: address?.city ?? ''),
      'province': TextEditingController(text: address?.province ?? ''),
      'postalCode': TextEditingController(text: address?.postalCode ?? ''),
      'countryCode': TextEditingController(
        text: address?.countryCode ?? AppStrings.defaultCountryCode,
      ),
    };
    _latitude = address?.latitude;
    _longitude = address?.longitude;
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
  Widget build(BuildContext context) => AppDialog(
    title: widget.address == null
        ? AppStrings.addAddress
        : AppStrings.editAddressTitle,
    cancelLabel: AppStrings.cancel,
    confirmLabel: AppStrings.save,
    onCancel: () => Navigator.pop(context),
    onConfirm: () {
      if (!_formKey.currentState!.validate()) return;
      Navigator.pop(context, <String, Object?>{
        for (final entry in _fields.entries)
          entry.key: entry.value.text.trim().isEmpty
              ? null
              : entry.value.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'isDefault': _isDefault,
      });
    },
    content: SizedBox(
      width: 460,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.mapLocationPickerHeader,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              MapPointPicker(
                height: 220,
                initialLatitude: _latitude,
                initialLongitude: _longitude,
                onPointChanged: (lat, lng) {
                  setState(() {
                    _latitude = lat;
                    _longitude = lng;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              for (final entry in _fields.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: entry.value,
                    keyboardType: TextInputType.text,
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
                        ? (_) => AppStrings.required
                        : null,
                  ),
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.setAsDefault),
                value: _isDefault,
                onChanged: (value) =>
                    setState(() => _isDefault = value ?? false),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String _addressFieldLabel(String key) => switch (key) {
    'label' => AppStrings.fieldAddressLabel,
    'recipientName' => AppStrings.fieldRecipientName,
    'phoneNumber' => AppStrings.fieldPhoneNumber,
    'addressLine' => AppStrings.fieldAddressLine,
    'city' => AppStrings.fieldCity,
    'province' => AppStrings.fieldProvince,
    'postalCode' => AppStrings.fieldPostalCode,
    'countryCode' => AppStrings.fieldCountryCode,
    _ => key,
  };
}
