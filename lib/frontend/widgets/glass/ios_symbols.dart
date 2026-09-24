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

  static IconData lock(BuildContext c) => resolve(
    c,
    material: Symbols.lock,
    cupertino: CupertinoIcons.lock_fill,
  );

  static IconData lockOpen(BuildContext c) => resolve(
    c,
    material: Symbols.lock_open,
    cupertino: CupertinoIcons.lock_open,
  );

  static IconData image(BuildContext c) => resolve(
    c,
    material: Symbols.image,
    cupertino: CupertinoIcons.photo,
  );

  static IconData movie(BuildContext c) => resolve(
    c,
    material: Symbols.movie,
    cupertino: CupertinoIcons.film,
  );

  static IconData warning(BuildContext c) => resolve(
    c,
    material: Symbols.warning,
    cupertino: CupertinoIcons.exclamationmark_triangle,
  );

  static IconData notifications(BuildContext c) => resolve(
    c,
    material: Symbols.notifications,
    cupertino: CupertinoIcons.bell,
  );

  static IconData chatBubble(BuildContext c) => resolve(
    c,
    material: Symbols.chat_bubble,
    cupertino: CupertinoIcons.chat_bubble,
  );

  static IconData checkCircle(BuildContext c) => resolve(
    c,
    material: Symbols.check_circle,
    cupertino: CupertinoIcons.check_mark_circled_solid,
  );

  static IconData doneAll(BuildContext c) => resolve(
    c,
    material: Symbols.done_all,
    cupertino: CupertinoIcons.checkmark_alt,
  );

  static IconData block(BuildContext c) => resolve(
    c,
    material: Symbols.block,
    cupertino: CupertinoIcons.xmark_circle,
  );

  static IconData palette(BuildContext c) => resolve(
    c,
    material: Symbols.palette,
    cupertino: CupertinoIcons.paintbrush,
  );

  static IconData camera(BuildContext c) => resolve(
    c,
    material: Symbols.photo_camera,
    cupertino: CupertinoIcons.camera,
  );

  static IconData cameraOff(BuildContext c) => resolve(
    c,
    material: Symbols.no_photography,
    cupertino: CupertinoIcons.camera,
  );

  static IconData archive(BuildContext c) => resolve(
    c,
    material: Symbols.archive,
    cupertino: CupertinoIcons.archivebox,
  );

  static IconData keep(BuildContext c) => resolve(
    c,
    material: Symbols.keep,
    cupertino: CupertinoIcons.pin,
  );

  static IconData brokenImage(BuildContext c) => resolve(
    c,
    material: Symbols.broken_image,
    cupertino: CupertinoIcons.photo,
  );

  static IconData settings(BuildContext c) => settingsGear(c);

  static IconData call(BuildContext c) => phone(c);

  static IconData contentCopy(BuildContext c) => copy(c);

  static IconData description(BuildContext c) => doc(c);

  static IconData moreVert(BuildContext c) => resolve(
    c,
    material: Symbols.more_vert,
    cupertino: CupertinoIcons.ellipsis_vertical,
  );

  static IconData visibilityOff(BuildContext c) => resolve(
    c,
    material: Symbols.visibility_off,
    cupertino: CupertinoIcons.eye_slash,
  );

  static IconData folder(BuildContext c) => resolve(
    c,
    material: Symbols.folder,
    cupertino: CupertinoIcons.folder,
  );

  static IconData switchAccount(BuildContext c) => resolve(
    c,
    material: Symbols.switch_account,
    cupertino: CupertinoIcons.person_2,
  );

  static IconData downloadOffline(BuildContext c) => resolve(
    c,
    material: Symbols.download_for_offline,
    cupertino: CupertinoIcons.arrow_down_circle,
  );


  static IconData arrowBack(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_back,
    cupertino: CupertinoIcons.back,
  );

  static IconData arrowBackIos(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_back_ios_new,
    cupertino: CupertinoIcons.chevron_back,
  );

  static IconData expandMore(BuildContext c) => resolve(
    c,
    material: Symbols.expand_more,
    cupertino: CupertinoIcons.chevron_down,
  );

  static IconData expandLess(BuildContext c) => resolve(
    c,
    material: Symbols.expand_less,
    cupertino: CupertinoIcons.chevron_up,
  );

  static IconData keyboardArrowDown(BuildContext c) => resolve(
    c,
    material: Symbols.keyboard_arrow_down,
    cupertino: CupertinoIcons.chevron_down,
  );

  static IconData radioChecked(BuildContext c) => resolve(
    c,
    material: Symbols.radio_button_checked,
    cupertino: CupertinoIcons.circle_filled,
  );

  static IconData radioUnchecked(BuildContext c) => resolve(
    c,
    material: Symbols.radio_button_unchecked,
    cupertino: CupertinoIcons.circle,
  );

  static IconData hourglass(BuildContext c) => resolve(
    c,
    material: Symbols.hourglass_top,
    cupertino: CupertinoIcons.time,
  );

  static IconData deleteSweep(BuildContext c) => resolve(
    c,
    material: Symbols.delete_sweep,
    cupertino: CupertinoIcons.delete,
  );

  static IconData campaign(BuildContext c) => resolve(
    c,
    material: Symbols.campaign,
    cupertino: CupertinoIcons.speaker_3,
  );

  static IconData badge(BuildContext c) => resolve(
    c,
    material: Symbols.badge,
    cupertino: CupertinoIcons.person_crop_circle_badge_checkmark,
  );

  static IconData autoAwesome(BuildContext c) => resolve(
    c,
    material: Symbols.auto_awesome,
    cupertino: CupertinoIcons.sparkles,
  );

  static IconData audioFile(BuildContext c) => resolve(
    c,
    material: Symbols.audio_file,
    cupertino: CupertinoIcons.music_note,
  );

  static IconData uploadFile(BuildContext c) => resolve(
    c,
    material: Symbols.upload_file,
    cupertino: CupertinoIcons.cloud_upload,
  );

  static IconData smartphone(BuildContext c) => resolve(
    c,
    material: Symbols.smartphone,
    cupertino: CupertinoIcons.device_phone_portrait,
  );

  static IconData settingsVoice(BuildContext c) => resolve(
    c,
    material: Symbols.settings_voice,
    cupertino: CupertinoIcons.waveform,
  );

  static IconData vpnLock(BuildContext c) => resolve(
    c,
    material: Symbols.vpn_lock,
    cupertino: CupertinoIcons.lock_shield,
  );

  static IconData verifiedUser(BuildContext c) => resolve(
    c,
    material: Symbols.verified_user,
    cupertino: CupertinoIcons.checkmark_shield,
  );

  static IconData pushPin(BuildContext c) => resolve(
    c,
    material: Symbols.push_pin,
    cupertino: CupertinoIcons.pin,
  );

  static IconData keepOff(BuildContext c) => resolve(
    c,
    material: Symbols.keep_off,
    cupertino: CupertinoIcons.pin_slash,
  );

  static IconData photoCamera(BuildContext c) => resolve(
    c,
    material: Symbols.photo_camera,
    cupertino: CupertinoIcons.camera,
  );

  static IconData noPhotography(BuildContext c) => resolve(
    c,
    material: Symbols.no_photography,
    cupertino: CupertinoIcons.camera,
  );

  static IconData attachment(BuildContext c) => resolve(
    c,
    material: Symbols.attachment,
    cupertino: CupertinoIcons.paperclip,
  );

  static IconData barChart(BuildContext c) => resolve(
    c,
    material: Symbols.bar_chart,
    cupertino: CupertinoIcons.chart_bar,
  );

  static IconData locationOn(BuildContext c) => resolve(
    c,
    material: Symbols.location_on,
    cupertino: CupertinoIcons.location_solid,
  );

  static IconData groups(BuildContext c) => resolve(
    c,
    material: Symbols.groups,
    cupertino: CupertinoIcons.person_3,
  );

  static IconData groupAdd(BuildContext c) => resolve(
    c,
    material: Symbols.group_add,
    cupertino: CupertinoIcons.person_add,
  );

  static IconData markChatUnread(BuildContext c) => resolve(
    c,
    material: Symbols.mark_chat_unread,
    cupertino: CupertinoIcons.envelope_badge,
  );

  static IconData adminPanel(BuildContext c) => resolve(
    c,
    material: Symbols.admin_panel_settings,
    cupertino: CupertinoIcons.shield_lefthalf_fill,
  );

  static IconData gridView(BuildContext c) => resolve(
    c,
    material: Symbols.grid_view,
    cupertino: CupertinoIcons.square_grid_2x2,
  );

  static IconData downloadForOffline(BuildContext c) => resolve(
    c,
    material: Symbols.download_for_offline,
    cupertino: CupertinoIcons.arrow_down_circle,
  );

  static IconData errorOutline(BuildContext c) => resolve(
    c,
    material: Symbols.error_outline,
    cupertino: CupertinoIcons.exclamationmark_circle,
  );

  static IconData moreHoriz(BuildContext c) => resolve(
    c,
    material: Symbols.more_horiz,
    cupertino: CupertinoIcons.ellipsis,
  );

  static IconData playArrow(BuildContext c) => resolve(
    c,
    material: Symbols.play_arrow,
    cupertino: CupertinoIcons.play_fill,
  );

  static IconData volumeDown(BuildContext c) => resolve(
    c,
    material: Symbols.volume_down,
    cupertino: CupertinoIcons.speaker_1_fill,
  );

  static IconData callEnd(BuildContext c) => resolve(
    c,
    material: Symbols.call_end,
    cupertino: CupertinoIcons.phone_down_fill,
  );

  static IconData callMade(BuildContext c) => resolve(
    c,
    material: Symbols.call_made,
    cupertino: CupertinoIcons.phone_arrow_up_right,
  );

  static IconData callReceived(BuildContext c) => resolve(
    c,
    material: Symbols.call_received,
    cupertino: CupertinoIcons.phone_arrow_down_left,
  );

  static IconData frontHand(BuildContext c) => resolve(
    c,
    material: Symbols.front_hand,
    cupertino: CupertinoIcons.hand_raised_fill,
  );

  static IconData rotate90(BuildContext c) => resolve(
    c,
    material: Symbols.rotate_90_degrees_ccw,
    cupertino: CupertinoIcons.rotate_left,
  );

  static IconData arrowForward(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_forward,
    cupertino: CupertinoIcons.arrow_right,
  );

  static IconData cancel(BuildContext c) => resolve(
    c,
    material: Symbols.cancel,
    cupertino: CupertinoIcons.clear_thick_circled,
  );

  static IconData password(BuildContext c) => resolve(
    c,
    material: Symbols.password,
    cupertino: CupertinoIcons.lock_fill,
  );

  static IconData devices(BuildContext c) => resolve(
    c,
    material: Symbols.devices,
    cupertino: CupertinoIcons.device_phone_portrait,
  );

  static IconData graphicEq(BuildContext c) => resolve(
    c,
    material: Symbols.graphic_eq,
    cupertino: CupertinoIcons.waveform,
  );

  static IconData chat(BuildContext c) => resolve(
    c,
    material: Symbols.chat,
    cupertino: CupertinoIcons.chat_bubble,
  );

  static IconData flipCamera(BuildContext c) => resolve(
    c,
    material: Symbols.flip_camera_android,
    cupertino: CupertinoIcons.switch_camera,
  );

  static IconData speed(BuildContext c) => resolve(
    c,
    material: Symbols.speed,
    cupertino: CupertinoIcons.gauge,
  );

  static IconData cropRotate(BuildContext c) => resolve(
    c,
    material: Symbols.crop_rotate,
    cupertino: CupertinoIcons.crop_rotate,
  );

  static IconData brush(BuildContext c) => resolve(
    c,
    material: Symbols.brush,
    cupertino: CupertinoIcons.paintbrush,
  );

  static IconData personOff(BuildContext c) => resolve(
    c,
    material: Symbols.person_off,
    cupertino: CupertinoIcons.person_badge_minus,
  );

  static IconData construction(BuildContext c) => resolve(
    c,
    material: Symbols.construction,
    cupertino: CupertinoIcons.hammer,
  );

  static IconData filterAlt(BuildContext c) => resolve(
    c,
    material: Symbols.filter_alt,
    cupertino: CupertinoIcons.line_horizontal_3_decrease,
  );

  static IconData logout(BuildContext c) => resolve(
    c,
    material: Symbols.logout,
    cupertino: CupertinoIcons.square_arrow_right,
  );

  static IconData darkMode(BuildContext c) => resolve(
    c,
    material: Symbols.dark_mode,
    cupertino: CupertinoIcons.moon_fill,
  );

  static IconData wallpaper(BuildContext c) => resolve(
    c,
    material: Symbols.wallpaper,
    cupertino: CupertinoIcons.photo,
  );

  static IconData textFields(BuildContext c) => resolve(
    c,
    material: Symbols.text_fields,
    cupertino: CupertinoIcons.textformat,
  );

  static IconData apps(BuildContext c) => resolve(
    c,
    material: Symbols.apps,
    cupertino: CupertinoIcons.square_grid_2x2,
  );

  static IconData security(BuildContext c) => resolve(
    c,
    material: Symbols.security,
    cupertino: CupertinoIcons.shield,
  );

  static IconData notificationsActive(BuildContext c) => resolve(
    c,
    material: Symbols.notifications_active,
    cupertino: CupertinoIcons.bell_fill,
  );

  static IconData qrCode(BuildContext c) => resolve(
    c,
    material: Symbols.qr_code_2,
    cupertino: CupertinoIcons.qrcode,
  );

  static IconData personPin(BuildContext c) => resolve(
    c,
    material: Symbols.person_pin,
    cupertino: CupertinoIcons.person_crop_circle,
  );

  static IconData createNewFolder(BuildContext c) => resolve(
    c,
    material: Symbols.create_new_folder,
    cupertino: CupertinoIcons.folder_badge_plus,
  );

  static IconData contacts(BuildContext c) => resolve(
    c,
    material: Symbols.contacts,
    cupertino: CupertinoIcons.person_2,
  );

  static IconData folderOpen(BuildContext c) => resolve(
    c,
    material: Symbols.folder_open,
    cupertino: CupertinoIcons.folder_open,
  );

  static IconData undo(BuildContext c) => resolve(
    c,
    material: Symbols.undo,
    cupertino: CupertinoIcons.arrow_uturn_left,
  );

  static IconData mail(BuildContext c) => resolve(
    c,
    material: Symbols.mail,
    cupertino: CupertinoIcons.mail,
  );

  static IconData flashOn(BuildContext c) => resolve(
    c,
    material: Symbols.flash_on,
    cupertino: CupertinoIcons.bolt_fill,
  );

  static IconData timer(BuildContext c) => resolve(
    c,
    material: Symbols.timer,
    cupertino: CupertinoIcons.timer,
  );

  static IconData shield(BuildContext c) => resolve(
    c,
    material: Symbols.shield,
    cupertino: CupertinoIcons.shield_fill,
  );

  static IconData contactPhone(BuildContext c) => resolve(
    c,
    material: Symbols.contact_phone,
    cupertino: CupertinoIcons.phone,
  );

  static IconData keyboardAlt(BuildContext c) => resolve(
    c,
    material: Symbols.keyboard_alt,
    cupertino: CupertinoIcons.keyboard,
  );

  static IconData wifiOff(BuildContext c) => resolve(
    c,
    material: Symbols.wifi_off,
    cupertino: CupertinoIcons.wifi_slash,
  );

  static IconData cloudOff(BuildContext c) => resolve(
    c,
    material: Symbols.cloud_off,
    cupertino: CupertinoIcons.cloud,
  );

  static IconData ampStories(BuildContext c) => resolve(
    c,
    material: Symbols.amp_stories,
    cupertino: CupertinoIcons.rectangle_stack,
  );

  static IconData showChart(BuildContext c) => resolve(
    c,
    material: Symbols.show_chart,
    cupertino: CupertinoIcons.chart_bar,
  );

  static IconData smartToy(BuildContext c) => resolve(
    c,
    material: Symbols.smart_toy,
    cupertino: CupertinoIcons.desktopcomputer,
  );

  static IconData brightnessAuto(BuildContext c) => resolve(
    c,
    material: Symbols.brightness_auto,
    cupertino: CupertinoIcons.circle_lefthalf_fill,
  );

  static IconData lightMode(BuildContext c) => resolve(
    c,
    material: Symbols.light_mode,
    cupertino: CupertinoIcons.sun_max,
  );

  static IconData addAPhoto(BuildContext c) => resolve(
    c,
    material: Symbols.add_a_photo,
    cupertino: CupertinoIcons.camera,
  );

  static IconData addCircleOutline(BuildContext c) => resolve(
    c,
    material: Symbols.add_circle_outline,
    cupertino: CupertinoIcons.plus,
  );

  static IconData animation(BuildContext c) => resolve(
    c,
    material: Symbols.animation,
    cupertino: CupertinoIcons.circle,
  );

  static IconData arrowDownward(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_downward,
    cupertino: CupertinoIcons.arrow_down,
  );

  static IconData arrowRightAlt(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_right_alt,
    cupertino: CupertinoIcons.arrow_right,
  );

  static IconData arrowSplit(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_split,
    cupertino: CupertinoIcons.arrow_right,
  );

  static IconData arrowUpward(BuildContext c) => resolve(
    c,
    material: Symbols.arrow_upward,
    cupertino: CupertinoIcons.arrow_up,
  );

  static IconData article(BuildContext c) => resolve(
    c,
    material: Symbols.article,
    cupertino: CupertinoIcons.circle,
  );

  static IconData attachFile(BuildContext c) => resolve(
    c,
    material: Symbols.attach_file,
    cupertino: CupertinoIcons.paperclip,
  );

  static IconData autorenew(BuildContext c) => resolve(
    c,
    material: Symbols.autorenew,
    cupertino: CupertinoIcons.arrow_2_circlepath,
  );

  static IconData backHand(BuildContext c) => resolve(
    c,
    material: Symbols.back_hand,
    cupertino: CupertinoIcons.hand_raised,
  );

  static IconData bedtime(BuildContext c) => resolve(
    c,
    material: Symbols.bedtime,
    cupertino: CupertinoIcons.circle,
  );

  static IconData bluetoothDisabled(BuildContext c) => resolve(
    c,
    material: Symbols.bluetooth_disabled,
    cupertino: CupertinoIcons.circle,
  );

  static IconData blurCircular(BuildContext c) => resolve(
    c,
    material: Symbols.blur_circular,
    cupertino: CupertinoIcons.circle,
  );

  static IconData blurLinear(BuildContext c) => resolve(
    c,
    material: Symbols.blur_linear,
    cupertino: CupertinoIcons.circle,
  );

  static IconData blurOn(BuildContext c) => resolve(
    c,
    material: Symbols.blur_on,
    cupertino: CupertinoIcons.circle,
  );

  static IconData bubbleChart(BuildContext c) => resolve(
    c,
    material: Symbols.bubble_chart,
    cupertino: CupertinoIcons.circle,
  );

  static IconData bugReport(BuildContext c) => resolve(
    c,
    material: Symbols.bug_report,
    cupertino: CupertinoIcons.ant,
  );

  static IconData callMissed(BuildContext c) => resolve(
    c,
    material: Symbols.call_missed,
    cupertino: CupertinoIcons.phone_down,
  );

  static IconData cameraAlt(BuildContext c) => resolve(
    c,
    material: Symbols.camera_alt,
    cupertino: CupertinoIcons.photo,
  );

  static IconData cameraFront(BuildContext c) => resolve(
    c,
    material: Symbols.camera_front,
    cupertino: CupertinoIcons.camera,
  );

  static IconData cameraRear(BuildContext c) => resolve(
    c,
    material: Symbols.camera_rear,
    cupertino: CupertinoIcons.photo,
  );

  static IconData cellTower(BuildContext c) => resolve(
    c,
    material: Symbols.cell_tower,
    cupertino: CupertinoIcons.circle,
  );

  static IconData checkBox(BuildContext c) => resolve(
    c,
    material: Symbols.check_box,
    cupertino: CupertinoIcons.checkmark_square,
  );

  static IconData checkBoxOutlineBlank(BuildContext c) => resolve(
    c,
    material: Symbols.check_box_outline_blank,
    cupertino: CupertinoIcons.square,
  );

  static IconData circle(BuildContext c) => resolve(
    c,
    material: Symbols.circle,
    cupertino: CupertinoIcons.circle,
  );

  static IconData closeFullscreen(BuildContext c) => resolve(
    c,
    material: Symbols.close_fullscreen,
    cupertino: CupertinoIcons.circle,
  );

  static IconData cloud(BuildContext c) => resolve(
    c,
    material: Symbols.cloud,
    cupertino: CupertinoIcons.cloud,
  );

  static IconData cloudDone(BuildContext c) => resolve(
    c,
    material: Symbols.cloud_done,
    cupertino: CupertinoIcons.checkmark,
  );

  static IconData code(BuildContext c) => resolve(
    c,
    material: Symbols.code,
    cupertino: CupertinoIcons.circle,
  );

  static IconData contactPage(BuildContext c) => resolve(
    c,
    material: Symbols.contact_page,
    cupertino: CupertinoIcons.circle,
  );

  static IconData contrast(BuildContext c) => resolve(
    c,
    material: Symbols.contrast,
    cupertino: CupertinoIcons.circle,
  );

  static IconData deleteHistory(BuildContext c) => resolve(
    c,
    material: Symbols.delete_history,
    cupertino: CupertinoIcons.delete,
  );

  static IconData dialpad(BuildContext c) => resolve(
    c,
    material: Symbols.dialpad,
    cupertino: CupertinoIcons.circle,
  );

  static IconData dns(BuildContext c) => resolve(
    c,
    material: Symbols.dns,
    cupertino: CupertinoIcons.cloud,
  );

  static IconData doNotDisturbOn(BuildContext c) => resolve(
    c,
    material: Symbols.do_not_disturb_on,
    cupertino: CupertinoIcons.circle,
  );

  static IconData doNotTouch(BuildContext c) => resolve(
    c,
    material: Symbols.do_not_touch,
    cupertino: CupertinoIcons.hand_raised_slash,
  );

  static IconData editSquare(BuildContext c) => resolve(
    c,
    material: Symbols.edit_square,
    cupertino: CupertinoIcons.circle,
  );

  static IconData emojiEmotions(BuildContext c) => resolve(
    c,
    material: Symbols.emoji_emotions,
    cupertino: CupertinoIcons.smiley,
  );

  static IconData encrypted(BuildContext c) => resolve(
    c,
    material: Symbols.encrypted,
    cupertino: CupertinoIcons.circle,
  );

  static IconData error2(BuildContext c) => resolve(
    c,
    material: Symbols.error,
    cupertino: CupertinoIcons.exclamationmark_circle,
  );

  static IconData exitToApp(BuildContext c) => resolve(
    c,
    material: Symbols.exit_to_app,
    cupertino: CupertinoIcons.circle,
  );

  static IconData extension(BuildContext c) => resolve(
    c,
    material: Symbols.extension,
    cupertino: CupertinoIcons.circle,
  );

  static IconData face(BuildContext c) => resolve(
    c,
    material: Symbols.face,
    cupertino: CupertinoIcons.circle,
  );

  static IconData flashOff(BuildContext c) => resolve(
    c,
    material: Symbols.flash_off,
    cupertino: CupertinoIcons.circle,
  );

  static IconData flip(BuildContext c) => resolve(
    c,
    material: Symbols.flip,
    cupertino: CupertinoIcons.circle,
  );

  static IconData flipCameraIos(BuildContext c) => resolve(
    c,
    material: Symbols.flip_camera_ios,
    cupertino: CupertinoIcons.photo,
  );

  static IconData folderOff(BuildContext c) => resolve(
    c,
    material: Symbols.folder_off,
    cupertino: CupertinoIcons.folder,
  );

  static IconData folderZip(BuildContext c) => resolve(
    c,
    material: Symbols.folder_zip,
    cupertino: CupertinoIcons.folder,
  );

  static IconData formatQuote(BuildContext c) => resolve(
    c,
    material: Symbols.format_quote,
    cupertino: CupertinoIcons.circle,
  );

  static IconData formatSize(BuildContext c) => resolve(
    c,
    material: Symbols.format_size,
    cupertino: CupertinoIcons.circle,
  );

  static IconData forum(BuildContext c) => resolve(
    c,
    material: Symbols.forum,
    cupertino: CupertinoIcons.circle,
  );

  static IconData fullscreen(BuildContext c) => resolve(
    c,
    material: Symbols.fullscreen,
    cupertino: CupertinoIcons.fullscreen,
  );

  static IconData gifBox(BuildContext c) => resolve(
    c,
    material: Symbols.gif_box,
    cupertino: CupertinoIcons.photo,
  );

  static IconData gppBad(BuildContext c) => resolve(
    c,
    material: Symbols.gpp_bad,
    cupertino: CupertinoIcons.circle,
  );

  static IconData gppMaybe(BuildContext c) => resolve(
    c,
    material: Symbols.gpp_maybe,
    cupertino: CupertinoIcons.shield,
  );

  static IconData gridOn(BuildContext c) => resolve(
    c,
    material: Symbols.grid_on,
    cupertino: CupertinoIcons.circle,
  );

  static IconData hd(BuildContext c) => resolve(
    c,
    material: Symbols.hd,
    cupertino: CupertinoIcons.circle,
  );

  static IconData historyEdu(BuildContext c) => resolve(
    c,
    material: Symbols.history_edu,
    cupertino: CupertinoIcons.circle,
  );

  static IconData howToReg(BuildContext c) => resolve(
    c,
    material: Symbols.how_to_reg,
    cupertino: CupertinoIcons.person_crop_circle_badge_checkmark,
  );

  static IconData inkEraser(BuildContext c) => resolve(
    c,
    material: Symbols.ink_eraser,
    cupertino: CupertinoIcons.circle,
  );

  static IconData inkHighlighter(BuildContext c) => resolve(
    c,
    material: Symbols.ink_highlighter,
    cupertino: CupertinoIcons.circle,
  );

  static IconData insertDriveFile(BuildContext c) => resolve(
    c,
    material: Symbols.insert_drive_file,
    cupertino: CupertinoIcons.circle,
  );

  static IconData installMobile(BuildContext c) => resolve(
    c,
    material: Symbols.install_mobile,
    cupertino: CupertinoIcons.circle,
  );

  static IconData inventory2(BuildContext c) => resolve(
    c,
    material: Symbols.inventory_2,
    cupertino: CupertinoIcons.circle,
  );

  static IconData iosShare(BuildContext c) => resolve(
    c,
    material: Symbols.ios_share,
    cupertino: CupertinoIcons.circle,
  );

  static IconData key(BuildContext c) => resolve(
    c,
    material: Symbols.key,
    cupertino: CupertinoIcons.lock_rotation,
  );

  static IconData keyboardArrowUp(BuildContext c) => resolve(
    c,
    material: Symbols.keyboard_arrow_up,
    cupertino: CupertinoIcons.chevron_up,
  );

  static IconData lan(BuildContext c) => resolve(
    c,
    material: Symbols.lan,
    cupertino: CupertinoIcons.circle,
  );

  static IconData layers(BuildContext c) => resolve(
    c,
    material: Symbols.layers,
    cupertino: CupertinoIcons.square_stack,
  );

  static IconData locationCity(BuildContext c) => resolve(
    c,
    material: Symbols.location_city,
    cupertino: CupertinoIcons.circle,
  );

  static IconData lockClock(BuildContext c) => resolve(
    c,
    material: Symbols.lock_clock,
    cupertino: CupertinoIcons.lock,
  );

  static IconData markChatRead(BuildContext c) => resolve(
    c,
    material: Symbols.mark_chat_read,
    cupertino: CupertinoIcons.circle,
  );

  static IconData memory(BuildContext c) => resolve(
    c,
    material: Symbols.memory,
    cupertino: CupertinoIcons.cube,
  );

  static IconData menu(BuildContext c) => resolve(
    c,
    material: Symbols.menu,
    cupertino: CupertinoIcons.circle,
  );

  static IconData missedVideoCall(BuildContext c) => resolve(
    c,
    material: Symbols.missed_video_call,
    cupertino: CupertinoIcons.videocam,
  );

  static IconData modeComment(BuildContext c) => resolve(
    c,
    material: Symbols.mode_comment,
    cupertino: CupertinoIcons.circle,
  );

  static IconData mood(BuildContext c) => resolve(
    c,
    material: Symbols.mood,
    cupertino: CupertinoIcons.smiley,
  );

  static IconData mop(BuildContext c) => resolve(
    c,
    material: Symbols.mop,
    cupertino: CupertinoIcons.trash,
  );

  static IconData motionPhotosOn(BuildContext c) => resolve(
    c,
    material: Symbols.motion_photos_on,
    cupertino: CupertinoIcons.photo,
  );

  static IconData musicNote(BuildContext c) => resolve(
    c,
    material: Symbols.music_note,
    cupertino: CupertinoIcons.circle,
  );

  static IconData nfc(BuildContext c) => resolve(
    c,
    material: Symbols.nfc,
    cupertino: CupertinoIcons.radiowaves_right,
  );

  static IconData noiseControlOn(BuildContext c) => resolve(
    c,
    material: Symbols.noise_control_on,
    cupertino: CupertinoIcons.circle,
  );

  static IconData northEast(BuildContext c) => resolve(
    c,
    material: Symbols.north_east,
    cupertino: CupertinoIcons.arrow_up_right,
  );

  static IconData notificationsOff(BuildContext c) => resolve(
    c,
    material: Symbols.notifications_off,
    cupertino: CupertinoIcons.bell_slash,
  );

  static IconData numbers(BuildContext c) => resolve(
    c,
    material: Symbols.numbers,
    cupertino: CupertinoIcons.number,
  );

  static IconData openInFull(BuildContext c) => resolve(
    c,
    material: Symbols.open_in_full,
    cupertino: CupertinoIcons.circle,
  );

  static IconData openInNew(BuildContext c) => resolve(
    c,
    material: Symbols.open_in_new,
    cupertino: CupertinoIcons.circle,
  );

  static IconData personRemove(BuildContext c) => resolve(
    c,
    material: Symbols.person_remove,
    cupertino: CupertinoIcons.person_badge_minus,
  );

  static IconData pictureAsPdf(BuildContext c) => resolve(
    c,
    material: Symbols.picture_as_pdf,
    cupertino: CupertinoIcons.doc,
  );

  static IconData priorityHigh(BuildContext c) => resolve(
    c,
    material: Symbols.priority_high,
    cupertino: CupertinoIcons.circle,
  );

  static IconData qrCodeScanner(BuildContext c) => resolve(
    c,
    material: Symbols.qr_code_scanner,
    cupertino: CupertinoIcons.circle,
  );

  static IconData radar(BuildContext c) => resolve(
    c,
    material: Symbols.radar,
    cupertino: CupertinoIcons.circle,
  );

  static IconData recordVoiceOver(BuildContext c) => resolve(
    c,
    material: Symbols.record_voice_over,
    cupertino: CupertinoIcons.person_crop_circle,
  );

  static IconData rectangle(BuildContext c) => resolve(
    c,
    material: Symbols.rectangle,
    cupertino: CupertinoIcons.circle,
  );

  static IconData removeCircle(BuildContext c) => resolve(
    c,
    material: Symbols.remove_circle,
    cupertino: CupertinoIcons.delete,
  );

  static IconData removeModerator(BuildContext c) => resolve(
    c,
    material: Symbols.remove_moderator,
    cupertino: CupertinoIcons.person_badge_minus,
  );

  static IconData rotateRight(BuildContext c) => resolve(
    c,
    material: Symbols.rotate_right,
    cupertino: CupertinoIcons.circle,
  );

  static IconData saveAlt(BuildContext c) => resolve(
    c,
    material: Symbols.save_alt,
    cupertino: CupertinoIcons.square_arrow_down,
  );

  static IconData shieldLock(BuildContext c) => resolve(
    c,
    material: Symbols.shield_lock,
    cupertino: CupertinoIcons.lock,
  );

  static IconData shieldPerson(BuildContext c) => resolve(
    c,
    material: Symbols.shield_person,
    cupertino: CupertinoIcons.shield,
  );

  static IconData slideshow(BuildContext c) => resolve(
    c,
    material: Symbols.slideshow,
    cupertino: CupertinoIcons.photo_on_rectangle,
  );

  static IconData southWest(BuildContext c) => resolve(
    c,
    material: Symbols.south_west,
    cupertino: CupertinoIcons.circle,
  );

  static IconData stadiaController(BuildContext c) => resolve(
    c,
    material: Symbols.stadia_controller,
    cupertino: CupertinoIcons.circle,
  );

  static IconData star(BuildContext c) => resolve(
    c,
    material: Symbols.star,
    cupertino: CupertinoIcons.star,
  );

  static IconData stayCurrentPortrait(BuildContext c) => resolve(
    c,
    material: Symbols.stay_current_portrait,
    cupertino: CupertinoIcons.circle,
  );

  static IconData stopCircle(BuildContext c) => resolve(
    c,
    material: Symbols.stop_circle,
    cupertino: CupertinoIcons.stop_circle,
  );

  static IconData styler(BuildContext c) => resolve(
    c,
    material: Symbols.styler,
    cupertino: CupertinoIcons.circle,
  );

  static IconData swipeRight(BuildContext c) => resolve(
    c,
    material: Symbols.swipe_right,
    cupertino: CupertinoIcons.circle,
  );

  static IconData sync(BuildContext c) => resolve(
    c,
    material: Symbols.sync,
    cupertino: CupertinoIcons.arrow_2_circlepath,
  );

  static IconData systemUpdate(BuildContext c) => resolve(
    c,
    material: Symbols.system_update,
    cupertino: CupertinoIcons.circle,
  );

  static IconData tableChart(BuildContext c) => resolve(
    c,
    material: Symbols.table_chart,
    cupertino: CupertinoIcons.table,
  );

  static IconData terminal(BuildContext c) => resolve(
    c,
    material: Symbols.terminal,
    cupertino: CupertinoIcons.circle,
  );

  static IconData textSnippet(BuildContext c) => resolve(
    c,
    material: Symbols.text_snippet,
    cupertino: CupertinoIcons.circle,
  );

  static IconData touchApp(BuildContext c) => resolve(
    c,
    material: Symbols.touch_app,
    cupertino: CupertinoIcons.hand_draw,
  );

  static IconData translate(BuildContext c) => resolve(
    c,
    material: Symbols.translate,
    cupertino: CupertinoIcons.textformat,
  );

  static IconData unarchive(BuildContext c) => resolve(
    c,
    material: Symbols.unarchive,
    cupertino: CupertinoIcons.archivebox,
  );

  static IconData update(BuildContext c) => resolve(
    c,
    material: Symbols.update,
    cupertino: CupertinoIcons.arrow_2_circlepath,
  );

  static IconData vibration(BuildContext c) => resolve(
    c,
    material: Symbols.vibration,
    cupertino: CupertinoIcons.circle,
  );

  static IconData videoFile(BuildContext c) => resolve(
    c,
    material: Symbols.video_file,
    cupertino: CupertinoIcons.videocam,
  );

  static IconData visibilityLock(BuildContext c) => resolve(
    c,
    material: Symbols.visibility_lock,
    cupertino: CupertinoIcons.lock,
  );

  static IconData voiceOverOff(BuildContext c) => resolve(
    c,
    material: Symbols.voice_over_off,
    cupertino: CupertinoIcons.mic_off,
  );

  static IconData vpnKey(BuildContext c) => resolve(
    c,
    material: Symbols.vpn_key,
    cupertino: CupertinoIcons.lock_shield,
  );

  static IconData vpnKeyOff(BuildContext c) => resolve(
    c,
    material: Symbols.vpn_key_off,
    cupertino: CupertinoIcons.circle,
  );

  static IconData waterDrop(BuildContext c) => resolve(
    c,
    material: Symbols.water_drop,
    cupertino: CupertinoIcons.circle,
  );

  static IconData wbSunny(BuildContext c) => resolve(
    c,
    material: Symbols.wb_sunny,
    cupertino: CupertinoIcons.circle,
  );

  /// Adapts a Material [Symbols] icon to the Cupertino twin when in iOS mode.
  /// Prefer named helpers when the icon is known at the call site.
  static IconData adapt(BuildContext context, IconData material) {
    if (!IosGlass.of(context)) return material;
    final mapped = _cupertinoByCodePoint[material.codePoint];
    return mapped ?? material;
  }

  static final Map<int, IconData> _cupertinoByCodePoint = {
    Symbols.search.codePoint: CupertinoIcons.search,
    Symbols.search_off.codePoint: CupertinoIcons.search,
    Symbols.close.codePoint: CupertinoIcons.xmark,
    Symbols.cancel.codePoint: CupertinoIcons.clear_thick_circled,
    Symbols.arrow_back.codePoint: CupertinoIcons.back,
    Symbols.chevron_right.codePoint: CupertinoIcons.chevron_right,
    Symbols.person_add.codePoint: CupertinoIcons.person_add,
    Symbols.person.codePoint: CupertinoIcons.person,
    Symbols.groups.codePoint: CupertinoIcons.person_2,
    Symbols.group_add.codePoint: CupertinoIcons.person_add,
    Symbols.verified.codePoint: CupertinoIcons.checkmark_seal_fill,
    Symbols.call.codePoint: CupertinoIcons.phone,
    Symbols.call_end.codePoint: CupertinoIcons.phone_down_fill,
    Symbols.phone_missed.codePoint: CupertinoIcons.phone_down,
    Symbols.phone_disabled.codePoint: CupertinoIcons.phone_down,
    Symbols.call_made.codePoint: CupertinoIcons.phone_arrow_up_right,
    Symbols.call_received.codePoint: CupertinoIcons.phone_arrow_down_left,
    Symbols.more_vert.codePoint: CupertinoIcons.ellipsis,
    Symbols.delete.codePoint: CupertinoIcons.delete,
    Symbols.link.codePoint: CupertinoIcons.link,
    Symbols.tag.codePoint: CupertinoIcons.tag,
    Symbols.mic.codePoint: CupertinoIcons.mic_fill,
    Symbols.mic_off.codePoint: CupertinoIcons.mic_off,
    Symbols.videocam.codePoint: CupertinoIcons.videocam_fill,
    Symbols.videocam_off.codePoint: CupertinoIcons.videocam,
    Symbols.volume_up.codePoint: CupertinoIcons.speaker_3_fill,
    Symbols.volume_down.codePoint: CupertinoIcons.speaker_1_fill,
    Symbols.screen_share.codePoint: CupertinoIcons.rectangle_on_rectangle,
    Symbols.front_hand.codePoint: CupertinoIcons.hand_raised_fill,
    Symbols.error_outline.codePoint: CupertinoIcons.exclamationmark_circle,
    Symbols.arrow_back_ios_new.codePoint: CupertinoIcons.chevron_back,
    Symbols.more_horiz.codePoint: CupertinoIcons.ellipsis,
    Symbols.reply.codePoint: CupertinoIcons.reply,
    Symbols.forward.codePoint: CupertinoIcons.arrowshape_turn_up_right,
    Symbols.content_copy.codePoint: CupertinoIcons.doc_on_doc,
    Symbols.edit.codePoint: CupertinoIcons.pencil,
    Symbols.push_pin.codePoint: CupertinoIcons.pin,
    Symbols.keep_off.codePoint: CupertinoIcons.pin_slash,
    Symbols.flag.codePoint: CupertinoIcons.flag,
    Symbols.info.codePoint: CupertinoIcons.info_circle,
    Symbols.history.codePoint: CupertinoIcons.clock,
    Symbols.visibility.codePoint: CupertinoIcons.eye,
    Symbols.mark_chat_unread.codePoint: CupertinoIcons.envelope_badge,
    Symbols.send.codePoint: CupertinoIcons.paperplane_fill,
    Symbols.attachment.codePoint: CupertinoIcons.paperclip,
    Symbols.add.codePoint: CupertinoIcons.plus,
    Symbols.image.codePoint: CupertinoIcons.photo,
    Symbols.description.codePoint: CupertinoIcons.doc,
    Symbols.location_on.codePoint: CupertinoIcons.location,
    Symbols.bar_chart.codePoint: CupertinoIcons.chart_bar,
    Symbols.keyboard_arrow_down.codePoint: CupertinoIcons.chevron_down,
    Symbols.schedule.codePoint: CupertinoIcons.clock,
    Symbols.bookmark.codePoint: CupertinoIcons.bookmark_fill,
    Symbols.download.codePoint: CupertinoIcons.cloud_download,
    Symbols.arrow_forward.codePoint: CupertinoIcons.arrow_right,
    Symbols.language.codePoint: CupertinoIcons.globe,
    Symbols.settings.codePoint: CupertinoIcons.gear_alt,
    Symbols.admin_panel_settings.codePoint: CupertinoIcons.shield,
    Symbols.fingerprint.codePoint: CupertinoIcons.hand_raised_fill,
    Symbols.backspace.codePoint: CupertinoIcons.delete_left,
    Symbols.refresh.codePoint: CupertinoIcons.refresh,
    Symbols.tune.codePoint: CupertinoIcons.slider_horizontal_3,
    Symbols.grid_view.codePoint: CupertinoIcons.square_grid_2x2,
    Symbols.photo_library.codePoint: CupertinoIcons.photo_on_rectangle,
    Symbols.check.codePoint: CupertinoIcons.check_mark,
    Symbols.pause.codePoint: CupertinoIcons.pause_fill,
    Symbols.play_arrow.codePoint: CupertinoIcons.play_fill,
    Symbols.rotate_90_degrees_ccw.codePoint: CupertinoIcons.rotate_left,
    Symbols.volume_off.codePoint: CupertinoIcons.speaker_slash_fill,
    Symbols.group.codePoint: CupertinoIcons.person_2,
    Symbols.public.codePoint: CupertinoIcons.globe,
    Symbols.chevron_left.codePoint: CupertinoIcons.chevron_left,
    Symbols.lock.codePoint: CupertinoIcons.lock_fill,
    Symbols.lock_open.codePoint: CupertinoIcons.lock_open,
    Symbols.movie.codePoint: CupertinoIcons.film,
    Symbols.warning.codePoint: CupertinoIcons.exclamationmark_triangle,
    Symbols.notifications.codePoint: CupertinoIcons.bell,
    Symbols.chat_bubble.codePoint: CupertinoIcons.chat_bubble,
    Symbols.check_circle.codePoint: CupertinoIcons.check_mark_circled_solid,
    Symbols.done_all.codePoint: CupertinoIcons.checkmark_alt,
    Symbols.block.codePoint: CupertinoIcons.xmark_circle,
    Symbols.palette.codePoint: CupertinoIcons.paintbrush,
    Symbols.photo_camera.codePoint: CupertinoIcons.camera,
    Symbols.no_photography.codePoint: CupertinoIcons.camera,
    Symbols.archive.codePoint: CupertinoIcons.archivebox,
    Symbols.keep.codePoint: CupertinoIcons.pin,
    Symbols.broken_image.codePoint: CupertinoIcons.photo,
    Symbols.visibility_off.codePoint: CupertinoIcons.eye_slash,
    Symbols.folder.codePoint: CupertinoIcons.folder,
    Symbols.switch_account.codePoint: CupertinoIcons.person_2,
    Symbols.download_for_offline.codePoint: CupertinoIcons.arrow_down_circle,
    Symbols.expand_more.codePoint: CupertinoIcons.chevron_down,
    Symbols.expand_less.codePoint: CupertinoIcons.chevron_up,
    Symbols.radio_button_checked.codePoint: CupertinoIcons.circle_filled,
    Symbols.radio_button_unchecked.codePoint: CupertinoIcons.circle,
    Symbols.hourglass_top.codePoint: CupertinoIcons.time,
    Symbols.delete_sweep.codePoint: CupertinoIcons.delete,
    Symbols.campaign.codePoint: CupertinoIcons.speaker_3,
    Symbols.badge.codePoint: CupertinoIcons.person_crop_circle_badge_checkmark,
    Symbols.auto_awesome.codePoint: CupertinoIcons.sparkles,
    Symbols.audio_file.codePoint: CupertinoIcons.music_note,
    Symbols.upload_file.codePoint: CupertinoIcons.cloud_upload,
    Symbols.smartphone.codePoint: CupertinoIcons.device_phone_portrait,
    Symbols.settings_voice.codePoint: CupertinoIcons.waveform,
    Symbols.vpn_lock.codePoint: CupertinoIcons.lock_shield,
    Symbols.verified_user.codePoint: CupertinoIcons.checkmark_shield,
    Symbols.password.codePoint: CupertinoIcons.lock_fill,
    Symbols.devices.codePoint: CupertinoIcons.device_phone_portrait,
    Symbols.graphic_eq.codePoint: CupertinoIcons.waveform,
    Symbols.chat.codePoint: CupertinoIcons.chat_bubble,
    Symbols.flip_camera_android.codePoint: CupertinoIcons.switch_camera,
    Symbols.speed.codePoint: CupertinoIcons.gauge,
    Symbols.crop_rotate.codePoint: CupertinoIcons.crop_rotate,
    Symbols.brush.codePoint: CupertinoIcons.paintbrush,
    Symbols.person_off.codePoint: CupertinoIcons.person_badge_minus,
    Symbols.construction.codePoint: CupertinoIcons.hammer,
    Symbols.filter_alt.codePoint: CupertinoIcons.line_horizontal_3_decrease,
    Symbols.logout.codePoint: CupertinoIcons.square_arrow_right,
    Symbols.dark_mode.codePoint: CupertinoIcons.moon_fill,
    Symbols.wallpaper.codePoint: CupertinoIcons.photo,
    Symbols.text_fields.codePoint: CupertinoIcons.textformat,
    Symbols.apps.codePoint: CupertinoIcons.square_grid_2x2,
    Symbols.security.codePoint: CupertinoIcons.shield,
    Symbols.notifications_active.codePoint: CupertinoIcons.bell_fill,
    Symbols.qr_code_2.codePoint: CupertinoIcons.qrcode,
    Symbols.person_pin.codePoint: CupertinoIcons.person_crop_circle,
    Symbols.create_new_folder.codePoint: CupertinoIcons.folder_badge_plus,
    Symbols.contacts.codePoint: CupertinoIcons.person_2,
    Symbols.folder_open.codePoint: CupertinoIcons.folder_open,
    Symbols.undo.codePoint: CupertinoIcons.arrow_uturn_left,
    Symbols.mail.codePoint: CupertinoIcons.mail,
    Symbols.flash_on.codePoint: CupertinoIcons.bolt_fill,
    Symbols.timer.codePoint: CupertinoIcons.timer,
    Symbols.shield.codePoint: CupertinoIcons.shield_fill,
    Symbols.contact_phone.codePoint: CupertinoIcons.phone,
    Symbols.keyboard_alt.codePoint: CupertinoIcons.keyboard,
    Symbols.wifi_off.codePoint: CupertinoIcons.wifi_slash,
    Symbols.cloud_off.codePoint: CupertinoIcons.cloud,
    Symbols.amp_stories.codePoint: CupertinoIcons.rectangle_stack,
    Symbols.show_chart.codePoint: CupertinoIcons.chart_bar,
    Symbols.smart_toy.codePoint: CupertinoIcons.desktopcomputer,
    Symbols.brightness_auto.codePoint: CupertinoIcons.circle_lefthalf_fill,
    Symbols.light_mode.codePoint: CupertinoIcons.sun_max,
    Symbols.add_a_photo.codePoint: CupertinoIcons.camera,
    Symbols.add_circle_outline.codePoint: CupertinoIcons.plus,
    Symbols.animation.codePoint: CupertinoIcons.circle,
    Symbols.arrow_downward.codePoint: CupertinoIcons.arrow_down,
    Symbols.arrow_right_alt.codePoint: CupertinoIcons.arrow_right,
    Symbols.arrow_split.codePoint: CupertinoIcons.arrow_right,
    Symbols.arrow_upward.codePoint: CupertinoIcons.arrow_up,
    Symbols.article.codePoint: CupertinoIcons.circle,
    Symbols.attach_file.codePoint: CupertinoIcons.paperclip,
    Symbols.autorenew.codePoint: CupertinoIcons.arrow_2_circlepath,
    Symbols.back_hand.codePoint: CupertinoIcons.hand_raised,
    Symbols.bedtime.codePoint: CupertinoIcons.circle,
    Symbols.bluetooth_disabled.codePoint: CupertinoIcons.circle,
    Symbols.blur_circular.codePoint: CupertinoIcons.circle,
    Symbols.blur_linear.codePoint: CupertinoIcons.circle,
    Symbols.blur_on.codePoint: CupertinoIcons.circle,
    Symbols.bubble_chart.codePoint: CupertinoIcons.circle,
    Symbols.bug_report.codePoint: CupertinoIcons.ant,
    Symbols.call_missed.codePoint: CupertinoIcons.phone_down,
    Symbols.camera_alt.codePoint: CupertinoIcons.photo,
    Symbols.camera_front.codePoint: CupertinoIcons.camera,
    Symbols.camera_rear.codePoint: CupertinoIcons.photo,
    Symbols.cell_tower.codePoint: CupertinoIcons.circle,
    Symbols.check_box.codePoint: CupertinoIcons.checkmark_square,
    Symbols.check_box_outline_blank.codePoint: CupertinoIcons.square,
    Symbols.circle.codePoint: CupertinoIcons.circle,
    Symbols.close_fullscreen.codePoint: CupertinoIcons.circle,
    Symbols.cloud.codePoint: CupertinoIcons.cloud,
    Symbols.cloud_done.codePoint: CupertinoIcons.checkmark,
    Symbols.code.codePoint: CupertinoIcons.circle,
    Symbols.contact_page.codePoint: CupertinoIcons.circle,
    Symbols.contrast.codePoint: CupertinoIcons.circle,
    Symbols.delete_history.codePoint: CupertinoIcons.delete,
    Symbols.dialpad.codePoint: CupertinoIcons.circle,
    Symbols.dns.codePoint: CupertinoIcons.cloud,
    Symbols.do_not_disturb_on.codePoint: CupertinoIcons.circle,
    Symbols.do_not_touch.codePoint: CupertinoIcons.hand_raised_slash,
    Symbols.edit_square.codePoint: CupertinoIcons.circle,
    Symbols.emoji_emotions.codePoint: CupertinoIcons.smiley,
    Symbols.encrypted.codePoint: CupertinoIcons.circle,
    Symbols.error.codePoint: CupertinoIcons.exclamationmark_circle,
    Symbols.exit_to_app.codePoint: CupertinoIcons.circle,
    Symbols.extension.codePoint: CupertinoIcons.circle,
    Symbols.face.codePoint: CupertinoIcons.circle,
    Symbols.flash_off.codePoint: CupertinoIcons.circle,
    Symbols.flip.codePoint: CupertinoIcons.circle,
    Symbols.flip_camera_ios.codePoint: CupertinoIcons.photo,
    Symbols.folder_off.codePoint: CupertinoIcons.folder,
    Symbols.folder_zip.codePoint: CupertinoIcons.folder,
    Symbols.format_quote.codePoint: CupertinoIcons.circle,
    Symbols.format_size.codePoint: CupertinoIcons.circle,
    Symbols.forum.codePoint: CupertinoIcons.circle,
    Symbols.fullscreen.codePoint: CupertinoIcons.fullscreen,
    Symbols.gif_box.codePoint: CupertinoIcons.photo,
    Symbols.gpp_bad.codePoint: CupertinoIcons.circle,
    Symbols.gpp_maybe.codePoint: CupertinoIcons.shield,
    Symbols.grid_on.codePoint: CupertinoIcons.circle,
    Symbols.hd.codePoint: CupertinoIcons.circle,
    Symbols.history_edu.codePoint: CupertinoIcons.circle,
    Symbols.how_to_reg.codePoint: CupertinoIcons.person_crop_circle_badge_checkmark,
    Symbols.ink_eraser.codePoint: CupertinoIcons.circle,
    Symbols.ink_highlighter.codePoint: CupertinoIcons.circle,
    Symbols.insert_drive_file.codePoint: CupertinoIcons.circle,
    Symbols.install_mobile.codePoint: CupertinoIcons.circle,
    Symbols.inventory_2.codePoint: CupertinoIcons.circle,
    Symbols.ios_share.codePoint: CupertinoIcons.circle,
    Symbols.key.codePoint: CupertinoIcons.lock_rotation,
    Symbols.keyboard_arrow_up.codePoint: CupertinoIcons.chevron_up,
    Symbols.lan.codePoint: CupertinoIcons.circle,
    Symbols.layers.codePoint: CupertinoIcons.square_stack,
    Symbols.location_city.codePoint: CupertinoIcons.circle,
    Symbols.lock_clock.codePoint: CupertinoIcons.lock,
    Symbols.mark_chat_read.codePoint: CupertinoIcons.circle,
    Symbols.memory.codePoint: CupertinoIcons.cube,
    Symbols.menu.codePoint: CupertinoIcons.circle,
    Symbols.missed_video_call.codePoint: CupertinoIcons.videocam,
    Symbols.mode_comment.codePoint: CupertinoIcons.circle,
    Symbols.mood.codePoint: CupertinoIcons.smiley,
    Symbols.mop.codePoint: CupertinoIcons.trash,
    Symbols.motion_photos_on.codePoint: CupertinoIcons.photo,
    Symbols.music_note.codePoint: CupertinoIcons.circle,
    Symbols.nfc.codePoint: CupertinoIcons.radiowaves_right,
    Symbols.noise_control_on.codePoint: CupertinoIcons.circle,
    Symbols.north_east.codePoint: CupertinoIcons.arrow_up_right,
    Symbols.notifications_off.codePoint: CupertinoIcons.bell_slash,
    Symbols.numbers.codePoint: CupertinoIcons.number,
    Symbols.open_in_full.codePoint: CupertinoIcons.circle,
    Symbols.open_in_new.codePoint: CupertinoIcons.circle,
    Symbols.person_remove.codePoint: CupertinoIcons.person_badge_minus,
    Symbols.picture_as_pdf.codePoint: CupertinoIcons.doc,
    Symbols.priority_high.codePoint: CupertinoIcons.circle,
    Symbols.qr_code_scanner.codePoint: CupertinoIcons.circle,
    Symbols.radar.codePoint: CupertinoIcons.circle,
    Symbols.record_voice_over.codePoint: CupertinoIcons.person_crop_circle,
    Symbols.rectangle.codePoint: CupertinoIcons.circle,
    Symbols.remove_circle.codePoint: CupertinoIcons.delete,
    Symbols.remove_moderator.codePoint: CupertinoIcons.person_badge_minus,
    Symbols.rotate_right.codePoint: CupertinoIcons.circle,
    Symbols.save_alt.codePoint: CupertinoIcons.square_arrow_down,
    Symbols.shield_lock.codePoint: CupertinoIcons.lock,
    Symbols.shield_person.codePoint: CupertinoIcons.shield,
    Symbols.slideshow.codePoint: CupertinoIcons.photo_on_rectangle,
    Symbols.south_west.codePoint: CupertinoIcons.circle,
    Symbols.stadia_controller.codePoint: CupertinoIcons.circle,
    Symbols.star.codePoint: CupertinoIcons.star,
    Symbols.stay_current_portrait.codePoint: CupertinoIcons.circle,
    Symbols.stop_circle.codePoint: CupertinoIcons.stop_circle,
    Symbols.styler.codePoint: CupertinoIcons.circle,
    Symbols.swipe_right.codePoint: CupertinoIcons.circle,
    Symbols.sync.codePoint: CupertinoIcons.arrow_2_circlepath,
    Symbols.system_update.codePoint: CupertinoIcons.circle,
    Symbols.table_chart.codePoint: CupertinoIcons.table,
    Symbols.terminal.codePoint: CupertinoIcons.circle,
    Symbols.text_snippet.codePoint: CupertinoIcons.circle,
    Symbols.touch_app.codePoint: CupertinoIcons.hand_draw,
    Symbols.translate.codePoint: CupertinoIcons.textformat,
    Symbols.unarchive.codePoint: CupertinoIcons.archivebox,
    Symbols.update.codePoint: CupertinoIcons.arrow_2_circlepath,
    Symbols.vibration.codePoint: CupertinoIcons.circle,
    Symbols.video_file.codePoint: CupertinoIcons.videocam,
    Symbols.visibility_lock.codePoint: CupertinoIcons.lock,
    Symbols.voice_over_off.codePoint: CupertinoIcons.mic_off,
    Symbols.vpn_key.codePoint: CupertinoIcons.lock_shield,
    Symbols.vpn_key_off.codePoint: CupertinoIcons.circle,
    Symbols.water_drop.codePoint: CupertinoIcons.circle,
    Symbols.wb_sunny.codePoint: CupertinoIcons.circle,
  };
}
