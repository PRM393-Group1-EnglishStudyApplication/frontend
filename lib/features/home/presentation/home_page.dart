import 'dart:math' as math;

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/presentation/providers/auth_providers.dart';
import '../../auth/presentation/screens/profile_screen.dart';
import '../../hearts/presentation/providers/heart_providers.dart';
import '../../hearts/presentation/widgets/heart_indicator.dart';
import '../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../lessons/presentation/providers/lessons_providers.dart';
import '../../lessons/presentation/screens/course_detail_screen.dart';
import '../../lessons/presentation/screens/course_path_screen.dart';
import '../../practice/presentation/screens/practice_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  int _navIndex = 0;

  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pathCtrl;

  late final Animation<double> _pulse;
  late final Animation<double> _float;
  late final Animation<double> _path;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _float = Tween<double>(
      begin: 0.0,
      end: -10.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _path = Tween<double>(begin: 0.0, end: 1.0).animate(_pathCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Text(_getAppBarTitle()),
              centerTitle: true,
              actions: const <Widget>[HeartIndicator(), SizedBox(width: 8)],
            ),
      body: Builder(
        builder: (context) {
          switch (_currentIndex) {
            case 0:
              return const CoursePathScreen();
            case 1:
              return const PracticeScreen();
            case 2:
              return const LeaderboardScreen();
            case 3:
              return const ProfileScreen();
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: _kPrimary),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: _kPrimary),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded, color: _kPrimary),
            label: 'Quests',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person_rounded, color: _kPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Learn tab ──────────────────────────────────────────────────────────────

class _LearnTab extends StatelessWidget {
  final Animation<double> pulse;
  final Animation<double> float;
  final Animation<double> path;

  const _LearnTab({
    required this.pulse,
    required this.float,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 1,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 22,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text('🇻🇳', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Vietnamese',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const _StatPill(
                icon: Icons.local_fire_department_rounded,
                iconColor: _kOrange,
                value: '7',
              ),
              const SizedBox(width: 8),
              const _StatPill(
                icon: Icons.diamond_rounded,
                iconColor: Color(0xFF1CB0F6),
                value: '320',
              ),
              const SizedBox(width: 8),
              const _StatPill(
                icon: Icons.favorite_rounded,
                iconColor: _kRed,
                value: '5',
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _LevelProgressCard(),
          ),
        ),
        SliverToBoxAdapter(
          child: _AdventureMap(pulse: pulse, float: float, path: path),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _DailyQuestsCard(),
          ),
        ),
      ],
    );
  }
}

// ── Stat pill ──────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

// ── Level progress card ────────────────────────────────────────────────────

class _LevelProgressCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseData = ref.watch(_enrolledCourseProvider).valueOrNull;
    final completedIds =
        ref.watch(_completedLessonsProvider).valueOrNull ?? const {};

    String unitLabel = 'Unit 1';
    String unitSubtitle = 'Basics – Greetings & Numbers';
    int completedCount = 0;
    int totalCount = 5;

    if (courseData != null) {
      final units = courseData['units'] as List<dynamic>?;
      if (units != null && units.isNotEmpty) {
        final firstUnit = units.first as Map<String, dynamic>;
        unitSubtitle = (firstUnit['title'] ?? unitSubtitle) as String;
        final lessons = firstUnit['lessons'] as List<dynamic>? ?? [];
        totalCount = lessons.isEmpty ? 1 : lessons.length;
        completedCount = lessons.where((l) {
          final id = ((l as Map<String, dynamic>)['_id'] ?? '') as String;
          return completedIds.contains(id);
        }).length;
      }
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.courseList),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    unitLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    unitSubtitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                minHeight: 10,
                backgroundColor: const Color(0xFFE5E5E5),
                valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$completedCount of $totalCount lessons completed',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Adventure map ──────────────────────────────────────────────────────────

enum _NodeStatus { completed, active, locked }

class _NodeData {
  final _NodeStatus status;
  final String label;
  final double xFraction;
  final String? lessonId;

  const _NodeData({
    required this.status,
    required this.label,
    required this.xFraction,
    this.lessonId,
  });
}

class _AdventureMap extends ConsumerWidget {
  final Animation<double> pulse;
  final Animation<double> float;
  final Animation<double> path;

  const _AdventureMap({
    required this.pulse,
    required this.float,
    required this.path,
  });

  static const _xFractions = [0.50, 0.72, 0.28, 0.55];

  List<_NodeData> _buildNodes(
    Map<String, dynamic>? courseData,
    Set<String> completedIds,
  ) {
    if (courseData == null) {
      return const [
        _NodeData(
          status: _NodeStatus.active,
          label: 'Lesson 1',
          xFraction: 0.50,
        ),
      ];
    }

    final units = courseData['units'] as List<dynamic>?;
    if (units == null || units.isEmpty) {
      return const [
        _NodeData(
          status: _NodeStatus.active,
          label: 'Lesson 1',
          xFraction: 0.50,
        ),
      ];
    }

    final firstUnit = units.first as Map<String, dynamic>;
    final rawLessons = (firstUnit['lessons'] as List<dynamic>? ?? [])
        .take(4)
        .toList();
    if (rawLessons.isEmpty) {
      return const [
        _NodeData(
          status: _NodeStatus.active,
          label: 'Lesson 1',
          xFraction: 0.50,
        ),
      ];
    }

    // Find first incomplete lesson to mark as active
    int activeIndex = rawLessons.indexWhere((l) {
      final id = ((l as Map<String, dynamic>)['_id'] ?? '') as String;
      return !completedIds.contains(id);
    });
    if (activeIndex == -1) activeIndex = 0; // all completed — keep first active

    return List.generate(rawLessons.length, (i) {
      final lesson = rawLessons[i] as Map<String, dynamic>;
      final id = (lesson['_id'] ?? '') as String;
      final title = (lesson['title'] ?? 'Lesson ${i + 1}') as String;

      final _NodeStatus status;
      if (completedIds.contains(id)) {
        status = _NodeStatus.completed;
      } else if (i == activeIndex) {
        status = _NodeStatus.active;
      } else {
        status = _NodeStatus.locked;
      }

      return _NodeData(
        status: status,
        label: title,
        xFraction: _xFractions[i % _xFractions.length],
        lessonId: id.isNotEmpty ? id : null,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseData = ref.watch(_enrolledCourseProvider).valueOrNull;
    final completedIds =
        ref.watch(_completedLessonsProvider).valueOrNull ?? const {};
    final nodes = _buildNodes(courseData, completedIds);

    const mapHeight = 480.0;
    return SizedBox(
      height: mapHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final spacing = mapHeight / (nodes.length + 1);
          final positions = List.generate(
            nodes.length,
            (i) =>
                Offset(nodes[i].xFraction * w, mapHeight - spacing * (i + 1)),
          );
          return Stack(
            children: [
              AnimatedBuilder(
                animation: path,
                builder: (_, __) => CustomPaint(
                  size: Size(w, mapHeight),
                  painter: _PathPainter(
                    positions: positions,
                    progress: path.value,
                  ),
                ),
              ),
              for (int i = 0; i < nodes.length; i++)
                Positioned(
                  left: positions[i].dx - 32,
                  top: positions[i].dy - 32,
                  child: _LessonNode(
                    data: nodes[i],
                    pulse: nodes[i].status == _NodeStatus.active ? pulse : null,
                    float: nodes[i].status == _NodeStatus.active ? float : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  final _NodeData data;
  final Animation<double>? pulse;
  final Animation<double>? float;

  const _LessonNode({required this.data, this.pulse, this.float});

  @override
  Widget build(BuildContext context) {
    Widget node = _buildCircle();

    if (float != null) {
      node = AnimatedBuilder(
        animation: float!,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, float!.value), child: child),
        child: node,
      );
    }
    if (pulse != null) {
      node = AnimatedBuilder(
        animation: pulse!,
        builder: (_, child) =>
            Transform.scale(scale: pulse!.value, child: child),
        child: node,
      );
    }

    return SizedBox(
      width: 64,
      height: 64,
      child: GestureDetector(
        onTap: () {
          if (data.status != _NodeStatus.locked) {
            final lessonId = data.lessonId;
            if (lessonId != null) {
              context.push('/lessons/$lessonId/vocabulary');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This lesson is locked. Complete previous lessons first!',
                ),
                duration: Duration(milliseconds: 1000),
              ),
            );
          }
        },
        child: node,
      ),
    );
  }

  Widget _buildCircle() {
    switch (data.status) {
      case _NodeStatus.completed:
        return const _CircleNode(
          color: _kGreen,
          borderColor: Color(0xFF006B28),
          child: Icon(Icons.check_rounded, color: Colors.white, size: 28),
        );
      case _NodeStatus.active:
        return const _CircleNode(
          color: _kPrimary,
          borderColor: Color(0xFF003D8F),
          shadow: true,
          child: Icon(Icons.star_rounded, color: Colors.white, size: 28),
        );
      case _NodeStatus.locked:
        return const _CircleNode(
          color: Color(0xFFD1D5DB),
          borderColor: Color(0xFF9CA3AF),
          child: Icon(Icons.lock_rounded, color: Colors.white, size: 24),
        );
    }
  }
}

class _CircleNode extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Widget child;
  final bool shadow;

  const _CircleNode({
    required this.color,
    required this.borderColor,
    required this.child,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(child: child),
    );
  }
}

// ── Path painter ───────────────────────────────────────────────────────────

class _PathPainter extends CustomPainter {
  final List<Offset> positions;
  final double progress;

  const _PathPainter({required this.positions, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;

    final basePaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = _kPrimary.withValues(alpha: 0.55)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < positions.length - 1; i++) {
      final p1 = positions[i];
      final p2 = positions[i + 1];
      final ctrl = Offset(p1.dx, (p1.dy + p2.dy) / 2);
      _drawDashed(canvas, p1, ctrl, p2, i == 0 ? activePaint : basePaint);
    }
  }

  void _drawDashed(
    Canvas canvas,
    Offset p0,
    Offset ctrl,
    Offset p2,
    Paint paint,
  ) {
    const dashLen = 10.0;
    const gapLen = 6.0;
    const steps = 60;

    bool drawing = true;
    double carry = 0;
    Offset prev = p0;

    for (int s = 1; s <= steps; s++) {
      final t = s / steps;
      final x =
          math.pow(1 - t, 2) * p0.dx +
          2 * (1 - t) * t * ctrl.dx +
          t * t * p2.dx;
      final y =
          math.pow(1 - t, 2) * p0.dy +
          2 * (1 - t) * t * ctrl.dy +
          t * t * p2.dy;
      final curr = Offset(x.toDouble(), y.toDouble());
      final segLen = (curr - prev).distance;

      double rem = segLen;
      Offset from = prev;

      while (rem > 0) {
        final needed = drawing ? dashLen - carry : gapLen - carry;
        if (rem >= needed) {
          final frac = needed / segLen;
          final to = Offset(
            from.dx + (curr.dx - prev.dx) * frac,
            from.dy + (curr.dy - prev.dy) * frac,
          );
          if (drawing) canvas.drawLine(from, to, paint);
          from = to;
          rem -= needed;
          carry = 0;
          drawing = !drawing;
        } else {
          if (drawing) canvas.drawLine(from, curr, paint);
          carry += rem;
          rem = 0;
        }
      }
      prev = curr;
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.progress != progress || old.positions != positions;
}

// ── Daily quests card ──────────────────────────────────────────────────────

class _QuestData {
  final String label;
  final int current;
  final int total;
  final Color color;

  const _QuestData({
    required this.label,
    required this.current,
    required this.total,
    required this.color,
  });
}

class _DailyQuestsCard extends StatelessWidget {
  static const _quests = [
    _QuestData(label: 'Earn 10 XP', current: 6, total: 10, color: _kOrange),
    _QuestData(
      label: 'Complete 1 lesson',
      current: 0,
      total: 1,
      color: _kPrimary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: _kOrange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Daily Quests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Text(
                'Resets in 5h',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _quests.length; i++) ...[
            _QuestRow(quest: _quests[i]),
            if (i < _quests.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  final _QuestData quest;

  const _QuestRow({required this.quest});

  @override
  Widget build(BuildContext context) {
    final done = quest.current >= quest.total;
    return Row(
      children: [
        Icon(
          done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: done ? _kGreen : Colors.grey.shade400,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quest.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: quest.current / quest.total,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E5E5),
                  valueColor: AlwaysStoppedAnimation<Color>(quest.color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${quest.current}/${quest.total}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ── Profile tab ────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clerkUser = ClerkAuth.of(context).user;
    final name = (clerkUser?.name.isNotEmpty == true)
        ? clerkUser!.name
        : 'PRM Student';
    final email = clerkUser?.email ?? '';
    final avatarUrl = clerkUser?.imageUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: _kPrimary,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    (name.isNotEmpty ? name : email)[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await ClerkAuth.of(context).signOut();
              } catch (_) {}
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── Placeholder tabs ───────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            'Coming soon',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
