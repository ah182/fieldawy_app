import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fieldawy_store/features/authentication/domain/user_model.dart';
import 'package:fieldawy_store/features/authentication/services/auth_service.dart';
import 'package:fieldawy_store/features/home/application/user_data_provider.dart';
import 'package:fieldawy_store/features/settings/presentation/screens/settings_screen.dart';
import 'package:fieldawy_store/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldawy_store/features/products/presentation/screens/my_products_screen.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:fieldawy_store/features/distributors/presentation/screens/distributors_screen.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: userDataAsync.when(
                data: (user) => _buildMenuHeader(context, user),
                loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
                error: (e, s) =>
                    const Text('Error', style: TextStyle(color: Colors.white)),
              ),
            ),
            Expanded(
              child: userDataAsync.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  if (user.role == 'doctor') {
                    return _buildDoctorMenu(context);
                  } else if (user.role == 'distributor') {
                    return _buildDistributorMenu(context);
                  } else {
                    return _buildViewerMenu(context);
                  }
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const Text('Error loading menu',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const Divider(color: Colors.white24, indent: 20, endIndent: 20),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'signOut'.tr(),
              onTap: () {
                ref.read(authServiceProvider).signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// The menu for the distributor
  Widget _buildDistributorMenu(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildMenuItem(
            icon: Icons.home_outlined,
            title: 'home'.tr(),
            onTap: () => ZoomDrawer.of(context)!.close()),
        _buildMenuItem(
            icon: Icons.dashboard_outlined,
            title: 'dashboard'.tr(),
            onTap: () {}),
        _buildMenuItem(
            icon: Icons.inventory_2_outlined, // أيقونة جديدة
            title: 'myMedicines'.tr(),
            onTap: () {
              ZoomDrawer.of(context)!.close();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const MyProductsScreen()));
            }),
        _buildMenuItem(
            icon: Icons.category_outlined,
            title: 'category'.tr(),
            onTap: () {}),
        _buildMenuItem(
            icon: Icons.chat_bubble_outline,
            title: 'chatMode'.tr(),
            onTap: () {}),
        _buildMenuItem(
            icon: Icons.person_outline,
            title: 'profile'.tr(),
            onTap: () {
              ZoomDrawer.of(context)!.close();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ProfileScreen()));
            }),
        _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'settings'.tr(),
            onTap: () {
              ZoomDrawer.of(context)!.close();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SettingsScreen()));
            }),
      ],
    );
  }

  /// The menu for the doctor
  Widget _buildDoctorMenu(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildMenuItem(
            icon: Icons.home_outlined,
            title: 'home'.tr(),
            onTap: () => ZoomDrawer.of(context)!.close()),
        _buildMenuItem(
            icon: Icons.people_alt_outlined,
            title: 'distributors'.tr(),
            onTap: () {
              ZoomDrawer.of(context)!.close();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const DistributorsScreen()));
            }),
        _buildMenuItem(
            icon: Icons.add_box_outlined, title: 'addDrug'.tr(), onTap: () {}),
        _buildMenuItem(
            icon: Icons.category_outlined,
            title: 'category'.tr(),
            onTap: () {}),
        _buildMenuItem(
            icon: Icons.chat_bubble_outline,
            title: 'chatMode'.tr(),
            onTap: () {}),
        _buildMenuItem(
            icon: Icons.person_outline,
            title: 'profile'.tr(),
            onTap: () {
              ZoomDrawer.of(context)!.close();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ProfileScreen()));
            }),
        _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'settings'.tr(),
            onTap: () {
              ZoomDrawer.of(context)!.close();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SettingsScreen()));
            }),
      ],
    );
  }

  /// The menu for the standard viewer
  Widget _buildViewerMenu(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildMenuItem(
            icon: Icons.home_outlined,
            title: 'home'.tr(),
            onTap: () => ZoomDrawer.of(context)!.close()),
        _buildMenuItem(
            icon: Icons.person_outline, title: 'profile'.tr(), onTap: () {}),
      ],
    );
  }

  Widget _buildMenuHeader(BuildContext context, UserModel? user) {
    if (user == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white24,
          child: user.photoURL != null && user.photoURL!.isNotEmpty
              ? ClipOval(child: CachedNetworkImage(imageUrl: user.photoURL!))
              : const Icon(Icons.person, size: 35, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          'helloUser'.tr(namedArgs: {'name': user.displayName ?? ''}),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      splashColor: Colors.white24,
    );
  }
}
