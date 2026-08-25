import 'dart:async';

import 'package:flutter/material.dart';

/// A glyph that spins continuously while [spinning] is true, and sits still
/// otherwise — the shared treatment for "this is a loading indicator, not a
/// decorative icon" across the buttons that show a `loader-circle`/
/// `refresh-cw` glyph while a sync retry is in flight.
///
/// One turn every 2s, matching `SyncIndicator` (`lib/features/home/
/// presentation/widgets/sync_indicator.dart`): slow enough to read as calm
/// progress, fast enough to visibly move at icon size. Respects the OS
/// "reduce motion" setting — the semantics of *why* the glyph is there
/// (its label, owned by the caller) still communicate progress when the
/// spin itself is suppressed.
///
/// Stateful only for the [AnimationController]; never leaves it ticking once
/// [spinning] turns false, so it does not burn frames in the background.
class SpinningIcon extends StatefulWidget {
  const SpinningIcon({
    required this.icon,
    required this.spinning,
    this.size,
    this.color,
    super.key,
  });

  final IconData icon;

  /// Whether the glyph should be rotating right now.
  final bool spinning;
  final double? size;
  final Color? color;

  @override
  State<SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  bool _motionAllowed = true;

  bool get _shouldSpin => widget.spinning && _motionAllowed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionAllowed = !MediaQuery.disableAnimationsOf(context);
    _applySpin();
  }

  @override
  void didUpdateWidget(SpinningIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applySpin();
  }

  void _applySpin() {
    if (_shouldSpin) {
      if (!_controller.isAnimating) {
        // The ticker future only completes on dispose; nothing to await.
        unawaited(_controller.repeat());
      }
    } else if (_controller.isAnimating || _controller.value != 0) {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
