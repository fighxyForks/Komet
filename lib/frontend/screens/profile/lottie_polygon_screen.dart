import 'package:flutter/material.dart';
import '../../widgets/glass/ios_settings_scaffold.dart';
import 'package:lottie/lottie.dart';

import '../../../core/config/app_animations.dart';

class LottiePolygonScreen extends StatelessWidget {
  const LottiePolygonScreen({super.key});

  static const List<_PolygonEntry> _entries = [
    _PolygonEntry('call', AppAnimations.call),
    _PolygonEntry('settings', AppAnimations.settings),
    _PolygonEntry('search', AppAnimations.search),
    _PolygonEntry('clock', AppAnimations.clock),
    _PolygonEntry('chat', AppAnimations.chat),
    _PolygonEntry('contacts', AppAnimations.contacts),
  ];

  @override
  Widget build(BuildContext context) {
    return IosSettingsScaffold(
      title: 'Lottie полигон',
      useConnectionTitle: false,
      body: SafeArea(
        top: false,
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [for (final entry in _entries) _PolygonTile(entry: entry)],
        ),
      ),
    );
  }
}

class _PolygonEntry {
  final String label;
  final String asset;

  const _PolygonEntry(this.label, this.asset);
}

class _PolygonTile extends StatefulWidget {
  final _PolygonEntry entry;

  const _PolygonTile({required this.entry});

  @override
  State<_PolygonTile> createState() => _PolygonTileState();
}

class _PolygonTileState extends State<_PolygonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _controller.forward(from: 0),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 56,
                child: Lottie.asset(
                  widget.entry.asset,
                  controller: _controller,
                  fit: BoxFit.contain,
                  delegates: LottieDelegates(
                    values: [
                      ValueDelegate.color(const ['**'], value: cs.onSurface),
                      ValueDelegate.strokeColor(const [
                        '**',
                      ], value: cs.onSurface),
                    ],
                  ),
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.entry.label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
