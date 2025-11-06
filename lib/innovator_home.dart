import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:innovator/Innovatorscreens/Feed/Inner_Homepage.dart';
import 'package:innovator/Innovatorscreens/Feed/Video_Feed.dart';
import 'package:innovator/Innovatorwidget/FloatingMenuwidget.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Check for app updates when the widget initializes
    _checkForUpdate();
  }

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
      key: _scaffoldKey,
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
            // Remove FeedToggleButton from Homepage
          ],
        ),
      ),
    );
  }
}