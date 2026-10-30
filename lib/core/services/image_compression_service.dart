import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageCompressionResult {
  final Uint8List compressedBytes;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final int width;
  final int height;

  const ImageCompressionResult({
    required this.compressedBytes,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.width,
    required this.height,
  });

  double get compressionRatio => originalSizeBytes > 0
      ? (1.0 - (compressedSizeBytes / originalSizeBytes)) * 100
      : 0.0;
}

class ImageCompressionService {
  static const int maxStoryWidth = 1080;
  static const int maxStoryHeight = 1920;
  static const int storyJpegQuality = 82;

  static const int maxAvatarDimension = 360;
  static const int avatarJpegQuality = 85;

  Future<ImageCompressionResult> compressStoryImage(Uint8List rawBytes) async {
    return compute(_compressImageIsolate, {
      'bytes': rawBytes,
      'maxWidth': maxStoryWidth,
      'maxHeight': maxStoryHeight,
      'quality': storyJpegQuality,
    });
  }

  Future<ImageCompressionResult> compressAvatarImage(Uint8List rawBytes) async {
    return compute(_compressImageIsolate, {
      'bytes': rawBytes,
      'maxWidth': maxAvatarDimension,
      'maxHeight': maxAvatarDimension,
      'quality': avatarJpegQuality,
      'squareCrop': true,
    });
  }

  static ImageCompressionResult _compressImageIsolate(
    Map<String, dynamic> params,
  ) {
    final rawBytes = params['bytes'] as Uint8List;
    final maxWidth = params['maxWidth'] as int;
    final maxHeight = params['maxHeight'] as int;
    final quality = params['quality'] as int;
    final squareCrop = params['squareCrop'] == true;

    final image = img.decodeImage(rawBytes);
    if (image == null) {
      return ImageCompressionResult(
        compressedBytes: rawBytes,
        originalSizeBytes: rawBytes.length,
        compressedSizeBytes: rawBytes.length,
        width: 0,
        height: 0,
      );
    }

    img.Image processed = image;

    if (squareCrop) {
      final side = image.width < image.height ? image.width : image.height;
      final x = ((image.width - side) / 2).toInt();
      final y = ((image.height - side) / 2).toInt();
      processed = img.copyCrop(image, x: x, y: y, width: side, height: side);
    }

    // Downscale if larger than max bounds maintaining aspect ratio
    if (processed.width > maxWidth || processed.height > maxHeight) {
      final double scaleW = maxWidth / processed.width;
      final double scaleH = maxHeight / processed.height;
      final double scale = scaleW < scaleH ? scaleW : scaleH;

      final targetW = (processed.width * scale).round().clamp(1, maxWidth);
      final targetH = (processed.height * scale).round().clamp(1, maxHeight);

      processed = img.copyResize(
        processed,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.linear,
      );
    }

    final compressed = Uint8List.fromList(
      img.encodeJpg(processed, quality: quality),
    );

    return ImageCompressionResult(
      compressedBytes: compressed,
      originalSizeBytes: rawBytes.length,
      compressedSizeBytes: compressed.length,
      width: processed.width,
      height: processed.height,
    );
  }
}
