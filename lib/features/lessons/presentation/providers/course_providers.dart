import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/course_model.dart';
import '../../data/models/unit_model.dart';
import '../../data/models/lesson_model.dart';
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

final isUnitUnlockedProvider = Provider.family<bool, UnitModel>((ref, unit) {
  final unitsAsync = ref.watch(unitsDataProvider(unit.courseId));
  return unitsAsync.maybeWhen(
    data: (units) {
      final sortedUnits = List<UnitModel>.from(units)..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final index = sortedUnits.indexWhere((u) => u.id == unit.id);
      if (index <= 0) return true; // first unit is always unlocked

      final completedSet = ref.watch(completedLessonsProvider);
      for (int i = 0; i < index; i++) {
        final prevUnit = sortedUnits[i];
        final lessonsAsync = ref.watch(lessonsDataProvider(prevUnit.id));
        final isCompleted = lessonsAsync.maybeWhen(
          data: (lessons) {
            if (lessons.isEmpty) return true;
            return lessons.every((l) => completedSet.contains(l.id));
          },
          orElse: () => false,
        );
        if (!isCompleted) return false;
      }
      return true;
    },
    orElse: () => false,
  );
});

final isLessonUnlockedProvider = Provider.family<bool, LessonModel>((ref, lesson) {
  final activeCourse = ref.watch(activeCourseProvider);
  if (activeCourse == null) return false;

  final unitsAsync = ref.watch(unitsDataProvider(activeCourse.id));
  return unitsAsync.maybeWhen(
    data: (units) {
      final unitList = units.where((u) => u.id == lesson.unitId).toList();
      if (unitList.isEmpty) return false;
      final unit = unitList.first;

      final isUnitUnlocked = ref.watch(isUnitUnlockedProvider(unit));
      if (!isUnitUnlocked) return false;

      final lessonsAsync = ref.watch(lessonsDataProvider(unit.id));
      return lessonsAsync.maybeWhen(
        data: (lessons) {
          final sortedLessons = List<LessonModel>.from(lessons)..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          final completedSet = ref.watch(completedLessonsProvider);
          if (completedSet.contains(lesson.id)) return true;

          int activeIndex = -1;
          for (int i = 0; i < sortedLessons.length; i++) {
            if (!completedSet.contains(sortedLessons[i].id)) {
              activeIndex = i;
              break;
            }
          }
          final lessonIndex = sortedLessons.indexWhere((l) => l.id == lesson.id);
          return lessonIndex == activeIndex || (activeIndex == -1 && lessonIndex == 0);
        },
        orElse: () => false,
      );
    },
    orElse: () => false,
  );
});
