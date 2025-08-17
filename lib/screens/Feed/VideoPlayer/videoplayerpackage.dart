import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class NetworkSpeedMonitor {
  static final NetworkSpeedMonitor _instance = NetworkSpeedMonitor._internal();
  factory NetworkSpeedMonitor() => _instance;
  NetworkSpeedMonitor._internal();

  double _currentSpeed = 2.0; // Default moderate speed in Mbps
  Timer? _speedTestTimer;
  final List<double> _speedHistory = [];
  final int _maxHistorySize = 5;
  
  double get currentSpeed => _currentSpeed;
  double get averageSpeed {
    if (_speedHistory.isEmpty) return _currentSpeed;
    return _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;
  }

  void startMonitoring() {
    _speedTestTimer?.cancel();
    _speedTestTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _measureNetworkSpeed();
    });
    // Initial measurement
    _measureNetworkSpeed();
  }

  void stopMonitoring() {
    _speedTestTimer?.cancel();
  }

  Future<void> _measureNetworkSpeed() async {
    try {
      double speed = await _testDownloadSpeed();
      _updateSpeedHistory(speed);
      _currentSpeed = averageSpeed;
      print('Network Speed: ${_currentSpeed.toStringAsFixed(2)} Mbps');
    } catch (e) {
      print('Speed test failed: $e');
      _updateSpeedHistory(1.0); // Assume moderate connection on error
      _currentSpeed = averageSpeed;
    }
  }

  Future<double> _testDownloadSpeed() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test with a small image from a reliable CDN
      final response = await http.get(
        Uri.parse('https://httpbin.org/bytes/50000'), // 50KB test file
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(Duration(seconds: 8));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes.length;
        final timeInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
        final speedBps = bytes / timeInSeconds;
        final speedMbps = (speedBps * 8) / (1024 * 1024);
        return speedMbps.clamp(0.1, 50.0); // Reasonable bounds
      }
    } catch (e) {
      return await _estimateSpeedFromPing();
    }
    
    return 1.0; // Default moderate speed
  }

  Future<double> _estimateSpeedFromPing() async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup('8.8.8.8');
      stopwatch.stop();
      
      if (result.isNotEmpty) {
        final pingMs = stopwatch.elapsedMilliseconds;
        if (pingMs < 50) return 8.0;  // Excellent
        if (pingMs < 100) return 4.0; // Good
        if (pingMs < 200) return 2.0; // Fair
        if (pingMs < 500) return 1.0; // Poor
        return 0.5; // Very poor
      }
    } catch (e) {
      // No connection
    }
    return 1.0;
  }

  void _updateSpeedHistory(double speed) {
    _speedHistory.add(speed);
    if (_speedHistory.length > _maxHistorySize) {
      _speedHistory.removeAt(0);
    }
  }
}

// Video Quality Enum (Keep existing)
enum VideoQuality {
  auto,
  low144p,
  low240p,
  medium360p,
  medium480p,
  high720p,
  high1080p,
}

// Frontend Video Quality Manager
class VideoQualityManager {
  static final VideoQualityManager _instance = VideoQualityManager._internal();
  factory VideoQualityManager() => _instance;
  VideoQualityManager._internal();

  final NetworkSpeedMonitor _speedMonitor = NetworkSpeedMonitor();
  VideoQuality _currentQuality = VideoQuality.auto;
  VideoQuality _selectedQuality = VideoQuality.auto;

  VideoQuality get currentQuality => _currentQuality;
  VideoQuality get selectedQuality => _selectedQuality;

  void setManualQuality(VideoQuality quality) {
    _selectedQuality = quality;
    if (quality != VideoQuality.auto) {
      _currentQuality = quality;
    }
  }

  VideoQuality getOptimalQuality() {
    if (_selectedQuality != VideoQuality.auto) {
      return _selectedQuality;
    }

    final speed = _speedMonitor.averageSpeed;
    
    if (speed >= 6.0) return VideoQuality.high720p;
    if (speed >= 3.0) return VideoQuality.medium480p;
    if (speed >= 1.5) return VideoQuality.medium360p;
    if (speed >= 0.8) return VideoQuality.low240p;
    return VideoQuality.low144p;
  }

  String getQualityLabel(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.auto: return 'Auto';
      case VideoQuality.low144p: return '144p';
      case VideoQuality.low240p: return '240p';
      case VideoQuality.medium360p: return '360p';
      case VideoQuality.medium480p: return '480p';
      case VideoQuality.high720p: return '720p';
      case VideoQuality.high1080p: return '1080p';
    }
  }

  void updateQualityBasedOnSpeed() {
    if (_selectedQuality == VideoQuality.auto) {
      final newQuality = getOptimalQuality();
      if (newQuality != _currentQuality) {
        _currentQuality = newQuality;
        print('Quality adjusted to: ${getQualityLabel(newQuality)}');
      }
    }
  }
}

// Frontend URL Generator for different qualities
class FrontendVideoUrlGenerator {
  // Generate quality-specific URLs by adding parameters
  static String generateQualityUrl(String originalUrl, VideoQuality quality) {
    if (originalUrl.isEmpty) return originalUrl;
    
    final uri = Uri.parse(originalUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    
    // Add quality-specific parameters that many video services recognize
    switch (quality) {
      case VideoQuality.low144p:
        queryParams['quality'] = 'low';
        queryParams['resolution'] = '144p';
        queryParams['maxres'] = '144';
        queryParams['bitrate'] = '200k';
        break;
      case VideoQuality.low240p:
        queryParams['quality'] = 'low';
        queryParams['resolution'] = '240p';
        queryParams['maxres'] = '240';
        queryParams['bitrate'] = '400k';
        break;
      case VideoQuality.medium360p:
        queryParams['quality'] = 'medium';
        queryParams['resolution'] = '360p';
        queryParams['maxres'] = '360';
        queryParams['bitrate'] = '800k';
        break;
      case VideoQuality.medium480p:
        queryParams['quality'] = 'medium';
        queryParams['resolution'] = '480p';
        queryParams['maxres'] = '480';
        queryParams['bitrate'] = '1200k';
        break;
      case VideoQuality.high720p:
        queryParams['quality'] = 'high';
        queryParams['resolution'] = '720p';
        queryParams['maxres'] = '720';
        queryParams['bitrate'] = '2500k';
        break;
      case VideoQuality.high1080p:
        queryParams['quality'] = 'hd';
        queryParams['resolution'] = '1080p';
        queryParams['maxres'] = '1080';
        queryParams['bitrate'] = '5000k';
        break;
      default:
        return originalUrl;
    }
    
    // Add a unique identifier to prevent caching issues
    queryParams['q'] = quality.index.toString();
    queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();
    
    return uri.replace(queryParameters: queryParams).toString();
  }

  // Generate multiple quality URLs from a single original URL
  static Map<VideoQuality, String> generateAllQualityUrls(String originalUrl) {
    final qualityUrls = <VideoQuality, String>{};
    
    for (VideoQuality quality in VideoQuality.values) {
      if (quality != VideoQuality.auto) {
        qualityUrls[quality] = generateQualityUrl(originalUrl, quality);
      }
    }
    
    return qualityUrls;
  }
}