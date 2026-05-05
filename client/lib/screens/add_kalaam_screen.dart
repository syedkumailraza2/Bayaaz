import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kalaam_model.dart';
import '../providers/kalaam_provider.dart';

class AddKalaamScreen extends StatefulWidget {
  const AddKalaamScreen({super.key});

  @override
  State<AddKalaamScreen> createState() => _AddKalaamScreenState();
}

class _AddKalaamScreenState extends State<AddKalaamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _poetController = TextEditingController();
  final _tagsController = TextEditingController();
  String _category = kKalaamCategories.first;
  bool _isPublic = true;
  bool _submitting = false;

  // Each stanza is a list of line controllers
  final List<List<TextEditingController>> _stanzas = [];

  @override
  void initState() {
    super.initState();
    _addStanza(); // start with one stanza
  }

  void _addStanza() {
    setState(() {
      _stanzas.add([TextEditingController()]);
    });
  }

  void _removeStanza(int stanzaIndex) {
    setState(() {
      for (final c in _stanzas[stanzaIndex]) { c.dispose(); }
      _stanzas.removeAt(stanzaIndex);
    });
  }

  void _addLine(int stanzaIndex) {
    setState(() => _stanzas[stanzaIndex].add(TextEditingController()));
  }

  void _removeLine(int stanzaIndex, int lineIndex) {
    setState(() {
      _stanzas[stanzaIndex][lineIndex].dispose();
      _stanzas[stanzaIndex].removeAt(lineIndex);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _poetController.dispose();
    _tagsController.dispose();
    for (final stanza in _stanzas) {
      for (final c in stanza) { c.dispose(); }
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _buildContent() {
    return _stanzas.asMap().entries.map((entry) {
      final lines = entry.value
          .map((c) => c.text.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      return {'stanzaNumber': entry.key + 1, 'lines': lines};
    }).where((s) => (s['lines'] as List).isNotEmpty).toList();
  }

  bool _hasContent() => _stanzas.any(
        (stanza) => stanza.any((c) => c.text.trim().isNotEmpty),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasContent()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line of content'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _submitting = true);

    final parsedTags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final success = await context.read<KalaamProvider>().addKalaam(
          title: _titleController.text.trim(),
          content: _buildContent(),
          category: _category,
          isPublic: _isPublic,
          poet: _poetController.text.trim().isEmpty ? null : _poetController.text.trim(),
          tags: parsedTags,
        );

    setState(() => _submitting = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kalaam saved!'), backgroundColor: Color(0xFF2d7a4f)),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        title: const Text('Add Kalaam'),
        actions: [
          if (_submitting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFe2b96f))),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Save', style: TextStyle(color: Color(0xFFe2b96f), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _FieldLabel('Title'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Enter kalaam title'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            _FieldLabel('Poet (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _poetController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('e.g. Mir Anis, Allama Iqbal'),
            ),
            const SizedBox(height: 20),
            _FieldLabel('Tags (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _tagsController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('e.g. imam hussain, karbala, azadari'),
            ),
            const SizedBox(height: 20),
            _FieldLabel('Category'),
            const SizedBox(height: 10),
            _CategorySelector(
              selected: _category,
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 24),
            _FieldLabel('Content'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showPasteDialog,
              icon: const Icon(Icons.content_paste, color: Color(0xFFe2b96f), size: 18),
              label: const Text('Paste Full Kalaam', style: TextStyle(color: Color(0xFFe2b96f))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFe2b96f)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // Stanzas
            ..._stanzas.asMap().entries.map((stanzaEntry) {
              final si = stanzaEntry.key;
              final lineControllers = stanzaEntry.value;
              return _StanzaEditor(
                stanzaNumber: si + 1,
                lineControllers: lineControllers,
                canRemove: _stanzas.length > 1,
                onAddLine: () => _addLine(si),
                onRemoveLine: (li) => _removeLine(si, li),
                onRemoveStanza: () => _removeStanza(si),
              );
            }),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addStanza,
              icon: const Icon(Icons.add, color: Color(0xFFe2b96f)),
              label: const Text('Add Stanza', style: TextStyle(color: Color(0xFFe2b96f))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFe2b96f)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            _VisibilityToggle(
              isPublic: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _applyPastedText(String raw) {
    // Normalize line endings
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (text.isEmpty) return;

    // Split into stanza chunks by one or more blank lines
    final chunks = text
        .split(RegExp(r'\n[ \t]*\n+'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    if (chunks.isEmpty) return;

    // Dispose existing controllers
    for (final stanza in _stanzas) {
      for (final c in stanza) c.dispose();
    }

    setState(() {
      _stanzas.clear();
      for (final chunk in chunks) {
        final lines = chunk
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        if (lines.isEmpty) continue;
        final controllers = lines.map((l) {
          final c = TextEditingController(text: l);
          return c;
        }).toList();
        _stanzas.add(controllers);
      }
      // Ensure at least one stanza
      if (_stanzas.isEmpty) _stanzas.add([TextEditingController()]);
    });
  }

  void _showPasteDialog() {
    final pasteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste Kalaam Text',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Separate stanzas with a blank line',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: pasteController,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                maxLines: 12,
                minLines: 6,
                decoration: InputDecoration(
                  hintText: 'Paste your kalaam here…',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0f0f1a),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFe2b96f))),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _applyPastedText(pasteController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFe2b96f),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Parse & Apply',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: const Color(0xFF1a1a2e),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFe2b96f))),
      );
}

class _StanzaEditor extends StatelessWidget {
  final int stanzaNumber;
  final List<TextEditingController> lineControllers;
  final bool canRemove;
  final VoidCallback onAddLine;
  final void Function(int) onRemoveLine;
  final VoidCallback onRemoveStanza;

  const _StanzaEditor({
    required this.stanzaNumber,
    required this.lineControllers,
    required this.canRemove,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onRemoveStanza,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stanza header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFe2b96f).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Stanza $stanzaNumber',
                    style: const TextStyle(color: Color(0xFFe2b96f), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (canRemove)
                  GestureDetector(
                    onTap: onRemoveStanza,
                    child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Lines
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                ...lineControllers.asMap().entries.map((entry) {
                  final li = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 16, child: Text('${li + 1}', style: const TextStyle(color: Colors.white24, fontSize: 12))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: entry.value,
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                            decoration: InputDecoration(
                              hintText: 'Line ${li + 1}',
                              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFF0f0f1a),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFe2b96f))),
                            ),
                          ),
                        ),
                        if (lineControllers.length > 1) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onRemoveLine(li),
                            child: const Icon(Icons.close, color: Colors.white24, size: 16),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAddLine,
                    icon: const Icon(Icons.add, size: 14, color: Colors.white38),
                    label: const Text('Add line', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
      );
}

class _CategorySelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _CategorySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: kKalaamCategories.map((cat) {
        final isSelected = selected == cat;
        final label = cat[0].toUpperCase() + cat.substring(1);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(cat),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFe2b96f) : const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? const Color(0xFFe2b96f) : Colors.white24),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool isPublic;
  final void Function(bool) onChanged;
  const _VisibilityToggle({required this.isPublic, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(isPublic ? Icons.public : Icons.lock_outline, color: isPublic ? const Color(0xFFe2b96f) : Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPublic ? 'Public' : 'Private', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(isPublic ? 'Visible to everyone' : 'Only you can see this', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: isPublic,
            activeThumbColor: const Color(0xFFe2b96f),
            activeTrackColor: const Color(0x80e2b96f),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
