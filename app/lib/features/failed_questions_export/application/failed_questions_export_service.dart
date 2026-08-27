import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../models/local_user.dart';
import '../../backup/data/backup_file_io.dart';
import '../data/failed_questions_export_store.dart';
import '../domain/failed_question_item.dart';
import '../domain/failed_questions_range.dart';
import '../domain/failed_questions_reminder.dart';
import 'failed_questions_collector.dart';
import 'failed_questions_html_report.dart';

class FailedQuestionsExportResult {
  const FailedQuestionsExportResult({
    required this.filePath,
    required this.shareName,
    required this.count,
    required this.skippedMissingTests,
  });

  final String filePath;
  final String shareName;
  final int count;
  final int skippedMissingTests;
}

class FailedQuestionsExportService {
  FailedQuestionsExportService(
    this._collector, {
    FailedQuestionsExportStore? store,
    BackupFileIo? fileIo,
    FailedQuestionsHtmlReport? report,
  })  : _store = store ?? FailedQuestionsExportStore(),
        _fileIo = fileIo ?? BackupFileIo(),
        _report = report ?? const FailedQuestionsHtmlReport();

  final FailedQuestionsCollector _collector;
  final FailedQuestionsExportStore _store;
  final BackupFileIo _fileIo;
  final FailedQuestionsHtmlReport _report;

  Future<DateTime?> lastExportAt(String userId) => _store.lastExportAt(userId);

  Future<void> markExported(String userId, {DateTime? at}) {
    return _store.setLastExportAt(userId, at ?? DateTime.now());
  }

  Future<FailedQuestionsReminderInterval> reminderInterval() => _store.reminderInterval();

  Future<void> setReminderInterval(FailedQuestionsReminderInterval interval) {
    return _store.setReminderInterval(interval);
  }

  Future<DateTime?> lastPromptedAt(String userId) => _store.lastPromptedAt(userId);

  Future<void> markReminderPrompted(String userId, {DateTime? at}) {
    return _store.setLastPromptedAt(userId, at ?? DateTime.now());
  }

  Future<bool> shouldPromptReminder({
    required String userId,
    DateTime? now,
  }) async {
    final interval = await reminderInterval();
    final lastExport = await lastExportAt(userId);
    final lastPrompt = await lastPromptedAt(userId);
    return shouldPromptFailedQuestionsReminder(
      interval: interval,
      now: now ?? DateTime.now(),
      lastExportAt: lastExport,
      lastPromptedAt: lastPrompt,
    );
  }

  FailedQuestionsRange rangeForReminder(FailedQuestionsReminderInterval interval, {DateTime? now}) {
    return switch (interval) {
      FailedQuestionsReminderInterval.none || FailedQuestionsReminderInterval.daily =>
        FailedQuestionsRange.lastDay(now: now),
      FailedQuestionsReminderInterval.weekly => FailedQuestionsRange.last7Days(now: now),
    };
  }

  Future<FailedQuestionsCollectResult> preview({
    required String userId,
    required FailedQuestionsRange range,
  }) {
    return _collector.collect(userId: userId, range: range);
  }

  Future<FailedQuestionsExportResult> export({
    required LocalUser user,
    required FailedQuestionsRange range,
    Directory? targetDir,
    DateTime? generatedAt,
  }) async {
    final collected = await _collector.collect(userId: user.id, range: range);
    final at = generatedAt ?? DateTime.now();
    final html = _report.build(
      userName: user.name,
      range: range,
      items: collected.items,
      skippedMissingTests: collected.skippedMissingTests,
      generatedAt: at,
    );
    final shareName = _shareName(user.name, at);
    final fileName = _fileName(user.name, at);
    final written = await _fileIo.writeText(
      fileName: fileName,
      contents: html,
      targetDir: targetDir ?? await getTemporaryDirectory(),
    );
    return FailedQuestionsExportResult(
      filePath: written.filePath,
      shareName: shareName,
      count: collected.items.length,
      skippedMissingTests: collected.skippedMissingTests,
    );
  }

  String _stamp(DateTime at) {
    final local = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}_${two(local.hour)}-${two(local.minute)}';
  }

  String _safeProfile(String profileName) {
    final trimmed = profileName.trim().isEmpty ? 'usuario' : profileName.trim();
    return trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll('·', '-')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  String _shareName(String profileName, DateTime at) {
    return 'OpoTest fallos_${_safeProfile(profileName)}_${_stamp(at)}';
  }

  String _fileName(String profileName, DateTime at) {
    return 'opotest_fallos_${_safeProfile(profileName)}_${_stamp(at)}.html';
  }
}
