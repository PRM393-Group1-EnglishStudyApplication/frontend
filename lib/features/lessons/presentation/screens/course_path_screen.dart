import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/unit.dart';
import '../providers/course_providers.dart';
import '../providers/lessons_providers.dart';
import '../widgets/curved_path_painter.dart';
import 'course_list_screen.dart';
import 'lesson_screen.dart';

class CoursePathScreen extends ConsumerStatefulWidget {
  const CoursePathScreen({super.key});

  @override
  ConsumerState<CoursePathScreen> createState() => _CoursePathScreenState();
}

class _CoursePathScreenState extends ConsumerState<CoursePathScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isDailyRewardClaimed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double _getXOffset(int index, double width) {
    final center = width / 2;
    // We wiggle gently and symmetrically around the center axis (alternating left and right)
    // with a moderate amplitude (40-50px) that keeps nodes perfectly balanced and responsive.
    final double amplitude = math.min(45.0, width * 0.12);
    final double sign = (index % 2 == 0) ? -1.0 : 1.0;
    return center + (amplitude * sign) - 40; // 40 is half of button width (80)
  }

  @override
  Widget build(BuildContext context) {
    final activeCourse = ref.watch(activeCourseProvider);
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // If no active course is selected yet, show fallback to select course
    if (activeCourse == null) {
      return Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 80, color: colors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Chọn một khóa học để bắt đầu!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Khám phá danh sách các khóa học ngoại ngữ hấp dẫn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const CourseListScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text(
                    'Xem danh sách khóa học',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final unitsAsync = ref.watch(unitsDataProvider(activeCourse.id));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: Container(
          decoration: BoxDecoration(color: colors.surfaceContainerLowest),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Active Course Dropdown/Selector Button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const CourseListScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              activeCourse.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Streak & Gems / XP stats
                  userAsync.maybeWhen(
                    data: (user) => Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange.shade200.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.streakCount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.diamond_rounded,
                                color: colors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.totalXp}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: unitsAsync.when(
        data: (units) {
          if (units.isEmpty) {
            return const Center(
              child: Text('Khóa học chưa có chương học nào.'),
            );
          }

          // Read the active unit ID from state provider. If null, default to first unit.
          final activeUnitId = ref.watch(activeUnitProvider) ?? units.first.id;
          final index = units.indexWhere((u) => u.id == activeUnitId);
          final currentUnit = index != -1 ? units[index] : units.first;

          final lessonsAsync = ref.watch(lessonsDataProvider(currentUnit.id));

          return Column(
            children: [
              // Level Progress Banner with Unit Dropdown Selector
              _buildLevelProgressBanner(context, units, currentUnit),

              // Scrollable Curved Path Area
              Expanded(
                child: lessonsAsync.when(
                  data: (lessons) {
                    if (lessons.isEmpty) {
                      return const Center(
                        child: Text('Chương học chưa có bài học nào.'),
                      );
                    }
                    return _buildCurvedPath(context, lessons);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      Center(child: Text('Lỗi tải bài học: $err')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi tải chương học: $err')),
      ),
    );
  }

  Widget _buildLevelProgressBanner(
    BuildContext context,
    List<Unit> units,
    Unit currentUnit,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lessonsAsync = ref.watch(lessonsDataProvider(currentUnit.id));
    final completedSet = ref.watch(completedLessonsProvider);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHƯƠNG HIỆN TẠI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Dropdown to switch units
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentUnit.id,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: colors.primary,
                      ),
                      style: TextStyle(
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colors.primary,
                      ),
                      onChanged: (String? newUnitId) {
                        if (newUnitId != null) {
                          final selectedUnit = units.firstWhere(
                            (u) => u.id == newUnitId,
                          );
                          final isUnlocked = ref.read(
                            isUnitUnlockedProvider(selectedUnit),
                          );
                          if (!isUnlocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Chương học này đang bị khóa. Hãy hoàn thành các chương trước!',
                                ),
                                backgroundColor: Colors.black87,
                              ),
                            );
                            return;
                          }
                          ref.read(activeUnitProvider.notifier).state =
                              newUnitId;
                        }
                      },
                      items: units.map((Unit unit) {
                        final isUnlocked = ref.watch(
                          isUnitUnlockedProvider(unit),
                        );
                        return DropdownMenuItem<String>(
                          value: unit.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                unit.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? null : Colors.black38,
                                ),
                              ),
                              if (!isUnlocked) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              // Progress text percentage
              lessonsAsync.maybeWhen(
                data: (lessons) {
                  if (lessons.isEmpty) {
                    return const Text(
                      '0%',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );
                  }
                  final completedInUnit = lessons
                      .where((l) => completedSet.contains(l.id))
                      .length;
                  final percentage = (completedInUnit / lessons.length * 100)
                      .toInt();
                  return Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.secondary,
                    ),
                  );
                },
                orElse: () => const Text(
                  '--%',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          lessonsAsync.maybeWhen(
            data: (lessons) {
              double value = 0.0;
              if (lessons.isNotEmpty) {
                final completedInUnit = lessons
                    .where((l) => completedSet.contains(l.id))
                    .length;
                value = completedInUnit / lessons.length;
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.secondary),
                ),
              );
            },
            orElse: () => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.0,
                minHeight: 12,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurvedPath(BuildContext context, List<Lesson> lessons) {
    final completedSet = ref.watch(completedLessonsProvider);

    const double dy = 135.0; // vertical spacing
    final double pathHeight = lessons.length * dy + 80.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final List<Offset> points = [];

        for (int i = 0; i < lessons.length; i++) {
          final x = _getXOffset(i, width);
          final y = i * dy + 40.0;
          // Curve connects center points of buttons (which are 80x80)
          points.add(Offset(x + 40, y + 40));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: Column(
            children: [
              // Path Stack
              SizedBox(
                height: pathHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Layer 0: SVG dotted curve
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CurvedPathPainter(
                          points: points,
                          color: Theme.of(context).colorScheme.outlineVariant,
                          strokeWidth: 5.0,
                        ),
                      ),
                    ),

                    // Layer 1: Lesson button nodes
                    ...lessons.map((lesson) {
                      final idx = lessons.indexOf(lesson);
                      final x = _getXOffset(idx, width);
                      final y = idx * dy + 40.0;

                      final isCompleted = completedSet.contains(lesson.id);
                      final isUnlocked = ref.watch(
                        isLessonUnlockedProvider(lesson),
                      );
                      final isActive = isUnlocked && !isCompleted;
                      final isLocked = !isUnlocked;

                      return Positioned(
                        left:
                            x +
                            40 -
                            85, // Centered at x + 40, container width is 170
                        width: 170,
                        top: y,
                        child: _buildPathNode(
                          context,
                          lesson,
                          isCompleted,
                          isActive,
                          isLocked,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Daily Quests Card at the bottom of the map
              _buildDailyQuestsCard(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPathNode(
    BuildContext context,
    Lesson lesson,
    bool isCompleted,
    bool isActive,
    bool isLocked,
  ) {
    Widget buttonContent;
    BoxDecoration decoration;
    double size = 80.0;
    final colors = Theme.of(context).colorScheme;

    if (isCompleted) {
      buttonContent = const Icon(
        Icons.done_all_rounded,
        size: 40,
        color: Colors.white,
      );
      decoration = BoxDecoration(
        color: Colors.green.shade600,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green.shade800, width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (isActive) {
      size = 90.0;
      buttonContent = const Icon(
        Icons.play_arrow_rounded,
        size: 48,
        color: Colors.white,
      );
      final darkerPrimary = HSLColor.fromColor(colors.primary)
          .withLightness(
            (HSLColor.fromColor(colors.primary).lightness - 0.2).clamp(
              0.0,
              1.0,
            ),
          )
          .toColor();
      decoration = BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: darkerPrimary, width: 6),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      );
    } else {
      buttonContent = Icon(
        Icons.lock_rounded,
        size: 32,
        color: colors.onSurfaceVariant.withValues(alpha: 0.5),
      );
      decoration = BoxDecoration(
        color: colors.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: colors.outlineVariant, width: 6),
      );
    }

    final buttonWidget = InkWell(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bài học này đang bị khóa. Hãy hoàn thành các bài học trước!',
              ),
              backgroundColor: Colors.black87,
            ),
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
      borderRadius: BorderRadius.circular(48),
      child: Container(
        width: size,
        height: size,
        decoration: decoration,
        child: buttonContent,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "START HERE" flag above active button
        if (isActive) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: colors.secondary.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'BẮT ĐẦU',
              style: TextStyle(
                color: colors.onSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        // Pulse animation wrapper for active node
        isActive
            ? AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.05);
                  return Transform.scale(scale: scale, child: buttonWidget);
                },
              )
            : buttonWidget,
        const SizedBox(height: 8),
        // Lesson title label
        Container(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Text(
            lesson.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isLocked
                  ? colors.onSurfaceVariant.withValues(alpha: 0.6)
                  : colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyQuestsCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const int questTarget = 10;
    const int questCompleted = 7;
    final double progressValue = (questCompleted / questTarget).clamp(0.0, 1.0);
    final int progressPercent = (progressValue * 100).round();
    final bool isQuestCompleted = questCompleted >= questTarget;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.military_tech_rounded,
                  color: colors.onSecondaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nhiệm vụ hàng ngày',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Học thêm 10 từ vựng mới',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đã hoàn thành $questCompleted/$questTarget',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // Circular progress indicator
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progressValue,
                      backgroundColor: colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.secondary,
                      ),
                      strokeWidth: 4,
                    ),
                    Center(
                      child: Text(
                        '$progressPercent%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (!isQuestCompleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bạn cần hoàn thành đủ $questTarget/$questTarget để nhận thưởng.',
                      ),
                    ),
                  );
                  return;
                }
                if (_isDailyRewardClaimed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bạn đã nhận thưởng nhiệm vụ hôm nay rồi.'),
                    ),
                  );
                  return;
                }

                setState(() {
                  _isDailyRewardClaimed = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã nhận 150 XP Nhiệm vụ hàng ngày!'),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.secondary,
                foregroundColor: colors.onSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                _isDailyRewardClaimed ? 'ĐÃ NHẬN THƯỞNG' : 'NHẬN THƯỞNG',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
