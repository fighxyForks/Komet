import 'dart:collection';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../config/app_ios_glass.dart';

// #***! Expando привязывает провайдер к сообщению, base64 декодируется один раз а не на каждый билд
final Expando<ImageProvider> _providers = Expando<ImageProvider>('preview');

const int previewCacheCapacity = 256;
final LinkedHashMap<String, ImageProvider> _byContent =
    LinkedHashMap<String, ImageProvider>();

// #***! размытая превьюшка из data-uri
ImageProvider? dataUriImage(Object owner, String? data) {
  if (data == null || !data.startsWith('data:')) return null;
  if (AppIosGlass.active.value) return _dataUriByContent(data);
  final cached = _providers[owner];
  if (cached != null) return cached;
  final comma = data.indexOf(',');
  if (comma < 0) return null;
  try {
    final provider = MemoryImage(base64Decode(data.substring(comma + 1)));
    _providers[owner] = provider;
    return provider;
  } catch (_) {
    return null;
  }
}

ImageProvider? _dataUriByContent(String data) {
  final cached = _byContent.remove(data);
  if (cached != null) {
    _byContent[data] = cached;
    return cached;
  }
  final comma = data.indexOf(',');
  if (comma < 0) return null;
  try {
    final provider = MemoryImage(base64Decode(data.substring(comma + 1)));
    _byContent[data] = provider;
    if (_byContent.length > previewCacheCapacity) {
      _byContent.remove(_byContent.keys.first);
    }
    return provider;
  } catch (_) {
    return null;
  }
}
