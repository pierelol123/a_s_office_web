import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SliverGridDelegateWithResponsiveColumns extends SliverGridDelegate {
  final double minColumnWidth;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  const SliverGridDelegateWithResponsiveColumns({
    required this.minColumnWidth,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double usableWidth = constraints.crossAxisExtent - crossAxisSpacing;
    final int crossAxisCount = ((usableWidth + crossAxisSpacing) / (minColumnWidth + crossAxisSpacing)).floor();
    final double childCrossAxisExtent = (usableWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
    final double childMainAxisExtent = childCrossAxisExtent / childAspectRatio;

    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithResponsiveColumns oldDelegate) {
    return oldDelegate.minColumnWidth != minColumnWidth ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.childAspectRatio != childAspectRatio;
  }
}