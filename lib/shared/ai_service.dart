import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../features/journal/data/journal_model.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_KEY', defaultValue: '');
  return AIService(apiKey);
});

class AIService {
  final String _apiKey;

  AIService(this._apiKey) {
    print('=== AI SERVICE INIT ===');
    print('API Key empty: ${_apiKey.isEmpty}');
    print(
      'API Key first 8 chars: ${_apiKey.length > 8 ? _apiKey.substring(0, 8) : _apiKey}',
    );
  }

  GenerativeModel get _model => GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );

  // The gen z personality system prompt
  static const String _personality = '''
You are TrackIt AI — a chill, supportive productivity assistant for a gen z audience.

Your vibe:
- Talk like a smart friend who actually cares, not a corporate bot
- Keep it real and direct — no fluff, no filler phrases like "Certainly!" or "Great question!"
- Use emojis naturally but don't overdo it (1-2 per response max)
- Be encouraging without being fake or over the top
- When things look rough (overspending, missed habits), be honest but kind — like a friend who gets it

Your formatting style (ALWAYS follow this):
- Start with a one-line punchy summary of the answer
- Use short paragraphs (2-3 lines max each)
- When listing things, use this exact format with line breaks:
  → item one
  → item two
  → item three
- Never use ** for bold, never use # for headers, never use markdown
- Separate sections with a blank line
- End with one short actionable tip or encouraging line

Max 160 words total. Keep it tight.
''';

  String _cleanResponse(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*', dotAll: true), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*', dotAll: true), r'$1')
        .replaceAll(RegExp(r'#{1,6}\s.*'), '')
        .replaceAll(RegExp(r'`(.+?)`'), r'$1')
        .replaceAll(RegExp(r'^\s*[-*•]\s', multiLine: true), '→ ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<String> testConnection() async {
    try {
      if (_apiKey.isEmpty) return 'ERROR: API key is empty';
      final response = await _model.generateContent([
        Content.text('Say hello in one casual sentence.'),
      ]);
      return response.text ?? 'No response';
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  Future<String> getTaskPrioritySuggestion(
    List<String> taskTitles,
    List<String?> dueDates,
  ) async {
    try {
      if (_apiKey.isEmpty) return 'AI unavailable: API key not configured.';

      final tasks = List.generate(taskTitles.length, (index) {
        final due = index < dueDates.length ? dueDates[index] : null;
        return due == null || due.isEmpty
            ? '- ${taskTitles[index]}'
            : '- ${taskTitles[index]} (due: $due)';
      }).join('\n');

      final prompt = '''$_personality

The user has these pending tasks:
$tasks

Tell them which 3 to focus on today and why. Be specific about the deadlines.
Format: one punchy line, then list with → for each task, then one tip.''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _cleanResponse(response.text?.trim() ?? 'No response received');
    } catch (e) {
      print('Gemini task error: $e');
      return 'Can\'t reach AI rn — check your connection and try again.';
    }
  }

  Future<String> getExpenseSuggestions(
    Map<String, double> categoryTotals,
    double budget,
  ) async {
    try {
      if (_apiKey.isEmpty) return 'AI unavailable: API key not configured.';

      final categories = categoryTotals.entries
          .map((e) => '- ${e.key}: ₹${e.value.toStringAsFixed(0)}')
          .join('\n');

      final prompt = '''$_personality

Monthly budget: ₹$budget
What they spent:
$categories

Give 3 specific money-saving suggestions based on their actual spending.
Format: one punchy opening line, then list with » for each tip, then one encouraging close.''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _cleanResponse(response.text?.trim() ?? 'No response received');
    } catch (e) {
      print('Gemini expense error: $e');
      return 'Can\'t reach AI rn — check your connection and try again.';
    }
  }

  Future<String> getMoodSummary(List<JournalEntry> weekEntries) async {
    try {
      if (_apiKey.isEmpty) return 'AI unavailable: API key not configured.';

      if (weekEntries.isEmpty) {
        return 'No entries this week yet 📓\n\nStart writing — even just a few sentences counts. Your future self will thank you.';
      }

      final entrySummaries = weekEntries.map((e) {
        try {
          final date = DateTime.parse(e.date);
          final dayName =
              ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
          final preview = e.body.trim().isEmpty
              ? 'no text'
              : (e.body.length > 60 ? e.body.substring(0, 60) : e.body);
          final tags =
              e.emotionTags.isEmpty ? 'none' : e.emotionTags.join(', ');
          return '$dayName: mood ${e.moodScore}/10, energy ${e.energyLevel}, feeling: $tags. "$preview"';
        } catch (_) {
          return 'mood ${e.moodScore}/10';
        }
      }).join('\n');

      final avgMood =
          weekEntries.map((e) => e.moodScore).reduce((a, b) => a + b) /
              weekEntries.length;

      final prompt = '''$_personality

Journal data this week:
$entrySummaries

Average mood: ${avgMood.toStringAsFixed(1)}/10

Write a warm 3-4 sentence weekly mood summary. Note real patterns. End with something genuinely encouraging.
No lists needed here — just flowing honest prose like a thoughtful friend reflecting back their week.''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _cleanResponse(
          response.text?.trim() ?? 'Could not generate summary.');
    } catch (e) {
      print('Gemini mood summary error: $e');
      return 'Can\'t generate summary rn — try again later.';
    }
  }

  Future<String> getHabitInsight(
    Map<String, List<bool>> habitCompletions,
  ) async {
    try {
      if (_apiKey.isEmpty) return 'AI unavailable: API key not configured.';

      final data = habitCompletions.entries
          .map((e) =>
              '- ${e.key}: ${e.value.where((v) => v).length}/${e.value.length} days')
          .join('\n');

      final prompt = '''$_personality

30-day habit completion data:
$data

Give 2-3 insights about their patterns. Be real about what's working and what's not.
Format: one punchy opener, then list with → for each insight, then one tip.''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _cleanResponse(response.text?.trim() ?? 'No response received');
    } catch (e) {
      print('Gemini habit error: $e');
      return 'Can\'t reach AI rn — check your connection.';
    }
  }

  Future<String> chatWithData({
    required String userMessage,
    required Map<String, dynamic> appData,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        return 'AI needs a Gemini API key to work 🔑\n\nAdd it to your launch.json and restart the app.';
      }

      final hasData = (appData['pendingTasks'] ?? 0) > 0 ||
          (appData['monthlySpent'] ?? 0) > 0 ||
          (appData['habitCount'] ?? 0) > 0 ||
          (appData['journalCount'] ?? 0) > 0;

      final contextString = hasData
          ? '''User's TrackIt data:
- Pending tasks: ${appData['pendingTasks'] ?? 0}
- Tasks done this week: ${appData['completedThisWeek'] ?? 0}
- Monthly budget: ₹${appData['monthlyBudget'] ?? 0}
- Spent this month: ₹${appData['monthlySpent'] ?? 0}
- Biggest spending category: ${appData['topCategory'] ?? 'None'}
- Active habits: ${appData['habitCount'] ?? 0}
- Best streak: ${appData['bestStreak'] ?? 0} days
- Journal entries this week: ${appData['journalCount'] ?? 0}
- Avg mood this week: ${appData['avgMood'] ?? 'not tracked'}/10'''
          : 'User just joined TrackIt — no data yet. Welcome them and suggest what to set up first.';

      final prompt = '''$_personality

$contextString

User asked: $userMessage

Answer directly using their actual numbers where relevant.
If they ask something vague like "how was my week", give them a real summary across all their data.
If they ask for tips, make them specific to their situation not generic advice.''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();

      if (text == null || text.isEmpty) {
        return 'Got an empty response 😅 Try asking again!';
      }

      return _cleanResponse(text);
    } catch (e) {
      print('=== GEMINI FULL ERROR ===');
      print('Type: ${e.runtimeType}');
      print('Error: $e');
      return 'Connection issue rn 📡 Check your internet and try again.';
    }
  }
}