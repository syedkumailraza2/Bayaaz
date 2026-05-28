import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import '../config/app_config.dart';
import '../models/kalaam_model.dart';
import '../services/analytics_service.dart';
import '../services/device_capability_service.dart';
import '../services/feedback_engine.dart';
import '../services/scoring_service.dart';

enum ListenSessionState { idle, recording, processing, scored, error }

class ListenSessionProvider extends ChangeNotifier {
  ListenSessionState _state = ListenSessionState.idle;
  SessionScore? _latestScore;
  PracticeFeedback? _latestFeedback;
  KalaamModel? _kalaam;

  // Running timer shown while recording (seconds elapsed).
  int _elapsedSeconds = 0;
  Timer? _timer;

  DateTime? _sessionStart;
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmSub;
  final _pcmChunks = <Uint8List>[];

  ListenSessionState get state => _state;
  SessionScore? get latestScore => _latestScore;
  PracticeFeedback? get latestFeedback => _latestFeedback;
  KalaamModel? get kalaam => _kalaam;
  int get elapsedSeconds => _elapsedSeconds;

  Future<void> startListening(KalaamModel kalaam) async {
    if (_state == ListenSessionState.recording) return;
    _kalaam = kalaam;
    _pcmChunks.clear();
    _latestScore = null;
    _latestFeedback = null;
    _elapsedSeconds = 0;
    _sessionStart = null;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _state = ListenSessionState.error;
      notifyListeners();
      return;
    }

    _state = ListenSessionState.recording;
    _sessionStart = DateTime.now();
    notifyListeners();

    // Start elapsed-time ticker so the UI can show a recording clock.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));
    _pcmSub = stream.listen((chunk) => _pcmChunks.add(chunk));
  }

  Future<void> stopAndScore() async {
    if (_state != ListenSessionState.recording) return;

    _timer?.cancel();
    _timer = null;
    await _pcmSub?.cancel();
    _pcmSub = null;
    await _recorder.stop();

    await _scoreFromRecording();
  }

  Future<void> _scoreFromRecording() async {
    _state = ListenSessionState.processing;
    notifyListeners();

    final kalaam = _kalaam;
    if (kalaam == null) {
      _state = ListenSessionState.error;
      notifyListeners();
      return;
    }

    try {
      final refLines = [
        for (final stanza in kalaam.content) ...stanza.lines,
      ];

      final transcript = await _transcribeViaServer(refLines);
      debugPrint('[Listen] transcript: $transcript');

      final hypLines = ScoringService.alignToLines(transcript, refLines);
      final duration = _sessionStart != null
          ? DateTime.now().difference(_sessionStart!)
          : null;
      _latestScore = ScoringService.scoreSession(
        referenceLines: refLines,
        hypothesisLines: hypLines,
        sessionDuration: duration,
      );

      final tier = DeviceCapabilityService.instance.tier;
      _latestFeedback =
          await FeedbackEngine.forTier(tier).generate(_latestScore!, kalaam);

      AnalyticsService.instance
          .recordSession(kalaam: kalaam, score: _latestScore!, mode: 'listen')
          .ignore();

      _state = ListenSessionState.scored;
    } catch (e) {
      debugPrint('[Listen] Scoring error: $e');
      _state = ListenSessionState.error;
    }
    notifyListeners();
  }

  // Send the collected PCM audio to the server's Whisper STT endpoint.
  // Whisper handles Urdu speech and outputs Roman transliteration when
  // given language="en" — no vocabulary list needed.
  Future<String> _transcribeViaServer(List<String> refLines) async {
    if (_pcmChunks.isEmpty) return '';

    // Concatenate all PCM chunks.
    final totalLen = _pcmChunks.fold(0, (s, c) => s + c.length);
    final pcm = Uint8List(totalLen);
    var offset = 0;
    for (final chunk in _pcmChunks) {
      pcm.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    // Prepend a minimal 44-byte WAV header so Whisper can read the file.
    final wav = _buildWav(pcm, sampleRate: 16000, channels: 1, bitsPerSample: 16);

    // First two lines as Whisper initial_prompt — this biases the output
    // toward Roman Urdu style instead of English translation.
    final hint = refLines.take(2).join(' ');

    final uri = Uri.parse('${AppConfig.apiUrl}/stt/transcribe');
    final request = http.MultipartRequest('POST', uri)
      ..fields['hint'] = hint
      ..files.add(http.MultipartFile.fromBytes(
        'audio',
        wav,
        filename: 'recording.wav',
      ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final body = await http.Response.fromStream(streamed);
    if (body.statusCode != 200) {
      throw Exception('STT server error ${body.statusCode}: ${body.body}');
    }

    // Parse {"transcript": "..."}
    final json = body.body;
    final match = RegExp(r'"transcript"\s*:\s*"([^"]*)"').firstMatch(json);
    return match?.group(1) ?? '';
  }

  // Build a 44-byte RIFF WAV header + PCM body.
  static Uint8List _buildWav(
    Uint8List pcm, {
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataLen = pcm.length;
    final fileLen = 36 + dataLen;

    final buf = ByteData(44 + dataLen);
    // RIFF chunk
    buf.setUint8(0, 0x52); buf.setUint8(1, 0x49); // 'R','I'
    buf.setUint8(2, 0x46); buf.setUint8(3, 0x46); // 'F','F'
    buf.setUint32(4, fileLen, Endian.little);
    buf.setUint8(8, 0x57); buf.setUint8(9, 0x41);  // 'W','A'
    buf.setUint8(10, 0x56); buf.setUint8(11, 0x45); // 'V','E'
    // fmt sub-chunk
    buf.setUint8(12, 0x66); buf.setUint8(13, 0x6D); // 'f','m'
    buf.setUint8(14, 0x74); buf.setUint8(15, 0x20); // 't',' '
    buf.setUint32(16, 16, Endian.little);  // chunk size
    buf.setUint16(20, 1, Endian.little);   // PCM format
    buf.setUint16(22, channels, Endian.little);
    buf.setUint32(24, sampleRate, Endian.little);
    buf.setUint32(28, byteRate, Endian.little);
    buf.setUint16(32, blockAlign, Endian.little);
    buf.setUint16(34, bitsPerSample, Endian.little);
    // data sub-chunk
    buf.setUint8(36, 0x64); buf.setUint8(37, 0x61); // 'd','a'
    buf.setUint8(38, 0x74); buf.setUint8(39, 0x61); // 't','a'
    buf.setUint32(40, dataLen, Endian.little);

    final out = buf.buffer.asUint8List();
    out.setRange(44, 44 + dataLen, pcm);
    return out;
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _pcmSub?.cancel();
    _pcmSub = null;
    _recorder.cancel().ignore();
    _state = ListenSessionState.idle;
    _latestScore = null;
    _latestFeedback = null;
    _elapsedSeconds = 0;
    _pcmChunks.clear();
    _sessionStart = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pcmSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
