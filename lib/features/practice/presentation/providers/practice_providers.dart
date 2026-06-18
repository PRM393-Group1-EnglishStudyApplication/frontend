import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../progress/presentation/providers/progress_providers.dart';

final FutureProvider<int> completedLessonCountProvider =
    FutureProvider<int>((Ref ref) async {
  final summary = await ref.watch(progressSummaryProvider.future);
  return summary.completedLessons;
});

final FutureProvider<int> practiceStreakProvider =
    FutureProvider<int>((Ref ref) async {
  return ref.watch(currentUserProvider).maybeWhen(
        data: (user) => user.streakCount,
        orElse: () => 0,
      );
});

final FutureProvider<int> earnedXpProvider =
    FutureProvider<int>((Ref ref) async {
  final summary = await ref.watch(progressSummaryProvider.future);
  return summary.totalXp;
});

final FutureProvider<int> accuracyPercentageProvider =
    FutureProvider<int>((Ref ref) async {
  final summary = await ref.watch(progressSummaryProvider.future);
  return summary.averageScore;
});
