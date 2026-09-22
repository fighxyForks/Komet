import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
  });

  tearDown(AppIosGlass.debugReset);

  group('Определение поддержки', () {
    test('вне iOS 26 интерфейс недоступен и выключен', () async {
      final active = await AppIosGlass.load();
      expect(AppIosGlass.supported, isFalse);
      expect(active, isFalse);
      expect(AppIosGlass.active.value, isFalse);
      expect(AppIosGlass.nativeViews, isFalse);
    });

    test('на поддерживаемом устройстве включается по умолчанию', () async {
      await AppIosGlass.load();
      AppIosGlass.debugSetSupported(true);
      expect(AppIosGlass.enabled.value, isTrue);
      expect(AppIosGlass.active.value, isTrue);
    });
  });

  group('Тумблер', () {
    test('сохранённое выключение уважается при загрузке', () async {
      SharedPreferences.setMockInitialValues({AppIosGlass.prefKey: false});
      await AppIosGlass.load();
      AppIosGlass.debugSetSupported(true);
      expect(AppIosGlass.enabled.value, isFalse);
      expect(AppIosGlass.active.value, isFalse);
    });

    test('переключение сразу меняет active и пишется в prefs', () async {
      await AppIosGlass.load();
      AppIosGlass.debugSetSupported(true);
      await AppIosGlass.save(false);
      expect(AppIosGlass.active.value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppIosGlass.prefKey), isFalse);
      await AppIosGlass.save(true);
      expect(AppIosGlass.active.value, isTrue);
    });

    test('без поддержки включённый тумблер ничего не активирует', () async {
      await AppIosGlass.load();
      await AppIosGlass.save(true);
      expect(AppIosGlass.active.value, isFalse);
    });
  });
}
