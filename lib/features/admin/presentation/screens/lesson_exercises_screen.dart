import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lessons/domain/entities/exercise_entities.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/providers/lessons_providers.dart';
import '../providers/admin_providers.dart';
import 'exercise_editor_screen.dart';
import 'exercise_import_screen.dart';

class LessonExercisesScreen extends ConsumerWidget {
  final String unitTitle;
  final Lesson lesson;

  const LessonExercisesScreen({
    super.key,
    required this.unitTitle,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$unitTitle > ${lesson.title}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Text('Nội dung bài học'),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Câu hỏi (Exercises)', icon: Icon(Icons.quiz_rounded)),
              Tab(text: 'Từ vựng (Vocabulary)', icon: Icon(Icons.translate_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExercisesTab(context, ref),
            _buildVocabularyTab(context, ref),
          ],
        ),
      ),
    );
  }

  // === Tab 1: Exercises ===
  Widget _buildExercisesTab(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(lessonExercisesProvider(lesson.id));

    return Scaffold(
      body: exercisesAsync.when(
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có câu hỏi nào trong bài học này.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _navigateToAddExercise(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Thêm câu hỏi'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _navigateToImport(context),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Import từ file'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withAlpha(127),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              exercise.exerciseType.toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) => ExerciseEditorScreen(
                                        lessonTitle: lesson.title,
                                        lessonId: lesson.id,
                                        exercise: exercise,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                                onPressed: () => _showDeleteExerciseDialog(context, ref, exercise),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exercise.question,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (exercise.audioUrl != null && exercise.audioUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.audiotrack_rounded, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                exercise.audioUrl!,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (exercise.options.isNotEmpty) ...[
                        const Text(
                          'Đáp án lựa chọn:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        ...exercise.options.map((opt) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  opt.isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: opt.isCorrect ? Colors.green : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  opt.optionText,
                                  style: TextStyle(
                                    fontWeight: opt.isCorrect ? FontWeight.bold : FontWeight.normal,
                                    color: opt.isCorrect ? Colors.green : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else ...[
                        Row(
                          children: [
                            const Text(
                              'Đáp án đúng: ',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            Text(
                              exercise.correctAnswer,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Lỗi khi tải câu hỏi: $err', style: TextStyle(color: theme.colorScheme.error)),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'import_exercises',
            onPressed: () => _navigateToImport(context),
            tooltip: 'Import câu hỏi',
            child: const Icon(Icons.upload_file_rounded),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_exercise',
            onPressed: () => _navigateToAddExercise(context),
            tooltip: 'Thêm câu hỏi',
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  // === Tab 2: Vocabulary ===
  Widget _buildVocabularyTab(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lessonDetailAsync = ref.watch(lessonDetailDataProvider(lesson.id));

    return Scaffold(
      body: lessonDetailAsync.when(
        data: (detail) {
          final vocabs = detail.vocabulary;
          if (vocabs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.translate_rounded, size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có từ vựng nào trong bài học.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _showAddVocabMenu(context, ref, vocabs),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Thêm từ vựng'),
                      ),
                    ],
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: vocabs.length,
            itemBuilder: (context, index) {
              final vocab = vocabs[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Text(vocab.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        '/${vocab.pronunciation}/',
                        style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Nghĩa: ${vocab.meaning}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Ví dụ: ${vocab.exampleSentence}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _showEditVocabDialog(context, ref, vocab),
                      ),
                      IconButton(
                        icon: const Icon(Icons.link_off_rounded, color: Colors.red),
                        tooltip: 'Gỡ khỏi bài',
                        onPressed: () => _showDetachVocabDialog(context, ref, vocab),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                        tooltip: 'Xóa vĩnh viễn',
                        onPressed: () => _showDeleteVocabDialog(context, ref, vocab),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Lỗi khi tải từ vựng: $err', style: TextStyle(color: theme.colorScheme.error)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(lessonDetailDataProvider(lesson.id)).whenData((detail) {
            _showAddVocabMenu(context, ref, detail.vocabulary);
          });
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _navigateToAddExercise(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ExerciseEditorScreen(
          lessonTitle: lesson.title,
          lessonId: lesson.id,
          exercise: null,
        ),
      ),
    );
  }

  void _navigateToImport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ExerciseImportScreen(
          lessonId: lesson.id,
          lessonTitle: lesson.title,
        ),
      ),
    );
  }

  void _showDeleteExerciseDialog(BuildContext context, WidgetRef ref, Exercise exercise) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa câu hỏi?'),
          content: const Text('Bạn có chắc chắn muốn xóa câu hỏi này khỏi bài học không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(adminServiceProvider).deleteExercise(exercise.id);
                  ref.invalidate(lessonExercisesProvider(lesson.id));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa câu hỏi: $e')),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // === Vocabulary Actions ===

  void _showAddVocabMenu(BuildContext context, WidgetRef ref, List<Vocabulary> currentVocabs) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create_new_folder_rounded),
                title: const Text('Tạo & gán từ vựng mới'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateVocabDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('Gán từ vựng đã có sẵn'),
                onTap: () {
                  Navigator.pop(context);
                  _showAttachExistingVocabDialog(context, ref, currentVocabs);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateVocabDialog(BuildContext context, WidgetRef ref) {
    final wordController = TextEditingController();
    final meaningController = TextEditingController();
    final pronController = TextEditingController();
    final exampleController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tạo từ vựng mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: wordController, decoration: const InputDecoration(labelText: 'Từ tiếng Anh')),
                TextField(controller: meaningController, decoration: const InputDecoration(labelText: 'Nghĩa tiếng Việt')),
                TextField(controller: pronController, decoration: const InputDecoration(labelText: 'Phiên âm (Pronunciation)')),
                TextField(controller: exampleController, decoration: const InputDecoration(labelText: 'Câu ví dụ (Example)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            TextButton(
              onPressed: () async {
                final word = wordController.text.trim();
                final meaning = meaningController.text.trim();
                final pron = pronController.text.trim();
                final example = exampleController.text.trim();

                if (word.isNotEmpty && meaning.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    final adminService = ref.read(adminServiceProvider);
                    // 1. Create globally
                    final newVocab = await adminService.createVocabulary(
                      word: word,
                      meaning: meaning,
                      pronunciation: pron,
                      exampleSentence: example,
                    );
                    // 2. Attach to lesson
                    await adminService.attachVocabularyToLesson(
                      lessonId: lesson.id,
                      vocabId: newVocab.id,
                    );
                    ref.invalidate(lessonDetailDataProvider(lesson.id));
                    ref.invalidate(globalVocabularyProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi tạo từ vựng: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showEditVocabDialog(BuildContext context, WidgetRef ref, Vocabulary vocab) {
    final wordController = TextEditingController(text: vocab.word);
    final meaningController = TextEditingController(text: vocab.meaning);
    final pronController = TextEditingController(text: vocab.pronunciation);
    final exampleController = TextEditingController(text: vocab.exampleSentence);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa từ vựng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: wordController, decoration: const InputDecoration(labelText: 'Từ tiếng Anh')),
                TextField(controller: meaningController, decoration: const InputDecoration(labelText: 'Nghĩa tiếng Việt')),
                TextField(controller: pronController, decoration: const InputDecoration(labelText: 'Phiên âm (Pronunciation)')),
                TextField(controller: exampleController, decoration: const InputDecoration(labelText: 'Câu ví dụ (Example)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            TextButton(
              onPressed: () async {
                final word = wordController.text.trim();
                final meaning = meaningController.text.trim();
                final pron = pronController.text.trim();
                final example = exampleController.text.trim();

                if (word.isNotEmpty && meaning.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await ref.read(adminServiceProvider).updateVocabulary(
                          vocabId: vocab.id,
                          word: word,
                          meaning: meaning,
                          pronunciation: pron,
                          exampleSentence: example,
                        );
                    ref.invalidate(lessonDetailDataProvider(lesson.id));
                    ref.invalidate(globalVocabularyProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi sửa từ vựng: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showDetachVocabDialog(BuildContext context, WidgetRef ref, Vocabulary vocab) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gỡ từ vựng?'),
          content: Text('Bạn có muốn gỡ từ "${vocab.word}" khỏi bài học này không? (Từ vẫn tồn tại trong hệ thống).'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(adminServiceProvider).detachVocabularyFromLesson(
                        lessonId: lesson.id,
                        vocabId: vocab.id,
                      );
                  ref.invalidate(lessonDetailDataProvider(lesson.id));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi gỡ từ vựng: $e')),
                    );
                  }
                }
              },
              child: const Text('Gỡ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteVocabDialog(BuildContext context, WidgetRef ref, Vocabulary vocab) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa vĩnh viễn từ vựng?'),
          content: Text('Bạn có chắc chắn muốn xóa từ "${vocab.word}" vĩnh viễn khỏi toàn bộ hệ thống không? Hành động này sẽ gỡ từ khỏi tất cả bài học đang gán.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(adminServiceProvider).deleteVocabulary(vocab.id);
                  ref.invalidate(lessonDetailDataProvider(lesson.id));
                  ref.invalidate(globalVocabularyProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi xóa vĩnh viễn từ vựng: $e')),
                    );
                  }
                }
              },
              child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAttachExistingVocabDialog(
      BuildContext context, WidgetRef ref, List<Vocabulary> currentVocabs) {
    final globalVocabAsync = ref.watch(globalVocabularyProvider);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn từ vựng gán vào bài'),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: globalVocabAsync.when(
              data: (allVocabs) {
                // Filter out words that are already in the lesson
                final available = allVocabs.where((v) => !currentVocabs.any((c) => c.id == v.id)).toList();

                if (available.isEmpty) {
                  return const Center(child: Text('Tất cả từ vựng trong hệ thống đã được gán vào bài này.'));
                }

                return ListView.builder(
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final vocab = available[index];
                    return ListTile(
                      title: Text(vocab.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(vocab.meaning),
                      trailing: const Icon(Icons.add_link_rounded, color: Colors.green),
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await ref.read(adminServiceProvider).attachVocabularyToLesson(
                                lessonId: lesson.id,
                                vocabId: vocab.id,
                              );
                          ref.invalidate(lessonDetailDataProvider(lesson.id));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi gán từ vựng: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Lỗi: $err'),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ],
        );
      },
    );
  }
}
