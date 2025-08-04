import 'package:flutter/material.dart';

// Option 1: Custom RefreshIndicator with GIF
class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String gifPath;

  const CustomRefreshIndicator({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.gifPath = 'animation/IdeaBulb.gif',
  }) : super(key: key);

  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator>
    with TickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _animationController.forward();

    try {
      await widget.onRefresh();
    } finally {
      await _animationController.reverse();
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.transparent.withOpacity(0.00),
          backgroundColor: Colors.transparent.withOpacity(0.00),
          child: widget.child,
        ),
        // Custom GIF overlay
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            if (!_isRefreshing && _animation.value == 0.0) {
              return SizedBox.shrink();
            }
            
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(0, -80 + (80 * _animation.value)),
                child: Container(
                  height: 80,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        widget.gifPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// // Option 2: Using flutter_pulltorefresh package (recommended)
// // First add to pubspec.yaml: pull_to_refresh: ^2.0.0

// /*
// import 'package:pull_to_refresh/pull_to_refresh.dart';

// class CustomGifHeader extends RefreshIndicator {
//   final String gifPath;
  
//   const CustomGifHeader({
//     this.gifPath = 'assets/animations/loading.gif',
//   });

//   @override
//   Widget build(BuildContext context, RefreshStatus? mode) {
//     Widget body;
//     if (mode == RefreshStatus.idle) {
//       body = Text("Pull down to refresh");
//     } else if (mode == RefreshStatus.refreshing) {
//       body = Container(
//         width: 40,
//         height: 40,
//         child: Image.asset(
//           gifPath,
//           fit: BoxFit.contain,
//         ),
//       );
//     } else if (mode == RefreshStatus.canRefresh) {
//       body = Text("Release to refresh");
//     } else if (mode == RefreshStatus.completed) {
//       body = Text("Refresh completed");
//     } else {
//       body = Text("Failed to refresh");
//     }
    
//     return Container(
//       height: 55.0,
//       child: Center(child: body),
//     );
//   }
// }
// */

// // Option 3: Simple overlay approach (easiest to implement)
// class GifRefreshOverlay extends StatelessWidget {
//   final bool isVisible;
//   final String gifPath;

//   const GifRefreshOverlay({
//     Key? key,
//     required this.isVisible,
//     this.gifPath = 'assets/animations/loading.gif',
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     if (!isVisible) return SizedBox.shrink();

//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 10,
//       left: 0,
//       right: 0,
//       child: Center(
//         child: Container(
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(25),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 24,
//                 height: 24,
//                 child: Image.asset(
//                   gifPath,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Refreshing...',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.grey[700],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }