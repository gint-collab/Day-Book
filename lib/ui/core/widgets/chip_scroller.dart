import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// A horizontally scrolling row (for filter chips) that works with a mouse:
///
/// * the vertical mouse wheel scrolls it sideways (instead of the page)
///   while there is somewhere to scroll,
/// * it can be dragged with the mouse as well as touch / trackpad,
/// * a thin scrollbar appears on hover so it's clear more chips exist.
class ChipScroller extends StatefulWidget {
  const ChipScroller({super.key, required this.children, this.spacing = Space.sm - 2});

  final List<Widget> children;
  final double spacing;

  @override
  State<ChipScroller> createState() => _ChipScrollerState();
}

class _ChipScrollerState extends State<ChipScroller> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final position = _controller.position;
    final delta = event.scrollDelta.dx != 0 ? event.scrollDelta.dx : event.scrollDelta.dy;
    final target = (position.pixels + delta).clamp(position.minScrollExtent, position.maxScrollExtent);
    // At either end, let the wheel fall through to scroll the page.
    if (target == position.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) => _controller.jumpTo(target));
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      for (final (i, child) in widget.children.indexed) ...[if (i > 0) SizedBox(width: widget.spacing), child],
    ];

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {...PointerDeviceKind.values}, scrollbars: false),
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: Scrollbar(
          controller: _controller,
          thickness: 3,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            // Room for the scrollbar under the chips.
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(children: children),
          ),
        ),
      ),
    );
  }
}
