import 'dart:ui';

import 'package:flutter/material.dart';

TextTheme textTheme(BuildContext context) => Theme.of(context).textTheme;
ColorScheme colorScheme(BuildContext context) => Theme.of(context).colorScheme;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
class SliverChildBuilderSeparatedDelegate extends SliverChildBuilderDelegate {
  SliverChildBuilderSeparatedDelegate(
      {int childCount = 0,
      bool after = false,
      bool before = false,
      required Widget Function(BuildContext context, int index) builder,
      Widget Function(BuildContext context, int index)? separatorBuilder})
      : super((context, index) {
          final ib = before ? 1 : 0;
          final int itemIndex = (index - ib) ~/ 2;
          if (before && index.isEven || !before && index.isOdd) {
            return separatorBuilder != null
                ? separatorBuilder(context, itemIndex)
                : Container();
          } else {
            return builder(context, itemIndex);
          }
        },
            childCount: childCount == 0
                ? 0
                : (childCount * 2 - 1 + (before ? 1 : 0) + (after ? 1 : 0)));
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Expandable extends StatefulWidget {
  final Duration duration;
  final Widget? child;
  final bool expanded;
  final bool alwaysInTree;
  const Expandable(
      {this.expanded = false,
      this.child,
      this.duration = const Duration(milliseconds: 500),
      this.alwaysInTree = false,
      super.key});
  @override
  ExpandableState createState() => ExpandableState();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class ExpandableState extends State<Expandable>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: widget.duration);
    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );
    _update();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _update() {
    if (widget.expanded) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  @override
  void didUpdateWidget(Expandable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
      axisAlignment: 1.0,
      sizeFactor: animation,
      child: widget.alwaysInTree
          ? widget.child
          : (widget.expanded || controller.value > 0)
              ? widget.child
              : null);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class PanScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
  static Widget scrollConfiguration({required Widget child}) =>
      ScrollConfiguration(behavior: PanScrollBehavior(), child: child);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
