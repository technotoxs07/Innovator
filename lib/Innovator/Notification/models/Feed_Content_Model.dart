import 'dart:developer' as developer;

import 'package:innovator/Innovatormodels/Author_model.dart';
import 'package:innovator/Innovatorscreens/Feed/Inner_Homepage.dart';

class FeedContent {
  final String id;
  String status;
  final String type;
  final List<String> files;
  final List<dynamic> optimizedFiles;
  final Author author;
  final DateTime createdAt;
  final DateTime updatedAt;
  int views;
  bool isShared;
  int likes;
  int comments;
  bool isLiked;
  bool isFollowed;
  bool engagementLoaded;
  String loadPriority;

  late final List<String> _mediaUrls;
  late final bool _hasImages;
  late final bool _hasVideos;
  late final bool _hasPdfs;
  late final bool _hasWordDocs;

  FeedContent({
    required this.id,
    required this.status,
    required this.type,
    required this.files,
    required this.optimizedFiles,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.views = 0,
    this.isShared = false,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isFollowed = false,
    this.engagementLoaded = false,
    this.loadPriority = 'normal',
  }) {
    try {
      final allUrls = [
        ...files.map((file) => formatUrl(file)),
        ...optimizedFiles
            .where((file) => file != null && file is Map && file['url'] != null)
            .map((file) => formatUrl(file['url'])),
      ];

      _mediaUrls = allUrls.toSet().toList();

      _hasImages =
          _mediaUrls.any((url) => FileTypeHelper.isImage(url)) ||
          optimizedFiles.any(
            (file) => file != null && file is Map && file['type'] == 'image',
          );

      _hasVideos =
          _mediaUrls.any((url) => FileTypeHelper.isVideo(url)) ||
          optimizedFiles.any(
            (file) => file != null && file is Map && file['type'] == 'video',
          );

      _hasPdfs =
          _mediaUrls.any((url) => FileTypeHelper.isPdf(url)) ||
          optimizedFiles.any(
            (file) => file != null && file is Map && file['type'] == 'pdf',
          );

      _hasWordDocs = _mediaUrls.any((url) => FileTypeHelper.isWordDoc(url));
    } catch (e) {
      _mediaUrls = [];
      _hasImages = false;
      _hasVideos = false;
      _hasPdfs = false;
      _hasWordDocs = false;
      developer.log('Error initializing FeedContent media: $e');
    }
  }

  String formatUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    }
    return 'http://182.93.94.210:3067${url.startsWith('/') ? url : '/$url'}';
  }

  factory FeedContent.fromJson(Map<String, dynamic> json) {
    try {
      // Enhanced error handling for user interactions
      final userInteractions =
          json['userInteractions'] as Map<String, dynamic>? ?? {};

      return FeedContent(
        id: json['_id'] ?? '',
        status: json['status'] ?? '',
        type: json['type'] ?? 'innovation',
        files: List<String>.from(json['files'] ?? []),
        optimizedFiles: List<dynamic>.from(json['optimizedFiles'] ?? []),
        author: Author.fromJson(json['author'] ?? {}),
        createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          json['updatedAt'] ?? DateTime.now().toIso8601String(),
        ),
        views: json['views'] ?? 0,
        isShared: json['isShared'] ?? false,
        likes: json['likes'] ?? 0,
        comments: json['comments'] ?? 0,
        isLiked: json['liked'] ?? userInteractions['liked'] ?? false,
        isFollowed: userInteractions['followed'] ?? false,
        engagementLoaded: json['engagementLoaded'] ?? false,
        loadPriority: json['loadPriority'] ?? 'normal',
      );
    } catch (e) {
      developer.log('Error parsing FeedContent: $e');
      return FeedContent(
        id: '',
        status: '',
        type: '',
        files: [],
        optimizedFiles: [],
        author: Author(id: '', name: 'Error', email: '', picture: ''),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  List<String> get mediaUrls => _mediaUrls;
  bool get hasImages => _hasImages;
  bool get hasVideos => _hasVideos;
  bool get hasPdfs => _hasPdfs;
  bool get hasWordDocs => _hasWordDocs;

  String? get bestVideoUrl {
    try {
      final videoFiles =
          optimizedFiles
              .where(
                (file) =>
                    file != null && file is Map && file['type'] == 'video',
              )
              .toList();
      if (videoFiles.isEmpty) return null;

      videoFiles.sort((a, b) {
        final aQualities = List<String>.from(a['qualities'] ?? []);
        final bQualities = List<String>.from(b['qualities'] ?? []);
        return bQualities.length.compareTo(aQualities.length);
      });

      return formatUrl(
        videoFiles.first['url'] ?? videoFiles.first['hls'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  String? get thumbnailUrl {
    try {
      for (final file in optimizedFiles) {
        if (file != null && file is Map && file['thumbnail'] != null) {
          return formatUrl(file['thumbnail']);
        }
      }

      final imageUrl = _mediaUrls.firstWhere(
        (url) => FileTypeHelper.isImage(url),
        orElse: () => '',
      );

      return imageUrl.isNotEmpty ? imageUrl : null;
    } catch (e) {
      return null;
    }
  }
}