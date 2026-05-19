import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/socket_service.dart';

/// Opens a dialog letting the user override the server base URL at runtime.
/// Returns `true` if the URL was changed (caller can hot-restart the app).
Future<bool> showServerUrlDialog(BuildContext context) async {
  final controller = TextEditingController(text: AppConfig.override ?? AppConfig.envBaseUrl);
  String? errorText;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            title: const Text('Server URL', style: TextStyle(color: Color(0xFFe2b96f))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Default (build flag):\n${AppConfig.envBaseUrl}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Base URL',
                    labelStyle: const TextStyle(color: Colors.white54),
                    hintText: 'https://your-tunnel.trycloudflare.com',
                    hintStyle: const TextStyle(color: Colors.white24),
                    errorText: errorText,
                    filled: true,
                    fillColor: const Color(0xFF0f0f1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFe2b96f)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tip: enter the bare host (no /api). Restart the app after saving so all sockets reconnect.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () async {
                  await AppConfig.setBaseUrl(null);
                  SocketService().disconnect();
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe2b96f),
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final raw = controller.text.trim();
                  if (raw.isEmpty) {
                    setLocal(() => errorText = 'URL cannot be empty');
                    return;
                  }
                  final uri = Uri.tryParse(raw);
                  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                    setLocal(() => errorText = 'Enter a valid URL (https://host or http://host)');
                    return;
                  }
                  await AppConfig.setBaseUrl(raw);
                  SocketService().disconnect();
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  return result ?? false;
}
