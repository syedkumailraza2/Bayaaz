// On-device LLM service.
//
// CURRENT STATE: Pack lifecycle (auto-download / 24h auto-delete) is fully
// wired. Inference is a stub — activate by completing the native build steps:
//
//   Android (NDK):
//     cd llama.cpp && mkdir build-android && cd build-android
//     cmake .. -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
//              -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24
//     cmake --build . --config Release
//     cp libllama.so <project>/android/app/src/main/jniLibs/arm64-v8a/
//
//   iOS (Xcode):
//     cmake -B build-ios -G Xcode -DCMAKE_SYSTEM_NAME=iOS ...
//     Embed xcframework → ios/Frameworks/
//
//   Then replace the generate() body with dart:ffi bindings to
//   llama_init / llama_tokenize / llama_decode / llama_sampling_sample.
//
// Model: Phi-3 Mini Q4_K_M GGUF (~2.3 GB).
// Downloaded automatically by PackManager when COACH_PACK_URL is set
// and the device is high-tier. Auto-deleted after 24 hours.

import 'dart:io';

import 'pack_manager.dart';

class LlmService {
  static final LlmService instance = LlmService._();
  LlmService._();

  bool _loaded = false;

  /// True once tryLoadFromInstalledPack() has found the model file on disk.
  /// Checked by FeedbackEngine to decide whether to use AI or template feedback.
  bool get isModelLoaded => _loaded;

  /// Checks whether the coach pack's model file is present and marks the
  /// service as loaded. Call this at startup after PackManager finishes.
  Future<void> tryLoadFromInstalledPack() async {
    final dir = await PackManager.instance.packDirectory(PackId.coach);
    if (dir == null) {
      _loaded = false;
      return;
    }
    _loaded = File('$dir/pack.bin').existsSync();
    if (_loaded) {
      // TODO: call llama_model_load_from_file('$dir/pack.bin') via dart:ffi
    }
  }

  /// Token-streaming generation. Yields tokens as they are produced.
  /// Falls back to an empty stream until the dart:ffi bindings are wired up.
  Stream<String> generate(String prompt, {int maxTokens = 256}) async* {
    if (!_loaded) return;
    // TODO: call llama_decode in a background isolate and yield tokens
  }

  void unloadModel() {
    _loaded = false;
    // TODO: call llama_model_free via dart:ffi
  }
}
