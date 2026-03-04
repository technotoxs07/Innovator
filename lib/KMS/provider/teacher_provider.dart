
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/api_calling_services.dart/teacher_service.dart';
import 'package:innovator/KMS/model/teacher_model/teacher-profile.dart';

final teacherServiceProvider = Provider<TeacherService>(
  (_) => TeacherService(),
);

final teacherProfileProvider = FutureProvider<TeacherProfileModel>((ref) {
  return ref.watch(teacherServiceProvider).teacherProfile();
});

 
final checkInProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, schoolId) => ref.read(teacherServiceProvider).checkIn(schoolId: schoolId),
);

final checkOutProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, schoolId) => ref.read(teacherServiceProvider).checkOut(schoolId: schoolId),
);

final kycUploadProvider = FutureProvider.family<Map<String, dynamic>, File>(
  (ref, imageFile) => ref.read(teacherServiceProvider).uploadKyc(imageFile: imageFile),
);