import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lessons/data/models/course_model.dart';
import '../../../lessons/data/models/lesson_model.dart';
import '../../../lessons/data/models/unit_model.dart';
import '../../../lessons/presentation/providers/lessons_providers.dart';
import '../providers/admin_providers.dart';
import 'lesson_exercises_screen.dart';

class UnitWithLessons {
  final UnitModel unit;
  final List<LessonModel> lessons;
  UnitWithLessons({required this.unit, required this.lessons});
}

final curriculumDataProvider = FutureProvider.autoDispose.family<List<UnitWithLessons>, String>((ref, courseId) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  final units = await repository.getUnits(courseId);
  final List<UnitWithLessons> list = [];
  for (final unit in units) {
    final lessons = await repository.getLessons(unit.id);
    list.add(UnitWithLessons(unit: unit, lessons: lessons));
  }
  list.sort((a, b) => a.unit.orderIndex.compareTo(b.unit.orderIndex));
  for (var u in list) {
    u.lessons.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
  return list;
});

class CurriculumManagementScreen extends ConsumerStatefulWidget {
  const CurriculumManagementScreen({super.key});

  @override
  ConsumerState<CurriculumManagementScreen> createState() => _CurriculumManagementScreenState();
}

class _CurriculumManagementScreenState extends ConsumerState<CurriculumManagementScreen> {
  String _searchQuery = '';
  final Set<String> _expandedUnitIds = {};
  bool _isSavingOrder = false;
  String? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(coursesDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lộ trình', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Add course button
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Thêm khóa học mới',
            onPressed: () => _showAddCourseDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(coursesDataProvider);
              if (_selectedCourseId != null) {
                ref.invalidate(curriculumDataProvider(_selectedCourseId!));
              }
            },
          ),
        ],
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded, size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('Chưa có khóa học nào.', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddCourseDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tạo khóa học đầu tiên'),
                  ),
                ],
              ),
            );
          }

          // Auto-select first course if none selected
          if (_selectedCourseId == null || !courses.any((c) => c.id == _selectedCourseId)) {
            _selectedCourseId = courses.first.id;
          }

          final selectedCourse = courses.firstWhere((c) => c.id == _selectedCourseId);

          return Column(
            children: [
              // Course Selector & Actions Bar
              Container(
                color: theme.colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCourseId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Chọn khóa học quản lý',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course.id,
                            child: Text(
                              '${course.title} (${course.targetLevel.toUpperCase()})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourseId = val;
                            _expandedUnitIds.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded),
                      tooltip: 'Sửa khóa học',
                      onPressed: () => _showEditCourseDialog(context, selectedCourse),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      tooltip: 'Xóa khóa học',
                      onPressed: () => _showDeleteCourseDialog(context, selectedCourse),
                    ),
                  ],
                ),
              ),

              // Search & Add Unit Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm chương...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _showAddUnitDialog(context, selectedCourse.id),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Chương'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isSavingOrder)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: LinearProgressIndicator(),
                ),

              Expanded(
                child: ref.watch(curriculumDataProvider(selectedCourse.id)).when(
                  data: (data) {
                    final filtered = data.where((item) {
                      return item.unit.title.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 64, color: theme.colorScheme.outlineVariant),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có chương nào trong khóa học này.',
                              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }

                    // Parent units list supporting drag-and-drop
                    return ReorderableListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final unit = item.unit;
                        final isExpanded = _expandedUnitIds.contains(unit.id);

                        return Card(
                          key: ValueKey(unit.id),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isExpanded
                                  ? theme.colorScheme.primary.withAlpha(50)
                                  : theme.colorScheme.outlineVariant.withAlpha(127),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Unit Header
                              Container(
                                decoration: BoxDecoration(
                                  color: isExpanded ? theme.colorScheme.primary.withAlpha(12) : null,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '#${unit.orderIndex} ${unit.title}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isExpanded ? theme.colorScheme.primary : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, size: 20),
                                      onPressed: () => _showEditUnitDialog(context, unit),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                                      onPressed: () => _showDeleteUnitDialog(context, unit),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                      ),
                                      onPressed: () => _toggleUnitExpanded(unit.id),
                                    ),
                                  ],
                                ),
                              ),
                              // Unit content (Expanded lessons)
                              if (isExpanded) ...[
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      if (item.lessons.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                                          child: Text(
                                            'Chưa có bài học nào.',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                          ),
                                        )
                                      else
                                        // Lessons Reorderable List
                                        ReorderableListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: item.lessons.length,
                                          itemBuilder: (context, lIndex) {
                                            final lesson = item.lessons[lIndex];
                                            return Container(
                                              key: ValueKey(lesson.id),
                                              margin: const EdgeInsets.only(bottom: 8),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceContainerLowest,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: theme.colorScheme.outlineVariant.withAlpha(127),
                                                ),
                                              ),
                                              child: ListTile(
                                                leading: ReorderableDragStartListener(
                                                  index: lIndex,
                                                  child: const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                                                ),
                                                title: Text(
                                                  '#${lesson.orderIndex} ${lesson.title}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                subtitle: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.tertiary.withAlpha(20),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        '${lesson.xpReward} XP',
                                                        style: TextStyle(
                                                          color: theme.colorScheme.tertiary,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_rounded, size: 18),
                                                      onPressed: () => _showEditLessonDialog(context, lesson),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                                      onPressed: () => _showDeleteLessonDialog(context, lesson),
                                                    ),
                                                  ],
                                                ),
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute<void>(
                                                      builder: (context) => LessonExercisesScreen(
                                                        unitTitle: unit.title,
                                                        lesson: lesson,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          onReorder: (oldIndex, newIndex) =>
                                              _reorderLessons(item.lessons, oldIndex, newIndex, selectedCourse.id),
                                        ),
                                      const SizedBox(height: 8),
                                      // Add Lesson dashed button
                                      OutlinedButton.icon(
                                        onPressed: () => _showAddLessonDialog(context, unit.id, item.lessons.length),
                                        icon: const Icon(Icons.add_circle_outline_rounded),
                                        label: const Text('Thêm bài học'),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size.fromHeight(48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          side: BorderSide(
                                            color: theme.colorScheme.outlineVariant,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ]
                            ],
                          ),
                        );
                      },
                      onReorder: (oldIndex, newIndex) => _reorderUnits(filtered, oldIndex, newIndex, selectedCourse.id),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Lỗi tải chương: $err')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi tải khóa học: $err')),
      ),
    );
  }

  // === Dialogs and REST Actions for Courses ===

  void _showAddCourseDialog(BuildContext context) {
    final titleController = TextEditingController();
    String level = 'beginner';

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tạo khóa học mới'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tên khóa học'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: level,
                    decoration: const InputDecoration(labelText: 'Độ khó mục tiêu'),
                    items: const [
                      DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                      DropdownMenuItem(value: 'elementary', child: Text('Elementary')),
                      DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          level = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      Navigator.pop(context);
                      try {
                        final newCourse = await ref.read(adminServiceProvider).createCourse(
                              title: title,
                              targetLevel: level,
                            );
                        ref.invalidate(coursesDataProvider);
                        setState(() {
                          _selectedCourseId = newCourse.id;
                        });
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi tạo khóa học: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCourseDialog(BuildContext context, CourseModel course) {
    final titleController = TextEditingController(text: course.title);
    String level = course.targetLevel;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chỉnh sửa khóa học'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tên khóa học'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: level,
                    decoration: const InputDecoration(labelText: 'Độ khó mục tiêu'),
                    items: const [
                      DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                      DropdownMenuItem(value: 'elementary', child: Text('Elementary')),
                      DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          level = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      Navigator.pop(context);
                      try {
                        await ref.read(adminServiceProvider).updateCourse(
                              courseId: course.id,
                              title: title,
                              targetLevel: level,
                            );
                        ref.invalidate(coursesDataProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi sửa khóa học: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteCourseDialog(BuildContext context, CourseModel course) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa khóa học?'),
          content: Text(
            'Bạn có chắc chắn muốn xóa khóa học "${course.title}"? Điều này sẽ xóa tất cả các chương và bài học đi kèm!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(adminServiceProvider).deleteCourse(course.id);
                  setState(() {
                    _selectedCourseId = null;
                  });
                  ref.invalidate(coursesDataProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi xóa khóa học: $e')),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // === REST Actions for Units & Lessons ===

  Future<void> _reorderUnits(List<UnitWithLessons> list, int oldIndex, int newIndex, String courseId) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      _isSavingOrder = true;
    });

    try {
      final moved = list.removeAt(oldIndex);
      list.insert(newIndex, moved);

      final adminService = ref.read(adminServiceProvider);
      for (int i = 0; i < list.length; i++) {
        final currentUnit = list[i].unit;
        final targetIndex = i + 1;
        if (currentUnit.orderIndex != targetIndex) {
          await adminService.updateUnit(
            unitId: currentUnit.id,
            orderIndex: targetIndex,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi reorder chương: $e')),
        );
      }
    } finally {
      ref.invalidate(curriculumDataProvider(courseId));
      if (mounted) {
        setState(() {
          _isSavingOrder = false;
        });
      }
    }
  }

  Future<void> _reorderLessons(List<LessonModel> lessons, int oldIndex, int newIndex, String courseId) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      _isSavingOrder = true;
    });

    try {
      final moved = lessons.removeAt(oldIndex);
      lessons.insert(newIndex, moved);

      final adminService = ref.read(adminServiceProvider);
      for (int i = 0; i < lessons.length; i++) {
        final currentLesson = lessons[i];
        final targetIndex = i + 1;
        if (currentLesson.orderIndex != targetIndex) {
          await adminService.updateLesson(
            lessonId: currentLesson.id,
            orderIndex: targetIndex,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi reorder bài học: $e')),
        );
      }
    } finally {
      ref.invalidate(curriculumDataProvider(courseId));
      if (mounted) {
        setState(() {
          _isSavingOrder = false;
        });
      }
    }
  }

  void _toggleUnitExpanded(String unitId) {
    setState(() {
      if (_expandedUnitIds.contains(unitId)) {
        _expandedUnitIds.remove(unitId);
      } else {
        _expandedUnitIds.add(unitId);
      }
    });
  }

  void _showAddUnitDialog(BuildContext context, String courseId) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm chương mới'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Tên chương'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    final currentUnits = ref.read(curriculumDataProvider(courseId)).value ?? [];
                    final orderIndex = currentUnits.length + 1;

                    await ref.read(adminServiceProvider).createUnit(
                          courseId: courseId,
                          title: title,
                          orderIndex: orderIndex,
                        );
                    ref.invalidate(curriculumDataProvider(courseId));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi tạo chương: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showEditUnitDialog(BuildContext context, UnitModel unit) {
    final controller = TextEditingController(text: unit.title);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sửa tên chương'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Tên chương'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await ref.read(adminServiceProvider).updateUnit(
                          unitId: unit.id,
                          title: title,
                        );
                    ref.invalidate(curriculumDataProvider(unit.courseId));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi cập nhật chương: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUnitDialog(BuildContext context, UnitModel unit) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa chương?'),
          content: Text('Bạn có chắc chắn muốn xóa "${unit.title}" không? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(adminServiceProvider).deleteUnit(unit.id);
                  ref.invalidate(curriculumDataProvider(unit.courseId));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa chương: $e')),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddLessonDialog(BuildContext context, String unitId, int currentLessonsCount) {
    final titleController = TextEditingController();
    final xpController = TextEditingController(text: '10');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm bài học mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tên bài học'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: xpController,
                decoration: const InputDecoration(labelText: 'Điểm thưởng (XP)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final xp = int.tryParse(xpController.text) ?? 10;
                if (title.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await ref.read(adminServiceProvider).createLesson(
                          unitId: unitId,
                          title: title,
                          orderIndex: currentLessonsCount + 1,
                          xpReward: xp,
                        );
                    if (_selectedCourseId != null) {
                      ref.invalidate(curriculumDataProvider(_selectedCourseId!));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi tạo bài học: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showEditLessonDialog(BuildContext context, LessonModel lesson) {
    final titleController = TextEditingController(text: lesson.title);
    final xpController = TextEditingController(text: '${lesson.xpReward}');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sửa bài học'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tên bài học'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: xpController,
                decoration: const InputDecoration(labelText: 'Điểm thưởng (XP)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final xp = int.tryParse(xpController.text) ?? 10;
                if (title.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await ref.read(adminServiceProvider).updateLesson(
                          lessonId: lesson.id,
                          title: title,
                          xpReward: xp,
                        );
                    if (_selectedCourseId != null) {
                      ref.invalidate(curriculumDataProvider(_selectedCourseId!));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi cập nhật bài học: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteLessonDialog(BuildContext context, LessonModel lesson) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa bài học?'),
          content: Text('Bạn có chắc chắn muốn xóa bài học "${lesson.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(adminServiceProvider).deleteLesson(lesson.id);
                  if (_selectedCourseId != null) {
                    ref.invalidate(curriculumDataProvider(_selectedCourseId!));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa bài học: $e')),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
