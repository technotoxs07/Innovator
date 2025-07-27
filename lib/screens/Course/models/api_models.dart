// models/api_models.dart - Updated for new API structure

import 'package:flutter/material.dart';

// Updated ParentCategory model for new API response
class ParentCategory {
  final String id;
  final String name;
  final String description;
  final String slug;
  final String icon;
  final String color;
  final bool isActive;
  final int sortOrder;
  final List<String> keywords;
  final CreatedBy createdBy;
  final Statistics statistics;
  final String createdAt;
  final String updatedAt;

  ParentCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.slug,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.sortOrder,
    required this.keywords,
    required this.createdBy,
    required this.statistics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentCategory.fromJson(Map<String, dynamic> json) {
    return ParentCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#FF5733',
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
      keywords: (json['keywords'] as List?)?.cast<String>() ?? [],
      createdBy: CreatedBy.fromJson(json['createdBy'] ?? {}),
      statistics: Statistics.fromJson(json['statistics'] ?? {}),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class CreatedBy {
  final String id;
  final String email;
  final String name;

  CreatedBy({
    required this.id,
    required this.email,
    required this.name,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class Statistics {
  final int courses;
  final int lessons;
  final int notes;
  final int videos;

  Statistics({
    required this.courses,
    required this.lessons,
    required this.notes,
    required this.videos,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      courses: json['courses'] ?? 0,
      lessons: json['lessons'] ?? 0,
      notes: json['notes'] ?? 0,
      videos: json['videos'] ?? 0,
    );
  }
}

// Add CategoryInfo class here
class CategoryInfo {
  final String id;
  final String name;
  final String slug;
  final String? description;

  CategoryInfo({
    required this.id, 
    required this.name, 
    required this.slug,
    this.description,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
    );
  }
}

// Course model for category courses response
class Course {
  final String id;
  final String title;
  final String description;
  final Price price;
  final String thumbnail;
  final String? overviewVideo;
  final String overviewVideoDuration;
  final dynamic categoryId; // Can be String or CategoryInfo object
  final List<Lesson> lessons;
  final Instructor instructor;
  final Author author;
  final String level;
  final String language;
  final List<String> tags;
  final List<String> prerequisites;
  final List<String> learningOutcomes;
  final List<String> targetAudience;
  final bool isPublished;
  final int enrollmentCount;
  final Rating rating;
  final Settings settings;
  final List<dynamic> courseVideos;
  final List<dynamic> coursePDFs;
  final ContentStatistics? contentStatistics; // Make nullable
  final String createdAt;
  final String updatedAt;
  final CategoryInfo? category; // Add category field

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.thumbnail,
    this.overviewVideo,
    required this.overviewVideoDuration,
    required this.categoryId,
    required this.lessons,
    required this.instructor,
    required this.author,
    required this.level,
    required this.language,
    required this.tags,
    required this.prerequisites,
    required this.learningOutcomes,
    required this.targetAudience,
    required this.isPublished,
    required this.enrollmentCount,
    required this.rating,
    required this.settings,
    required this.courseVideos,
    required this.coursePDFs,
    this.contentStatistics,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: Price.fromJson(json['price'] ?? {}),
      thumbnail: json['thumbnail'] ?? '',
      overviewVideo: json['overviewVideo'],
      overviewVideoDuration: json['overviewVideoDuration'] ?? '00:00:00',
      categoryId: json['categoryId'], // Keep as dynamic
      lessons: (json['lessons'] as List?)
          ?.map((lesson) => Lesson.fromJson(lesson))
          .toList() ?? [],
      instructor: Instructor.fromJson(json['instructor'] ?? {}),
      author: Author.fromJson(json['author'] ?? {}),
      level: json['level'] ?? '',
      language: json['language'] ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      prerequisites: (json['prerequisites'] as List?)?.cast<String>() ?? [],
      learningOutcomes: (json['learningOutcomes'] as List?)?.cast<String>() ?? [],
      targetAudience: (json['targetAudience'] as List?)?.cast<String>() ?? [],
      isPublished: json['isPublished'] ?? false,
      enrollmentCount: json['enrollmentCount'] ?? 0,
      rating: Rating.fromJson(json['rating'] ?? {}),
      settings: Settings.fromJson(json['settings'] ?? {}),
      courseVideos: json['courseVideos'] ?? [],
      coursePDFs: json['coursePDFs'] ?? [],
      contentStatistics: json['contentStructure'] != null 
          ? ContentStatistics.fromJson(json['contentStructure'])
          : ContentStatistics(), // Provide default instance
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      category: json['category'] != null 
          ? CategoryInfo.fromJson(json['category'])
          : null,
    );
  }
}

class Price {
  final double usd;
  final double npr;

  Price({required this.usd, required this.npr});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      usd: (json['usd'] ?? 0).toDouble(),
      npr: (json['npr'] ?? 0).toDouble(),
    );
  }
}

class Instructor {
  final String name;
  final String bio;
  final List<String> credentials;

  Instructor({required this.name, required this.bio, required this.credentials});

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      credentials: (json['credentials'] as List?)?.cast<String>() ?? [],
    );
  }
}

class Author {
  final String id;
  final String email;
  final String phone;

  Author({required this.id, required this.email, required this.phone});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? 'Not provided',
    );
  }
}

class Rating {
  final double average;
  final int count;

  Rating({required this.average, required this.count});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      average: (json['average'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class Settings {
  final bool allowDownloads;
  final bool certificateEnabled;

  Settings({
    required this.allowDownloads,
    required this.certificateEnabled,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      allowDownloads: json['allowDownloads'] ?? false,
      certificateEnabled: json['certificateEnabled'] ?? true,
    );
  }
}

class ContentStatistics {
  final int totalLessons;
  final int totalLessonVideos;
  final int totalLessonNotes;
  final int totalCourseVideos;
  final int totalCoursePDFs;
  final int totalVideos;
  final int totalPDFs;
  final bool hasOverviewVideo;
  final String overviewVideoDuration;

  ContentStatistics({
    this.totalLessons = 0,
    this.totalLessonVideos = 0,
    this.totalLessonNotes = 0,
    this.totalCourseVideos = 0,
    this.totalCoursePDFs = 0,
    this.totalVideos = 0,
    this.totalPDFs = 0,
    this.hasOverviewVideo = false,
    this.overviewVideoDuration = '00:00:00',
  });

  factory ContentStatistics.fromJson(Map<String, dynamic> json) {
    return ContentStatistics(
      totalLessons: json['totalLessons'] ?? 0,
      totalLessonVideos: json['totalLessonVideos'] ?? 0,
      totalLessonNotes: json['totalLessonNotes'] ?? 0,
      totalCourseVideos: json['totalCourseVideos'] ?? 0,
      totalCoursePDFs: json['totalCoursePDFs'] ?? 0,
      totalVideos: json['totalVideos'] ?? 0,
      totalPDFs: json['totalPDFs'] ?? 0,
      hasOverviewVideo: json['hasOverviewVideo'] ?? false,
      overviewVideoDuration: json['overviewVideoDuration'] ?? '00:00:00',
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final int sortOrder;
  final String duration;
  final bool isPublished;
  final List<Note> notes;
  final List<Video> videos;
  final LessonMetadata metadata;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.duration,
    required this.isPublished,
    required this.notes,
    required this.videos,
    required this.metadata,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      duration: json['duration'] ?? '',
      isPublished: json['isPublished'] ?? false,
      notes: (json['notes'] as List?)
          ?.map((note) => Note.fromJson(note))
          .toList() ?? [],
      videos: (json['videos'] as List?)
          ?.map((video) => Video.fromJson(video))
          .toList() ?? [],
      metadata: LessonMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class LessonMetadata {
  final int estimatedTime;
  final String difficulty;

  LessonMetadata({required this.estimatedTime, required this.difficulty});

  factory LessonMetadata.fromJson(Map<String, dynamic> json) {
    return LessonMetadata(
      estimatedTime: json['estimatedTime'] ?? 0,
      difficulty: json['difficulty'] ?? '',
    );
  }
}

class Note {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType;
  final int sortOrder;
  final bool premium;
  final NoteMetadata metadata;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    required this.sortOrder,
    required this.premium,
    required this.metadata,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      premium: json['premium'] ?? false,
      metadata: NoteMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class NoteMetadata {
  final String fileSize;
  final int downloadCount;
  final String uploadedAt;

  NoteMetadata({
    required this.fileSize,
    required this.downloadCount,
    required this.uploadedAt,
  });

  factory NoteMetadata.fromJson(Map<String, dynamic> json) {
    return NoteMetadata(
      fileSize: json['fileSize'] ?? 'Unknown',
      downloadCount: json['downloadCount'] ?? 0,
      uploadedAt: json['uploadedAt'] ?? '',
    );
  }
}

class Video {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnail;
  final String duration;
  final int sortOrder;
  final VideoMetadata metadata;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnail,
    required this.duration,
    required this.sortOrder,
    required this.metadata,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? '00:00:00',
      sortOrder: json['sortOrder'] ?? 0,
      metadata: VideoMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class VideoMetadata {
  final String quality;
  final String fileSize;
  final int viewCount;
  final int durationSeconds;
  final int width;
  final int height;
  final String aspectRatio;
  final int bitrate;
  final String codec;
  final String format;
  final String uploadedAt;

  VideoMetadata({
    required this.quality,
    required this.fileSize,
    required this.viewCount,
    required this.durationSeconds,
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.bitrate,
    required this.codec,
    required this.format,
    required this.uploadedAt,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      quality: json['quality'] ?? 'unknown',
      fileSize: json['fileSize'] ?? '0',
      viewCount: json['viewCount'] ?? 0,
      durationSeconds: json['durationSeconds'] ?? 0,
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      aspectRatio: json['aspectRatio'] ?? 'unknown',
      bitrate: json['bitrate'] ?? 0,
      codec: json['codec'] ?? 'unknown',
      format: json['format'] ?? 'unknown',
      uploadedAt: json['uploadedAt'] ?? '',
    );
  }
}

// Course detail response models
class CourseDetailResponse {
  final int status;
  final CourseDetailData data;
  final String? error;
  final String message;

  CourseDetailResponse({
    required this.status,
    required this.data,
    this.error,
    required this.message,
  });

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) {
    return CourseDetailResponse(
      status: json['status'] ?? 0,
      data: CourseDetailData.fromJson(json['data'] ?? {}),
      error: json['error'],
      message: json['message'] ?? '',
    );
  }
}

class CourseDetailData {
  final Course course;
  final List<Lesson> lessons;
  final Lesson? selectedLesson;
  final List<Note> lessonNotes;
  final List<Video> lessonVideos;

  CourseDetailData({
    required this.course,
    required this.lessons,
    this.selectedLesson,
    required this.lessonNotes,
    required this.lessonVideos,
  });

  factory CourseDetailData.fromJson(Map<String, dynamic> json) {
    return CourseDetailData(
      course: Course.fromJson(json['course'] ?? {}),
      lessons: (json['lessons'] as List?)
          ?.map((lesson) => Lesson.fromJson(lesson))
          .toList() ?? [],
      selectedLesson: json['selectedLesson'] != null 
          ? Lesson.fromJson(json['selectedLesson'])
          : null,
      lessonNotes: (json['lessonNotes'] as List?)
          ?.map((note) => Note.fromJson(note))
          .toList() ?? [],
      lessonVideos: (json['lessonVideos'] as List?)
          ?.map((video) => Video.fromJson(video))
          .toList() ?? [],
    );
  }
}

// Category courses response
class CategoryCoursesResponse {
  final int status;
  final CategoryCoursesData data;
  final String? error;
  final String message;

  CategoryCoursesResponse({
    required this.status,
    required this.data,
    this.error,
    required this.message,
  });

  factory CategoryCoursesResponse.fromJson(Map<String, dynamic> json) {
    return CategoryCoursesResponse(
      status: json['status'] ?? 0,
      data: CategoryCoursesData.fromJson(json['data'] ?? {}),
      error: json['error'],
      message: json['message'] ?? '',
    );
  }
}

class CategoryCoursesData {
  final ParentCategory category;
  final List<Course> courses;
  final Pagination pagination;

  CategoryCoursesData({
    required this.category,
    required this.courses,
    required this.pagination,
  });

  factory CategoryCoursesData.fromJson(Map<String, dynamic> json) {
    return CategoryCoursesData(
      category: ParentCategory.fromJson(json['category'] ?? {}),
      courses: (json['courses'] as List?)
          ?.map((course) => Course.fromJson(course))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasMore;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasMore,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 0,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
      hasMore: json['hasMore'] ?? false,
    );
  }
}