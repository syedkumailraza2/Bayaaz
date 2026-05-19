import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kalaam_model.dart';
import '../providers/kalaam_provider.dart';

class AddKalaamScreen extends StatefulWidget {
  final KalaamModel? existing;
  const AddKalaamScreen({super.key, this.existing});

  @override
  State<AddKalaamScreen> createState() => _AddKalaamScreenState();
}

class _AddKalaamScreenState extends State<AddKalaamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _poetController = TextEditingController();
  final _tagsController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = kKalaamCategories.first;
  bool _isPublic = true;
  bool _submitting = false;

  KalaamModel? get _existing =>
      widget.existing ?? ModalRoute.of(context)?.settings.arguments as KalaamModel?;

  bool get _isEditing => _existing != null;

  @override
  void initState() {
    super.initState();
    // Defer to didChangeDependencies for ModalRoute access
  }

  bool _prefilled = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    final existing = _existing;
    if (existing == null) {
      _prefilled = true;
      return;
    }
    _titleController.text = existing.title;
    _poetController.text = existing.poet ?? '';
    _tagsController.text = existing.tags.join(', ');
    _contentController.text = existing.content
        .map((s) => s.lines.join('\n'))
        .join('\n\n');
    _category = existing.category;
    _isPublic = existing.isPublic;
    _prefilled = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _poetController.dispose();
    _tagsController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _buildContent() {
    final text = _contentController.text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (text.isEmpty) return [];

    final chunks = text
        .split(RegExp(r'\n[ \t]*\n+'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final stanzas = <Map<String, dynamic>>[];
    for (final chunk in chunks) {
      final lines = chunk
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;
      stanzas.add({'stanzaNumber': stanzas.length + 1, 'lines': lines});
    }
    return stanzas;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final content = _buildContent();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste the kalaam content'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _submitting = true);

    final parsedTags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final provider = context.read<KalaamProvider>();
    final existing = _existing;
    final bool success;
    if (existing != null) {
      success = await provider.updateKalaam(
        id: existing.id,
        title: _titleController.text.trim(),
        content: content,
        category: _category,
        isPublic: _isPublic,
        poet: _poetController.text.trim().isEmpty ? null : _poetController.text.trim(),
        tags: parsedTags,
      );
    } else {
      success = await provider.addKalaam(
        title: _titleController.text.trim(),
        content: content,
        category: _category,
        isPublic: _isPublic,
        poet: _poetController.text.trim().isEmpty ? null : _poetController.text.trim(),
        tags: parsedTags,
      );
    }

    setState(() => _submitting = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Kalaam updated!' : 'Kalaam saved!'),
          backgroundColor: const Color(0xFF2d7a4f),
        ),
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
        title: Text(_isEditing ? 'Edit Kalaam' : 'Add Kalaam'),
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
            const SizedBox(height: 4),
            const Text(
              'Paste the full kalaam. Separate stanzas with a blank line.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contentController,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
              maxLines: null,
              minLines: 12,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: _inputDecoration('Paste your kalaam here…'),
            ),
            const SizedBox(height: 24),
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
