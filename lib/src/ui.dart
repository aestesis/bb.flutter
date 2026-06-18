import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
class Expandable extends StatefulWidget {
  final Duration duration;
  final Widget? child;
  final bool expanded;
  final bool alwaysInTree;
  final VoidCallback? onTapInside;
  final VoidCallback? onTapOutside;
  final AlignmentGeometry? alignement;
  const Expandable({
    this.expanded = false,
    this.child,
    this.duration = const Duration(milliseconds: 400),
    this.alwaysInTree = false,
    super.key,
    this.onTapInside,
    this.onTapOutside,
    this.alignement,
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
      alignment: widget.alignement,
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
  final Widget Function(BuildContext context, DeviceOrientation orientation)?
  builder;
  final void Function(DeviceOrientation orientation)? onOrientationChanged;
  const DeviceOrientationBuilder({
    super.key,
    this.builder,
    this.onOrientationChanged,
  });
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
      if (o.deviceOrientation != null && o.deviceOrientation != orientation) {
        orientation = o.deviceOrientation!;
        widget.onOrientationChanged?.call(orientation);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder?.call(context, orientation) ?? Container();
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension DeviceOrientationExt on DeviceOrientation {
  bool get isLandscape => this == .landscapeLeft || this == .landscapeRight;
  bool get isPortrait => !isLandscape;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class DeviceOrientationNotification {
  static StreamSubscription listen(void Function(DeviceOrientation o) onData) {
    DeviceOrientation orientation = .portraitUp;
    return NativeDeviceOrientationCommunicator().onOrientationChanged().listen((
      o,
    ) {
      if (o.deviceOrientation != null && o.deviceOrientation != orientation) {
        orientation = o.deviceOrientation!;
        onData(orientation);
      }
    });
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class TickerWidget extends StatefulWidget {
  final Widget Function(BuildContext context, TickerProvider vsync) builder;
  const TickerWidget({super.key, required this.builder});
  @override
  State<TickerWidget> createState() => _TickerWidgetState();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////

class _TickerWidgetState extends State<TickerWidget>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, this);
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 * Copyright © 2025 Birju Vachhani. All rights reserved.
 * Use of this source code is governed by a BSD 3-Clause License that can be
 * found in the LICENSE file.
 */

/// A [WidgetSpan] that represents a link with hover effects and tap handling.
///
/// It can be used to create clickable text spans with a hover style and
/// optional background decoration. This allows easy and clean implementation of
/// links within rich text widgets.
///
/// The [LinkSpan] widget provides various customization options such as
/// text [style], [hoverStyle], [background] decoration, [padding], animation [duration],
/// and curve. It also supports optional [prefix] and [suffix] widgets that can be
/// displayed before and after the text respectively.
///
/// Example usage:
///
/// ```dart
/// Text.rich(
///   TextSpan(
///     text: 'By signing up, you agree to our ',
///     children: [
///       LinkSpan(
///         onTap: () => launchUrlString('https://example.com/terms'),
///         text: 'Terms of Service',
///         style: TextStyle(color: Colors.blue,
///         hoverStyle: TextStyle(decoration: TextDecoration.underline),
///       ),
///       TextSpan(text: ' and '),
///       LinkSpan(
///       onTap: () => launchUrlString('https://example.com/privacy'),
///       text: 'Privacy Policy',
///       style: TextStyle(color: Colors.blue),
///       hoverStyle: TextStyle(decoration: TextDecoration.underline),
///     ),
///   ],
/// ),
/// ```
///
/// This will create a text span with two clickable links that change style on hover.
class LinkSpan extends WidgetSpan {
  /// The style to apply to the text when not hovering.
  final TextStyle? hoverStyle;

  /// Callback function that is called when the link is tapped.
  final VoidCallback? onTap;

  /// The text to display in the link span.
  final String text;

  /// Optional background decoration for the link span.
  ///
  /// If [hoverBackground] is not provided, this will be used for both
  /// normal and hovered states.
  ///
  /// If neither [background] nor [hoverBackground] is provided, no background
  /// decoration will be applied.
  ///
  /// This is useful when you want to apply a background style. e.g. color highlight
  final Decoration? background;

  /// Optional background decoration for the link span in hovered state.
  final Decoration? hoverBackground;

  /// The cursor to display when hovering over the link span.
  final MouseCursor? cursor;

  /// Foreground color of the text and/or icon in the link span when not hovered.
  ///
  /// This is useful when you want to apply a different color on hover for both
  /// text and icons(prefix/suffix).
  final Color? color;

  /// Foreground color of the text and/or icon in the link span when hovered.
  ///
  /// If not provided, it defaults to [color].
  /// This is useful when you want to apply a different color on hover for both
  /// text and icons(prefix/suffix).
  final Color? hoverColor;

  /// The padding around the link span.
  final EdgeInsets? padding;

  /// The duration of the hover animation.
  ///
  /// If set to [Duration.zero], no animation will be applied and animation mechanism
  /// will be skipped.
  final Duration duration;

  /// The curve of the hover animation.
  ///
  /// This is ignored if [duration] is set to [Duration.zero].
  /// Defaults to [Curves.linear].
  final Curve curve;

  /// An optional widget to display before the text.
  /// This can be used to add an icon or any other widget before the text.
  final Widget? prefix;

  /// An optional widget to display after the text.
  /// This can be used to add an icon or any other widget after the text.
  final Widget? suffix;

  /// Creates a [LinkSpan] with the given parameters.
  const LinkSpan({
    super.style,
    this.hoverStyle,
    this.onTap,
    required this.text,
    this.background,
    this.hoverBackground,
    this.cursor,
    this.color,
    this.hoverColor,
    this.padding,
    this.duration = Duration.zero,
    this.curve = Curves.linear,
    super.alignment = PlaceholderAlignment.baseline,
    super.baseline = TextBaseline.alphabetic,
    this.prefix,
    this.suffix,
  }) : super(child: const SizedBox.shrink());

  @override
  Widget get child => _buildChild();

  Widget _buildChild() {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hoverable(
        cursor: cursor ?? SystemMouseCursors.click,
        builder: (context, hovering, child) {
          final style = TextStyle(
            color: hovering ? hoverColor ?? color : color,
            decorationColor: hovering ? hoverColor ?? color : null,
          );

          Widget child = Text(
            text,
            style: hovering ? super.style?.merge(hoverStyle) : super.style,
          );

          if (prefix != null || suffix != null) {
            child = Row(
              mainAxisSize: MainAxisSize.min,
              children: [?prefix, child, ?suffix],
            );
          }

          if (duration == Duration.zero) {
            // no animation
            return DefaultTextStyle.merge(
              style: style,
              child: IconTheme.merge(
                data: IconThemeData(color: hovering ? hoverColor : color),
                child: Container(
                  padding: padding ?? EdgeInsets.zero,
                  decoration: hovering
                      ? hoverBackground ?? background
                      : background,
                  child: child,
                ),
              ),
            );
          }

          return AnimatedDefaultTextStyle(
            duration: duration,
            curve: curve,
            style: DefaultTextStyle.of(context).style.merge(style),
            child: IconTheme.merge(
              data: IconThemeData(color: hovering ? hoverColor : color),
              child: AnimatedContainer(
                duration: duration,
                curve: curve,
                padding: padding ?? EdgeInsets.zero,
                decoration: hovering
                    ? hoverBackground ?? background
                    : background,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Copyright © 2022 Birju Vachhani. All rights reserved.
// Use of this source code is governed by a BSD 3-Clause License that can be
// found in the LICENSE file.

// Author: Birju Vachhani
// Created Date: November 30, 2022

/// Builder function type for [Hoverable] where [hovering] is a boolean
/// indicating whether the widget is currently being hovered or not.
/// [child] is the child widget of [Hoverable] which won't be rebuilt
/// when [hovering] changes.
typedef HoverWidgetBuilder =
    Widget Function(BuildContext context, bool hovering, Widget? child);

/// A widget that detects mouse hover events and notifies its child.
/// This widget is useful when you want to change the appearance of a widget
/// when the mouse hovers over it.
///
/// Example:
///   HoverBuilder(
///     builder: (context, hovering, child) {
///       return AnimatedContainer(
///         duration: const Duration(milliseconds: 200),
///         width: 100,
///         height: 100,
///         color: hovering ? Colors.orange : Colors.red,
///         alignment: Alignment.center,
///         child: child,
///       );
///     },
///     child: const Text('Hover Me'),
///   ),
///
class Hoverable extends StatefulWidget {
  /// Builder that builds the child.
  final HoverWidgetBuilder builder;

  /// Refers to the [MouseRegion.opaque] property.
  final bool opaque;

  /// Refers to the [MouseRegion.cursor] property.
  final MouseCursor cursor;

  /// Refers to the [MouseRegion.onEnter] property.
  final HitTestBehavior? hitTestBehavior;

  /// Child of this widget.
  final Widget? child;

  /// Creates Hoverable widget with given values.
  const Hoverable({
    super.key,
    required this.builder,
    this.opaque = true,
    this.cursor = MouseCursor.defer,
    this.hitTestBehavior,
    this.child,
  });

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: widget.opaque,
      cursor: widget.cursor,
      hitTestBehavior: widget.hitTestBehavior,
      onEnter: (_) => setState(() => hovering = true),
      onHover: (event) {
        if (hovering) return;
        setState(() => hovering = true);
      },
      onExit: (event) => setState(() => hovering = false),
      child: widget.builder(context, hovering, widget.child),
    );
  }
}
