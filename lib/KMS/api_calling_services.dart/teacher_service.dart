 
import 'dart:io';
import 'package:dio/dio.dart'; 
import 'package:innovator/KMS/core/constants/api_constants.dart';
import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
import 'package:innovator/KMS/core/constants/network/dio_client.dart';
import 'package:innovator/KMS/model/teacher_model/teacher-profile.dart';
 
class TeacherService extends BaseApiService {
  TeacherService() : super(dio: DioClient.instance);
 

 
  Future<TeacherProfileModel> teacherProfile() async {
    final data = await get<Map<String, dynamic>>(
      ApiConstants.teacherProfile,

    );
    return TeacherProfileModel.fromJson(data);
  }

  
  Future<Map<String, dynamic>> checkIn({required String schoolId}) async {
    return await post<Map<String, dynamic>>(
      ApiConstants.teacherCheckIn,
      data: {
        'school': schoolId,
        'check_in': DateTime.now().toIso8601String(),
      },
    );
  }

 

  Future<Map<String, dynamic>> checkOut({required String schoolId}) async {
    return await post<Map<String, dynamic>>(
      ApiConstants.teacherCheckOut,
      data: {
        'school': schoolId,
        'check_out': DateTime.now().toIso8601String(),
      },
    );
  }

 
Future<Map<String, dynamic>> uploadKyc({required File imageFile}) async {
  final fileName = imageFile.path.split('/').last;

  final formData = FormData.fromMap({
    'id_doc': await MultipartFile.fromFile(
      imageFile.path,
      filename: fileName,
    ),
  });

  return await post<Map<String, dynamic>>(
    ApiConstants.teacherKyc,
    data: formData,                           
    options: Options(
      headers: {
        'Content-Type': 'multipart/form-data', 
      },
    ),
  );
}
}