import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/calls/call_controller.dart';
import '../../core/native/native_tab_chrome_bridge.dart';
import '../widgets/glass/ios_glass.dart';
import '../widgets/glass/ios_native_tab_bar.dart';
import '../widgets/sliding_pill_nav.dart';

class NativeTabChromeHost extends StatefulWidget {
  final List<PillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;
  final VoidCallback? onCallAccessoryTap;

  const NativeTabChromeHost({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.height,
    this.onCallAccessoryTap,
  });

  @override
  State<NativeTabChromeHost> createState() => _NativeTabChromeHostState();
}

class _NativeTabChromeHostState extends State<NativeTabChromeHost> {
  static const _channel = MethodChannel('ru.komet.app/native_tab_chrome_events');

  StreamSubscription<void>? _endedSub;
  StreamSubscription<IncomingCall>? _incomingSub;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_onNative);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCall());
    _endedSub = CallController.instance.callEnded.listen((_) => _syncCall());
    _incomingSub =
        CallController.instance.incomingCalls.listen((_) => _syncCall());
  }

  @override
  void dispose() {
    unawaited(_endedSub?.cancel());
    unawaited(_incomingSub?.cancel());
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didUpdateWidget(NativeTabChromeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      NativeTabChromeBridge.setSelectedIndex(widget.currentIndex);
    }
  }

  Future<void> _onNative(MethodCall call) async {
    if (call.method == 'accessoryTap') {
      widget.onCallAccessoryTap?.call();
    } else if (call.method == 'tabSelected') {
      final index = (call.arguments as Map?)?['index'] as int?;
      if (index != null) widget.onTap(index);
    }
  }

  void _syncCall() {
    final busy = CallController.instance.isBusy;
    final title = busy ? 'Вернуться к звонку' : null;
    NativeTabChromeBridge.setCallAccessory(visible: busy, title: title);
  }

  @override
  Widget build(BuildContext context) {
    if (!NativeTabChromeBridge.isEligibleWithContext(context) ||
        kIsWeb ||
        !Platform.isIOS) {
      if (IosGlass.of(context)) {
        return IosNativeTabBar(
          items: widget.items,
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
        );
      }
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: UiKitView(
        viewType: NativeTabChromeBridge.viewType,
        creationParams: <String, Object?>{
          'index': widget.currentIndex,
          'callVisible': CallController.instance.isBusy,
          'callTitle': 'Вернуться к звонку',
        },
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),
    );
  }
}

class NativeTabScrollBinder extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const NativeTabScrollBinder({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!NativeTabChromeBridge.isEligibleWithContext(context)) {
      return child;
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final dy = notification.scrollDelta ?? 0;
          NativeTabChromeBridge.onScrollDelta(dy);
        }
        return false;
      },
      child: child,
    );
  }
}
