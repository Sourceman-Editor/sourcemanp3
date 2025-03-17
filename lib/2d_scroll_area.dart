import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sourcemanv3/datatype.dart';
import 'package:sourcemanv3/event.dart';
import 'package:sourcemanv3/managers/env_var_manager.dart';
import 'package:sourcemanv3/widgets/line.dart';

class ScrollAreaControl {
  late Function mapCursorToLineIndex;
  late Function setHighlight;
  late Function displayCursor;
  late Function displayCursorAt;
  late Function insertChar;
  late Function removeChar;
  late Function getRunes;
  late Function getRunesLength;
  late Function refreshAll;
}

class TwoDiScrollAreaWidget extends StatefulWidget {
  final Doc doc;
  final EventManager eventManager;
  final EnvVarManager envVarManager;
  final ScrollAreaControl controller;

  const TwoDiScrollAreaWidget({
    super.key,
    required this.doc,
    required this.eventManager,
    required this.envVarManager,
    required this.controller,
  });

  @override
  State<TwoDiScrollAreaWidget> createState() => _TwoDiScrollAreaWidgetState();
}

class _TwoDiScrollAreaWidgetState extends State<TwoDiScrollAreaWidget> {
  final ScrollController c1 = ScrollController();
  final ScrollController c2 = ScrollController();
  Map<int, LineController> lineCtrls = {};

  @override
  void initState() {
    // TODO: implement initState
    initController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: c1,
      thumbVisibility: true,
      child: Scrollbar(
        controller: c2,
        thumbVisibility: true,
        child: TwoDimensionalGridView(
          verticalDetails: ScrollableDetails.vertical(controller: c1),
          horizontalDetails: ScrollableDetails.horizontal(controller: c2),
          diagonalDragBehavior: DiagonalDragBehavior.free,
          delegate: TwoDimensionalChildBuilderDelegate(
              maxXIndex: 0,
              maxYIndex: widget.doc.lines.length,
              builder: (BuildContext context, ChildVicinity vicinity) {
                var lineCtrl = LineController();
                lineCtrls[vicinity.yIndex] = lineCtrl;
                return OverflowBox(
                  alignment: Alignment.topLeft,
                  maxWidth: double.infinity,
                  child: LineWidget(
                    key: UniqueKey(),
                    lineIdx: vicinity.yIndex, 
                    doc: widget.doc,
                    envVarManager: widget.envVarManager,
                    eventManager: widget.eventManager,
                    controller: lineCtrl,
                  ),
                );
              }),
        ),
      ),
    );
  }

  void initController() {
    widget.controller.mapCursorToLineIndex = mapCursorToLineIndex;
    widget.controller.setHighlight = setHighlight;
    widget.controller.displayCursor = displayCursor;
    widget.controller.displayCursorAt = displayCursorAt;
    widget.controller.insertChar = insertChar;
    widget.controller.removeChar = removeChar;
    widget.controller.getRunes = getRunes;
    widget.controller.getRunesLength = getRunesLength;
    widget.controller.refreshAll = refreshAll;
  }

  int mapCursorToLineIndex(double dy) {
    // print(uiDetails.lineHeight);
    double clickPositionY = dy + c1.offset;
    
    int idx = (clickPositionY / 22).floor();
    if (idx > widget.doc.lines.length) {
      idx = widget.doc.lines.length;
    }
    // print("$clickPositionY $idx");
    return idx;
  }

  void setHighlight(int lineIdx, int startIdx, int endIdx) {
    if (!lineCtrls.containsKey(lineIdx)) {
      return;
    }
    lineCtrls[lineIdx]!.setHighlight(startIdx, endIdx);
  }

  int displayCursor(int lineIdx, double dx, bool? atEnd) {
    if (!lineCtrls.containsKey(lineIdx)) {
      return 0;
    }
    return lineCtrls[lineIdx]!.displayCursor(dx, atEnd);
  }

  void displayCursorAt(int lineIdx, int? index) {
    if (!lineCtrls.containsKey(lineIdx)) {
      return;
    }
    lineCtrls[lineIdx]!.displayCursorAt(index);
  }

  void insertChar(int lineIdx, int index, String ch) {
    if (!lineCtrls.containsKey(lineIdx)) {
      return;
    }
    lineCtrls[lineIdx]!.insertChar(index, ch);
  }

  void removeChar(int lineIdx, int index) {
    if (!lineCtrls.containsKey(lineIdx)) {
      return;
    }
    lineCtrls[lineIdx]!.removeChar(index);
  }

  List<Rune> getRunes(int lineIdx, int start, int end) {
    if (!lineCtrls.containsKey(lineIdx)) {
      return [];
    }
    return lineCtrls[lineIdx]!.getRunes(start, end);
  }

  int getRunesLength(int lineIdx) {
    if (!lineCtrls.containsKey(lineIdx)) {
      return 0;
    }
    return lineCtrls[lineIdx]!.getRunesLength();
  }

  void refreshAll() {
    setState(() {
      
    });
  }
}

class TwoDimensionalGridView extends TwoDimensionalScrollView {
  const TwoDimensionalGridView({
    super.key,
    super.primary,
    super.mainAxis = Axis.vertical,
    super.verticalDetails = const ScrollableDetails.vertical(),
    super.horizontalDetails = const ScrollableDetails.horizontal(),
    required TwoDimensionalChildBuilderDelegate delegate,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.none,
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
  }) : super(delegate: delegate);

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return TwoDimensionalGridViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }
}

class TwoDimensionalGridViewport extends TwoDimensionalViewport {
  const TwoDimensionalGridViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  });

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return RenderTwoDimensionalGridViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      childManager: context as TwoDimensionalChildManager,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTwoDimensionalGridViewport renderObject,
  ) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..delegate = delegate
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class RenderTwoDimensionalGridViewport extends RenderTwoDimensionalViewport {
  RenderTwoDimensionalGridViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  }) : super(delegate: delegate);

  @override
  void layoutChildSequence() {
    final double horizontalPixels = horizontalOffset.pixels;
    final double verticalPixels = verticalOffset.pixels;
    final double viewportWidth = viewportDimension.width + cacheExtent;
    final double viewportHeight = viewportDimension.height + cacheExtent;
    final TwoDimensionalChildBuilderDelegate builderDelegate =
        delegate as TwoDimensionalChildBuilderDelegate;

    final int maxRowIndex = builderDelegate.maxYIndex!;
    final int maxColumnIndex = builderDelegate.maxXIndex!;

    // get line height, it is fixed. Unlike line width, which is dynamic
    ChildVicinity firstRune = const ChildVicinity(xIndex: 0, yIndex: 0);
    final RenderBox firstRuneRB = buildOrObtainChildFor(firstRune)!;
    double lineHeight = firstRuneRB.getMaxIntrinsicHeight(double.maxFinite);
    double width = firstRuneRB.getMaxIntrinsicWidth(double.maxFinite);
    parentDataOf(firstRuneRB).layoutOffset = Offset(0, -verticalOffset.pixels);

    int leadingRow = max((verticalPixels / lineHeight).floor(), 0);
    int tailingRow = min(((verticalPixels + viewportHeight) / lineHeight).ceil(), maxRowIndex);
    if (tailingRow <= leadingRow) {
      tailingRow = leadingRow + 1;
    }
    double yLayoutOffset = (leadingRow * lineHeight) - verticalOffset.pixels;

    // text column
    double maxWidth = 0;
    for (int i = leadingRow; i < tailingRow; i++) {
      final ChildVicinity vicinity = ChildVicinity(xIndex: 0, yIndex: i);
      late RenderBox child;
      if (i == 0) {
        child = firstRuneRB;
      } else {
        child = buildOrObtainChildFor(vicinity)!;
      }
      double width = child.getMaxIntrinsicWidth(double.maxFinite) + 100;
      if (width > maxWidth) {
        maxWidth = width;
      }
      child.layout(BoxConstraints(minHeight: lineHeight, maxHeight: lineHeight, minWidth: width, maxWidth: width));
      parentDataOf(child).layoutOffset = Offset(-horizontalOffset.pixels, yLayoutOffset);
      yLayoutOffset += lineHeight;
    }

    // Set the min and max scroll extents for each axis.
    final double verticalExtent = lineHeight * (maxRowIndex + 1);
    verticalOffset.applyContentDimensions(
      0.0,
      clampDouble(verticalExtent - viewportDimension.height, 0.0, double.infinity),
    );
    horizontalOffset.applyContentDimensions(
      0.0,
      clampDouble(maxWidth - viewportDimension.width, 0.0, double.infinity),
    );
    // Super class handles garbage collection too!
  }
  
}
