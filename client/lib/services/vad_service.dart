// VAD service stub — Silero VAD via onnxruntime is deferred until the
// listen pipeline switches from speech_to_text to raw PCM recording
// (record package + Vosk). When that switch happens:
//   1. Add `onnxruntime: ^1.18.0` to pubspec.yaml
//   2. Add `assets/models/silero_vad.onnx` to flutter.assets
//   3. Replace the body below with real OrtSession inference
//
// Silero VAD expects:
//   - Input tensor: float32 [1, 1, 512] (32ms frame at 16kHz)
//   - Output tensor: float32 probability of speech [0.0–1.0]
//   - Context tensors: h/c (LSTM state, shape [2, 1, 64])
import 'dart:typed_data';

class SpeechSegment {
  final int startFrame;
  final int endFrame;
  const SpeechSegment({required this.startFrame, required this.endFrame});

  int get lengthFrames => endFrame - startFrame;
}

class VadService {
  static final VadService instance = VadService._();
  VadService._();

  bool get isReady => false;

  Future<void> ensureLoaded() async {
    // No-op until onnxruntime integration is added.
  }

  // Feed one 512-sample (32ms @ 16kHz) PCM frame; returns speech probability.
  // Returns 0.0 in stub mode.
  double processPcmFrame(Uint8List frame) => 0.0;

  // Detect speech segments in a sequence of 32ms frames.
  List<SpeechSegment> detectSegments(
    List<Uint8List> frames, {
    double threshold = 0.5,
    int minSpeechFrames = 3,
    int paddingFrames = 2,
  }) =>
      [];

  void dispose() {}
}
