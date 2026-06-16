import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/course_model.dart';
import 'lessons_providers.dart';

class ActiveCourseNotifier extends StateNotifier<CourseModel?> {
  final Ref _ref;

  ActiveCourseNotifier(this._ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCourseId = prefs.getString('active_course_id');
      
      final courses = await _ref.read(coursesDataProvider.future);
      if (courses.isNotEmpty) {
        if (savedCourseId != null) {
          final matched = courses.firstWhere(
            (c) => c.id == savedCourseId,
            orElse: () => courses.first,
          );
          state = matched;
        } else {
          state = courses.first;
        }
      }
    } catch (e) {
      print('Error initializing active course: $e');
      // Try fallback from cache/sync
      _ref.read(coursesDataProvider).whenData((courses) {
        if (courses.isNotEmpty && state == null) {
          state = courses.first;
        }
      });
    }
  }

  Future<void> setActiveCourse(CourseModel course) async {
    state = course;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_course_id', course.id);
    } catch (e) {
      print('Error saving active course: $e');
    }
  }
}

final activeCourseProvider = StateNotifierProvider<ActiveCourseNotifier, CourseModel?>((ref) {
  return ActiveCourseNotifier(ref);
});

final activeUnitProvider = StateProvider<String?>((ref) => null);

class CompletedLessonsNotifier extends StateNotifier<Set<String>> {
  CompletedLessonsNotifier() : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> keys = prefs.getKeys();
      final Set<String> completed = <String>{};
      for (final String key in keys) {
        if (key.startsWith('completed_lesson_') && prefs.getBool(key) == true) {
          completed.add(key.substring('completed_lesson_'.length));
        }
      }
      state = completed;
    } catch (e) {
      print('Error loading completed lessons: $e');
    }
  }

  Future<void> markAsCompleted(String lessonId) async {
    state = <String>{...state, lessonId};
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('completed_lesson_$lessonId', true);
    } catch (e) {
      print('Error saving completed lesson: $e');
    }
  }
}

final StateNotifierProvider<CompletedLessonsNotifier, Set<String>> completedLessonsProvider =
    StateNotifierProvider<CompletedLessonsNotifier, Set<String>>((Ref ref) {
  return CompletedLessonsNotifier();
});
