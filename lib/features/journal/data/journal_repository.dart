import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/account_scope.dart';
import 'journal_model.dart';

class JournalRepository {
  static const String boxName = 'journal_box';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<JournalEntry>(boxName);
    }
  }

  Stream<BoxEvent> watchEntries() {
    return _box.watch();
  }

  Box<JournalEntry> get _box => Hive.box<JournalEntry>(boxName);

  List<JournalEntry> getAllEntries() {
    final entries = _box.keys
        .where(AccountScope.matchesCurrentScopeKey)
        .map((key) => _box.get(key))
        .whereType<JournalEntry>()
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  JournalEntry? getEntryByDate(String date) {
    for (final entry in _box.values) {
      if (entry.date == date) {
        return entry;
      }
    }
    return null;
  }

  Future<void> saveEntry(JournalEntry entry) async {
    entry.updatedAt = DateTime.now();
    await _box.put(AccountScope.scopedHiveKey(entry.id), entry);
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(AccountScope.scopedHiveKey(id));
  }

  bool hasEntryForToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return getEntryByDate(today) != null;
  }
}
