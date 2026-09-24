import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'glass/ios_glass.dart';

class TextWithMeta extends MultiChildRenderObjectWidget {
  final bool fillWidth;

  TextWithMeta({
    super.key,
    required Widget text,
    required Widget meta,
    this.fillWidth = false,
  }) : super(children: [text, meta]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderTextWithMeta(fillWidth, alignBaseline: IosGlass.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTextWithMeta renderObject,
  ) {
    renderObject
      ..fillWidth = fillWidth
      ..alignBaseline = IosGlass.of(context);
  }
}

class TextWithMetaParentData extends ContainerBoxParentData<RenderBox> {}

class RenderTextWithMeta extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextWithMetaParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TextWithMetaParentData> {
  RenderTextWithMeta(this._fillWidth, {bool alignBaseline = false})
    : _alignBaseline = alignBaseline;

  static const double _gap = 8;
  static const double _baselineNudge = 2;

  bool _fillWidth;
  set fillWidth(bool value) {
    if (value == _fillWidth) return;
    _fillWidth = value;
    markNeedsLayout();
  }

  bool _alignBaseline;
  set alignBaseline(bool value) {
    if (value == _alignBaseline) return;
    _alignBaseline = value;
    markNeedsLayout();
  }

  RenderBox get _text => firstChild!;
  RenderBox get _meta => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextWithMetaParentData) {
      child.parentData = TextWithMetaParentData();
    }
  }

  RenderParagraph? _soleParagraph() {
    RenderParagraph? found;
    var seen = 0;
    void visit(RenderObject node) {
      if (node is RenderParagraph) {
        found = node;
        seen++;
        return;
      }
      node.visitChildren(visit);
    }

    _text.visitChildren(visit);
    if (_text is RenderParagraph) {
      found = _text as RenderParagraph;
      seen = 1;
    }
    return seen == 1 ? found : null;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _text.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _text.getMaxIntrinsicWidth(height) +
      _gap +
      _meta.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _text.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _text.getMaxIntrinsicHeight(width) + _meta.getMaxIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      BaselineOffset(_text.getDistanceToActualBaseline(baseline)).offset;

  @override
  void performLayout() {
    _meta.layout(const BoxConstraints(), parentUsesSize: true);
    final metaSize = _meta.size;

    _text.layout(constraints.loosen(), parentUsesSize: true);
    final textSize = _text.size;

    final lineWidth = _fillWidth && constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : textSize.width;
    final paragraph = _soleParagraph();
    final needed = _gap + metaSize.width;

    double width;
    double height;
    var metaOnOwnLine = false;

    if (paragraph != null) {
      final length = paragraph.text.toPlainText().length;
      final caret = paragraph.getOffsetForCaret(
        TextPosition(offset: length),
        Rect.zero,
      );
      final lastLine = caret.dx;
      final singleLine = caret.dy < 0.5;
      if (lastLine + needed <= lineWidth) {
        width = lineWidth;
        height = textSize.height;
      } else if (singleLine && lastLine + needed <= constraints.maxWidth) {
        width = lastLine + needed;
        height = textSize.height;
      } else {
        width = math.max(lineWidth, metaSize.width);
        height = textSize.height + metaSize.height;
        metaOnOwnLine = true;
      }
    } else {
      width = math.max(lineWidth, metaSize.width);
      height = textSize.height + metaSize.height;
      metaOnOwnLine = true;
    }

    size = constraints.constrain(Size(width, height));

    (_text.parentData! as TextWithMetaParentData).offset = Offset.zero;

    final bottom = size.height - metaSize.height;
    final baselineDy = metaOnOwnLine || !_alignBaseline
        ? null
        : _lastLineBaselineDy(paragraph);
    final metaDy = metaOnOwnLine
        ? bottom
        : baselineDy?.clamp(0.0, math.max(0.0, bottom)).toDouble() ??
              bottom - _baselineNudge;

    (_meta.parentData! as TextWithMetaParentData).offset = Offset(
      math.max(0, size.width - metaSize.width),
      metaDy,
    );
  }

  double? _lastLineBaselineDy(RenderParagraph? paragraph) {
    if (paragraph == null) return null;
    final textBaseline = _text.getDistanceToBaseline(
      TextBaseline.alphabetic,
      onlyReal: true,
    );
    final metaBaseline = _meta.getDistanceToBaseline(
      TextBaseline.alphabetic,
      onlyReal: true,
    );
    if (textBaseline == null || metaBaseline == null) return null;
    const first = TextPosition(offset: 0);
    final last = TextPosition(offset: paragraph.text.toPlainText().length);
    final firstBottom =
        paragraph.getOffsetForCaret(first, Rect.zero).dy +
        paragraph.getFullHeightForCaret(first);
    final lastBottom =
        paragraph.getOffsetForCaret(last, Rect.zero).dy +
        paragraph.getFullHeightForCaret(last);
    return textBaseline + lastBottom - firstBottom - metaBaseline;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
