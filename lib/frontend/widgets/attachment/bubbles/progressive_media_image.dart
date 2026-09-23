import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProgressiveMediaImage extends StatelessWidget {
  static const Duration fadeDuration = Duration(milliseconds: 150);
  static const double previewBlurSigma = 6;

  final String url;
  final ImageProvider? preview;
  final double width;
  final double height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final WidgetBuilder fallback;

  const ProgressiveMediaImage({
    super.key,
    required this.url,
    required this.preview,
    required this.width,
    required this.height,
    required this.fallback,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  Widget _previewImage(ImageProvider image) => Image(
    image: image,
    width: width,
    height: height,
    fit: BoxFit.cover,
    filterQuality: FilterQuality.medium,
    gaplessPlayback: true,
  );

  Widget _loading(BuildContext context) {
    final image = preview;
    if (image == null) return fallback(context);
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(
        sigmaX: previewBlurSigma,
        sigmaY: previewBlurSigma,
        tileMode: TileMode.clamp,
      ),
      child: _previewImage(image),
    );
  }

  Widget _failed(BuildContext context) {
    final image = preview;
    return image == null ? fallback(context) : _previewImage(image);
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeDuration,
      fadeOutDuration: fadeDuration,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (context, _) => _loading(context),
      errorWidget: (context, _, _) => _failed(context),
    );
  }
}
