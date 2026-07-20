import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/lesson.dart';
import 'lessons_providers.dart';

class ActiveCourseNotifier extends StateNotifier<AsyncValue<Course?>> {
  final Ref _ref;

  ActiveCourseNotifier(this._ref) : super(const AsyncValue<Course?>.loading()) {
    reload();
  }

  Future<void> reload({bool refreshCourses = false}) async {
    state = const AsyncValue<Course?>.loading();
    try {
      if (refreshCourses) {
        _ref.invalidate(coursesDataProvider);
      }
      final prefs = await SharedPreferences.getInstance();
      final savedCourseId = prefs.getString('active_course_id');
      final courses = await _ref.read(coursesDataProvider.future);
      final Course? selectedCourse;
      if (courses.isEmpty) {
        selectedCourse = null;
      } else if (savedCourseId != null) {
        final index = courses.indexWhere((course) => course.id == savedCourseId);
        selectedCourse = index == -1 ? courses.first : courses[index];
      } else {
        selectedCourse = courses.first;
      }
      state = AsyncValue<Course?>.data(selectedCourse);
    } catch (error, stackTrace) {
      state = AsyncValue<Course?>.error(error, stackTrace);
    }
  }

  Future<void> setActiveCourse(Course course) async {
    state = AsyncValue<Course?>.data(course);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_course_id', course.id);
    } catch (e) {
      print('Error saving active course: $e');
    }
  }
}

final activeCourseProvider =
    StateNotifierProvider<ActiveCourseNotifier, AsyncValue<Course?>>((ref) {
      return ActiveCourseNotifier(ref);
    });

final activeUnitProvider = StateProvider<String?>((ref) => null);

class CompletedLessonsNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;

  CompletedLessonsNotifier(this._ref) : super(<String>{}) {
    reloadFromApi();
  }

  Future<void> reloadFromApi() async {
    try {
      final progress = await _ref.read(progressEntriesProvider.future);
      state = progress
          .where((entry) => entry.isCompleted)
          .map((entry) => entry.lessonId)
          .where((lessonId) => lessonId.isNotEmpty)
          .toSet();
    } catch (e) {
      print('Error loading completed lessons from API: $e');
    }
  }

  void markAsCompleted(String lessonId) {
    state = <String>{...state, lessonId};
  }
}

final StateNotifierProvider<CompletedLessonsNotifier, Set<String>> completedLessonsProvider =
    StateNotifierProvider<CompletedLessonsNotifier, Set<String>>((Ref ref) {
  return CompletedLessonsNotifier(ref);
});

final isUnitUnlockedProvider = Provider.family<bool, Unit>((ref, unit) {
  final unitsAsync = ref.watch(unitsDataProvider(unit.courseId));
  return unitsAsync.maybeWhen(
    data: (units) {
      final sortedUnits = List<Unit>.from(units)..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
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

final isLessonUnlockedProvider = Provider.family<bool, Lesson>((ref, lesson) {
  final activeCourse = ref.watch(activeCourseProvider).asData?.value;
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
          final sortedLessons = List<Lesson>.from(lessons)..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
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
