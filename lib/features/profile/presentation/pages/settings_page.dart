import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  // Privacy settings
  bool _locationSharing = true;
  bool _dataUsage = true;

  // App settings
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Notifications Section
          _buildSection(
            context,
            title: 'Notifications',
            children: [
              _buildSwitchTile(
                context,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications',
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                  // TODO: Save to backend/local storage
                },
              ),
              _buildSwitchTile(
                context,
                title: 'Email Notifications',
                subtitle: 'Receive email notifications',
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                  // TODO: Save to backend/local storage
                },
              ),
              _buildSwitchTile(
                context,
                title: 'SMS Notifications',
                subtitle: 'Receive SMS notifications',
                value: _smsNotifications,
                onChanged: (value) {
                  setState(() {
                    _smsNotifications = value;
                  });
                  // TODO: Save to backend/local storage
                },
              ),
            ],
          ),

          // Privacy Section
          _buildSection(
            context,
            title: 'Privacy',
            children: [
              _buildSwitchTile(
                context,
                title: 'Location Sharing',
                subtitle: 'Allow location sharing for services',
                value: _locationSharing,
                onChanged: (value) {
                  setState(() {
                    _locationSharing = value;
                  });
                  // TODO: Save to backend/local storage
                },
              ),
              _buildSwitchTile(
                context,
                title: 'Data Usage',
                subtitle: 'Optimize data usage',
                value: _dataUsage,
                onChanged: (value) {
                  setState(() {
                    _dataUsage = value;
                  });
                  // TODO: Save to backend/local storage
                },
              ),
            ],
          ),

          // App Section
          _buildSection(
            context,
            title: 'App',
            children: [
              _buildListTile(
                context,
                title: 'Language',
                subtitle: _selectedLanguage,
                leading: const Icon(Icons.language),
                onTap: () {
                  _showLanguageDialog(context);
                },
              ),
              _buildListTile(
                context,
                title: 'Theme',
                subtitle: _selectedTheme,
                leading: const Icon(Icons.palette),
                onTap: () {
                  _showThemeDialog(context);
                },
              ),
              _buildListTile(
                context,
                title: 'Clear Cache',
                subtitle: 'Clear app cache and temporary files',
                leading: const Icon(Icons.delete_outline),
                onTap: () {
                  _clearCache(context);
                },
                isLast: true,
              ),
            ],
          ),

          // Account Section
          _buildSection(
            context,
            title: 'Account',
            children: [
              _buildListTile(
                context,
                title: 'Change Password',
                subtitle: 'Update your password',
                leading: const Icon(Icons.lock_outline),
                onTap: () {
                  _showChangePasswordDialog(context);
                },
              ),
              _buildListTile(
                context,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                leading: const Icon(Icons.delete_forever, color: AppColors.error),
                textColor: AppColors.error,
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget leading,
    required VoidCallback onTap,
    Color? textColor,
    bool isLast = false,
  }) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: textColor != null ? TextStyle(color: textColor) : null,
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: isLast
          ? null
          : const Border(
              bottom: BorderSide(color: AppColors.divider),
            ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languages = ['English', 'Spanish', 'French', 'German'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  Navigator.pop(context);
                  // TODO: Save language preference
                  Helpers.showSnackBar(context, 'Language changed to $value');
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themes = ['Light', 'Dark', 'System'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((theme) {
            return RadioListTile<String>(
              title: Text(theme),
              value: theme,
              groupValue: _selectedTheme,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTheme = value;
                  });
                  Navigator.pop(context);
                  // TODO: Implement theme change
                  Helpers.showSnackBar(context, 'Theme changed to $value');
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement cache clearing
      if (mounted) {
        Helpers.showSuccessSnackBar(context, 'Cache cleared successfully');
      }
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Current password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'New password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                final profileProvider = context.read<ProfileProvider>();
                final success = await profileProvider.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );

                if (mounted) {
                  if (success) {
                    Helpers.showSuccessSnackBar(
                      context,
                      'Password changed successfully',
                    );
                  } else {
                    Helpers.showErrorSnackBar(
                      context,
                      profileProvider.errorMessage ?? 'Failed to change password',
                    );
                  }
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final profileProvider = context.read<ProfileProvider>();
      final success = await profileProvider.deleteAccount();

      if (mounted) {
        if (success) {
          final authProvider = context.read<AuthProvider>();
          await authProvider.logout();
          if (mounted) {
            context.go(RouteConstants.login);
            Helpers.showSnackBar(context, 'Account deleted successfully');
          }
        } else {
          Helpers.showErrorSnackBar(
            context,
            profileProvider.errorMessage ?? 'Failed to delete account',
          );
        }
      }
    }
  }
}

