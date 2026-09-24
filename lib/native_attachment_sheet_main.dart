import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
void nativeAttachmentSheetMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _NativeAttachmentSheetApp());
}

class _NativeAttachmentSheetApp extends StatelessWidget {
  const _NativeAttachmentSheetApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const _NativeAttachmentSheetHost(),
    );
  }
}

class _NativeAttachmentSheetHost extends StatefulWidget {
  const _NativeAttachmentSheetHost();

  @override
  State<_NativeAttachmentSheetHost> createState() =>
      _NativeAttachmentSheetHostState();
}

class _NativeAttachmentSheetHostState extends State<_NativeAttachmentSheetHost> {
  static const _channel = MethodChannel('ru.komet.app/native_sheet_content');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHigh,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Нативный sheet (прототип)',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'UISheetPresentationController с medium/large detent. '
                'Полный вложенный AttachmentSheet на втором engine — '
                'следующий шаг; сейчас подтверждается оболочка и каналы.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: () {
                  unawaited(
                    _channel.invokeMethod<void>('requestDismiss', {
                      'result': 'done',
                    }),
                  );
                },
                child: const Text('Закрыть'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
