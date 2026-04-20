import 'package:flutter/material.dart';

/// A widget that displays an image with a fallback placeholder when the image fails to load.
class ImageWithFallback extends StatelessWidget {
  final String? src;
  final String? alt;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ImageWithFallback({
    super.key,
    this.src,
    this.alt,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (src == null || src!.isEmpty) {
      imageWidget = _buildErrorWidget();
    } else if (src!.startsWith('http://') || src!.startsWith('https://')) {
      imageWidget = Image.network(
        src!,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: alt,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      imageWidget = Image.asset(
        src!,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: alt,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: (width != null && height != null)
              ? (width! < height! ? width! : height!) * 0.4
              : 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
