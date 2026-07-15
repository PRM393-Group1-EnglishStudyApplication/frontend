import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/unit_model.dart';
import '../data/services/unit_service.dart';
import '../../auth/presentation/providers/auth_providers.dart';

final _unitServiceProvider = Provider<UnitService>((ref) {
  return UnitService(ref.watch(authDioProvider));
});

final _unitsProvider = FutureProvider.family<List<UnitModel>, String>(
  (ref, courseId) => ref.watch(_unitServiceProvider).getUnits(courseId),
);

class UnitListPage extends ConsumerWidget {
  final String courseId;

  const UnitListPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unitsAsync = ref.watch(_unitsProvider(courseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Units'), centerTitle: true),
      body: unitsAsync.when(
        data: (units) {
          if (units.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_outlined, size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No units available', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _UnitCard(
              unit: units[i],
              isLocked: i > 0,
              index: i,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Failed to load units', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(_unitsProvider(courseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final UnitModel unit;
  final bool isLocked;
  final int index;

  const _UnitCard({
    required this.unit,
    required this.isLocked,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = isLocked;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: locked
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: locked
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complete the previous unit to unlock')),
                )
            : () => context.go('/units/${unit.id}/lessons'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: locked
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  locked ? Icons.lock_rounded : Icons.layers_rounded,
                  color: locked
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit ${index + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: locked ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                color: locked ? theme.colorScheme.outlineVariant : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
