// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:innovator/KMS/core/constants/app_style.dart';
// import 'package:innovator/KMS/provider/teacher_provider.dart';

// class KycUploadScreen extends ConsumerStatefulWidget {
//   const KycUploadScreen({super.key});

//   @override
//   ConsumerState<KycUploadScreen> createState() => _KycUploadScreenState();
// }

// class _KycUploadScreenState extends ConsumerState<KycUploadScreen> {
//   File? _selectedImage;
//   bool _isUploading = false;
//   bool _uploadSuccess = false;
//   final ImagePicker _picker = ImagePicker();

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? picked = await _picker.pickImage(
//         source: source,
//         imageQuality: 85,
//         maxWidth: 1500,
//       );
//       if (picked != null) {
//         setState(() {
//           _selectedImage = File(picked.path);
//           _uploadSuccess = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) _showSnack('Could not pick image: $e', isError: true);
//     }
//   }

//   Future<void> _uploadKyc() async {
//     if (_selectedImage == null) return;
//     setState(() => _isUploading = true);
//     try {
//       await ref.read(kycUploadProvider(_selectedImage!).future);
//       setState(() => _uploadSuccess = true);
//       if (mounted) _showSnack('Document uploaded successfully!', isError: false);
//     } catch (e) {
//       if (mounted) _showSnack('Upload failed: $e', isError: true);
//     } finally {
//       setState(() => _isUploading = false);
//     }
//   }

//   void _showSnack(String message, {required bool isError}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(children: [
//           Icon(
//             isError ? Icons.error_outline : Icons.check_circle,
//             color: Colors.white,
//             size: 18,
//           ),
//           const SizedBox(width: 8),
//           Expanded(child: Text(message)),
//         ]),
//         backgroundColor: isError ? Colors.red.shade400 : AppStyle.primaryColor,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   void _showPickerBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Select Document',
//               style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: 'Inter'),
//             ),
//             const SizedBox(height: 20),
//             Row(children: [
//               Expanded(
//                 child: _PickerOption(
//                   icon: Icons.camera_alt_rounded,
//                   label: 'Camera',
//                   onTap: () {
//                     Navigator.pop(context);
//                     _pickImage(ImageSource.camera);
//                   },
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _PickerOption(
//                   icon: Icons.photo_library_rounded,
//                   label: 'Gallery',
//                   onTap: () {
//                     Navigator.pop(context);
//                     _pickImage(ImageSource.gallery);
//                   },
//                 ),
//               ),
//             ]),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8FA),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: GestureDetector(
//           onTap: () => Navigator.pop(context),
//           child: Container(
//             margin: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(Icons.arrow_back_ios_new_rounded,
//                 color: Colors.black87, size: 18),
//           ),
//         ),
//         title: const Text(
//           'KYC Verification',
//           style: TextStyle(
//               color: Colors.black87,
//               fontWeight: FontWeight.bold,
//               fontSize: 17,
//               fontFamily: 'Inter'),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     AppStyle.primaryColor,
//                     AppStyle.primaryColor.withValues(alpha: 0.78),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppStyle.primaryColor.withValues(alpha: 0.3),
//                     blurRadius: 16,
//                     offset: const Offset(0, 6),
//                   ),
//                 ],
//               ),
//               child: Row(children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.2),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: const Icon(Icons.shield_rounded,
//                       color: Colors.white, size: 32),
//                 ),
//                 const SizedBox(width: 16),
//                 const Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Identity Verification',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                             fontFamily: 'Inter'),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         'Upload a clear image of your government-issued ID',
//                         style: TextStyle(
//                             color: Colors.white70,
//                             fontSize: 12,
//                             fontFamily: 'Inter'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ]),
//             ),
//             const SizedBox(height: 28),
//             const Text(
//               'Accepted Documents',
//               style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                   fontFamily: 'Inter',
//                   color: Colors.black87),
//             ),
//             const SizedBox(height: 12),
//             Row(children: [
//               _DocChip(icon: Icons.credit_card_rounded, label: 'National ID'),
//               const SizedBox(width: 10),
//               _DocChip(icon: Icons.book_rounded, label: 'Passport'),
//               const SizedBox(width: 10),
//               _DocChip(
//                   icon: Icons.directions_car_rounded,
//                   label: 'Driving License'),
//             ]),
//             const SizedBox(height: 28),
//             const Text(
//               'Upload Document',
//               style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                   fontFamily: 'Inter',
//                   color: Colors.black87),
//             ),
//             const SizedBox(height: 12),
//             GestureDetector(
//               onTap: _showPickerBottomSheet,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 width: double.infinity,
//                 height: 220,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: _selectedImage != null
//                         ? AppStyle.primaryColor.withValues(alpha: 0.5)
//                         : Colors.grey.shade300,
//                     width: 2,
//                     strokeAlign: BorderSide.strokeAlignInside,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withValues(alpha: 0.04),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: _selectedImage != null
//                     ? ClipRRect(
//                         borderRadius: BorderRadius.circular(18),
//                         child: Stack(
//                           fit: StackFit.expand,
//                           children: [
//                             Image.file(_selectedImage!, fit: BoxFit.cover),
//                             Positioned(
//                               bottom: 0,
//                               left: 0,
//                               right: 0,
//                               child: Container(
//                                 padding:
//                                     const EdgeInsets.symmetric(vertical: 10),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       Colors.black.withValues(alpha: 0.6),
//                                       Colors.transparent,
//                                     ],
//                                     begin: Alignment.bottomCenter,
//                                     end: Alignment.topCenter,
//                                   ),
//                                 ),
//                                 child: const Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(Icons.edit_rounded,
//                                         color: Colors.white, size: 16),
//                                     SizedBox(width: 6),
//                                     Text(
//                                       'Tap to change',
//                                       style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 12,
//                                           fontFamily: 'Inter',
//                                           fontWeight: FontWeight.w500),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                     : Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: AppStyle.primaryColor.withValues(alpha: 0.08),
//                               shape: BoxShape.circle,
//                             ),
//                             child: Icon(Icons.cloud_upload_rounded,
//                                 color: AppStyle.primaryColor, size: 36),
//                           ),
//                           const SizedBox(height: 14),
//                           const Text(
//                             'Tap to upload document',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 14,
//                                 fontFamily: 'Inter',
//                                 color: Colors.black87),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             'JPG, PNG supported · Max 5MB',
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 fontFamily: 'Inter',
//                                 color: Colors.grey.shade500),
//                           ),
//                         ],
//                       ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.blue.shade100),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(children: [
//                     Icon(Icons.lightbulb_rounded,
//                         color: Colors.blue.shade600, size: 18),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Tips for a good photo',
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 13,
//                           fontFamily: 'Inter',
//                           color: Colors.blue.shade700),
//                     ),
//                   ]),
//                   const SizedBox(height: 10),
//                   ...[
//                     'Ensure all 4 corners of the document are visible',
//                     'Take photo in good lighting, avoid glare',
//                     'Make sure the text is clearly readable',
//                   ].map((tip) => Padding(
//                         padding: const EdgeInsets.only(bottom: 5),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Icon(Icons.check_circle,
//                                 color: Colors.blue.shade400, size: 14),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(tip,
//                                   style: TextStyle(
//                                       fontSize: 12,
//                                       fontFamily: 'Inter',
//                                       color: Colors.blue.shade700)),
//                             ),
//                           ],
//                         ),
//                       )),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 32),
//             SizedBox(
//               width: double.infinity,
//               height: 54,
//               child: ElevatedButton(
//                 onPressed:
//                     (_selectedImage == null || _isUploading) ? null : _uploadKyc,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor:
//                       _uploadSuccess ? Colors.green : AppStyle.primaryColor,
//                   disabledBackgroundColor: Colors.grey.shade300,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16)),
//                   elevation: _selectedImage != null ? 4 : 0,
//                   shadowColor: AppStyle.primaryColor.withValues(alpha: 0.4),
//                 ),
//                 child: _isUploading
//                     ? const SizedBox(
//                         width: 22,
//                         height: 22,
//                         child: CircularProgressIndicator(
//                             color: Colors.white, strokeWidth: 2.5),
//                       )
//                     : Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             _uploadSuccess
//                                 ? Icons.check_circle_rounded
//                                 : Icons.upload_rounded,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 10),
//                           Text(
//                             _uploadSuccess
//                                 ? 'Uploaded Successfully'
//                                 : 'Submit Document',
//                             style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                                 fontFamily: 'Inter'),
//                           ),
//                         ],
//                       ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PickerOption extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   const _PickerOption(
//       {required this.icon, required this.label, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 18),
//         decoration: BoxDecoration(
//           color: AppStyle.primaryColor.withValues(alpha: 0.07),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//               color: AppStyle.primaryColor.withValues(alpha: 0.2)),
//         ),
//         child: Column(children: [
//           Icon(icon, color: AppStyle.primaryColor, size: 30),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13,
//                 fontFamily: 'Inter',
//                 color: AppStyle.primaryColor),
//           ),
//         ]),
//       ),
//     );
//   }
// }

// class _DocChip extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _DocChip({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(mainAxisSize: MainAxisSize.min, children: [
//         Icon(icon, size: 14, color: AppStyle.primaryColor),
//         const SizedBox(width: 5),
//         Text(
//           label,
//           style: const TextStyle(
//               fontSize: 11,
//               fontFamily: 'Inter',
//               fontWeight: FontWeight.w500,
//               color: Colors.black87),
//         ),
//       ]),
//     );
//   }
// }



import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';

class KycUploadScreen extends ConsumerStatefulWidget {
  const KycUploadScreen({super.key});

  @override
  ConsumerState<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends ConsumerState<KycUploadScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isUploading = false;
  bool _uploadSuccess = false;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _successController;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  // ─── Permission ───────────────────────────────────────────────────────────

  Future<bool> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied && mounted) {
        _showPermissionDialog(
          title: 'Camera Permission Required',
          message: 'Camera access is permanently denied. Enable it from App Settings.',
        );
        return false;
      }
      if (mounted) _showSnack('Camera permission denied', isError: true);
      return false;
    } else {
      final Permission perm = Platform.isAndroid
          ? (await _isAndroid13Plus() ? Permission.photos : Permission.storage)
          : Permission.photos;
      final status = await perm.request();
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied && mounted) {
        _showPermissionDialog(
          title: 'Gallery Permission Required',
          message: 'Gallery access is permanently denied. Enable it from App Settings.',
        );
        return false;
      }
      if (mounted) _showSnack('Gallery permission denied', isError: true);
      return false;
    }
  }

  Future<bool> _isAndroid13Plus() async {
    try {
      return int.parse(Platform.operatingSystemVersion.split('.').first) >= 13;
    } catch (_) {
      return false;
    }
  }

  // ─── Image Actions ────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final hasPermission = await _requestPermission(source);
    if (!hasPermission) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1500,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _uploadSuccess = false;
        });
        _successController.reset();
      }
    } catch (e) {
      if (mounted) _showSnack('Could not pick image: $e', isError: true);
    }
  }

  void _removeImage() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Document?',
          style: TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to remove the selected document?',
          style: TextStyle(
              fontFamily: 'Inter', fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    TextStyle(fontFamily: 'Inter', color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedImage = null;
                _uploadSuccess = false;
              });
              _successController.reset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove',
                style: TextStyle(fontFamily: 'Inter', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadKyc() async {
    if (_selectedImage == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isUploading = true);
    try {
      await ref.read(kycUploadProvider(_selectedImage!).future);

      setState(() {
        _uploadSuccess = true;
        _isUploading = false;
      });
      await _successController.forward();
      HapticFeedback.heavyImpact();
      if (mounted) {
        _showSnack('Document uploaded successfully!', isError: false);
      }

      // Show success briefly, then auto-clear
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _selectedImage = null;
          _uploadSuccess = false;
        });
        _successController.reset();
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) _showSnack('Upload failed: $e', isError: true);
    }
  }

  // ─── UI Helpers ───────────────────────────────────────────────────────────

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
            ),
          ]),
          backgroundColor:
              isError ? Colors.red.shade400 : Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _showPermissionDialog(
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        content: Text(message,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Inter', color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Open Settings',
                style: TextStyle(fontFamily: 'Inter', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPickerBottomSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Document Source',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter'),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how you want to add your document',
              style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: _PickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  subtitle: 'Take a photo now',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  subtitle: 'Choose from files',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 18),
          ),
        ),
        title: const Text(
          'KYC Verification',
          style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              fontFamily: 'Inter'),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildAcceptedDocs(),
            const SizedBox(height: 28),
            const Text(
              'Upload Document',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildUploadZone(),

            // Change / Remove buttons — only when image selected & not uploading
            if (_selectedImage != null && !_isUploading && !_uploadSuccess) ...[
              const SizedBox(height: 12),
              _buildImageActions(),
            ],

            const SizedBox(height: 24),
            _buildTips(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyle.primaryColor,
            AppStyle.primaryColor.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppStyle.primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.shield_rounded,
              color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identity Verification',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Inter'),
              ),
              SizedBox(height: 4),
              Text(
                'Upload a clear image of your government-issued ID',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Inter'),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildAcceptedDocs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accepted Documents',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Inter',
              color: Colors.black87),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _DocChip(icon: Icons.credit_card_rounded, label: 'National ID'),
            const SizedBox(width: 10),
            _DocChip(icon: Icons.book_rounded, label: 'Passport'),
            const SizedBox(width: 10),
            _DocChip(
                icon: Icons.directions_car_rounded,
                label: 'Driving License'),
          ]),
        ),
      ],
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: (_isUploading || _uploadSuccess) ? null : _showPickerBottomSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _uploadSuccess
                ? Colors.green.withValues(alpha: 0.6)
                : _selectedImage != null
                    ? AppStyle.primaryColor.withValues(alpha: 0.5)
                    : Colors.grey.shade300,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _selectedImage != null
            ? _buildImagePreview()
            : _buildEmptyState(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImage!, fit: BoxFit.cover),

          // ✅ Animated success overlay
          if (_uploadSuccess)
            Container(
              color: Colors.green.withValues(alpha: 0.5),
              child: Center(
                child: ScaleTransition(
                  scale: _successScale,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded,
                        color: Colors.green.shade600, size: 52),
                  ),
                ),
              ),
            ),

          // Uploading overlay
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3),
                    SizedBox(height: 12),
                    Text(
                      'Uploading document...',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // "Tap to change" hint — idle only
          if (!_isUploading && !_uploadSuccess)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Tap to change',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppStyle.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cloud_upload_rounded,
              color: AppStyle.primaryColor, size: 38),
        ),
        const SizedBox(height: 14),
        const Text(
          'Tap to upload your document',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              fontFamily: 'Inter',
              color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(
          'JPG, PNG supported · Max 5MB',
          style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 16),
        // Quick source chips inside empty state
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniSourceChip(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(width: 10),
            _MiniSourceChip(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ],
    );
  }

  /// Change / Remove action row shown below the image preview
  Widget _buildImageActions() {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _showPickerBottomSheet,
          icon: Icon(Icons.swap_horiz_rounded,
              size: 16, color: AppStyle.primaryColor),
          label: Text(
            'Change',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppStyle.primaryColor),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: AppStyle.primaryColor.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _removeImage,
          icon: Icon(Icons.delete_outline_rounded,
              size: 16, color: Colors.red.shade400),
          label: Text(
            'Remove',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.shade200),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    ]);
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_rounded,
                color: Colors.blue.shade600, size: 18),
            const SizedBox(width: 8),
            Text(
              'Tips for a good photo',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  color: Colors.blue.shade700),
            ),
          ]),
          const SizedBox(height: 10),
          ...[
            'Ensure all 4 corners of the document are visible',
            'Take photo in good lighting, avoid glare',
            'Make sure the text is clearly readable',
          ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.blue.shade400, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tip,
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Inter',
                              color: Colors.blue.shade700)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final bool canSubmit =
        _selectedImage != null && !_isUploading && !_uploadSuccess;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: canSubmit ? _uploadKyc : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _uploadSuccess ? Colors.green.shade600 : AppStyle.primaryColor,
          disabledBackgroundColor: _uploadSuccess
              ? Colors.green.shade600
              : Colors.grey.shade200,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: canSubmit ? 4 : 0,
          shadowColor: AppStyle.primaryColor.withValues(alpha: 0.4),
        ),
        child: _isUploading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Inter'),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _uploadSuccess
                        ? Icons.check_circle_rounded
                        : _selectedImage != null
                            ? Icons.upload_rounded
                            : Icons.upload_file_rounded,
                    color: (_selectedImage == null && !_uploadSuccess)
                        ? Colors.grey.shade400
                        : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _uploadSuccess
                        ? 'Uploaded Successfully!'
                        : _selectedImage != null
                            ? 'Submit Document'
                            : 'Select a document first',
                    style: TextStyle(
                        color: (_selectedImage == null && !_uploadSuccess)
                            ? Colors.grey.shade400
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Inter'),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Reusable Widgets ──────────────────────────────────────────────────────────

/// Small pill-shaped chips shown inside the empty upload zone
class _MiniSourceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniSourceChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppStyle.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppStyle.primaryColor.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppStyle.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: AppStyle.primaryColor),
          ),
        ]),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppStyle.primaryColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppStyle.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppStyle.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppStyle.primaryColor, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Inter',
                color: AppStyle.primaryColor),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
                fontSize: 11,
                fontFamily: 'Inter',
                color: AppStyle.primaryColor.withValues(alpha: 0.6)),
          ),
        ]),
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DocChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppStyle.primaryColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Colors.black87),
        ),
      ]),
    );
  }
}