import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
class SliverChildBuilderSeparatedDelegate extends SliverChildBuilderDelegate {
  SliverChildBuilderSeparatedDelegate({
    int itemCount = 0,
    bool after = false,
    bool before = false,
    required Widget Function(BuildContext context, int index) itemBuilder,
    Widget Function(BuildContext context, int index)? separatorBuilder,
  }) : super(
         (context, index) {
           final ib = before ? 1 : 0;
           final int itemIndex = (index - ib) ~/ 2;
           if (before && index.isEven || !before && index.isOdd) {
             return separatorBuilder != null
                 ? separatorBuilder(context, itemIndex)
                 : Container();
           } else {
             return itemBuilder(context, itemIndex);
           }
         },
         childCount: itemCount == 0
             ? 0
             : (itemCount * 2 - 1 + (before ? 1 : 0) + (after ? 1 : 0)),
       );
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
enum AxisAlignement {
  start,
  center,
  end;

  double get value {
    switch (this) {
      case AxisAlignement.start:
        return -1;
      case AxisAlignement.center:
        return 0;
      case AxisAlignement.end:
        return 1;
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Expandable extends StatefulWidget {
  final Duration duration;
  final Widget? child;
  final bool expanded;
  final bool alwaysInTree;
  final VoidCallback? onTapInside;
  final VoidCallback? onTapOutside;
  final AxisAlignement axisAlignement;
  const Expandable({
    this.expanded = false,
    this.child,
    this.duration = const Duration(milliseconds: 400),
    this.alwaysInTree = false,
    super.key,
    this.onTapInside,
    this.onTapOutside,
    this.axisAlignement = AxisAlignement.start,
  });
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
  Widget build(BuildContext context) => TapRegion(
    consumeOutsideTaps: widget.expanded,
    onTapInside: (_) {
      if (widget.expanded) widget.onTapInside?.call();
    },
    onTapOutside: (_) {
      if (widget.expanded) widget.onTapOutside?.call();
    },
    child: SizeTransition(
      axisAlignment: widget.axisAlignement.value,
      sizeFactor: animation,
      child: widget.alwaysInTree
          ? widget.child
          : (widget.expanded || controller.value > 0)
          ? widget.child
          : null,
    ),
  );
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
class Spans extends StatelessWidget {
  final List<InlineSpan>? spans;
  const Spans({super.key, this.spans});
  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(children: spans));
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class DeviceOrientationBuilder extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    DeviceOrientation orientation,
  )?
  builder;
  const DeviceOrientationBuilder({super.key, this.builder});
  @override
  State<DeviceOrientationBuilder> createState() =>
      _DeviceOrientationBuilderState();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class _DeviceOrientationBuilderState extends State<DeviceOrientationBuilder> {
  DeviceOrientation orientation = .portraitUp;
  @override
  void initState() {
    super.initState();
    NativeDeviceOrientationCommunicator().onOrientationChanged().listen((o) {
      orientation = o;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder?.call(context, orientation) ?? Container();
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
typedef DeviceOrientation = NativeDeviceOrientation;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension DeviceOrientationExt on DeviceOrientation {
  bool get isLandscape => this == .landscapeLeft || this == .landscapeRight;
  bool get isPortrait => !isLandscape;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
