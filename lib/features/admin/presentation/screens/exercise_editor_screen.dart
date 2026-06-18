import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lessons/data/models/exercise_model.dart';
import '../providers/admin_providers.dart';

class OptionDraft {
  String id;
  String text;
  bool isCorrect;

  OptionDraft({
    this.id = '',
    this.text = '',
    this.isCorrect = false,
  });
}

class ExerciseEditorScreen extends ConsumerStatefulWidget {
  final String lessonTitle;
  final String lessonId;
  final ExerciseModel? exercise;

  const ExerciseEditorScreen({
    super.key,
    required this.lessonTitle,
    required this.lessonId,
    required this.exercise,
  });

  @override
  ConsumerState<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends ConsumerState<ExerciseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _exerciseType;
  late TextEditingController _questionController;
  late TextEditingController _audioUrlController;
  late TextEditingController _correctAnswerController;
  List<OptionDraft> _options = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _exerciseType = ex?.exerciseType ?? 'multiple_choice';
    _questionController = TextEditingController(text: ex?.question ?? '');
    _audioUrlController = TextEditingController(text: ex?.audioUrl ?? '');
    _correctAnswerController = TextEditingController(text: ex?.correctAnswer ?? '');


    if (ex != null && ex.options.isNotEmpty) {
      _options = ex.options
          .map((opt) => OptionDraft(
                id: opt.id,
                text: opt.optionText,
                isCorrect: opt.isCorrect,
              ))
          .toList();
    } else {
      _options = [
        OptionDraft(text: '', isCorrect: true),
        OptionDraft(text: '', isCorrect: false),
      ];
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _audioUrlController.dispose();
    _correctAnswerController.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add(OptionDraft(text: '', isCorrect: false));
    });
  }

  void _removeOption(int index) {
    if (_options.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bài tập trắc nghiệm cần ít nhất 2 đáp án.')),
      );
      return;
    }
    setState(() {
      final removed = _options.removeAt(index);
      if (removed.isCorrect && _options.isNotEmpty) {
        _options.first.isCorrect = true;
      }
    });
  }

  void _setCorrectOption(int index) {
    setState(() {
      for (int i = 0; i < _options.length; i++) {
        _options[i].isCorrect = (i == index);
      }
    });
  }

  bool get _requiresOptions {
    return _exerciseType == 'multiple_choice' || _exerciseType == 'listening';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final adminService = ref.read(adminServiceProvider);
    final question = _questionController.text.trim();
    final audioUrl = _audioUrlController.text.trim().isNotEmpty ? _audioUrlController.text.trim() : null;
    
    // Determine correct answer
    String correctAnswer = '';
    if (_requiresOptions) {
      final correctOpt = _options.firstWhere((opt) => opt.isCorrect, orElse: () => _options.first);
      correctAnswer = correctOpt.text.trim();
    } else {
      correctAnswer = _correctAnswerController.text.trim();
    }

    try {
      if (widget.exercise == null) {
        // Create exercise
        List<Map<String, dynamic>>? optionsPayload;
        if (_requiresOptions) {
          optionsPayload = _options
              .where((opt) => opt.text.trim().isNotEmpty)
              .map((opt) => <String, dynamic>{
                    'option_text': opt.text.trim(),
                    'is_correct': opt.isCorrect,
                  })
              .toList();
        }

        await adminService.createExercise(
          lessonId: widget.lessonId,
          question: question,
          exerciseType: _exerciseType,
          correctAnswer: correctAnswer,
          audioUrl: audioUrl,
          options: optionsPayload,
        );
      } else {
        final exerciseId = widget.exercise!.id;
        // Update exercise
        await adminService.updateExercise(
          exerciseId: exerciseId,
          question: question,
          exerciseType: _exerciseType,
          correctAnswer: correctAnswer,
          audioUrl: audioUrl,
        );

        // Update Options
        if (_requiresOptions) {
          final originalOptions = widget.exercise!.options;

          // Find deleted options
          for (final orig in originalOptions) {
            final exists = _options.any((draft) => draft.id == orig.id);
            if (!exists) {
              await adminService.deleteOption(orig.id);
            }
          }

          // Add / Update options
          for (final draft in _options) {
            if (draft.text.trim().isEmpty) continue;

            if (draft.id.isEmpty) {
              // Create new option
              await adminService.createOption(
                exerciseId: exerciseId,
                optionText: draft.text.trim(),
                isCorrect: draft.isCorrect,
              );
            } else {
              // Check if modified
              final orig = originalOptions.firstWhere((o) => o.id == draft.id);
              if (orig.optionText != draft.text.trim() || orig.isCorrect != draft.isCorrect) {
                await adminService.updateOption(
                  optionId: draft.id,
                  optionText: draft.text.trim(),
                  isCorrect: draft.isCorrect,
                );
              }
            }
          }
        }
      }

      ref.invalidate(lessonExercisesProvider(widget.lessonId));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu câu hỏi thành công.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showPreview() {
    final question = _questionController.text.trim().isNotEmpty
        ? _questionController.text.trim()
        : 'Ví dụ câu hỏi?';
    final audioUrl = _audioUrlController.text.trim();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Xem trước câu hỏi', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Student simulation
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withAlpha(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _exerciseType.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Audio helper UI
                      if (_exerciseType == 'listening' || audioUrl.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.volume_up_rounded),
                              label: const Text('Phát âm thanh'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Options or text input
                      if (_requiresOptions) ...[
                        ..._options.where((opt) => opt.text.trim().isNotEmpty).map((opt) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(opt.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        }),
                      ] else ...[
                        TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Nhập câu trả lời của bạn...',
                          ),
                          enabled: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.exercise != null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lesson: ${widget.lessonTitle}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(isEdit ? 'Chỉnh sửa câu hỏi' : 'Tạo câu hỏi mới'),
          ],
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Exercise Type Selector
            Text('Loại câu hỏi', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeChip('multiple_choice', 'Trắc nghiệm'),
                const SizedBox(width: 8),
                _buildTypeChip('listening', 'Nghe'),
                const SizedBox(width: 8),
                _buildTypeChip('translate', 'Dịch thuật'),
              ],
            ),
            const SizedBox(height: 20),

            // Question Prompt
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant.withAlpha(30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đề bài (Question Prompt)',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _questionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Nhập nội dung đề bài...',
                        border: InputBorder.none,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập đề bài';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Audio Helper (For listening or general upload)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Audio Helper (Tệp âm thanh)',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _audioUrlController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập URL file âm thanh (.mp3)...',
                        prefixIcon: Icon(Icons.link_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Answer options or correct answer text
            if (_requiresOptions)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Các đáp án lựa chọn',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '(Tích chọn đáp án đúng)',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _options.length,
                        itemBuilder: (context, index) {
                          final opt = _options[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: opt.text,
                                    decoration: InputDecoration(
                                      hintText: 'Đáp án ${index + 1}',
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onChanged: (val) {
                                      opt.text = val;
                                    },
                                    validator: (val) {
                                      if (_requiresOptions && (val == null || val.trim().isEmpty)) {
                                        return 'Không được để trống';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    opt.isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: opt.isCorrect ? Colors.green : Colors.grey,
                                  ),
                                  onPressed: () => _setCorrectOption(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: Colors.grey),
                                  onPressed: () => _removeOption(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Thêm đáp án lựa chọn'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đáp án đúng (Correct Answer)',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _correctAnswerController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập câu trả lời đúng mẫu...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (!_requiresOptions && (val == null || val.trim().isEmpty)) {
                            return 'Vui lòng nhập đáp án đúng';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Preview button
            FilledButton.icon(
              onPressed: _showPreview,
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Xem trước câu hỏi (Preview)'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: theme.colorScheme.surfaceVariant,
                foregroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final selected = _exerciseType == type;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _exerciseType = type;
          });
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
