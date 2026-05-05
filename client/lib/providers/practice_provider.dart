import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeProgress {
  final int lastLine;
  final int lastStanza;
  final bool completed;
  final String mode;
  final int loopStanza; // -1 = no loop

  const PracticeProgress({
    required this.lastLine,
    required this.lastStanza,
    required this.completed,
    required this.mode,
    required this.loopStanza,
  });

  PracticeProgress copyWith({
    int? lastLine,
    int? lastStanza,
    bool? completed,
    String? mode,
    int? loopStanza,
  }) {
    return PracticeProgress(
      lastLine: lastLine ?? this.lastLine,
      lastStanza: lastStanza ?? this.lastStanza,
      completed: completed ?? this.completed,
      mode: mode ?? this.mode,
      loopStanza: loopStanza ?? this.loopStanza,
    );
  }
}

class PracticeProvider extends ChangeNotifier {
  final Map<String, PracticeProgress> _progress = {};

  PracticeProgress? getProgress(String kalaamId) => _progress[kalaamId];

  Future<void> loadProgress(String kalaamId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLine = prefs.getInt('practice_last_line_$kalaamId') ?? 0;
    final lastStanza = prefs.getInt('practice_last_stanza_$kalaamId') ?? 0;
    final mode = prefs.getString('practice_mode_$kalaamId') ?? 'solo';
    final completed = prefs.getBool('practice_completed_$kalaamId') ?? false;
    final loopStanza = prefs.getInt('practice_loop_stanza_$kalaamId') ?? -1;

    _progress[kalaamId] = PracticeProgress(
      lastLine: lastLine,
      lastStanza: lastStanza,
      completed: completed,
      mode: mode,
      loopStanza: loopStanza,
    );
    notifyListeners();
  }

  Future<void> saveProgress(String kalaamId, PracticeProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('practice_last_line_$kalaamId', p.lastLine);
    await prefs.setInt('practice_last_stanza_$kalaamId', p.lastStanza);
    await prefs.setString('practice_mode_$kalaamId', p.mode);
    await prefs.setBool('practice_completed_$kalaamId', p.completed);
    await prefs.setInt('practice_loop_stanza_$kalaamId', p.loopStanza);

    _progress[kalaamId] = p;
    notifyListeners();
  }
}
