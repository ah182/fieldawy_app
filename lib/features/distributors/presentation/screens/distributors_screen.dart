// ignore: unused_import
import 'package:fieldawy_store/features/home/application/user_data_provider.dart';
import 'package:fieldawy_store/widgets/main_scaffold.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../widgets/shimmer_loader.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fieldawy_store/features/distributors/presentation/screens/distributor_products_screen.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

// نموذج بيانات الموزع - مُحدث
class DistributorModel {
  final String id;
  final String displayName;
  final String? photoURL;
  final String? email;
  final String? companyName;
  final String? distributorType;
  final int productCount;
  final bool isVerified;
  final DateTime? joinDate;
  final String? whatsappNumber; // ✅ تغيير من phoneNumber

  DistributorModel({
    required this.id,
    required this.displayName,
    this.photoURL,
    this.email,
    this.companyName,
    this.distributorType,
    this.productCount = 0,
    this.isVerified = false,
    this.joinDate,
    this.whatsappNumber, // ✅ تغيير من phoneNumber
  });

  factory DistributorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return DistributorModel(
      id: doc.id,
      displayName: data?['displayName'] ?? 'unknownDistributor'.tr(),
      photoURL: data?['photoURL'],
      email: data?['email'],
      companyName: data?['companyName'],
      distributorType: data?['role'],
      productCount: data?['productCount'] ?? 0,
      isVerified: data?['isVerified'] ?? false,
      joinDate: data?['joinDate']?.toDate(),
      whatsappNumber: data?['whatsappNumber'], // ✅ تغيير من phoneNumber
    );
  }
}

// Provider لجلب بيانات الموزعين
final distributorsProvider = StreamProvider<List<DistributorModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', whereIn: ['distributor', 'company'])
      .snapshots()
      .asyncMap((userSnapshot) async {
    if (userSnapshot.docs.isEmpty) {
      return [];
    }

    // 1. Fetch all distributor-product links at once
    final distributorProductsSnapshot =
        await FirebaseFirestore.instance.collection('distributorProducts').get();

    // 2. Count products for each distributor
    final productCounts = <String, int>{};
    for (var doc in distributorProductsSnapshot.docs) {
      final distributorId = doc.data()['distributorId'] as String?;
      if (distributorId != null) {
        productCounts[distributorId] = (productCounts[distributorId] ?? 0) + 1;
      }
    }

    // 3. Map distributors to models with the correct product count
    return userSnapshot.docs.map((distributorDoc) {
      final distributor = DistributorModel.fromFirestore(distributorDoc);
      final count = productCounts[distributor.id] ?? 0;
      return DistributorModel(
        id: distributor.id,
        displayName: distributor.displayName,
        photoURL: distributor.photoURL,
        email: distributor.email,
        companyName: distributor.companyName,
        distributorType: distributor.distributorType,
        productCount: count, // Use the calculated count
        isVerified: distributor.isVerified,
        joinDate: distributor.joinDate,
        whatsappNumber: distributor.whatsappNumber,
      );
    }).toList();
  });
});

class DistributorsScreen extends HookConsumerWidget {
  const DistributorsScreen({super.key});

  String _getRoleLabel(String? role) {
    if (role == 'company') {
      return 'distributionCompany'.tr();
    }
    return 'individualDistributor'.tr();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final distributorsAsync = ref.watch(distributorsProvider);
    final searchQuery = useState<String>('');
    final searchController = useTextEditingController();

    final selectedIndex = 0;

    final filteredDistributors = useMemoized(
      () {
        final distributors = distributorsAsync.asData?.value;
        if (distributors == null) {
          return <DistributorModel>[];
        }
        if (searchQuery.value.isEmpty) {
          return distributors;
        }
        return distributors.where((distributor) {
          final query = searchQuery.value.toLowerCase();
          return distributor.displayName.toLowerCase().contains(query) ||
              (distributor.companyName?.toLowerCase().contains(query) ??
                  false) ||
              (distributor.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      },
      [distributorsAsync, searchQuery.value],
    );

    final sliverAppBar = SliverAppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text(
          'distributors'.tr(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        pinned: true,
        floating: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'searchDistributor'.tr(),
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : Icon(
                        Icons.filter_list,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
      );

    return MainScaffold(
      selectedIndex: selectedIndex,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(distributorsProvider.future),
        child: distributorsAsync.when(
          data: (distributors) {
            return CustomScrollView(
              slivers: [
                sliverAppBar,
                if (distributors.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(context, theme),
                  )
                else if (filteredDistributors.isEmpty && searchQuery.value.isNotEmpty)
                  SliverFillRemaining(
                    child: _buildNoSearchResults(context, theme, searchQuery.value),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _buildStatsHeader(context, theme, filteredDistributors),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final distributor = filteredDistributors[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildDistributorCard(context, theme, distributor),
                        );
                      },
                      childCount: filteredDistributors.length,
                    ),
                  ),
                ]
              ],
            );
          },
          loading: () => CustomScrollView(
            slivers: [
              sliverAppBar,
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
                    child: DistributorCardShimmer(),
                  ),
                  childCount: 8,
                ),
              ),
            ],
          ),
          error: (error, stack) => CustomScrollView(
            slivers: [
              sliverAppBar,
              SliverFillRemaining(
                child: _buildErrorState(context, theme, error.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // إحصائيات سريعة - badge صغير (عدد الموزعين فقط)
  Widget _buildStatsHeader(BuildContext context, ThemeData theme,
      List<DistributorModel> distributors) {
    final totalDistributors = distributors.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'showingAvailableDistributors'.tr(args: [totalDistributors.toString()]),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // كارت الموزع - مُصغر
  Widget _buildDistributorCard(
      BuildContext context, ThemeData theme, DistributorModel distributor) {
    final isCompany = distributor.distributorType == 'company';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        shadowColor: theme.shadowColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            _showDistributorDetails(context, theme, distributor);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // صورة البروفايل - مُصغرة
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.1),
                            theme.colorScheme.secondary.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: distributor.photoURL != null &&
                                distributor.photoURL!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: distributor.photoURL!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  child: const Center(
                                    child: ImageLoadingIndicator(
                                  size: 24,
                                ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  child: Icon(
                                    Icons.person,
                                    size: 30,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              )
                            : Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: Icon(
                                  Icons.person,
                                  size: 30,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                      ),
                    ),
                    // بادج التحقق
                    if (distributor.isVerified)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: theme.colorScheme.surface, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // معلومات الموزع - مُصغرة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم الموزع - خط مُصغر
                      Text(
                        distributor.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 3),

                      // اسم الشركة أو النوع
                      Row(
                        children: [
                          Icon(
                            isCompany ? Icons.business : Icons.person_outline,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              distributor.companyName ?? _getRoleLabel(distributor.distributorType),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // عدد المنتجات - مُصغر
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'productCount'.tr(args: [distributor.productCount.toString()]),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // أيقونة السهم
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // عرض تفاصيل الموزع - تصميم جديد
  void _showDistributorDetails(
      BuildContext context, ThemeData theme, DistributorModel distributor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _buildDistributorDetailsDialog(context, theme, distributor),
    );
  }

  Widget _buildDistributorDetailsDialog(
      BuildContext context, ThemeData theme, DistributorModel distributor) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Header
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.8),
                            theme.colorScheme.primaryContainer.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surface,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: distributor.photoURL != null &&
                                  distributor.photoURL!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: distributor.photoURL!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const ImageLoadingIndicator(size: 24),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.person, size: 60),
                                )
                              : const Icon(Icons.person, size: 60),
                        ),
                      ),
                    ),
                    if (distributor.isVerified)
                      Positioned(
                        top: 155,
                        right: MediaQuery.of(context).size.width / 2 - 50,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                            border: Border.all(
                                color: theme.colorScheme.surface, width: 2),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 70), // Space for avatar

                // Distributor Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        distributor.displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (distributor.companyName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            distributor.companyName!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildInfoCard(theme, isDark, [
                    _buildDetailListTile(
                      theme,
                      Icons.email_outlined,
                      'email'.tr(),
                      distributor.email ?? 'notAvailable'.tr(),
                    ),
                    _buildDetailListTile(
                      theme,
                      Icons.inventory_2_outlined,
                      'numberOfProducts'.tr(),
                      'productCount'.tr(args: [distributor.productCount.toString()]),
                    ),
                    _buildDetailListTile(
                      theme,
                      Icons.business_outlined,
                      'distributorType'.tr(),
                      _getRoleLabel(distributor.distributorType),
                    ),
                    if (distributor.whatsappNumber != null &&
                        distributor.whatsappNumber!.isNotEmpty)
                      _buildDetailListTile(
                        theme,
                        FontAwesomeIcons.whatsapp,
                        'whatsapp'.tr(),
                        distributor.whatsappNumber!,
                      ),
                    if (distributor.joinDate != null)
                      _buildDetailListTile(
                        theme,
                        Icons.calendar_today_outlined,
                        'joinDate'.tr(),
                        DateFormat('dd/MM/yyyy')
                            .format(distributor.joinDate!),
                      ),
                  ]),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    DistributorProductsScreen(
                                  distributor: distributor,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: Text('viewProducts'.tr()),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _openWhatsApp(context, distributor);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                        ),
                        child: const FaIcon(FontAwesomeIcons.whatsapp, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(        children: children,
      ),
    );
  }

  Widget _buildDetailListTile(
      ThemeData theme, IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
    );
  }

  // وظيفة فتح الواتساب
  Future<void> _openWhatsApp(
      BuildContext context, DistributorModel distributor) async {
    final phoneNumber = distributor.whatsappNumber;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'خطأ',
            message: 'phoneNumberNotAvailable'.tr(),
            contentType: ContentType.failure,
          ),
        ),
      );
      return;
    }

    // إزالة أي رموز غير ضرورية من رقم الهاتف
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // رسالة افتراضية
    final message =
        Uri.encodeComponent('whatsappInquiry'.tr());

    // رابط الواتساب
    final whatsappUrl = 'https://wa.me/20$cleanPhone?text=$message';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'خطأ',
            message: 'couldNotOpenWhatsApp'.tr(),
            contentType: ContentType.failure,
          ),
        ),
      );
    }
  }


  // حالة الخطأ
  Widget _buildErrorState(BuildContext context, ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'errorLoadingDistributors'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // إعادة تحميل البيانات
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  // حالة عدم وجود موزعين
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'noDistributorsFound'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // حالة عدم وجود نتائج بحث
  Widget _buildNoSearchResults(
      BuildContext context, ThemeData theme, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'noSearchResults'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'noResultsFor'.tr(args: [query]),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}