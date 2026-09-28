// #***! комментарии в канале: сервер присылает в options чата флаг COMMENTS.
// #***! В options храним только включённые флаги, поэтому явное «выключено»
// #***! помечаем отдельной меткой, чтобы отличать его от отсутствия данных.
const String kCommentsOption = 'COMMENTS';
const String kCommentsOffOption = '-COMMENTS';

/// Adds the comments-off marker when the server sent `COMMENTS: false`.
Set<String> withCommentsMarker(Set<String> options, Map<dynamic, dynamic> raw) {
  if (raw[kCommentsOption] != false) return options;
  return {...options, kCommentsOffOption};
}

/// Whether a channel post shows the comments button.
///
/// Shown when the channel has comments on. Hidden only when the server
/// explicitly reported them off; with no data (older cache, options not
/// sent) the button stays so channels with working comments do not lose it.
bool showsCommentsButton({
  required bool isChannelPost,
  required Set<String> chatOptions,
}) {
  if (!isChannelPost) return false;
  if (chatOptions.contains(kCommentsOption)) return true;
  return !chatOptions.contains(kCommentsOffOption);
}
