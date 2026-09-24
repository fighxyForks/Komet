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

  static IconData chevronBack(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_back_ios_new,
    cupertino: CupertinoIcons.chevron_back,
  );

  static IconData ellipsisHoriz(BuildContext c) => resolve(
    c,
    material: Symbols.more_horiz,
    cupertino: CupertinoIcons.ellipsis,
  );

  static IconData reply(BuildContext c) =>
      resolve(c, material: Symbols.reply, cupertino: CupertinoIcons.reply);

  static IconData forward(BuildContext c) => resolve(
    c,
    material: Symbols.forward,
    cupertino: CupertinoIcons.arrowshape_turn_up_right,
  );

  static IconData copy(BuildContext c) => resolve(
    c,
    material: Symbols.content_copy,
    cupertino: CupertinoIcons.doc_on_doc,
  );

  static IconData edit(BuildContext c) =>
      resolve(c, material: Symbols.edit, cupertino: CupertinoIcons.pencil);

  static IconData pin(BuildContext c) =>
      resolve(c, material: Symbols.push_pin, cupertino: CupertinoIcons.pin);

  static IconData pinOff(BuildContext c) => resolve(
    c,
    material: Symbols.keep_off,
    cupertino: CupertinoIcons.pin_slash,
  );

  static IconData flag(BuildContext c) =>
      resolve(c, material: Symbols.flag, cupertino: CupertinoIcons.flag);

  static IconData info(BuildContext c) => resolve(
    c,
    material: Symbols.info,
    cupertino: CupertinoIcons.info_circle,
  );

  static IconData history(BuildContext c) => resolve(
    c,
    material: Symbols.history,
    cupertino: CupertinoIcons.clock,
  );

  static IconData visibility(BuildContext c) => resolve(
    c,
    material: Symbols.visibility,
    cupertino: CupertinoIcons.eye,
  );

  static IconData markUnread(BuildContext c) => resolve(
    c,
    material: Symbols.mark_chat_unread,
    cupertino: CupertinoIcons.envelope_badge,
  );

  static IconData send(BuildContext c) =>
      resolve(c, material: Symbols.send, cupertino: CupertinoIcons.paperplane_fill);

  static IconData attach(BuildContext c) => resolve(
    c,
    material: Symbols.attachment,
    cupertino: CupertinoIcons.paperclip,
  );

  static IconData add(BuildContext c) =>
      resolve(c, material: Symbols.add, cupertino: CupertinoIcons.plus);

  static IconData photo(BuildContext c) => resolve(
    c,
    material: Symbols.image,
    cupertino: CupertinoIcons.photo,
  );

  static IconData doc(BuildContext c) => resolve(
    c,
    material: Symbols.description,
    cupertino: CupertinoIcons.doc,
  );

  static IconData location(BuildContext c) => resolve(
    c,
    material: Symbols.location_on,
    cupertino: CupertinoIcons.location,
  );

  static IconData chart(BuildContext c) => resolve(
    c,
    material: Symbols.bar_chart,
    cupertino: CupertinoIcons.chart_bar,
  );

  static IconData keyboardDown(BuildContext c) => resolve(
    c,
    material: Symbols.keyboard_arrow_down,
    cupertino: CupertinoIcons.chevron_down,
  );

  static IconData schedule(BuildContext c) => resolve(
    c,
    material: Symbols.schedule,
    cupertino: CupertinoIcons.clock,
  );

  static IconData bookmark(BuildContext c) => resolve(
    c,
    material: Symbols.bookmark,
    cupertino: CupertinoIcons.bookmark_fill,
  );

  static IconData download(BuildContext c) => resolve(
    c,
    material: Symbols.download,
    cupertino: CupertinoIcons.cloud_download,
  );

  static IconData goToMessage(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_forward,
    cupertino: CupertinoIcons.arrow_right,
  );

  static IconData language(BuildContext c) => resolve(
    c,
    material: Symbols.language,
    cupertino: CupertinoIcons.globe,
  );

  static IconData settingsGear(BuildContext c) => resolve(
    c,
    material: Symbols.settings,
    cupertino: CupertinoIcons.gear_alt,
  );

  static IconData admin(BuildContext c) => resolve(
    c,
    material: Symbols.admin_panel_settings,
    cupertino: CupertinoIcons.shield,
  );

  static IconData fingerprint(BuildContext c) => resolve(
    c,
    material: Symbols.fingerprint,
    cupertino: CupertinoIcons.hand_raised_fill,
  );

  static IconData backspace(BuildContext c) => resolve(
    c,
    material: Symbols.backspace,
    cupertino: CupertinoIcons.delete_left,
  );

  static IconData refresh(BuildContext c) => resolve(
    c,
    material: Symbols.refresh,
    cupertino: CupertinoIcons.refresh,
  );

  static IconData tune(BuildContext c) => resolve(
    c,
    material: Symbols.tune,
    cupertino: CupertinoIcons.slider_horizontal_3,
  );

  static IconData grid(BuildContext c) => resolve(
    c,
    material: Symbols.grid_view,
    cupertino: CupertinoIcons.square_grid_2x2,
  );

  static IconData photoLibrary(BuildContext c) => resolve(
    c,
    material: Symbols.photo_library,
    cupertino: CupertinoIcons.photo_on_rectangle,
  );

  static IconData check(BuildContext c) => resolve(
    c,
    material: Symbols.check,
    cupertino: CupertinoIcons.check_mark,
  );

  static IconData pause(BuildContext c) =>
      resolve(c, material: Symbols.pause, cupertino: CupertinoIcons.pause_fill);

  static IconData play(BuildContext c) => resolve(
    c,
    material: Symbols.play_arrow,
    cupertino: CupertinoIcons.play_fill,
  );

  static IconData rotate(BuildContext c) => resolve(
    c,
    material: Symbols.rotate_90_degrees_ccw,
    cupertino: CupertinoIcons.rotate_left,
  );

  static IconData chevronDown(BuildContext c) => resolve(
    c,
    material: Symbols.keyboard_arrow_down,
    cupertino: CupertinoIcons.chevron_down,
  );

  static IconData volumeUp(BuildContext c) => speaker(c);

  static IconData volumeOff(BuildContext c) => resolve(
    c,
    material: Symbols.volume_off,
    cupertino: CupertinoIcons.speaker_slash_fill,
  );

  static IconData group(BuildContext c) => resolve(
    c,
    material: Symbols.group,
    cupertino: CupertinoIcons.person_2,
  );

  static IconData public(BuildContext c) => resolve(
    c,
    material: Symbols.public,
    cupertino: CupertinoIcons.globe,
  );

  static IconData addCircle(BuildContext c) => resolve(
    c,
    material: Symbols.add,
    cupertino: CupertinoIcons.add,
  );

  static IconData chevronLeft(BuildContext c) => resolve(
    c,
    material: Symbols.chevron_left,
    cupertino: CupertinoIcons.chevron_left,
  );

}
