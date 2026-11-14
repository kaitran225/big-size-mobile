import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_snack_bar.dart';

/// Administrator console: every account, plus provisioning store staff.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchController = TextEditingController();
  List<UserAccountSummary> _users = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await widget.api.getUsers(search: _searchController.text);
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is StoreApiException
            ? error.message
            : AppStrings.errorRequestFailed;
        _loading = false;
      });
    }
  }

  Future<void> _addStaff() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _StaffAccountDialog(),
    );
    if (result == null) return;
    try {
      await widget.api.createStaff(
        email: result['email']!,
        displayName: result['displayName']!,
        temporaryPassword: result['temporaryPassword']!,
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        AppStrings.staffAccountCreated(result['email']!),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnackBar(
        context,
        error,
        fallback: AppStrings.errorRequestFailed,
      );
    }
  }

  Future<void> _editUser(UserAccountSummary user) async {
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _EditUserDialog(user: user),
    );
    if (result == null) return;
    try {
      await widget.api.saveUser(
        id: user.id,
        displayName: result['displayName']! as String,
        roles: (result['roles']! as List<dynamic>).cast<String>(),
        newPassword: result['newPassword'] as String?,
      );
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnackBar(
        context,
        error,
        fallback: AppStrings.errorRequestFailed,
      );
    }
  }

  Future<void> _deleteUser(UserAccountSummary user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.deleteUserTitle),
        content: Text(AppStrings.deleteUserBody),
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
    try {
      await widget.api.deleteUser(user.id);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnackBar(
        context,
        error,
        fallback: AppStrings.errorRequestFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.usersAndRoles),
        actions: [
          IconButton(
            tooltip: AppStrings.refresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStaff,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(AppStrings.addStaffAccount),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: AppStrings.searchAccounts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: AppStrings.refresh,
                  onPressed: _load,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(child: Text(AppStrings.accountsEmpty));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: _users.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                user.displayName.isEmpty
                    ? '?'
                    : user.displayName.characters.first.toUpperCase(),
              ),
            ),
            title: Text(user.displayName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final role in user.roles)
                      _RoleChip(label: role, isAdmin: user.isAdmin),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editUser(user);
                } else {
                  _deleteUser(user);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(AppStrings.editUser),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(AppStrings.delete),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.isAdmin});

  final String label;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.brandSoft : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StaffAccountDialog extends StatefulWidget {
  const _StaffAccountDialog();

  @override
  State<_StaffAccountDialog> createState() => _StaffAccountDialogState();
}

class _StaffAccountDialogState extends State<_StaffAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.addStaffAccount),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppStrings.staffEmailLabel,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return AppStrings.required;
                  if (!text.contains('@') || !text.contains('.')) {
                    return AppStrings.staffEmailLabel;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _displayName,
                decoration: InputDecoration(
                  labelText: AppStrings.staffDisplayNameLabel,
                ),
                validator: (value) => (value == null || value.trim().length < 2)
                    ? AppStrings.required
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.staffTemporaryPasswordLabel,
                  helperText: AppStrings.staffTemporaryPasswordHelp,
                  helperMaxLines: 2,
                ),
                validator: (value) => (value == null || value.length < 12)
                    ? AppStrings.staffTemporaryPasswordHelp
                    : null,
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
            Navigator.pop(context, {
              'email': _email.text.trim(),
              'displayName': _displayName.text.trim(),
              'temporaryPassword': _password.text,
            });
          },
          child: Text(AppStrings.save),
        ),
      ],
    );
  }
}

/// Edits display name, roles, and optionally resets the password.
class _EditUserDialog extends StatefulWidget {
  const _EditUserDialog({required this.user});

  final UserAccountSummary user;

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayName;
  final _password = TextEditingController();
  late final Set<String> _roles;

  static const _roleOptions = ['Customer', 'StoreStaff', 'Admin'];

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.user.displayName);
    _roles = widget.user.roles.toSet();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  String _roleLabel(String role) => switch (role) {
    'Admin' => AppStrings.roleAdmin,
    'StoreStaff' => AppStrings.roleStoreStaff,
    _ => AppStrings.roleCustomer,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.editUser),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _displayName,
                decoration: InputDecoration(
                  labelText: AppStrings.staffDisplayNameLabel,
                ),
                validator: (value) => (value == null || value.trim().length < 2)
                    ? AppStrings.required
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(AppStrings.rolesLabel),
              for (final role in _roleOptions)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_roleLabel(role)),
                  value: _roles.contains(role),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _roles.add(role);
                    } else {
                      _roles.remove(role);
                    }
                  }),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.newPasswordLabel,
                  helperText: AppStrings.staffTemporaryPasswordHelp,
                  helperMaxLines: 2,
                ),
                validator: (value) {
                  final text = value ?? '';
                  if (text.isEmpty) return null;
                  return text.length < 12
                      ? AppStrings.staffTemporaryPasswordHelp
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
            if (_roles.isEmpty) {
              showAppSnackBar(context, AppStrings.rolesLabel);
              return;
            }

            Navigator.pop(context, <String, Object?>{
              'displayName': _displayName.text.trim(),
              'roles': _roles.toList(growable: false),
              'newPassword': _password.text.isEmpty ? null : _password.text,
            });
          },
          child: Text(AppStrings.save),
        ),
      ],
    );
  }
}
