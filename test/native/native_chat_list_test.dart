import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/config/app_native_chat_list_prototype.dart';
import 'package:komet/core/native/native_chat_list_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _alpha = NativeChatRow(
  id: 1,
  title: 'Альфа',
  time: '09:00',
  text: 'привет',
);
const _beta = NativeChatRow(id: 2, title: 'Бета', unread: 3, muted: true);
const _gamma = NativeChatRow(id: 3, title: 'Гамма', pinned: true);

NativeChatListCallbacks _callbacks(List<Object> log) => NativeChatListCallbacks(
  onOpen: (id) => log.add('open $id'),
  onAction: (id, action) => log.add('${action.name} $id'),
  onCompose: (rect) => log.add('compose $rect'),
  onMenu: (rect) => log.add('menu $rect'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    AppNativeChatListPrototype.debugReset();
    NativeChatListBridge.debugReset();
  });

  tearDown(() {
    AppIosGlass.debugReset();
    AppNativeChatListPrototype.debugReset();
    NativeChatListBridge.debugReset();
  });

  group('разница строк', () {
    test('без изменений ничего не отправляется', () {
      final update = NativeChatListUpdate.between(
        const [_alpha, _beta],
        const [_alpha, _beta],
      );
      expect(update.isEmpty, isTrue);
    });

    test('изменённая строка уходит без порядка', () {
      const changed = NativeChatRow(
        id: 2,
        title: 'Бета',
        unread: 4,
        muted: true,
      );
      final update = NativeChatListUpdate.between(
        const [_alpha, _beta],
        const [_alpha, changed],
      );
      expect(update.order, isNull);
      expect(update.rows, [changed]);
    });

    test('перестановка отправляет только порядок', () {
      final update = NativeChatListUpdate.between(
        const [_alpha, _beta],
        const [_beta, _alpha],
      );
      expect(update.order, [2, 1]);
      expect(update.rows, isEmpty);
    });

    test('новая строка приходит вместе с порядком', () {
      final update = NativeChatListUpdate.between(
        const [_alpha],
        const [_gamma, _alpha],
      );
      expect(update.order, [3, 1]);
      expect(update.rows, [_gamma]);
    });

    test('удаление меняет только порядок', () {
      final update = NativeChatListUpdate.between(
        const [_alpha, _beta],
        const [_alpha],
      );
      expect(update.order, [1]);
      expect(update.rows, isEmpty);
    });

    test('строка сериализуется для Swift', () {
      const row = NativeChatRow(
        id: 7,
        title: 'Чат',
        status: NativeChatStatus.read,
        mediaKind: 'photo',
        draft: 'набросок',
      );
      expect(row.toMap(), containsPair('status', 'read'));
      expect(row.toMap(), containsPair('mediaKind', 'photo'));
      expect(row.toMap(), containsPair('draft', 'набросок'));
    });
  });

  group('контроллер канала', () {
    const channelName = '${NativeChatListBridge.viewType}/5';

    test('отправляет только разницу', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
        call,
      ) async {
        calls.add(call);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel(channelName),
          null,
        ),
      );
      final controller = NativeChatListController(5, _callbacks([]))
        ..seed(const [_alpha, _beta]);
      addTearDown(controller.dispose);

      await controller.update(const [_alpha, _beta]);
      expect(calls, isEmpty);

      await controller.update(const [_beta, _alpha, _gamma]);
      expect(calls.single.method, 'apply');
      final args = calls.single.arguments as Map;
      expect(args['order'], [2, 1, 3]);
      expect((args['rows'] as List).single, _gamma.toMap());
    });

    test('события из Swift доходят до обработчиков', () async {
      final log = <Object>[];
      final controller = NativeChatListController(5, _callbacks(log));
      addTearDown(controller.dispose);
      const codec = StandardMethodCodec();

      Future<void> send(String method, Map<String, Object?> args) =>
          messenger.handlePlatformMessage(
            channelName,
            codec.encodeMethodCall(MethodCall(method, args)),
            (_) {},
          );

      await send('open', {'id': 42});
      await send('action', {'id': 42, 'action': 'pin'});
      await send('action', {'id': 42, 'action': 'unknown'});
      await send('compose', {'x': 1, 'y': 2, 'width': 3, 'height': 4});
      expect(log, [
        'open 42',
        'pin 42',
        'compose ${const Rect.fromLTWH(1, 2, 3, 4)}',
      ]);
    });
  });

  group('доступность', () {
    test('нужны флаг и iOS-стиль', () async {
      NativeChatListBridge.debugAvailable = true;
      expect(NativeChatListBridge.isEligible, isFalse);

      await AppNativeChatListPrototype.save(true);
      expect(NativeChatListBridge.isEligible, isFalse);

      AppIosGlass.debugSetSupported(true);
      expect(AppIosGlass.active.value, isTrue);
      expect(NativeChatListBridge.isEligible, isTrue);
    });

    test('вне iOS прототип выключен', () async {
      NativeChatListBridge.debugAvailable = false;
      await AppNativeChatListPrototype.save(true);
      AppIosGlass.debugSetSupported(true);
      expect(NativeChatListBridge.isEligible, isFalse);
    });

    test('флаг по умолчанию выключен', () {
      expect(AppNativeChatListPrototype.enabled.value, isFalse);
    });
  });
}
