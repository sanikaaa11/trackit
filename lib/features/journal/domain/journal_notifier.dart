import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trackit/features/badges/data/badge_service.dart';

import '../data/journal_model.dart';
import '../data/journal_repository.dart';

final journalRepositoryProvider = Provider((ref) => JournalRepository());

final journalProvider =
    StateNotifierProvider<JournalNotifier, List<JournalEntry>>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  return JournalNotifier(repository, ref);
});

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  JournalNotifier(this.repository, this.ref) : super([]) {
    _init();
  }

  final JournalRepository repository;
  final Ref ref;
  StreamSubscription? _watchSub;

  Future<void> _init() async {
    await repository.init();
    loadEntries();
    _watchSub = repository.watchEntries().listen((_) => loadEntries());
  }

  void loadEntries() {
    state = repository.getAllEntries();
  }

  Future<String?> saveEntry(JournalEntry entry) async {
    await repository.saveEntry(entry);
    loadEntries();

    // Badge check — dear diary
    final badgeService = ref.read(badgeServiceProvider);
    return await badgeService.checkAndAward('journal_written', {});
  }

  Future<void> deleteEntry(String id) async {
    await repository.deleteEntry(id);
    loadEntries();
  }

  @override
  void dispose() {
    _watchSub?.cancel();
    super.dispose();
  }
}

final todayEntryProvider = Provider<JournalEntry?>((ref) {
  final entries = ref.watch(journalProvider);
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  for (final entry in entries) {
    if (entry.date == today) return entry;
  }
  return null;
});