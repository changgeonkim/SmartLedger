import 'package:flutter/material.dart';

class AnimatedContentSwitcher extends StatefulWidget {
  final String viewKey;
  final Widget child;

  const AnimatedContentSwitcher({
    super.key,
    required this.viewKey,
    required this.child,
  });

  @override
  State<AnimatedContentSwitcher> createState() =>
      _AnimatedContentSwitcherState();
}

class _AnimatedContentSwitcherState extends State<AnimatedContentSwitcher> {
  final Set<String> _seenKeys = {};
  Duration _duration = const Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _seenKeys.add(widget.viewKey);
  }

  @override
  void didUpdateWidget(AnimatedContentSwitcher old) {
    super.didUpdateWidget(old);
    if (widget.viewKey != old.viewKey) {
      final isNew = !_seenKeys.contains(widget.viewKey);
      _seenKeys.add(widget.viewKey);
      // setState 없이도 부모 rebuild가 이미 예약되어 있으므로 직접 업데이트
      _duration =
          isNew ? const Duration(milliseconds: 200) : Duration.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _duration,
      // ListView가 Expanded 안에서 올바른 제약을 받도록 expand
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(widget.viewKey),
        child: widget.child,
      ),
    );
  }
}
