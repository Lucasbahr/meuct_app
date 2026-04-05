import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Imagem remota com cache em disco/memória e header de auth opcional (menos requisições ao bucket).
class CachedAuthNetworkImage extends StatelessWidget {
  const CachedAuthNetworkImage({
    super.key,
    required this.imageUrl,
    this.token,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth,
  });

  final String imageUrl;
  final String? token;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;

  Map<String, String>? get _headers =>
      token != null && token!.isNotEmpty
          ? {'Authorization': 'Bearer $token'}
          : null;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final logicalW =
        (width != null && width!.isFinite) ? width! : screenW;
    final w = memCacheWidth ??
        (logicalW * dpr).round().clamp(240, 1600);

    Widget img = CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: _headers,
      fit: fit,
      memCacheWidth: w,
      maxWidthDiskCache: w,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => Container(
        color: const Color(0xFF2A2A2A),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF2A2A2A),
        alignment: Alignment.center,
        child: const Text('Imagem indisponível'),
      ),
    );

    if (height != null || width != null) {
      img = SizedBox(height: height, width: width, child: img);
    }

    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }

    return img;
  }
}
