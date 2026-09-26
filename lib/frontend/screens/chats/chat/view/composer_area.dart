import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:komet/backend/modules/messages.dart'
    show CachedMessage, FileHistoryEntry;
import 'package:komet/frontend/commands/commands.dart' show SlashCommand;
import 'package:komet/core/config/app_chat_chrome.dart';
import 'package:komet/core/config/app_composer_background.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/config/app_composer_style.dart';
import 'package:komet/core/config/app_frost.dart';
import 'package:komet/core/media/clipboard/clipboard_media.dart';
import 'package:komet/models/animoji.dart' show Animoji;
import 'package:komet/models/sticker.dart' show StickerItem;
import 'package:komet/frontend/screens/chats/chat/sticker_panel_controller.dart';
import 'package:komet/frontend/screens/chats/chat/upload_status.dart'
    show UploadStatus;
import 'package:komet/frontend/screens/chats/chat/video_note_controller.dart';
import 'package:komet/frontend/screens/chats/chat/voice_record_controller.dart';
import 'package:komet/frontend/native/native_chat_composer_view.dart';
import 'package:komet/frontend/widgets/attachment_panel.dart';
import 'package:komet/frontend/widgets/e2ee_banner.dart';
import 'package:komet/core/utils/text_format.dart';
import 'package:komet/frontend/widgets/rich_message_controller.dart';
import 'package:komet/l10n/app_localizations.dart';

import 'command_arguments_form.dart';
import 'composer_input.dart';
import 'frosted_panel.dart';
import 'selection_bar.dart';
import 'sticker_panel_view.dart';

class ComposerArea extends StatelessWidget {
  final Animation<double> selectionAnim;
  final Animation<double> searchAnim;
  final Animation<double> attachAnim;
  final StickerPanelController stickers;

  final SlashCommand? selectedCommand;
  final Map<String, TextEditingController> commandArgumentControllers;
  final Map<String, FocusNode> commandArgumentFocusNodes;
  final VoidCallback onCancelSelectedCommand;
  final VoidCallback onSendMessage;

  final ValueNotifier<bool> showAttachmentPanel;
  final VoidCallback onPickFile;
  final Future<bool> Function(int fileId) onSendFileById;

  final bool commentsMode;
  final String chatType;
  final int chatId;
  final String peerName;
  final VoidCallback onOpenEncryption;
  final ChatChromeStyle chrome;
  final bool chromeVignette;
  final BackdropKey? pillBackdrop;
  final BackdropKey? barBackdrop;
  final ValueListenable<CachedMessage?> replyTo;
  final ValueListenable<List<CachedMessage>> forwardMessages;
  final int myId;
  final ValueListenable<bool> hasText;
  final ValueListenable<UploadStatus> uploadStatus;
  final RichMessageController messageController;
  final FocusNode messageFocusNode;
  final VoiceRecordController voiceRec;
  final VideoNoteController note;
  final VoidCallback onToggleStickerPanel;
  final VoidCallback onScheduleMessage;
  final VoidCallback onOpenAttach;
  final VoidCallback onOpenAttachScheduled;
  final Future<void> Function(FileHistoryEntry entry) onSendHistory;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelForward;
  final bool crossChatReplySupported;
  final Future<void> Function() onPickReplyChat;
  final String Function(int ms) formatElapsed;
  final Widget Function(
    RichMessageController controller,
    BuildContext context,
    EditableTextState editableState, {
    ContextMenuButtonItem? pasteItem,
  })
  formatContextMenu;
  final ContextMenuButtonItem? Function(
    BuildContext context,
    EditableTextState editableState,
  )
  pasteMenuItem;
  final Future<bool> Function()? onPasteMedia;
  final Future<void> Function(KeyboardInsertedContent content) onInsertContent;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final bool channelSubscribed;
  final bool channelSubscribing;
  final bool canPostToChannel;
  final VoidCallback onSubscribe;
  final VoidCallback? onOpenSearch;

  final void Function(StickerItem sticker) onStickerTap;
  final void Function(Animoji animoji) onEmojiTap;
  final void Function(String emoji)? onPlainEmojiTap;

  final ValueListenable<Set<String>> selectedIds;
  final VoidCallback onReplySelected;
  final VoidCallback onForwardSelected;
  final bool forwardDisabled;
  final bool replyDisabled;

  final bool useNativeComposer;
  final bool composerFrosted;
  final ValueListenable<bool>? scrollOpaque;

  const ComposerArea({
    super.key,
    required this.selectionAnim,
    required this.searchAnim,
    required this.attachAnim,
    required this.stickers,
    required this.selectedCommand,
    required this.commandArgumentControllers,
    required this.commandArgumentFocusNodes,
    required this.onCancelSelectedCommand,
    required this.onSendMessage,
    required this.showAttachmentPanel,
    required this.onPickFile,
    required this.onSendFileById,
    required this.commentsMode,
    required this.chatType,
    required this.chatId,
    required this.peerName,
    required this.onOpenEncryption,
    required this.chrome,
    required this.chromeVignette,
    required this.pillBackdrop,
    required this.barBackdrop,
    required this.replyTo,
    required this.forwardMessages,
    required this.myId,
    required this.hasText,
    required this.uploadStatus,
    required this.messageController,
    required this.messageFocusNode,
    required this.voiceRec,
    required this.note,
    required this.onToggleStickerPanel,
    required this.onScheduleMessage,
    required this.onOpenAttach,
    required this.onOpenAttachScheduled,
    required this.onSendHistory,
    required this.onCancelReply,
    required this.onCancelForward,
    required this.crossChatReplySupported,
    required this.onPickReplyChat,
    required this.formatElapsed,
    required this.formatContextMenu,
    required this.pasteMenuItem,
    required this.onPasteMedia,
    required this.onInsertContent,
    required this.isMuted,
    required this.onToggleMute,
    required this.channelSubscribed,
    required this.channelSubscribing,
    this.canPostToChannel = false,
    required this.onSubscribe,
    this.onOpenSearch,
    required this.onStickerTap,
    required this.onEmojiTap,
    this.onPlainEmojiTap,
    required this.selectedIds,
    required this.onReplySelected,
    required this.onForwardSelected,
    required this.forwardDisabled,
    this.replyDisabled = false,
    this.useNativeComposer = false,
    required this.composerFrosted,
    this.scrollOpaque,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (chatType == 'DIALOG' && myId != 0)
          E2eeBanner(
            accountId: myId,
            chatId: chatId,
            peerName: peerName,
            onOpenDetails: onOpenEncryption,
          ),
        AnimatedBuilder(
          animation: selectionAnim,
          builder: (context, child) {
            final t = Curves.easeOut.transform(
              selectionAnim.value.clamp(0.0, 1.0),
            );
            if (t == 0) return child!;
            if (t == 1) return const SizedBox.shrink();
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1 - t,
                child: Transform.translate(
                  offset: Offset(0, 48 * t),
                  child: Opacity(opacity: 1 - t, child: child),
                ),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedCommand != null)
                CommandArgumentsForm(
                  key: ValueKey(selectedCommand!.name),
                  command: selectedCommand!,
                  controllers: commandArgumentControllers,
                  focusNodes: commandArgumentFocusNodes,
                  onCancel: onCancelSelectedCommand,
                  onSubmit: onSendMessage,
                ),
              AnimatedBuilder(
                animation: attachAnim,
                builder: (context, _) {
                  if (attachAnim.value == 0) {
                    return const SizedBox.shrink();
                  }
                  final curve = attachAnim.status == AnimationStatus.reverse
                      ? Curves.easeIn
                      : Curves.easeOut;
                  final t = curve.transform(attachAnim.value);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: t,
                        child: Opacity(
                          opacity: t,
                          child: AttachmentPanel(
                            onClose: () => showAttachmentPanel.value = false,
                            onPickFile: onPickFile,
                            onSendById: onSendFileById,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: stickers.anim,
                builder: (context, _) {
                  Widget bar({required bool opaque}) => useNativeComposer &&
                          selectedCommand == null
                      ? ListenableBuilder(
                          listenable: Listenable.merge([
                            replyTo,
                            voiceRec.isRecording,
                            voiceRec.locked,
                            voiceRec.elapsedMs,
                            note.videoNoteMode,
                            note.isRecording,
                            note.locked,
                            note.elapsedMs,
                          ]),
                          builder: (context, _) {
                            final reply = replyTo.value?.text?.trim();
                            final videoRecording = note.isRecording.value;
                            final voiceRecording = voiceRec.isRecording.value;
                            final recording = videoRecording || voiceRecording;
                            final locked = videoRecording
                                ? note.locked.value
                                : voiceRec.locked.value;
                            final elapsed = videoRecording
                                ? note.elapsedMs.value
                                : voiceRec.elapsedMs.value;
                            final status = !recording
                                ? ''
                                : videoRecording
                                ? (locked
                                      ? 'Кружок зафиксирован'
                                      : 'Кружок · ${formatElapsed(elapsed)}')
                                : (locked
                                      ? 'Запись ${formatElapsed(elapsed)}'
                                      : 'Влево — отмена · ${formatElapsed(elapsed)}');
                            return NativeChatComposerView(
                              text: messageController,
                              reply: reply == null || reply.isEmpty
                                  ? ''
                                  : reply,
                              status: status,
                              recording: recording,
                              videoMode: note.videoNoteMode.value,
                              locked: locked,
                              onSend: onSendMessage,
                              onAttach: onOpenAttach,
                              onStickers: onToggleStickerPanel,
                              onToggleVideo: () => unawaited(note.toggleMode()),
                              onRecordStart: () {
                                if (note.videoNoteMode.value) {
                                  unawaited(note.start());
                                } else {
                                  unawaited(voiceRec.start());
                                }
                              },
                              onRecordDrag: (video, offset) {
                                if (video) {
                                  note.handleDrag(offset);
                                } else {
                                  voiceRec.handleDrag(offset);
                                }
                              },
                              onRecordEnd: (video) {
                                if (video) {
                                  note.handleEnd();
                                } else {
                                  voiceRec.handleEnd();
                                }
                              },
                              onSchedule: onScheduleMessage,
                              onFormat: () => unawaited(
                                _showComposerFormats(
                                  context,
                                  messageController,
                                ),
                              ),
                              onReplyCancel: onCancelReply,
                            );
                          },
                        )
                      : ComposerInputBar(
                    bottomSafe: stickers.anim.value == 0,
                    chatType: commentsMode ? 'CHAT' : chatType,
                    chrome: chrome,
                    vignette: chromeVignette,
                    style: ComposerChrome.effective,
                    background: ComposerMaterial.effective,
                    iosGlass: AppIosGlass.active.value,
                    forceOpaqueChrome: opaque,
                    backdropKey: pillBackdrop,
                    attachAnim: attachAnim,
                    replyTo: replyTo,
                    forwardMessages: forwardMessages,
                    myId: myId,
                    hasText: hasText,
                    uploadStatus: uploadStatus,
                    messageController: messageController,
                    messageFocusNode: messageFocusNode,
                    voiceRec: voiceRec,
                    note: note,
                    onToggleStickerPanel: onToggleStickerPanel,
                    onSendText: onSendMessage,
                    onScheduleMessage: onScheduleMessage,
                    onOpenAttach: onOpenAttach,
                    onOpenAttachScheduled: onOpenAttachScheduled,
                    onSendHistory: onSendHistory,
                    onCancelReply: onCancelReply,
                    onCancelForward: onCancelForward,
                    onPickReplyChat: commentsMode || !crossChatReplySupported
                        ? null
                        : () => unawaited(onPickReplyChat()),
                    formatElapsed: formatElapsed,
                    contextMenuBuilder: (ctx, state) => formatContextMenu(
                      messageController,
                      ctx,
                      state,
                      pasteItem: pasteMenuItem(ctx, state),
                    ),
                    onPasteMedia: ClipboardMedia.supported
                        ? onPasteMedia
                        : null,
                    onInsertContent: onInsertContent,
                    isMuted: isMuted,
                    onToggleMute: onToggleMute,
                    channelSubscribed: channelSubscribed,
                    canPostToChannel: canPostToChannel,
                    channelSubscribing: channelSubscribing,
                    onSubscribe: onSubscribe,
                    onOpenSearch: onOpenSearch,
                    showStickerButton: !commentsMode && selectedCommand == null,
                    showAttachButton: !commentsMode && selectedCommand == null,
                    forceSend: commentsMode || selectedCommand != null,
                    readOnly: selectedCommand != null,
                    hintText: selectedCommand != null
                        ? AppLocalizations.of(context)!.composerHintCommandArgs
                        : commentsMode
                        ? AppLocalizations.of(context)!.composerHintComment
                        : null,
                  );
                  final listen = scrollOpaque;
                  if (listen == null) return bar(opaque: false);
                  return ValueListenableBuilder<bool>(
                    valueListenable: listen,
                    builder: (context, opaque, _) => bar(opaque: opaque),
                  );
                },
              ),
              StickerPanelView(
                stickers: stickers,
                onStickerTap: onStickerTap,
                onEmojiTap: onEmojiTap,
                onPlainEmojiTap: onPlainEmojiTap,
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: selectionAnim,
          builder: (context, child) {
            final t = Curves.easeOut.transform(
              selectionAnim.value.clamp(0.0, 1.0),
            );
            if (t == 0) return const SizedBox.shrink();
            return ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: t,
                child: Opacity(opacity: t, child: child),
              ),
            );
          },
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: selectedIds,
            builder: (context, selected, _) => SelectionBottomBar(
              cs: cs,
              selected: selected,
              onReply: onReplySelected,
              onForward: onForwardSelected,
              allowForward: !forwardDisabled,
              allowReply: !replyDisabled,
            ),
          ),
        ),
      ],
    );
    Widget wrapChrome(Widget child) {
      if (composerFrosted) {
        if (ComposerChrome.isGlossy(ComposerChrome.effective)) {
          return child;
        }
        return FrostedPanel(
          sigma: AppFrost.sigma,
          tint: AppFrost.glassTint(cs),
          border: Border(top: AppFrost.hairline(cs)),
          backdropKey: barBackdrop,
          child: child,
        );
      }
      if (chrome != ChatChromeStyle.blur) return child;
      return FrostedPanel(
        tint: AppFrost.blurPanelTint(cs),
        border: Border(top: AppFrost.hairline(cs)),
        backdropKey: barBackdrop,
        child: child,
      );
    }

    final base = TextFieldTapRegion(child: wrapChrome(content));
    return AnimatedBuilder(
      animation: searchAnim,
      builder: (context, _) {
        final s = Curves.easeOut.transform(searchAnim.value.clamp(0.0, 1.0));
        if (s == 0) return base;
        if (s >= 1) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1 - s,
            child: Opacity(
              opacity: 1 - s,
              child: IgnorePointer(child: base),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showComposerFormats(
  BuildContext context,
  RichMessageController controller,
) async {
  final selection = controller.selection;
  if (!selection.isValid || selection.isCollapsed) return;
  final picked = await showCupertinoModalPopup<TextFormat>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: const Text('Формат'),
      actions: [
        for (final format in composerFormats)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(format),
            child: Text(
              controller.isFormatActive(format)
                  ? '✓ ${_composerFormatName(format)}'
                  : _composerFormatName(format),
            ),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: const Text('Отмена'),
      ),
    ),
  );
  if (picked != null) controller.toggleFormat(picked);
}

String _composerFormatName(TextFormat format) {
  return switch (format) {
    TextFormat.strong => 'Жирный',
    TextFormat.emphasized => 'Курсив',
    TextFormat.underline => 'Подчёркнутый',
    TextFormat.strikethrough => 'Зачёркнутый',
    TextFormat.quote => 'Цитата',
    TextFormat.heading => 'Заголовок',
    TextFormat.monospaced => 'Моноширинный',
    TextFormat.link => 'Ссылка',
    TextFormat.animoji => 'Animoji',
    TextFormat.userMention => 'Упоминание',
  };
}
