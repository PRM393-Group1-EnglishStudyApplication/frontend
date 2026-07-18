import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../lessons/data/models/exercise_model.dart';
import '../providers/admin_providers.dart';

class ExerciseImportScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const ExerciseImportScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  ConsumerState<ExerciseImportScreen> createState() => _ExerciseImportScreenState();
}

class _ExerciseImportScreenState extends ConsumerState<ExerciseImportScreen> {
  XFile? _selectedFile;
  bool _isValidating = false;
  bool _isImporting = false;
  ImportReportModel? _report;
  String? _errorMessage;

  Future<void> _pickFile() async {
    try {
      const typeGroupCsv = XTypeGroup(
        label: 'CSV Files',
        extensions: ['csv'],
        mimeTypes: ['text/csv', 'application/vnd.ms-excel'],
      );
      const typeGroupJson = XTypeGroup(
        label: 'JSON Files',
        extensions: ['json'],
        mimeTypes: ['application/json'],
      );

      final file = await openFile(
        acceptedTypeGroups: [typeGroupCsv, typeGroupJson],
      );

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _report = null;
          _errorMessage = null;
        });
        await _runDryRun();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chọn file: $e';
      });
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final bytes = await ref.read(adminServiceProvider).downloadImportTemplate();

      // getDownloadsDirectory() is only supported on Android/Linux/macOS/Windows
      // (throws UnsupportedError on iOS/web), so fall back to the app's sandboxed
      // documents folder there — file_selector's save dialog isn't an option since
      // getSaveLocation() has no Android/iOS implementation.
      Directory saveDir;
      try {
        saveDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      } catch (_) {
        saveDir = await getApplicationDocumentsDirectory();
      }

      final file = File('${saveDir.path}/exercise_import_template.csv');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu file mẫu vào: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải file mẫu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runDryRun() async {
    if (_selectedFile == null) return;
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final report = await ref.read(adminServiceProvider).importExercises(
            lessonId: widget.lessonId,
            fileBytes: bytes,
            fileName: _selectedFile!.name,
            dryRun: true,
          );
      setState(() {
        _report = report;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isValidating = false;
      });
    }
  }

  Future<void> _runImport() async {
    if (_selectedFile == null || _report == null || _report!.errors.isNotEmpty) return;
    setState(() {
      _isImporting = true;
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final finalReport = await ref.read(adminServiceProvider).importExercises(
            lessonId: widget.lessonId,
            fileBytes: bytes,
            fileName: _selectedFile!.name,
            dryRun: false,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã import thành công ${finalReport.inserted} câu hỏi!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(lessonExercisesProvider(widget.lessonId));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import câu hỏi từ file'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bài học: ${widget.lessonTitle}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập câu hỏi hàng loạt bằng file CSV hoặc JSON. Hệ thống sẽ tự động kiểm tra cú pháp và tính hợp lệ trước khi ghi đè hoặc bổ sung.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedFile == null) _buildFilePickerArea(theme) else _buildSelectedFileCard(theme),
            if (_isValidating) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Đang phân tích và kiểm tra file...', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              _buildErrorAlert(theme, _errorMessage!),
            ],
            if (!_isValidating && _report != null) ...[
              const SizedBox(height: 24),
              _buildReportSection(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerArea(ThemeData theme) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(80),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _pickFile,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(100),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_outlined, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Chọn file CSV hoặc JSON từ thiết bị',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Kích thước tối đa: 1MB',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Tải file mẫu (CSV)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              _selectedFile!.name.endsWith('.json') ? Icons.code_rounded : Icons.table_chart_rounded,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFile!.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: _selectedFile!.length(),
                    builder: (context, snapshot) {
                      final bytes = snapshot.data ?? 0;
                      final kb = bytes / 1024;
                      return Text(
                        '${kb.toStringAsFixed(1)} KB',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Chọn file khác',
              onPressed: _pickFile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorAlert(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withAlpha(100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lỗi tải file / Validation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection(ThemeData theme) {
    final hasErrors = _report!.errors.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: hasErrors ? theme.colorScheme.errorContainer.withAlpha(30) : Colors.green.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: hasErrors ? theme.colorScheme.error.withAlpha(100) : Colors.green.withAlpha(100),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  hasErrors ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
                  color: hasErrors ? theme.colorScheme.error : Colors.green,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasErrors ? 'Phát hiện lỗi nhập liệu!' : 'Kiểm tra hoàn tất!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasErrors ? theme.colorScheme.error : Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasErrors
                            ? 'Có ${_report!.errors.length} lỗi cần phải sửa trước khi tiếp tục.'
                            : 'Mọi thứ hợp lệ. Tổng số câu hỏi: ${_report!.totalRows}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hasErrors ? theme.colorScheme.error : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (hasErrors) ...[
          Text('Chi tiết lỗi (${_report!.errors.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildIssuesTable(theme, _report!.errors, isError: true),
          const SizedBox(height: 24),
        ],
        if (_report!.warnings.isNotEmpty) ...[
          Text('Cảnh báo (${_report!.warnings.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildIssuesTable(theme, _report!.warnings, isError: false),
          const SizedBox(height: 24),
        ],
        if (!hasErrors && _report!.preview.isNotEmpty) ...[
          Text('Bản xem trước (Tối đa 5 câu đầu)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _report!.preview.length,
            itemBuilder: (context, idx) {
              final item = _report!.preview[idx] as Map<String, dynamic>;
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withAlpha(127),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (item['exercise_type'] as String? ?? '').toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Mức độ: ${item['level']}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['question'] as String? ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đáp án đúng: ${item['correct_answer']}',
                        style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        ElevatedButton(
          onPressed: (hasErrors || _isImporting) ? null : _runImport,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isImporting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Xác nhận Import', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildIssuesTable(ThemeData theme, List<ImportIssue> issues, {required bool isError}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FixedColumnWidth(100),
            2: FlexColumnWidth(),
          },
          border: TableBorder.symmetric(
            inside: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
              ),
              children: const [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dòng', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Trường', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Chi tiết lỗi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            ...issues.map((issue) {
              return TableRow(
                decoration: BoxDecoration(
                  color: isError ? Colors.red.shade50.withAlpha(100) : Colors.orange.shade50.withAlpha(100),
                ),
                children: [
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(issue.row?.toString() ?? 'Tất cả'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(issue.field ?? 'File'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        issue.message,
                        style: TextStyle(
                          color: isError ? Colors.red.shade900 : Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
