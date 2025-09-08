import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fieldawy_store/features/authentication/services/auth_service.dart';
import 'package:fieldawy_store/features/home/application/user_data_provider.dart';
import 'package:fieldawy_store/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fieldawy_store/widgets/main_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedIndex = 2;

    return MainScaffold(
      selectedIndex: selectedIndex,
      appBar: AppBar(
        title: Text('profile'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onBackground,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: userDataAsync.when(
            data: (userModel) {
              if (userModel == null) {
                return Center(child: Text('userDataNotFound'.tr()));
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // --- User Info Header ---
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.surfaceVariant,
                          backgroundImage: userModel.photoURL != null &&
                                  userModel.photoURL!.isNotEmpty
                              ? CachedNetworkImageProvider(userModel.photoURL!)
                              : null,
                          child: userModel.photoURL == null ||
                                  userModel.photoURL!.isEmpty
                              ? Icon(Icons.person,
                                  size: 50, color: colorScheme.onSurfaceVariant)
                              : null,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                width: 3),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child:
                                Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userModel.displayName ?? 'N/A',
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (userModel.email != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          userModel.email!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // --- Options List ---
                    Card(
                      elevation: 1,
                      shadowColor:
                          Theme.of(context).shadowColor.withOpacity(0.1),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _buildProfileOption(
                            icon: Icons.edit_outlined,
                            title: 'editProfile'.tr(),
                            onTap: () {},
                          ),
                          const Divider(height: 0, indent: 16, endIndent: 16),
                          // --- تم التعديل هنا ---
                          _buildProfileOption(
                            icon: Icons.notifications_outlined,
                            title: 'notifications'.tr(),
                            onTap: () {},
                          ),
                          const Divider(height: 0, indent: 16, endIndent: 16),
                          // --- وتم التعديل هنا ---
                          _buildProfileOption(
                            icon: Icons.favorite_border,
                            title: 'favorites'.tr(),
                            onTap: () {},
                          ),
                          const Divider(height: 0, indent: 16, endIndent: 16),
                          _buildProfileOption(
                            icon: Icons.settings_outlined,
                            title: 'settings'.tr(),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Logout Section ---
                    Card(
                      elevation: 1,
                      shadowColor:
                          Theme.of(context).shadowColor.withOpacity(0.1),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: _buildProfileOption(
                        icon: Icons.logout,
                        title: 'signOut'.tr(),
                        isDestructive: true,
                        onTap: () {
                          ref.read(authServiceProvider).signOut();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final titleColor =
            isDestructive ? colorScheme.error : colorScheme.onSurface;
        final iconColor =
            isDestructive ? colorScheme.error : colorScheme.primary;

        return ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title,
              style: TextStyle(fontWeight: FontWeight.w500, color: titleColor)),
          trailing: isDestructive
              ? null
              : const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
          onTap: onTap,
        );
      },
    );
  }
}
