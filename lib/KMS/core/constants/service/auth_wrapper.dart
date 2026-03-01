import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:innovator/KMS/api_calling_services.dart/auth_service.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart';
import 'package:innovator/KMS/screens/dashboard/admin_dashboard_screen.dart';
import 'package:innovator/KMS/screens/dashboard/partner_dashboard_screen.dart';
import 'package:innovator/KMS/screens/dashboard/school_dashboard_screen.dart';
import 'package:innovator/KMS/screens/dashboard/student_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _resolveStartScreen() async {
    try {
      final authService = AuthService();

      final isLoggedIn = await authService.isLoggedIn();

      if (!isLoggedIn) {
        log('🔐 No token found — showing LoginScreen');
        return const LoginScreen();
      }

      final role = await authService.getSavedRole();
      log('🔑 Token found — role: $role — routing to dashboard');

      switch (role?.toLowerCase()) {
        case 'admin':
          return const AdminDashboardScreen();
        case 'partner':
          return const PartnerDashboardScreen();
        case 'school':
          return const SchoolDashboardScreen();
        case 'student':
          return const StudentDashboardScreen();
        default: 
          log('⚠️ Unknown role "$role" — falling back to LoginScreen');
          return const LoginScreen();
      }
    } catch (e) {
      log('❌ AuthWrapper error: $e — falling back to LoginScreen');
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveStartScreen(),
      builder: (context, snapshot) { 
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
 
        if (snapshot.hasError) {
          return const LoginScreen();
        }
 
        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}