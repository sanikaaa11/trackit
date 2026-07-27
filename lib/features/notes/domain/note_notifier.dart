import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/note_model.dart';
import '../data/note_repository.dart';

final noteRepositoryProvider = Provider((ref) => NoteRepository());

final notesProvider = StateNotifierProvider<NoteNotifier, List<Note>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return NoteNotifier(repository);
});

class NoteNotifier extends StateNotifier<List<Note>> {
  NoteNotifier(this.repository) : super([]) {
    loadNotes();
  }

  final NoteRepository repository;

  void loadNotes() {
    state = repository.getAllNotes();
  }

  Future<void> addNote(Note note) async {
    await repository.addNote(note);
    loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await repository.deleteNote(id);
    loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await repository.updateNote(note);
    loadNotes();
  }

  Future<void> togglePin(String id) async {
    await repository.togglePin(id);
    loadNotes();
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return notes;

  return notes.where((note) {
    return note.title.toLowerCase().contains(query) ||
        note.body.toLowerCase().contains(query);
  }).toList();
});
