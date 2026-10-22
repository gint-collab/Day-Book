import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import 'tag_pill.dart';

/// Chip-style tag editor.
///
/// A tag is committed on Enter, comma, space, or when the field loses
/// focus — so a typed tag is never silently dropped. Text that hasn't been
/// committed yet is reported through [onPendingChanged].
class TagsInput extends StatefulWidget {
  const TagsInput({super.key, required this.tags, required this.onAdd, required this.onRemove, this.onPendingChanged});

  final List<String> tags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String>? onPendingChanged;

  @override
  State<TagsInput> createState() => _TagsInputState();
}

class _TagsInputState extends State<TagsInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commit(_controller.text, refocus: false);
    });
  }

  @override
  void didUpdateWidget(TagsInput old) {
    super.didUpdateWidget(old);
    // The editor committed the pending text itself (e.g. on save).
    final pending = _controller.text.trim().replaceAll(RegExp(r'^#+'), '').toLowerCase();
    if (pending.isNotEmpty && widget.tags.contains(pending) && !old.tags.contains(pending)) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commit(String value, {bool refocus = true}) {
    if (value.replaceAll('#', '').trim().isNotEmpty) widget.onAdd(value);
    _controller.clear();
    widget.onPendingChanged?.call('');
    if (refocus) _focusNode.requestFocus();
  }

  void _onChanged(String v) {
    if (v.endsWith(',') || v.endsWith(' ')) {
      _commit(v.substring(0, v.length - 1));
    } else {
      widget.onPendingChanged?.call(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Wrap(
      spacing: Space.sm - 2,
      runSpacing: Space.sm - 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tag in widget.tags) TagPill(tag, onRemove: () => widget.onRemove(tag)),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
          child: IntrinsicWidth(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: _commit,
              onChanged: _onChanged,
              style: theme.textTheme.labelLarge,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: widget.tags.isEmpty ? 'Add tags — work, family…' : 'Add tag',
                prefixIcon: Icon(Icons.tag, size: 16, color: scheme.onSurfaceVariant),
                prefixIconConstraints: const BoxConstraints(minWidth: 28),
                contentPadding: const EdgeInsets.symmetric(vertical: Space.sm),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
