import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../hearts/presentation/providers/heart_providers.dart';
import '../../data/models/course_model.dart';
import '../../data/models/unit_model.dart';
import '../providers/lessons_providers.dart';
import '../providers/course_providers.dart';
import 'lesson_screen.dart';

class CourseDetailScreen extends ConsumerWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  String _getCourseImage(CourseModel course) {
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
    return 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=600&auto=format&fit=crop';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsDataProvider(course.id));
    final activeCourse = ref.watch(activeCourseProvider);
    final isActive = activeCourse?.id == course.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0055C6)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0055C6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero section with Image & Title
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    _getCourseImage(course),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFD9D06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Khóa học mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.group_rounded, color: Colors.white70, size: 16),
                          SizedBox(width: 4),
                          Text('1.2k Học viên', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          SizedBox(width: 16),
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text('4.9 (240)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Enrollment Action
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Học phí', style: TextStyle(color: Colors.black54, fontSize: 12)),
                          Text(
                            'Miễn phí',
                            style: TextStyle(
                              color: Color(0xFF0055C6),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          // Select course as active
                          await ref.read(activeCourseProvider.notifier).setActiveCourse(course);
                          
                          // Set active unit if possible
                          unitsAsync.whenData((units) {
                            if (units.isNotEmpty) {
                              ref.read(activeUnitProvider.notifier).state = units.first.id;
                            }
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã kích hoạt khóa học: ${course.title}'),
                                backgroundColor: const Color(0xFF008733),
                              ),
                            );
                            // Pop back to home screen
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0055C6),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: Icon(isActive ? Icons.play_arrow_rounded : Icons.bolt_rounded),
                        label: Text(
                          isActive ? 'Học tiếp' : 'Ghi danh ngay',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giới thiệu khóa học',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            
            // Bento statistics grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEEF0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Color(0xFF0055C6)),
                          const SizedBox(height: 12),
                          unitsAsync.maybeWhen(
                            data: (units) => Text(
                              '${units.length} Chương học',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            orElse: () => const Text(
                              '-- Chương học',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          const Text('Cấu trúc chi tiết', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEEF0),
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(
                          bottom: BorderSide(color: Color(0xFF53E16F), width: 3),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF008733)),
                          SizedBox(height: 12),
                          Text('Mastery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('300+ Từ vựng', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Syllabus Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: const Text(
                'Nội dung khóa học',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            
            unitsAsync.when(
              data: (units) {
                if (units.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Khóa học chưa có bài học nào.'),
                    ),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        title: Text(
                          unit.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD9E2FF),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFF0055C6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        children: [
                          _buildLessonsList(context, ref, unit),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              )),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Lỗi tải chương học: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList(BuildContext context, WidgetRef ref, UnitModel unit) {
    final lessonsAsync = ref.watch(lessonsDataProvider(unit.id));
    
    return lessonsAsync.when(
      data: (lessons) {
        if (lessons.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Chưa có bài học.', style: TextStyle(fontStyle: FontStyle.italic)),
          );
        }
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: lessons.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFECEEF0),
                child: Text(
                  '${lesson.orderIndex}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
              title: Text(
                lesson.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text('+${lesson.xpReward} XP', style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.play_arrow_rounded, color: Colors.green),
              onTap: () {
                final heartState = ref.read(heartProvider);
                if (!heartState.canStartLesson) {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        icon: const Icon(
                          Icons.heart_broken_rounded,
                          color: Color(0xFFE94057),
                          size: 36,
                        ),
                        title: const Text('Hết lượt tim'),
                        content: const Text('Hãy nạp lại tim trước khi bắt đầu bài học mới.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Đóng'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ref.read(heartProvider.notifier).refillHearts();
                            },
                            child: const Text('Nạp tim'),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => LessonScreen(lesson: lesson),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Lỗi: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
