import 'package:flutter/widgets.dart';

import '../config/app_bubble_behavior.dart';
import '../config/app_bubble_shape.dart';
import '../config/app_ios_glass.dart';

// #***! 20 обычный угол, 4 срезанный на стыке с соседним
const double kBubbleBigRadius = 20;
const double kBubbleSmallRadius = 4;

const double kIosBubbleRadius = 16;
const double kIosBubbleJoinRadius = 8;

// #***! скругления зависят от места в группе и настроек
BorderRadius computeBubbleRadius({
  required bool isMe,
  required bool isTop,
  required bool isBottom,
  required BubbleStyle style,
  required BubbleBehavior behavior,
  bool hasPhotoWithCaption = false,
  bool hasMultiplePhotosNoCaption = false,
  bool? ios,
}) {
  final iosShape = ios ?? AppIosGlass.active.value;
  final big = Radius.circular(iosShape ? kIosBubbleRadius : kBubbleBigRadius);
  final small = Radius.circular(
    iosShape ? kIosBubbleJoinRadius : kBubbleSmallRadius,
  );
  final isSingle = isTop && isBottom;

  // #***! фото с подписью, низ срезан потому что снизу текст
  if (hasPhotoWithCaption && (isTop || isBottom)) {
    return BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: isMe ? big : small,
      bottomRight: small,
    );
  }

  // #***! альбом без подписи, срезаны углы на стыках
  if (hasMultiplePhotosNoCaption && isBottom) {
    return BorderRadius.only(
      topLeft: isMe ? big : small,
      topRight: small,
      bottomLeft: isMe ? big : small,
      bottomRight: isMe ? small : big,
    );
  }

  final base = style == BubbleStyle.desktop && !iosShape ? small : big;
  Radius tl = base, tr = base, bl = base, br = base;

  // #***! неизменяемая форма или одиночное, углы одинаковые
  if (behavior == BubbleBehavior.immutable || isSingle) {
    return BorderRadius.only(
      topLeft: tl,
      topRight: tr,
      bottomLeft: bl,
      bottomRight: br,
    );
  }

  // #***! в группе срезается угол со стороны отправителя
  if (isTop) {
    if (isMe) {
      br = small;
    } else {
      bl = small;
    }
  } else if (isBottom) {
    if (isMe) {
      tr = small;
    } else {
      tl = small;
    }
  } else {
    if (isMe) {
      tr = small;
      br = small;
    } else {
      tl = small;
      bl = small;
    }
  }

  return BorderRadius.only(
    topLeft: tl,
    topRight: tr,
    bottomLeft: bl,
    bottomRight: br,
  );
}
