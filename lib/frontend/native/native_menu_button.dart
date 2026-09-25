import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@immutable
class NativeMenuItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? symbol;
  final String? imageUrl;
  final bool checked;
  final bool destructive;

  const NativeMenuItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.symbol,
    this.imageUrl,
    this.checked = false,
    this.destructive = false,
  });

  const NativeMenuItem.separator()
    : id = '',
      title = '',
      subtitle = null,
      symbol = null,
      imageUrl = null,
      checked = false,
      destructive = false;

  bool get isSeparator => id.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is NativeMenuItem &&
      other.id == id &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.symbol == symbol &&
      other.imageUrl == imageUrl &&
      other.checked == checked &&
      other.destructive == destructive;

  @override
  int get hashCode =>
      Object.hash(id, title, subtitle, symbol, imageUrl, checked, destructive);

  Map<String, Object?> toMap() => isSeparator
      ? const {'separator': true}
      : {
          'id': id,
          'title': title,
          'subtitle': subtitle,
          'symbol': symbol,
          'imageUrl': imageUrl,
          'checked': checked,
          'destructive': destructive,
        };
}

class NativeMenuButton extends StatefulWidget {
  static const viewType = 'ru.komet.app/menu_button';

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  final Widget child;
  final List<NativeMenuItem> items;
  final ValueChanged<String> onSelected;
  final ValueChanged<Rect> onFallback;

  const NativeMenuButton({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
    required this.onFallback,
  });

  @override
  State<NativeMenuButton> createState() => _NativeMenuButtonState();
}

class _NativeMenuButtonState extends State<NativeMenuButton> {
  MethodChannel? _channel;
  late final List<NativeMenuItem> _createdItems = widget.items;

  List<Map<String, Object?>> _encode(List<NativeMenuItem> items) => [
    for (final item in items) item.toMap(),
  ];

  void _onCreated(int viewId) {
    final channel = MethodChannel('${NativeMenuButton.viewType}/$viewId')
      ..setMethodCallHandler(_onCall);
    _channel = channel;
    if (!listEquals(_createdItems, widget.items)) _pushItems();
  }

  Future<void> _onCall(MethodCall call) async {
    if (!mounted) return;
    switch (call.method) {
      case 'select':
        final id = call.arguments;
        if (id is String) widget.onSelected(id);
      case 'fallback':
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        widget.onFallback(box.localToGlobal(Offset.zero) & box.size);
    }
  }

  void _pushItems() {
    _channel?.invokeMethod<void>('setItems', _encode(widget.items));
  }

  @override
  void didUpdateWidget(NativeMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items)) _pushItems();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: UiKitView(
            viewType: NativeMenuButton.viewType,
            creationParams: {'items': _encode(_createdItems)},
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onCreated,
          ),
        ),
      ],
    );
  }
}
