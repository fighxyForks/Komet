import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/api.dart';
import 'package:komet/frontend/screens/auth/session_stale_recovery.dart';

class _Probe extends StatefulWidget {
  final StreamController<SessionState> states;
  final ValueNotifier<int> epoch;
  final List<String> log;

  const _Probe({required this.states, required this.epoch, required this.log});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with SessionStaleRecovery {
  @override
  Stream<SessionState> get sessionStates => widget.states.stream;

  @override
  int get currentSessionEpoch => widget.epoch.value;

  @override
  String get connectionDroppedMessage => 'drop';

  @override
  void recoverStaleSession() => widget.log.add('recover');

  @override
  void initState() {
    super.initState();
    startSessionRecovery();
  }

  @override
  void dispose() {
    stopSessionRecovery();
    super.dispose();
  }

  void finishLogin() => stopSessionRecovery();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('новое соединение до входа считается устаревшей сессией', (
    tester,
  ) async {
    final states = StreamController<SessionState>.broadcast();
    addTearDown(states.close);
    final epoch = ValueNotifier<int>(1);
    final log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: _Probe(states: states, epoch: epoch, log: log),
      ),
    );

    epoch.value = 2;
    states.add(SessionState.online);
    await tester.pump();
    expect(log, ['recover']);
  });

  testWidgets('после успешного входа переподключение не закрывает экран', (
    tester,
  ) async {
    final states = StreamController<SessionState>.broadcast();
    addTearDown(states.close);
    final epoch = ValueNotifier<int>(1);
    final log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: _Probe(states: states, epoch: epoch, log: log),
      ),
    );
    tester.state<_ProbeState>(find.byType(_Probe)).finishLogin();

    epoch.value = 2;
    states.add(SessionState.online);
    await tester.pump();
    expect(log, isEmpty);
  });
}
