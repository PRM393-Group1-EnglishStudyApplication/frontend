import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/course_model.dart';
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

  final List<String> _difficulties = ['All Levels', 'Beginner', 'Intermediate', 'Advanced'];
  final List<String> _topics = ['All Topics', 'Travel', 'Business', 'Daily Life', 'Culture', 'Grammar'];

  String _getCourseImage(CourseModel course, int index) {
    final title = course.title.toLowerCase();
    if (title.contains('giao tiếp') || title.contains('communication') || title.contains('conversation')) {
      return 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=600&auto=format&fit=crop';
    } else if (title.contains('business') || title.contains('doanh nghiệp') || title.contains('correspondence')) {
      return 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=600&auto=format&fit=crop';
    } else if (title.contains('phrasebook') || title.contains('du lịch') || title.contains('travel')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600&auto=format&fit=crop';
    } else if (title.contains('speaking') || title.contains('thuyết trình') || title.contains('presentation')) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Khóa Học',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0055C6)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0055C6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF2F4F6),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
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
                          selectedColor: const Color(0xFF0055C6),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: const Color(0xFFE6E8EA),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
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
                          selectedColor: const Color(0xFFFD9D06),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: const Color(0xFFE6E8EA),
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
                      !course.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                      !course.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return false;
                  }
                  
                  // Filter by Difficulty
                  if (_selectedDifficulty != 'All Levels') {
                    if (course.targetLevel.toLowerCase() != _selectedDifficulty.toLowerCase()) {
                      return false;
                    }
                  }
                  
                  // Filter by Topic
                  if (_selectedTopic != 'All Topics') {
                    final title = course.title.toLowerCase();
                    final desc = course.description.toLowerCase();
                    final topicLower = _selectedTopic.toLowerCase();
                    if (!title.contains(topicLower) && !desc.contains(topicLower)) {
                      // Topic specific keyword mappings
                      if (topicLower == 'daily life' && (title.contains('giao tiếp') || title.contains('communication') || title.contains('phrasebook'))) {
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
                      const Icon(Icons.sync_problem_rounded, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Lỗi: $err', style: const TextStyle(color: Colors.red)),
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

  Widget _buildCourseCard(BuildContext context, CourseModel course, int index) {
    final isIntermediate = course.targetLevel.toLowerCase() == 'intermediate';
    final isAdvanced = course.targetLevel.toLowerCase() == 'advanced';
    
    Color levelBg = const Color(0xFF008733);
    if (isIntermediate) levelBg = const Color(0xFFFD9D06);
    if (isAdvanced) levelBg = const Color(0xFFBA1A1A);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        course.targetLevel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.description,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
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
                            builder: (context) => CourseDetailScreen(course: course),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0055C6), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Chi tiết khóa học',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0055C6)),
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
