import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/course.dart';
import '../providers/lessons_providers.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  String _searchQuery = '';
  String _selectedDifficulty = 'All Levels';
  String _selectedTopic = 'All Topics';

  final List<String> _difficulties = [
    'All Levels',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
  final List<String> _topics = [
    'All Topics',
    'Travel',
    'Business',
    'Daily Life',
    'Culture',
    'Grammar',
  ];

  String _getCourseImage(Course course, int index) {
    final title = course.title.toLowerCase();
    if (title.contains('giao tiếp') ||
        title.contains('communication') ||
        title.contains('conversation')) {
      return 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=600&auto=format&fit=crop';
    } else if (title.contains('business') ||
        title.contains('doanh nghiệp') ||
        title.contains('correspondence')) {
      return 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=600&auto=format&fit=crop';
    } else if (title.contains('phrasebook') ||
        title.contains('du lịch') ||
        title.contains('travel')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600&auto=format&fit=crop';
    } else if (title.contains('speaking') ||
        title.contains('thuyết trình') ||
        title.contains('presentation')) {
      return 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?q=80&w=600&auto=format&fit=crop';
    }
    // Fallbacks
    switch (index % 4) {
      case 0:
        return 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=600&auto=format&fit=crop';
      case 1:
        return 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=600&auto=format&fit=crop';
      case 2:
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600&auto=format&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?q=80&w=600&auto=format&fit=crop';
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesDataProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerLowest,
        elevation: 0.5,
        title: Text(
          'Khóa học',
          style: TextStyle(fontWeight: FontWeight.w800, color: colors.primary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search field
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm khóa học...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: colors.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),

                // Difficulty filters
                const Text(
                  'Mức độ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _difficulties.map((diff) {
                      final isSelected = _selectedDifficulty == diff;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(diff),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedDifficulty = diff;
                              });
                            }
                          },
                          selectedColor: colors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colors.onPrimary
                                : colors.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: colors.surfaceContainer,
                          elevation: 0,
                          pressElevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),
                // Topic filters
                const Text(
                  'Chủ đề phổ biến',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _topics.map((topic) {
                      final isSelected = _selectedTopic == topic;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(topic),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTopic = topic;
                              });
                            }
                          },
                          selectedColor: colors.secondary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colors.onPrimary
                                : colors.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: colors.surfaceContainer,
                          elevation: 0,
                          pressElevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Courses grid list
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                final filtered = courses.where((course) {
                  // Filter by Search Query
                  if (_searchQuery.isNotEmpty &&
                      !course.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) &&
                      !course.description.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      )) {
                    return false;
                  }

                  // Filter by Difficulty
                  if (_selectedDifficulty != 'All Levels') {
                    if (course.targetLevel.toLowerCase() !=
                        _selectedDifficulty.toLowerCase()) {
                      return false;
                    }
                  }

                  // Filter by Topic
                  if (_selectedTopic != 'All Topics') {
                    final title = course.title.toLowerCase();
                    final desc = course.description.toLowerCase();
                    final topicLower = _selectedTopic.toLowerCase();
                    if (!title.contains(topicLower) &&
                        !desc.contains(topicLower)) {
                      // Topic specific keyword mappings
                      if (topicLower == 'daily life' &&
                          (title.contains('giao tiếp') ||
                              title.contains('communication') ||
                              title.contains('phrasebook'))) {
                        return true;
                      }
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy khóa học nào phù hợp.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildCourseCard(context, course, index),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sync_problem_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => ref.invalidate(coursesDataProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, int index) {
    final colors = Theme.of(context).colorScheme;
    final isIntermediate = course.targetLevel.toLowerCase() == 'intermediate';
    final isAdvanced = course.targetLevel.toLowerCase() == 'advanced';

    Color levelBg = Colors.green.shade600;
    Color levelText = Colors.white;
    if (isIntermediate) {
      levelBg = colors.secondary;
      levelText = colors.onSecondary;
    }
    if (isAdvanced) {
      levelBg = colors.error;
      levelText = colors.onError;
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _getCourseImage(course, index),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: levelBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        course.targetLevel.toUpperCase(),
                        style: TextStyle(
                          color: levelText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.description,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                CourseDetailScreen(course: course),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Chi tiết khóa học',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
