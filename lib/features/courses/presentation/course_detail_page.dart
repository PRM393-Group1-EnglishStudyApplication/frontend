import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/course_model.dart';
import '../data/services/course_service.dart';
import '../../units/data/models/unit_model.dart';
import '../../units/data/services/unit_service.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../../routes/app_routes.dart';

final _courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService(ref.watch(authDioProvider));
});

final _unitServiceProvider = Provider<UnitService>((ref) {
  return UnitService(ref.watch(authDioProvider));
});

final _courseDetailProvider = FutureProvider.family<CourseModel, String>(
  (ref, courseId) => ref.watch(_courseServiceProvider).getCourse(courseId),
);

final _courseUnitsProvider = FutureProvider.family<List<UnitModel>, String>(
  (ref, courseId) => ref.watch(_unitServiceProvider).getUnits(courseId),
);

class CourseDetailPage extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  bool _enrolling = false;

  Future<void> _enroll(String courseId) async {
    setState(() => _enrolling = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('enrolled_course_id', courseId);
      if (mounted) context.go('/');
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final courseAsync = ref.watch(_courseDetailProvider(widget.courseId));
    final unitsAsync = ref.watch(_courseUnitsProvider(widget.courseId));

    return Scaffold(
      backgroundColor: cs.surface,
      body: courseAsync.when(
        data: (course) => _Body(
          course: course,
          unitsAsync: unitsAsync,
          enrolling: _enrolling,
          onEnroll: () => _enroll(course.id),
          theme: theme,
          cs: cs,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: cs.error),
              const SizedBox(height: 12),
              Text('Failed to load course', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(_courseDetailProvider(widget.courseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 1),
    );
  }
}

class _Body extends StatelessWidget {
  final CourseModel course;
  final AsyncValue<List<UnitModel>> unitsAsync;
  final bool enrolling;
  final VoidCallback onEnroll;
  final ThemeData theme;
  final ColorScheme cs;

  const _Body({
    required this.course,
    required this.unitsAsync,
    required this.enrolling,
    required this.onEnroll,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Top app bar with back button + hero image
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: cs.surface,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: cs.surface.withValues(alpha: 0.85),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: cs.primary),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '12 🔥  500 💎',
                  style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Hero image
                if (course.imageUrl != null)
                  Image.network(
                    course.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _HeroPlaceholder(cs: cs),
                  )
                else
                  _HeroPlaceholder(cs: cs),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                // Title / stats overlay
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'New Course',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        course.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.group_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text('1.2k Học viên', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
                          const SizedBox(width: 16),
                          const Icon(Icons.star_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text('4.9 (240 đánh giá)', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Enrollment card (floats below hero with negative-margin illusion via Stack not needed — use SliverToBoxAdapter with Transform)
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Học phí',
                          style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          'Miễn phí',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: enrolling ? null : onEnroll,
                      icon: enrolling
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                            )
                          : const Icon(Icons.bolt_rounded),
                      label: Text(enrolling ? 'Starting...' : 'Ghi danh ngay'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Description
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giới thiệu khóa học',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  course.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stats bento grid
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.menu_book_rounded,
                    iconColor: cs.primary,
                    title: '${course.unitCount ?? '?'} Units',
                    subtitle: 'Structured content',
                    bgColor: cs.surfaceContainerLow,
                    borderColor: Colors.transparent,
                    theme: theme,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    iconColor: cs.tertiary,
                    title: 'Mastery',
                    subtitle: '300+ Từ vựng',
                    bgColor: cs.surfaceContainerLow,
                    borderColor: cs.tertiaryContainer,
                    theme: theme,
                    cs: cs,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Unit roadmap
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiến trình bài học',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                unitsAsync.when(
                  data: (units) => units.isEmpty
                      ? Text(
                          'No units available yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        )
                      : _UnitRoadmap(units: units, courseId: units.first.courseId, theme: theme, cs: cs),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Text(
                    'Could not load units.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _HeroPlaceholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.4),
      child: Center(
        child: Icon(Icons.school_rounded, size: 64, color: cs.primary.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color borderColor;
  final ThemeData theme;
  final ColorScheme cs;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.borderColor,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != Colors.transparent
            ? Border(bottom: BorderSide(color: borderColor, width: 3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _UnitRoadmap extends StatelessWidget {
  final List<UnitModel> units;
  final String courseId;
  final ThemeData theme;
  final ColorScheme cs;

  const _UnitRoadmap({
    required this.units,
    required this.courseId,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Column(
            children: [
              const SizedBox(height: 9),
              Expanded(
                child: Container(
                  width: 2,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Units list
          Expanded(
            child: Column(
              children: List.generate(units.length, (i) {
                final unit = units[i];
                final isFirst = i == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Node dot (overlaps the line in the sibling Row above)
                      Transform.translate(
                        offset: const Offset(-24, 0),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFirst ? cs.primary : cs.outlineVariant,
                            border: Border.all(color: cs.surface, width: 3),
                            boxShadow: [
                              BoxShadow(color: cs.shadow.withValues(alpha: 0.15), blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('${AppRoutes.courseList}/$courseId/units'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit.title,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Unit ${unit.orderIndex + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isFirst)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Start',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.fitness_center_rounded, label: 'Practice'),
      (icon: Icons.leaderboard_rounded, label: 'League'),
      (icon: Icons.military_tech_rounded, label: 'Quests'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return GestureDetector(
                onTap: () {
                  if (i == 0) context.go('/');
                  if (i == 1) context.go(AppRoutes.courseList);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: isActive
                      ? BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12))
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: isActive ? cs.onSecondaryContainer : cs.onSurfaceVariant),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isActive ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
