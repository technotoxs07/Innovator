import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/services/firebase_services.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      developer.log('🚀 Splash screen initializing...');
      
      // Initialize AppData first
      await AppData().initialize();
      
      // Check for Firebase Auth state mismatch (happens after reinstall)
      await _checkAndHandleAuthState();
      
      // Add a small delay to show the splash screen
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Navigate based on final auth state
      if (AppData().isAuthenticated) {
        developer.log('✅ User authenticated, navigating to home');
        _navigateToHome();
      } else {
        developer.log('❌ User not authenticated, navigating to login');
        _navigateToLogin();
      }
    } catch (e) {
      developer.log('❌ Error in splash initialization: $e');
      // On any error, navigate to login for safety
      _navigateToLogin();
    }
  }

  Future<void> _checkAndHandleAuthState() async {
    try {
      developer.log('🔍 Checking auth state consistency...');
      
      // Get Firebase Auth user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      // Get local stored data
      final localAuthToken = AppData().authToken;
      final localUserData = AppData().currentUser;
      
      developer.log('Firebase User: ${firebaseUser?.uid ?? "null"}');
      developer.log('Local Token: ${localAuthToken != null ? "exists" : "null"}');
      developer.log('Local User Data: ${localUserData != null ? "exists" : "null"}');
      
      // Check for mismatch (typically happens after app reinstall)
      if (firebaseUser != null && (localAuthToken == null || localUserData == null)) {
        developer.log('⚠️ Auth state mismatch detected - Firebase user exists but local data missing');
        developer.log('This typically happens after app reinstall');
        
        // Try to restore user data from Firebase/Firestore
        final restored = await _restoreUserDataFromFirebase(firebaseUser);
        
        if (!restored) {
          developer.log('❌ Failed to restore user data - signing out');
          // If restoration fails, sign out completely
          await _signOutCompletely();
        } else {
          developer.log('✅ User data restored successfully');
        }
      } else if (firebaseUser != null && localAuthToken != null && localUserData != null) {
        developer.log('✅ Auth state is consistent - user properly logged in');
        
        // Verify the user exists in Firestore
        await _verifyUserInFirestore(firebaseUser, localUserData);
      } else if (firebaseUser == null && (localAuthToken != null || localUserData != null)) {
        developer.log('⚠️ Local data exists but no Firebase user - clearing local data');
        // Clear local data if no Firebase user
        await AppData().clearAuthToken();
        await AppData().clearCurrentUser();
      } else {
        developer.log('✅ Clean state - no user logged in');
      }
      
    } catch (e) {
      developer.log('❌ Error checking auth state: $e');
      // On error, sign out for safety
      await _signOutCompletely();
    }
  }

  Future<bool> _restoreUserDataFromFirebase(User firebaseUser) async {
    try {
      developer.log('🔄 Attempting to restore user data from Firebase...');
      developer.log('Firebase UID: ${firebaseUser.uid}');
      developer.log('Firebase Email: ${firebaseUser.email}');
      developer.log('Firebase Display Name: ${firebaseUser.displayName}');
      
      // Get fresh ID token
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        developer.log('❌ Failed to get ID token');
        return false;
      }
      
      developer.log('✅ Got fresh ID token');
      
      // Try to get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      
      if (userDoc.exists) {
        developer.log('✅ User document found in Firestore');
        
        final userData = userDoc.data() ?? {};
        
        // Ensure all required fields are present
        userData['_id'] = firebaseUser.uid;
        userData['id'] = firebaseUser.uid;
        userData['userId'] = firebaseUser.uid;
        userData['uid'] = firebaseUser.uid;
        userData['email'] = userData['email'] ?? firebaseUser.email ?? '';
        userData['name'] = userData['name'] ?? firebaseUser.displayName ?? 'User';
        userData['photoURL'] = userData['photoURL'] ?? firebaseUser.photoURL;
        userData['provider'] = userData['provider'] ?? 'google';
        userData['fcmTokens'] = userData['fcmTokens'] ?? [];
        
        // Save to AppData
        await AppData().setAuthToken(idToken);
        await AppData().setCurrentUser(userData);
        
        developer.log('✅ User data saved to AppData');
        
        // Get and save fresh FCM token
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await AppData().saveFcmToken(fcmToken);
            developer.log('✅ FCM token saved');
          }
        } catch (e) {
          developer.log('⚠️ FCM token error (non-critical): $e');
        }
        
        // Initialize FCM after login
        try {
          await AppData().initializeFcmAfterLogin();
        } catch (e) {
          developer.log('⚠️ FCM initialization error (non-critical): $e');
        }
        
        developer.log('✅ User data successfully restored from Firestore');
        return true;
        
      } else {
        developer.log('⚠️ User document not found in Firestore - creating new one');
        
        // Create user document from Firebase Auth data
        final newUserData = {
          '_id': firebaseUser.uid,
          'id': firebaseUser.uid,
          'userId': firebaseUser.uid,
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'name': firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
          'photoURL': firebaseUser.photoURL,
          'provider': 'google',
          'isEmailVerified': firebaseUser.emailVerified,
          'createdAt': DateTime.now().toIso8601String(),
          'fcmTokens': [],
        };
        
        // Create user document in Firestore
        await FirebaseService.verifyAndCreateUser(
          userId: firebaseUser.uid,
          name: newUserData['name'] as String,
          email: newUserData['email'] as String,
          photoURL: firebaseUser.photoURL,
          provider: 'google',
        );
        
        // Save to AppData
        await AppData().setAuthToken(idToken);
        await AppData().setCurrentUser(newUserData);
        
        // Get FCM token
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await AppData().saveFcmToken(fcmToken);
          }
        } catch (e) {
          developer.log('⚠️ FCM error: $e');
        }
        
        developer.log('✅ Created new user data from Firebase Auth');
        return true;
      }
      
    } catch (e) {
      developer.log('❌ Failed to restore user data: $e');
      return false;
    }
  }

  Future<void> _verifyUserInFirestore(User firebaseUser, Map<String, dynamic> localUserData) async {
    try {
      developer.log('🔍 Verifying user in Firestore...');
      
      // Ensure user document exists and is up to date
      await FirebaseService.verifyAndCreateUser(
        userId: localUserData['_id'] ?? firebaseUser.uid,
        name: localUserData['name'] ?? firebaseUser.displayName ?? 'User',
        email: localUserData['email'] ?? firebaseUser.email ?? '',
        phone: localUserData['phone'],
        dob: localUserData['dob'],
        photoURL: localUserData['photoURL'] ?? firebaseUser.photoURL,
        provider: localUserData['provider'] ?? 'email',
      );
      
      // Refresh FCM token if needed
      try {
        final currentToken = AppData().getMostRecentFcmToken();
        if (currentToken == null || currentToken.isEmpty) {
          final newToken = await FirebaseMessaging.instance.getToken();
          if (newToken != null) {
            await AppData().saveFcmToken(newToken);
            developer.log('✅ FCM token refreshed');
          }
        }
      } catch (e) {
        developer.log('⚠️ FCM refresh error: $e');
      }
      
      developer.log('✅ User verified in Firestore');
    } catch (e) {
      developer.log('❌ Error verifying user in Firestore: $e');
    }
  }

  Future<void> _signOutCompletely() async {
    try {
      developer.log('🚪 Signing out completely...');
      
      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();
      
      // Sign out from Google
      try {
        await GoogleSignIn().signOut();
      } catch (e) {
        developer.log('Google sign out error: $e');
      }
      
      // Clear local data
      await AppData().clearAuthToken();
      await AppData().clearCurrentUser();
      
      developer.log('✅ Complete sign out successful');
    } catch (e) {
      developer.log('❌ Error during sign out: $e');
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Homepage()),
    );
  }

  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => LoginPage()), 
        (route) => false
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar color to match splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your app logo
              Image.asset(
                'animation/splash_csreen.gif',
                width: 400,
                height: 400,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(244, 135, 6, 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}