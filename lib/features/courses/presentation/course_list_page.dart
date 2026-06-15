import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/course_model.dart';
import '../data/services/course_service.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../../routes/app_routes.dart';

final _courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService(ref.watch(authDioProvider));
});

final _coursesProvider = FutureProvider.family<List<CourseModel>, String?>(
  (ref, level) => ref.watch(_courseServiceProvider).getCourses(targetLevel: level),
);

final _enrolledCourseIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('enrolled_course_id');
});

class CourseListPage extends ConsumerStatefulWidget {
  const CourseListPage({super.key});

  @override
  ConsumerState<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends ConsumerState<CourseListPage> {
  String? _selectedLevel;
  String _searchQuery = '';
  String? _selectedTopic;
  final _searchController = TextEditingController();

  static const _levelChips = [
    (label: 'All Levels', value: null as String?),
    (label: 'Beginner', value: 'beginner'),
    (label: 'Intermediate', value: 'intermediate'),
    (label: 'Advanced', value: 'advanced'),
  ];

  static const _topics = ['Travel', 'Business', 'Daily Life', 'Culture', 'Grammar'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _badgeBg(BuildContext context, String level) {
    final cs = Theme.of(context).colorScheme;
    return switch (level.toLowerCase()) {
      'beginner' || 'elementary' || 'a1' || 'a2' => cs.tertiaryContainer,
      'intermediate' || 'b1' || 'b2' => cs.secondaryContainer,
      'advanced' || 'c1' || 'c2' => cs.errorContainer,
      _ => cs.surfaceContainerHigh,
    };
  }

  Color _badgeFg(BuildContext context, String level) {
    final cs = Theme.of(context).colorScheme;
    return switch (level.toLowerCase()) {
      'beginner' || 'elementary' || 'a1' || 'a2' => cs.onTertiaryContainer,
      'intermediate' || 'b1' || 'b2' => cs.onSecondaryContainer,
      'advanced' || 'c1' || 'c2' => cs.onErrorContainer,
      _ => cs.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final coursesAsync = ref.watch(_coursesProvider(_selectedLevel));
    final enrolledId = ref.watch(_enrolledCourseIdProvider).valueOrNull;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          _AppBar(theme: theme, cs: cs),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SearchBar(controller: _searchController, cs: cs, onChanged: (v) => setState(() => _searchQuery = v.toLowerCase())),
                const SizedBox(height: 20),
                _ChipRow(
                  label: 'Difficulty',
                  theme: theme,
                  cs: cs,
                  chips: _levelChips.map((c) => (label: c.label, isActive: _selectedLevel == c.value)).toList(),
                  onTap: (i) => setState(() => _selectedLevel = _levelChips[i].value),
                  activeColor: cs.primary,
                  activeFg: cs.onPrimary,
                ),
                const SizedBox(height: 16),
                _ChipRow(
                  label: 'Popular Topics',
                  theme: theme,
                  cs: cs,
                  chips: _topics.map((t) => (label: t, isActive: _selectedTopic == t)).toList(),
                  onTap: (i) => setState(() => _selectedTopic = _selectedTopic == _topics[i] ? null : _topics[i]),
                  activeColor: cs.secondaryContainer,
                  activeFg: cs.onSecondaryContainer,
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
          coursesAsync.when(
            data: (courses) {
              final filtered = _searchQuery.isEmpty
                  ? courses
                  : courses
                      .where((c) =>
                          c.title.toLowerCase().contains(_searchQuery) ||
                          c.description.toLowerCase().contains(_searchQuery))
                      .toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: cs.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No courses found', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, rowIdx) {
                      final left = filtered[rowIdx * 2];
                      final rightIdx = rowIdx * 2 + 1;
                      final right = rightIdx < filtered.length ? filtered[rightIdx] : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _CourseCard(
                                course: left,
                                isEnrolled: left.id == enrolledId,
                                badgeBg: _badgeBg(ctx, left.targetLevel),
                                badgeFg: _badgeFg(ctx, left.targetLevel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: right != null
                                  ? _CourseCard(
                                      course: right,
                                      isEnrolled: right.id == enrolledId,
                                      badgeBg: _badgeBg(ctx, right.targetLevel),
                                      badgeFg: _badgeFg(ctx, right.targetLevel),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: (filtered.length / 2).ceil(),
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (_, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: cs.error),
                    const SizedBox(height: 12),
                    Text('Failed to load courses', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => ref.invalidate(_coursesProvider(_selectedLevel)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 1),
    );
  }
}

class _AppBar extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme cs;

  const _AppBar({required this.theme, required this.cs});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: cs.surface.withValues(alpha: 0.95),
      elevation: 0,
      shadowColor: cs.shadow,
      toolbarHeight: 64,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.language_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'LinguaQuest',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '12 🔥  500 💎  5 ❤️',
              style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme cs;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.cs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Find your next challenge...',
        prefixIcon: Icon(Icons.search_rounded, color: cs.outline),
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final ThemeData theme;
  final ColorScheme cs;
  final List<({String label, bool isActive})> chips;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color activeFg;

  const _ChipRow({
    required this.label,
    required this.theme,
    required this.cs,
    required this.chips,
    required this.onTap,
    required this.activeColor,
    required this.activeFg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(chips.length, (i) {
              final chip = chips[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: chip.isActive ? activeColor : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chip.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: chip.isActive ? activeFg : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final bool isEnrolled;
  final Color badgeBg;
  final Color badgeFg;

  const _CourseCard({
    required this.course,
    required this.isEnrolled,
    required this.badgeBg,
    required this.badgeFg,
  });

  String _capitalise(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => context.go('${AppRoutes.courseList}/${course.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image (fixed 120px)
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (course.imageUrl != null)
                    Image.network(
                      course.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Placeholder(level: course.targetLevel),
                    )
                  else
                    _Placeholder(level: course.targetLevel),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _capitalise(course.targetLevel),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: badgeFg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Card body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        course.unitCount != null
                            ? '${course.unitCount} Unit${course.unitCount! > 1 ? 's' : ''}'
                            : 'Multiple Units',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isEnrolled)
                    OutlinedButton(
                      onPressed: () => context.go('${AppRoutes.courseList}/${course.id}'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
                        side: BorderSide(color: cs.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Continue'),
                    )
                  else
                    FilledButton(
                      onPressed: () => context.go('${AppRoutes.courseList}/${course.id}'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Start Course'),
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

class _Placeholder extends StatelessWidget {
  final String level;
  const _Placeholder({required this.level});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.3),
      child: Center(
        child: Icon(Icons.menu_book_rounded, size: 36, color: cs.primary.withValues(alpha: 0.5)),
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
