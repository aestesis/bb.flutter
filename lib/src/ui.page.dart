// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CustomPage extends StatelessWidget {
  final ScrollController? controller;
  final SliverPersistentHeaderDelegate? header;
  final List<Widget>? slivers;
  final Color? color;
  final bool pinnedHeader;
  final bool floatingHeader;
  const CustomPage({
    super.key,
    this.slivers,
    this.color,
    this.header,
    this.controller,
    this.pinnedHeader = true,
    this.floatingHeader = false,
  });
  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;
    return Container(
      color: color,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: controller,
              slivers: [
                if (header != null) ...[
                  SliverPersistentHeader(
                    pinned: pinnedHeader,
                    floating: floatingHeader,
                    delegate: header!,
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: safeArea.bottom),
                    sliver: SliverMainAxisGroup(slivers: slivers!),
                  ),
                ],
                if (header == null)
                  SliverPadding(
                    padding: safeArea,
                    sliver: SliverMainAxisGroup(slivers: slivers!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CustomHeader extends SliverPersistentHeaderDelegate {
  @override
  double minExtent;
  @override
  double maxExtent;
  Color? color;
  EdgeInsets? padding;
  Widget? child;
  CustomHeader({
    required this.minExtent,
    required this.maxExtent,
    this.color,
    this.padding,
    this.child,
  }) : super();
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: maxExtent),
      child: Container(
        color: color,
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Container(padding: padding, child: child),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CustomHeader oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(covariant CustomHeader other) {
    if (identical(this, other)) return true;
    return other.minExtent == minExtent &&
        other.maxExtent == maxExtent &&
        other.color == color &&
        other.padding == padding &&
        other.child == child;
  }

  @override
  int get hashCode {
    return minExtent.hashCode ^
        maxExtent.hashCode ^
        color.hashCode ^
        padding.hashCode ^
        child.hashCode;
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
