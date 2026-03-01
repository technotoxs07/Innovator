import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/api_calling_services.dart/teacher_service.dart';
import 'package:innovator/KMS/model/teacher_model/teacher-profile.dart'; 

final teacherServiceProvider = Provider<TeacherService>(
  (ref) => TeacherService(),
);

final teacherProfileProvider = FutureProvider<TeacherProfileModel>((ref) {
  final service = ref.watch(teacherServiceProvider);
  return service.teacherProfile();
});