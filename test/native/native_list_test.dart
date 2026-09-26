import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/native/native_list_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _anna = NativeListRow(id: 'contact:1', title: 'Анна');
const _boris = NativeListRow(id: 'contact:2', title: 'Борис');
const _create = NativeListRow(
  id: 'action:create',
  title: 'Создать звонок',
  style: NativeListRowStyle.action,
  symbol: 'link',
);

List<NativeListSection> _sections(Map<String, List<NativeListRow>> groups) => [
  for (final entry in groups.entries)
    NativeListSection(id: entry.key, title: entry.key, rows: entry.value),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    NativeListBridge.debugReset();
  });

  tearDown(() {
    AppIosGlass.debugReset();
    NativeListBridge.debugReset();
  });

  group('разница секций', () {
    test('без изменений ничего не отправляется', () {
      final sections = _sections({
        'А': [_anna],
        'Б': [_boris],
      });
      expect(NativeListUpdate.between(sections, sections).isEmpty, isTrue);
    });

    test('изменённая строка уходит без раскладки', () {
      const renamed = NativeListRow(id: 'contact:2', title: 'Борис Б.');
      final update = NativeListUpdate.between(
        _sections({
          'Б': [_boris],
        }),
        _sections({
          'Б': [renamed],
        }),
      );
      expect(update.sections, isNull);
      expect(update.rows, [renamed]);
    });

    test('новая секция приходит вместе с раскладкой', () {
      final update = NativeListUpdate.between(
        _sections({
          'Б': [_boris],
        }),
        _sections({
          'А': [_anna],
          'Б': [_boris],
        }),
      );
      expect(update.sections, [
        {
          'id': 'А',
          'title': 'А',
          'rows': ['contact:1'],
        },
        {
          'id': 'Б',
          'title': 'Б',
          'rows': ['contact:2'],
        },
      ]);
      expect(update.rows, [_anna]);
    });

    test('меню строки участвует в сравнении', () {
      const plain = NativeListRow(id: 'call:1', title: 'Звонок');
      const withMenu = NativeListRow(
        id: 'call:1',
        title: 'Звонок',
        menu: [
          NativeListAction(id: 'delete', title: 'Удалить', symbol: 'trash'),
        ],
      );
      expect(plain == withMenu, isFalse);
      expect(
        withMenu,
        const NativeListRow(
          id: 'call:1',
          title: 'Звонок',
          menu: [
            NativeListAction(id: 'delete', title: 'Удалить', symbol: 'trash'),
          ],
        ),
      );
    });

    test('строка действия сериализуется со стилем', () {
      expect(_create.toMap(), containsPair('style', 'action'));
      expect(_create.toMap(), containsPair('symbol', 'link'));
    });
  });

  group('контроллер канала', () {
    const channelName = '${NativeListBridge.viewType}/9';

    test('события из Swift доходят до обработчиков', () async {
      final log = <String>[];
      final controller = NativeListController(
        9,
        NativeListCallbacks(
          onTap: (id) => log.add('tap $id'),
          onMenu: (id, action) => log.add('menu $id $action'),
          onButton: (id, rect) => log.add('button $id ${rect.width}'),
          onSegment: (index) => log.add('segment $index'),
        ),
      );
      addTearDown(controller.dispose);
      const codec = StandardMethodCodec();

      Future<void> send(String method, Map<String, Object?> args) =>
          messenger.handlePlatformMessage(
            channelName,
            codec.encodeMethodCall(MethodCall(method, args)),
            (_) {},
          );

      await send('tap', {'id': 'action:create'});
      await send('menu', {'id': 'call:1', 'action': 'delete'});
      await send('button', {'id': 'find', 'width': 44});
      await send('segment', {'index': 1});
      expect(log, [
        'tap action:create',
        'menu call:1 delete',
        'button find 44.0',
        'segment 1',
      ]);
    });

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
      final initial = _sections({
        'А': [_anna],
      });
      final controller = NativeListController(
        9,
        NativeListCallbacks(onTap: (_) {}),
      )..seed(initial);
      addTearDown(controller.dispose);

      await controller.update(initial);
      expect(calls, isEmpty);

      await controller.update(
        _sections({
          'А': [_anna],
          'Б': [_boris],
        }),
      );
      expect(calls.single.method, 'apply');
      final args = calls.single.arguments as Map;
      expect((args['rows'] as List).single, _boris.toMap());
      expect((args['sections'] as List).length, 2);
    });
  });

  group('доступность', () {
    test('нужен iOS-стиль', () {
      NativeListBridge.debugAvailable = true;
      expect(NativeListBridge.isEligible, isFalse);
      AppIosGlass.debugSetSupported(true);
      expect(NativeListBridge.isEligible, isTrue);
    });

    test('вне iOS списки выключены', () {
      NativeListBridge.debugAvailable = false;
      AppIosGlass.debugSetSupported(true);
      expect(NativeListBridge.isEligible, isFalse);
    });
  });
}
