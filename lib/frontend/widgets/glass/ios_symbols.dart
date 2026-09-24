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
}
