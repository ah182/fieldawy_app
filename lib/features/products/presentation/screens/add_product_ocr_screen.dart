import 'dart:io';
import 'package:fieldawy_store/features/authentication/data/storage_service.dart';
import 'package:fieldawy_store/features/authentication/services/auth_service.dart';
import 'package:fieldawy_store/features/home/application/user_data_provider.dart';
import 'package:fieldawy_store/features/products/data/product_repository.dart';
import 'package:fieldawy_store/features/products/domain/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddProductOcrScreen extends ConsumerStatefulWidget {
  const AddProductOcrScreen({super.key});

  @override
  ConsumerState<AddProductOcrScreen> createState() =>
      _AddProductOcrScreenState();
}

class _AddProductOcrScreenState extends ConsumerState<AddProductOcrScreen> {
  // State variables for the new workflow
  File? _selectedImage;
  String? _previewUrl; // Holds the URL for the background-removed preview

  bool _isProcessing = false;
  bool _isFormValid = false;
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _activePrincipleController = TextEditingController();
  final _priceController = TextEditingController();
  final _packageController = TextEditingController();

  final List<String> _packageTypes = [
    'bottle',
    'vial',
    'tab',
    'amp',
    'sachet',
    'strip',
    'cream',
    'gel',
    'spray',
    'drops',
  ];
  String? _selectedPackageType;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _companyController.addListener(_validateForm);
    _activePrincipleController.addListener(_validateForm);
    _priceController.addListener(_validateForm);
    _packageController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid = _previewUrl != null &&
        _nameController.text.isNotEmpty &&
        _companyController.text.isNotEmpty &&
        _activePrincipleController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _packageController.text.isNotEmpty &&
        _selectedPackageType != null;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  Future<File> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final tempJpegPath = p.join(
        tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_temp.jpg');
    final XFile? compressedJpegXFile =
        await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      tempJpegPath,
      quality: 80,
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.jpeg,
    );

    if (compressedJpegXFile == null) {
      return file; // Return original if compression fails
    }
    return File(compressedJpegXFile.path);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    // Set the master processing state to true
    setState(() {
      _isProcessing = true;
      _previewUrl = null;
    });

    try {
      final compressedImage = await _compressImage(File(pickedFile.path));
      
      // Save the selected image
      setState(() {
        _selectedImage = compressedImage;
      });

      // Perform OCR on the local file before uploading
      await _processImage(compressedImage);

      // Upload the temp image to get the secureUrl and publicId
      final storageService = ref.read(storageServiceProvider);
      final tempResult = await storageService.uploadTempImage(compressedImage);
      
      if (tempResult == null) {
        throw Exception("Failed to upload temporary image.");
      }

      // Update state with the new IDs and preview URL.
      setState(() {
        _previewUrl = storageService.buildPreviewUrl(tempResult.secureUrl);
      });
      
      _validateForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    _parseRecognizedText(recognizedText);
  }

  void _parseRecognizedText(RecognizedText recognizedText) {
    _nameController.clear();
    _companyController.clear();
    _activePrincipleController.clear();
    _packageController.clear();

    final lines = recognizedText.blocks.expand((block) => block.lines).toList();
    if (lines.isEmpty) return;

    _nameController.text = lines.first.text;
    if (lines.length > 1) {
      _companyController.text = lines.last.text;
    }

    String tempPackage = '';
    for (final line in lines) {
      final text = line.text.toLowerCase();
      if (text.contains('ml') || text.contains('sachet')) {
        tempPackage += ' ' + line.text;
      }
    }
    _packageController.text = tempPackage.trim();

    if (_nameController.text == _companyController.text && lines.length > 1) {
      _nameController.text = lines[0].text;
    }

    _packageController.text = _packageController.text.trim();
  }

  @override
  void dispose() {
    // In the new approach, temporary images are automatically deleted by Cloudinary
    // We don't need to manually delete them unless there was an error

    _textRecognizer.close();
    _nameController.removeListener(_validateForm);
    _nameController.dispose();
    _companyController.removeListener(_validateForm);
    _companyController.dispose();
    _activePrincipleController.removeListener(_validateForm);
    _activePrincipleController.dispose();
    _priceController.removeListener(_validateForm);
    _priceController.dispose();
    _packageController.removeListener(_validateForm);
    _packageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerBgColor = isDark
        ? Colors.grey.shade800.withOpacity(0.5)
        : Colors.white.withOpacity(0.9);
    final cardElevation = isDark ? 2.0 : 4.0;
    final inputBgColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF8FDFF);
    final inputBorderColor = isDark ? Colors.grey.shade700 : const Color(0xFFE0E6F0);
    final accentColor = theme.colorScheme.primary;
    final priceColor =
        isDark ? Colors.lightGreenAccent.shade200 : Colors.green.shade700;

    final saveButton = Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24.0),
      child: ElevatedButton(
        onPressed: (_isFormValid && !_isProcessing)
            ? () async {
                setState(() {
                  _isProcessing = true;
                });

                try {
                  if (_selectedImage == null) {
                    throw Exception('Please select an image first.');
                  }

                  final storageService = ref.read(storageServiceProvider);
                  final finalUrl =
                      await storageService.uploadFinalImage(_selectedImage!);

                  if (finalUrl == null) {
                    throw Exception('Failed to make image permanent.');
                  }

                  final name = _nameController.text;
                  final company = _companyController.text;
                  final activePrinciple = _activePrincipleController.text;
                  String package = _packageController.text;
                  final price = double.tryParse(_priceController.text);

                  if (price == null) {
                    throw Exception('Invalid price format.');
                  }

                  if (_selectedPackageType != null &&
                      !package
                          .toLowerCase()
                          .contains(_selectedPackageType!.toLowerCase())) {
                    package = '${package.trim()} $_selectedPackageType'.trim();
                  }

                  final newProduct = ProductModel(
                    id: '',
                    name: name,
                    company: company,
                    activePrinciple: activePrinciple,
                    imageUrl: finalUrl,
                    package: package,
                    availablePackages: [package],
                  );

                  final productRepo = ref.read(productRepositoryProvider);
                  final newProductId =
                      await productRepo.addProductToCatalog(newProduct);

                  final userId = ref.read(authServiceProvider).currentUser?.uid;
                  final userData = await ref.read(userDataProvider.future);
                  final distributorName =
                      userData?.displayName ?? 'Unknown Distributor';

                  if (userId != null) {
                    await productRepo.addProductToDistributorCatalog(
                      distributorId: userId,
                      distributorName: distributorName,
                      productId: newProductId,
                      package: package,
                      price: price,
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Product added successfully!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save product: $e'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                } finally {
                  setState(() {
                    _isProcessing = false;
                  });
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(double.infinity, 54),
          elevation: _isFormValid && !_isProcessing ? 4 : 0,
          shadowColor: theme.colorScheme.primary.withOpacity(0.5),
        ).merge(
          ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return theme.colorScheme.onSurface.withOpacity(0.12);
                }
                return theme.colorScheme.primary;
              },
            ),
            foregroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return theme.colorScheme.onSurface.withOpacity(0.38);
                }
                return Colors.white;
              },
            ),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Save Product',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Product',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        scrolledUnderElevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(1),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: inputBorderColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _previewUrl != null ? Icons.image : Icons.photo_camera,
                            color: _previewUrl != null
                                ? accentColor
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _previewUrl != null
                                  ? 'Product Image Selected'
                                  : 'Take product photo',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _previewUrl != null
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isProcessing)
                      SizedBox(
                        height: 250,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                            strokeWidth: 4.0,
                          ),
                        ),
                      )
                      else if (_previewUrl != null)
                      SizedBox(
                        height: 250,
                        child: CachedNetworkImage(
                          imageUrl: _previewUrl!,
                          fit: BoxFit.contain,
                          progressIndicatorBuilder: (context, url, progress) => Center(
                            child: CircularProgressIndicator(
                              value: progress.progress,
                              color: accentColor,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: inputBgColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 44,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No image selected',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select an image to begin extraction',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed:
                            _isProcessing ? null : _showImageSourceDialog,
                        icon: Icon(
                          _isProcessing
                              ? Icons.hourglass_bottom
                              : Icons.camera_alt,
                          color: _isProcessing ? Colors.white60 : Colors.white,
                        ),
                        label: Text(
                          _isProcessing ? 'Processing...' : 'Scan Product',
                          style: TextStyle(
                            color:
                                _isProcessing ? Colors.white60 : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: accentColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Product Information',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in or verify the extracted details',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: containerBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Product Name',
                                hintText: 'e.g., diflam',
                                prefixIcon: Icon(
                                  Icons.medical_services,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              controller: _companyController,
                              decoration: InputDecoration(
                                labelText: 'Company',
                                hintText: 'e.g., Adwia',
                                prefixIcon: Icon(
                                  Icons.business,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              controller: _activePrincipleController,
                              decoration: InputDecoration(
                                labelText: 'Active Principle',
                                hintText: 'e.g., Amoxicillin',
                                prefixIcon: Icon(
                                  Icons.science,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      color: inputBorderColor,
                      margin: const EdgeInsets.only(right: 16, left: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Package Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              controller: _packageController,
                              decoration: InputDecoration(
                                labelText: 'Package Description',
                                hintText: 'e.g., 100 mL or 50 ml',
                                prefixIcon: Icon(
                                  Icons.content_paste,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedPackageType,
                            decoration: InputDecoration(
                              labelText: 'Package Type',
                              prefixIcon: Icon(
                                FontAwesomeIcons.boxesPacking,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: accentColor,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: inputBgColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: _packageTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getPackageIconData(type),
                                      size: 18,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(type),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedPackageType = newValue;
                              });
                              _validateForm();
                            },
                          ),
                          const SizedBox(height: 16),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Price',
                                hintText: 'Enter price in EGP',
                                prefixIcon: Icon(
                                  Icons.price_check,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                suffixText: 'EGP',
                                suffixStyle: TextStyle(
                                  color: priceColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: priceColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            saveButton,
          ],
        ),
      ),
    );
  }

  IconData _getPackageIconData(String type) {
    switch (type) {
      case 'bottle':
        return FontAwesomeIcons.prescriptionBottle;
      case 'vial':
        return FontAwesomeIcons.vial;
      case 'tab':
        return FontAwesomeIcons.tablet;
      case 'amp':
        return FontAwesomeIcons.syringe;
      case 'sachet':
        return FontAwesomeIcons.sackXmark;
      case 'strip':
        return FontAwesomeIcons.list;
      case 'box':
        return FontAwesomeIcons.box;

      case 'cream':
        return FontAwesomeIcons.cheese;
      case 'gel':
        return FontAwesomeIcons.flask;
      case 'spray':
        return FontAwesomeIcons.sprayCan;
      case 'drops':
        return FontAwesomeIcons.droplet;
      case 'suppository':
        return FontAwesomeIcons.pills;
      case 'injection':
        return FontAwesomeIcons.syringe;
      case 'kit':
        return FontAwesomeIcons.suitcaseMedical;
      default:
        return FontAwesomeIcons.box;
    }
  }
}