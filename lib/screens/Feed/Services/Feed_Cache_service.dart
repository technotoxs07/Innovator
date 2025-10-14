// Updated CacheManager with better offline handling and error resilience
import 'package:hive_flutter/hive_flutter.dart';
import 'package:innovator/models/Feed_Content_Model.dart';
import 'package:innovator/screens/Feed/Services/Feed_cached.g.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

class CacheManager {
  static const String feedBoxName = 'feed_cache';
  static const int maxCachedItems = 20;

  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FeedContentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AuthorAdapter());
    }
    await Hive.openBox<FeedContent>(feedBoxName);
  }

  // Enhanced: Check if cache exists and is recent (e.g., less than 24 hours old)
  static Future<bool> hasValidCache() async {
    try {
      final box = Hive.box<FeedContent>(feedBoxName);
      if (box.isEmpty) return false;

      // Optional: Check timestamp of latest item (assuming FeedContent has a createdAt or updatedAt DateTime)
      final latestItem = box.getAt(box.length - 1);
      if (latestItem == null) return false;

      // Example: Consider cache valid if updated within last 24 hours
      final now = DateTime.now();
      final cacheAge = now.difference(latestItem.updatedAt ?? latestItem.createdAt ?? now).inHours;
      return cacheAge < 24;
    } catch (e) {
      developer.log('Error checking cache validity: $e');
      return false;
    }
  }

  static Future<void> cacheFeedContent(List<FeedContent> contents) async {
    final box = Hive.box<FeedContent>(feedBoxName);
    
    // Keep only the most recent items within maxCachedItems limit
    if (box.length > maxCachedItems) {
      final itemsToRemove = box.length - maxCachedItems;
      for (int i = 0; i < itemsToRemove; i++) {
        await box.deleteAt(0);
      }
    }

    // Add new items (avoid duplicates by checking ID if available)
    for (var content in contents) {
      final existing = box.values.firstWhereOrNull((item) => item.id == content.id);
      if (existing == null) {
        await box.add(content);
      } else {
        // Update existing if newer
        if (content.updatedAt?.isAfter(existing.updatedAt ?? DateTime(2000)) ?? false) {
          final index = box.values.toList().indexOf(existing);
          await box.putAt(index, content);
        }
      }
    }
  }

  static Future<List<FeedContent>> getCachedFeed() async {
    final box = Hive.box<FeedContent>(feedBoxName);
    return box.values.toList();
  }

  static Future<void> clearCache() async {
    final box = Hive.box<FeedContent>(feedBoxName);
    await box.clear();
  }
}

// Extension for easier firstWhereOrNull (add this if not available in your utils)
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}