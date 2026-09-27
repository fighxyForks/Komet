import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/chat/chat_ui_state.dart';

void main() {
  test('срез композера не будит список', () {
    var state = const ChatUiState(composerHeight: 40, highlightId: 'a');
    final composer = ChatUiSelector((item) => item.composerHeight, state);
    final list = ChatUiSelector(
      (item) => (item.highlightId, item.selection.length),
      state,
    );
    var composerBuilds = 0;
    var listBuilds = 0;
    composer.addListener(() => composerBuilds++);
    list.addListener(() => listBuilds++);

    state = state.copyWith(composerHeight: 80);
    composer.apply(state);
    list.apply(state);
    expect(composerBuilds, 1);
    expect(listBuilds, 0);

    state = state.copyWith(highlightId: 'b');
    composer.apply(state);
    list.apply(state);
    expect(composerBuilds, 1);
    expect(listBuilds, 1);
  });

  test('выделение не меняет высоту композера', () {
    var state = const ChatUiState();
    final composer = ChatUiSelector((item) => item.composerHeight, state);
    var builds = 0;
    composer.addListener(() => builds++);
    state = state.copyWith(selection: {'m'});
    composer.apply(state);
    expect(builds, 0);
  });
}
