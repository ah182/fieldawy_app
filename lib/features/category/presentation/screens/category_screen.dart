import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category')),
      body: Center(child: Text('categoryScreen'.tr())),
    );
  }
}
