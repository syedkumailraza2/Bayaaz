// Stub — real Vosk integration deferred until vosk_flutter resolves its http
// dependency conflict with the rest of the app. The ListenSessionProvider uses
// speech_to_text (device-native) for Phase 1. This file is kept so the import
// in the provider compiles; replace the body when Vosk becomes available.
class VoskSttService {
  static final VoskSttService instance = VoskSttService._();
  VoskSttService._();
  bool get isReady => false;
  Future<void> ensureModelLoaded() async {}
  void dispose() {}
}
