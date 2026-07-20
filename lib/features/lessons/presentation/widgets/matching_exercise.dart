import 'package:flutter/material.dart';
import '../../domain/entities/exercise_entities.dart';
import '../../../../core/utils/matching_codec.dart';

class MatchingExercise extends StatefulWidget {
  final List<ExerciseOption> options;
  final bool enabled;
  final ValueChanged<String?> onAnswerChanged;

  const MatchingExercise({
    super.key,
    required this.options,
    required this.enabled,
    required this.onAnswerChanged,
  });

  @override
  State<MatchingExercise> createState() => _MatchingExerciseState();
}

class _MatchingExerciseState extends State<MatchingExercise> {
  late List<MatchingPair> pairs;
  late List<String> leftItems;
  late List<String> rightItems;

  final Set<String> matchedLefts = {};
  final Set<String> matchedRights = {};

  String? selectedLeft;
  String? selectedRight;

  bool isChecking = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    pairs = MatchingCodec.decodePairs(widget.options);
    leftItems = pairs.map((p) => p.left).toList()..shuffle();
    rightItems = pairs.map((p) => p.right).toList()..shuffle();
  }

  void _selectLeft(String left) {
    if (!widget.enabled || isChecking || matchedLefts.contains(left)) return;
    setState(() {
      if (selectedLeft == left) {
        selectedLeft = null;
      } else {
        selectedLeft = left;
        if (selectedRight != null) {
          _checkMatch();
        }
      }
    });
  }

  void _selectRight(String right) {
    if (!widget.enabled || isChecking || matchedRights.contains(right)) return;
    setState(() {
      if (selectedRight == right) {
        selectedRight = null;
      } else {
        selectedRight = right;
        if (selectedLeft != null) {
          _checkMatch();
        }
      }
    });
  }

  void _checkMatch() {
    final left = selectedLeft!;
    final right = selectedRight!;

    final isValid = pairs.any((p) => p.left == left && p.right == right);

    if (isValid) {
      setState(() {
        matchedLefts.add(left);
        matchedRights.add(right);
        selectedLeft = null;
        selectedRight = null;
      });
      if (matchedLefts.length == pairs.length) {
        widget.onAnswerChanged(MatchingCodec.canonicalAnswer(pairs));
      }
    } else {
      setState(() {
        isChecking = true;
        hasError = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            selectedLeft = null;
            selectedRight = null;
            isChecking = false;
            hasError = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List<Widget>.generate(leftItems.length, (index) {
        final left = leftItems[index];
        final right = rightItems[index];
        final leftSelected = selectedLeft == left;
        final rightSelected = selectedRight == right;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == leftItems.length - 1 ? 0 : 12,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildTile(
                    key: ValueKey('matching-left-$index'),
                    text: left,
                    theme: theme,
                    isMatched: matchedLefts.contains(left),
                    isSelected: leftSelected,
                    isWrong: hasError && leftSelected,
                    onTap: () => _selectLeft(left),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTile(
                    key: ValueKey('matching-right-$index'),
                    text: right,
                    theme: theme,
                    isMatched: matchedRights.contains(right),
                    isSelected: rightSelected,
                    isWrong: hasError && rightSelected,
                    onTap: () => _selectRight(right),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTile({
    required Key key,
    required String text,
    required ThemeData theme,
    required bool isMatched,
    required bool isSelected,
    required bool isWrong,
    required VoidCallback onTap,
  }) {
    Color backgroundColor = theme.colorScheme.surface;
    Color borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    double borderWidth = 1.0;
    Color textColor = theme.colorScheme.onSurface;

    if (isMatched) {
      backgroundColor = Colors.green.withValues(alpha: 0.15);
      borderColor = Colors.green;
      borderWidth = 1.5;
      textColor = Colors.green.shade700;
    } else if (isWrong) {
      backgroundColor = Colors.red.withValues(alpha: 0.15);
      borderColor = Colors.red;
      borderWidth = 1.5;
      textColor = Colors.red.shade700;
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primaryContainer.withValues(
        alpha: 0.4,
      );
      borderColor = theme.colorScheme.primary;
      borderWidth = 1.5;
      textColor = theme.colorScheme.primary;
    }

    return Container(
      key: key,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: widget.enabled && !isMatched && !isChecking ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected || isMatched
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
