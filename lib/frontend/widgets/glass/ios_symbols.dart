import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'ios_glass.dart';

/// SF-style icon mapping for Flutter-drawn chrome in iOS mode.
///
/// Material Symbols stay in Material mode. Prefer this over raw `Symbols.*`
/// on screens that already branch on [IosGlass]. Batch F will sweep the rest.
abstract final class IosSymbols {
  static IconData resolve(
    BuildContext context, {
    required IconData material,
    required IconData cupertino,
  }) => IosGlass.of(context) ? cupertino : material;

  static IconData search(BuildContext c) =>
      resolve(c, material: Symbols.search, cupertino: CupertinoIcons.search);

  static IconData searchOff(BuildContext c) => resolve(
    c,
    material: Symbols.search_off,
    cupertino: CupertinoIcons.search,
  );

  static IconData close(BuildContext c) =>
      resolve(c, material: Symbols.close, cupertino: CupertinoIcons.xmark);

  static IconData clearFill(BuildContext c) => resolve(
    c,
    material: Symbols.cancel,
    cupertino: CupertinoIcons.clear_thick_circled,
  );

  static IconData back(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_back,
    cupertino: CupertinoIcons.back,
  );

  static IconData chevronRight(BuildContext c) => resolve(
    c,
    material: Symbols.chevron_right,
    cupertino: CupertinoIcons.chevron_right,
  );

  static IconData personAdd(BuildContext c) => resolve(
    c,
    material: Symbols.person_add,
    cupertino: CupertinoIcons.person_add,
  );

  static IconData person(BuildContext c) =>
      resolve(c, material: Symbols.person, cupertino: CupertinoIcons.person);

  static IconData people(BuildContext c) => resolve(
    c,
    material: Symbols.groups,
    cupertino: CupertinoIcons.person_2,
  );

  static IconData personAddGroup(BuildContext c) => resolve(
    c,
    material: Symbols.group_add,
    cupertino: CupertinoIcons.person_add,
  );

  static IconData verified(BuildContext c) => resolve(
    c,
    material: Symbols.verified,
    cupertino: CupertinoIcons.checkmark_seal_fill,
  );

  static IconData phone(BuildContext c) =>
      resolve(c, material: Symbols.call, cupertino: CupertinoIcons.phone);

  static IconData phoneFill(BuildContext c) => resolve(
    c,
    material: Symbols.call,
    cupertino: CupertinoIcons.phone_fill,
  );

  static IconData phoneDown(BuildContext c) => resolve(
    c,
    material: Symbols.call_end,
    cupertino: CupertinoIcons.phone_down_fill,
  );

  static IconData phoneMissed(BuildContext c) => resolve(
    c,
    material: Symbols.phone_missed,
    cupertino: CupertinoIcons.phone_down,
  );

  static IconData phoneDisabled(BuildContext c) => resolve(
    c,
    material: Symbols.phone_disabled,
    cupertino: CupertinoIcons.phone_down,
  );

  static IconData callOutgoing(BuildContext c) => resolve(
    c,
    material: Symbols.call_made,
    cupertino: CupertinoIcons.phone_arrow_up_right,
  );

  static IconData callIncoming(BuildContext c) => resolve(
    c,
    material: Symbols.call_received,
    cupertino: CupertinoIcons.phone_arrow_down_left,
  );

  static IconData ellipsis(BuildContext c) => resolve(
    c,
    material: Symbols.more_vert,
    cupertino: CupertinoIcons.ellipsis,
  );

  static IconData delete(BuildContext c) =>
      resolve(c, material: Symbols.delete, cupertino: CupertinoIcons.delete);

  static IconData link(BuildContext c) =>
      resolve(c, material: Symbols.link, cupertino: CupertinoIcons.link);

  static IconData tag(BuildContext c) =>
      resolve(c, material: Symbols.tag, cupertino: CupertinoIcons.tag);

  static IconData number(BuildContext c) =>
      resolve(c, material: Symbols.tag, cupertino: CupertinoIcons.number);

  static IconData mic(BuildContext c) =>
      resolve(c, material: Symbols.mic, cupertino: CupertinoIcons.mic_fill);

  static IconData micOff(BuildContext c) =>
      resolve(c, material: Symbols.mic_off, cupertino: CupertinoIcons.mic_off);

  static IconData videocam(BuildContext c) => resolve(
    c,
    material: Symbols.videocam,
    cupertino: CupertinoIcons.videocam_fill,
  );

  static IconData videocamOff(BuildContext c) => resolve(
    c,
    material: Symbols.videocam_off,
    cupertino: CupertinoIcons.videocam,
  );

  static IconData speaker(BuildContext c) => resolve(
    c,
    material: Symbols.volume_up,
    cupertino: CupertinoIcons.speaker_3_fill,
  );

  static IconData speakerQuiet(BuildContext c) => resolve(
    c,
    material: Symbols.volume_down,
    cupertino: CupertinoIcons.speaker_1_fill,
  );

  static IconData screenShare(BuildContext c) => resolve(
    c,
    material: Symbols.screen_share,
    cupertino: CupertinoIcons.rectangle_on_rectangle,
  );

  static IconData handRaised(BuildContext c) => resolve(
    c,
    material: Symbols.front_hand,
    cupertino: CupertinoIcons.hand_raised_fill,
  );

  static IconData personCropCircle(BuildContext c) => resolve(
    c,
    material: Symbols.person,
    cupertino: CupertinoIcons.person_crop_circle,
  );

  static IconData error(BuildContext c) => resolve(
    c,
    material: Symbols.error_outline,
    cupertino: CupertinoIcons.exclamationmark_circle,
  );
}
