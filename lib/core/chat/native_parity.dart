import '../../backend/modules/messages.dart';
import '../../models/attachment.dart';
import '../crypto/chat_crypto_service.dart';
import '../crypto/e2ee_service.dart';
import '../crypto/message_decryption_cache.dart';

const nativeDecryptingLabel = 'Расшифровка…';
const nativeWrongKeyLabel = 'неверный ключ';
const nativeUnavailableLabel = 'недоступно на этом устройстве';

class NativeVisibleText {
  final String text;
  final bool hideFormats;

  const NativeVisibleText(this.text, {this.hideFormats = false});
}

NativeVisibleText nativeVisibleText({
  required int accountId,
  required int chatId,
  required String? messageId,
  required String? stored,
}) {
  final raw = stored ?? '';
  final current = messageId == null || messageId.isEmpty
      ? null
      : MessageDecryptionCache.instance.peek(messageId);
  if (current != null) {
    switch (current.state) {
    case MessageDecryptionState.decrypted:
      return NativeVisibleText(current.plaintext ?? '', hideFormats: true);
    case MessageDecryptionState.wrongKey:
      return const NativeVisibleText(nativeWrongKeyLabel, hideFormats: true);
    case MessageDecryptionState.unavailable:
      return const NativeVisibleText(
        nativeUnavailableLabel,
        hideFormats: true,
      );
    }
  }
  final active =
      E2eeService.instance.isOn(accountId, chatId) ||
      ChatCryptoService.instance.isEnabled(accountId, chatId);
  if (!active || raw.isEmpty || messageId == null || messageId.isEmpty) {
    return NativeVisibleText(raw);
  }
  MessageDecryptionCache.instance.request(
    accountId: accountId,
    chatId: chatId,
    messageId: messageId,
    cipherText: raw,
  );
  if (ChatCryptoService.instance.looksEncrypted(raw)) {
    return const NativeVisibleText(nativeDecryptingLabel, hideFormats: true);
  }
  return NativeVisibleText(raw);
}

({int chatId, String messageId}) nativePollTarget(CachedMessage message) {
  final forwarded = message.forwardedAttachment;
  final original =
      forwarded?.originalAttachments ?? const <MessageAttachment>[];
  for (final attachment in original) {
    if (attachment is PollAttachment) {
      return (
        chatId: forwarded?.originalChatId ?? message.chatId,
        messageId: forwarded?.originalMessageId ?? message.id,
      );
    }
  }
  return (chatId: message.chatId, messageId: message.id);
}

List<MessageAttachment> nativeVisualAttachments(CachedMessage message) {
  final forwarded = message.forwardedAttachment?.originalAttachments;
  final source = forwarded != null && forwarded.isNotEmpty
      ? forwarded
      : message.attachments ?? const <MessageAttachment>[];
  return [
    for (final attachment in source)
      if (attachment is PhotoAttachment ||
          (attachment is VideoAttachment && !attachment.isNote))
        attachment,
  ];
}

VideoAttachment? nativeSelectedVideo(CachedMessage message, int visualIndex) {
  final visuals = nativeVisualAttachments(message);
  if (visualIndex >= 0 &&
      visualIndex < visuals.length &&
      visuals[visualIndex] is VideoAttachment) {
    return visuals[visualIndex] as VideoAttachment;
  }
  for (final attachment in visuals) {
    if (attachment is VideoAttachment) return attachment;
  }
  return null;
}

({int chatId, String messageId}) nativeMediaTarget(
  CachedMessage message,
  MessageAttachment attachment,
) {
  final forwarded = message.forwardedAttachment;
  final original = forwarded?.originalAttachments;
  if (original != null && original.contains(attachment)) {
    return (
      chatId: forwarded?.originalChatId ?? message.chatId,
      messageId: forwarded?.originalMessageId ?? message.id,
    );
  }
  return (chatId: message.chatId, messageId: message.id);
}
