// ignore: unused_import
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/document_upload_controller.dart';
import 'profile_completion_screen.dart';

enum UserRole { doctor, distributor }

class DocumentUploadScreen extends ConsumerStatefulWidget {
  final UserRole role;
  const DocumentUploadScreen({super.key, required this.role});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  bool _isUploading = false;

  Future<void> _onNextPressed() async {
    final selectedImage = ref.read(documentUploadControllerProvider);
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pleaseSelectImageFirst'.tr())),
      );
      return;
    }

    setState(() => _isUploading = true);

    final downloadUrl = await ref
        .read(documentUploadControllerProvider.notifier)
        .uploadSelectedImage();

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (downloadUrl != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ProfileCompletionScreen(
            documentUrl: downloadUrl,
            selectedRole:
                widget.role == UserRole.doctor ? 'doctor' : 'distributor',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('imageUploadFailed'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = widget.role == UserRole.doctor
        ? 'uploadSyndicateCard'.tr()
        : 'uploadNationalId'.tr();

    final selectedImage = ref.watch(documentUploadControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('identityVerification'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(selectedImage, fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Icon(Icons.image_outlined,
                            size: 80, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(documentUploadControllerProvider.notifier)
                      .pickImage(ImageSource.camera, context),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text('camera'.tr()),
                ),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(documentUploadControllerProvider.notifier)
                      .pickImage(ImageSource.gallery, context),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text('gallery'.tr()),
                ),
              ],
            ),
            const Spacer(),
            if (_isUploading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _onNextPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text('next'.tr()),
              ),
          ],
        ),
      ),
    );
  }
}
