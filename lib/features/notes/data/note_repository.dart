import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/utils/account_scope.dart';
import 'note_model.dart';

class NoteRepository {
  static const String boxName = 'notes_box';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Note>(boxName);
    }
  }

  Box<Note> get _box => Hive.box<Note>(boxName);

  List<Note> getAllNotes() {
    final notes = _box.keys
        .where(AccountScope.matchesCurrentScopeKey)
        .map((key) => _box.get(key))
        .whereType<Note>()
        .toList();
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  Future<void> addNote(Note note) async {
    await _box.put(AccountScope.scopedHiveKey(note.id), note);
  }

  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    await note.save();
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(AccountScope.scopedHiveKey(id));
  }

  Future<void> togglePin(String id) async {
    final note = _box.get(AccountScope.scopedHiveKey(id));
    if (note == null) return;

    note.isPinned = !note.isPinned;
    note.updatedAt = DateTime.now();
    await note.save();
  }

  List<Note> searchNotes(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return getAllNotes();

    return getAllNotes().where((note) {
      return note.title.toLowerCase().contains(trimmed) ||
          note.body.toLowerCase().contains(trimmed);
    }).toList();
  }
}
