// ignore: unused_import
import 'package:fieldawy_store/features/home/application/user_data_provider.dart';
import 'package:fieldawy_store/widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userDataProvider).asData?.value?.role ?? '';
    final selectedIndex = userRole == 'distributor' ? 1 : 1;

    return MainScaffold(
      selectedIndex: selectedIndex,
      appBar: AppBar(title: const Text('Category')),
      body: Center(child: Text('categoryScreen'.tr())),
    );
  }
}
