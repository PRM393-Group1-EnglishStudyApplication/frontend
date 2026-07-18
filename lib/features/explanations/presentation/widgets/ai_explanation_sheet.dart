import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm_frontend/features/explanations/data/models/explanation_model.dart';
import 'package:prm_frontend/features/explanations/presentation/providers/explanation_providers.dart';

// FR-8: bam nut "Giai thich voi AI" -> mo bottom sheet nay.
Future<void> showAiExplanationSheet(
  BuildContext context, {
  required String exerciseId,
  required String userAnswer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => AiExplanationSheet(exerciseId: exerciseId, userAnswer: userAnswer),
  );
}

class AiExplanationSheet extends ConsumerWidget {
  final String exerciseId;
  final String userAnswer;

  const AiExplanationSheet({
    super.key,
    required this.exerciseId,
    required this.userAnswer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ExplanationRequest request = (exerciseId: exerciseId, userAnswer: userAnswer);
    final explanationAsync = ref.watch(explanationProvider(request));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giải thích với AI',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            explanationAsync.when(
              data: (explanation) => _buildContent(theme, explanation),
              loading: () => _buildSkeleton(theme),
              error: (error, _) => _buildError(context, ref, theme, request, error),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // Skeleton loading trong khi cho LLM tra loi (co the mat 2-8s) - NFR-1
  Widget _buildSkeleton(ThemeData theme) {
    Widget bar(double widthFraction) => FractionallySizedBox(
          widthFactor: widthFraction,
          child: Container(
            height: 14,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 20),
          bar(1),
          bar(0.9),
          bar(0.7),
          const SizedBox(height: 12),
          bar(1),
          bar(0.8),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ExplanationModel explanation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection(theme, '❌ Lỗi của bạn', explanation.whyWrong, Colors.red),
          const SizedBox(height: 12),
          _buildSection(theme, '✅ Vì sao đáp án đúng', explanation.whyCorrect, Colors.green),
          const SizedBox(height: 12),
          _buildSection(theme, '💡 Mẹo', explanation.tip, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String body, Color color) {
    if (body.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  // FR-9: loi mang/503/429 -> thong bao than thien + nut thu lai, khong chan luong lam bai.
  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ExplanationRequest request,
    Object error,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error, size: 40),
          const SizedBox(height: 12),
          Text(
            _friendlyMessage(error),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(explanationProvider(request)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _friendlyMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Đã có lỗi xảy ra, vui lòng thử lại.' : message;
  }
}
