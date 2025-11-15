import 'dart:developer';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:innovator/Innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/Innovator/screens/Feed/Video_Feed.dart';
<<<<<<< HEAD
import 'package:innovator/Innovator/services/InAppNotificationService.dart';
=======
import 'package:innovator/Innovator/services/notifcation_polling_services.dart';
 
>>>>>>> 9d4c90f (foreground notification)
import 'package:innovator/Innovator/widget/FloatingMenuwidget.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
<<<<<<< HEAD
    with SingleTickerProviderStateMixin {
=======
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NotificationPollingService _pollingService = NotificationPollingService();
>>>>>>> 9d4c90f (foreground notification)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check for app updates
    _checkForUpdate();
    
<<<<<<< HEAD
    // ✅ WAIT for GetX to be ready before showing test notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
Future.delayed(const Duration(seconds: 3), () {
      developer.log('🧪 Showing test notification...');
      InAppNotificationService().showNotification(
        title: '✅ Notification System Ready',
        body: 'In-app notifications are working correctly!',
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
        onTap: () {
          developer.log('✅ Test notification tapped');
        },
      );
    });      });
=======
    // Start notification polling
    _startNotificationPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Note: We don't stop polling here as it should continue app-wide
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        log('📱 App resumed - starting notification polling');
        _pollingService.startPolling();
        // Force check immediately when app resumes
        _pollingService.forceCheck();
        break;
      case AppLifecycleState.paused:
        log('⏸️ App paused - stopping notification polling');
        _pollingService.stopPolling();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startNotificationPolling() {
    // Start polling service
    _pollingService.startPolling();
    log('✅ Notification polling started');
    
    // Also do an immediate check
    Future.delayed(const Duration(seconds: 2), () {
      _pollingService.forceCheck();
>>>>>>> 9d4c90f (foreground notification)
    });
  }

  // ✅ ADD: Test notification method
  

  Future<void> _checkForUpdate() async {
    try {
      log('Checking for Update!');

      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        log('Update available!');

        // Check if immediate update is required (for critical updates)
        if (info.immediateUpdateAllowed) {
          _performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          _performFlexibleUpdate();
        }
      } else {
        log('No update available');
      }
    } catch (error) {
      log('Error checking for update: $error');
    }
  }

  Future<void> _performImmediateUpdate() async {
    try {
      log('Starting immediate update');
      await InAppUpdate.performImmediateUpdate();
    } catch (error) {
      log('Immediate update failed: $error');
    }
  }

  Future<void> _performFlexibleUpdate() async {
    try {
      log('Starting flexible update');
      await InAppUpdate.startFlexibleUpdate();

      // Listen for download completion
      InAppUpdate.completeFlexibleUpdate()
          .then((_) {
            log('Flexible update completed');
            _showUpdateCompletedSnackbar();
          })
          .catchError((error) {
            log('Error completing flexible update: $error');
          });
    } catch (error) {
      log('Flexible update failed: $error');
    }
  }

  void _showUpdateCompletedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update downloaded. Restart app to apply changes.'),
        action: SnackBarAction(
          label: 'RESTART',
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
        duration: Duration(seconds: 10),
      ),
    );
  }

  void _navigateToVideoFeed() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VideoFeedPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key: InAppNotificationService().navigatorKey,
      body: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          // Detect swipe from right to left
          if (details.primaryVelocity! < -200) {
            _navigateToVideoFeed();
          }
        },
        child: Stack(
          children: [
            Inner_HomePage(),
            // Add the floating menu widget
            FloatingMenuWidget(),
          ],
        ),
      ),
    );
  }
}