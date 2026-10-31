import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../domain/entities/cat_scan_result.dart';

class StickerGeneratorService {
  static const int _targetSize = 320;
  static const double _borderThickness = 8.0;

  Future<Uint8List> generateSticker({
    required Uint8List imageBytes,
    required CatScanResult scanResult,
    bool asSilhouette = false,
  }) async {
    return compute(_processStickerIsolate, {
      'bytes': imageBytes,
      'asSilhouette': asSilhouette,
      'box': scanResult.boundingBox != null
          ? [
              scanResult.boundingBox!.left,
              scanResult.boundingBox!.top,
              scanResult.boundingBox!.right,
              scanResult.boundingBox!.bottom,
            ]
          : null,
    });
  }

  static Uint8List _processStickerIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final asSilhouette = params['asSilhouette'] as bool? ?? false;
    final boxList = params['box'] as List<double>?;

    final original = img.decodeImage(bytes);
    if (original == null) {
      return bytes;
    }

    img.Image cropped;
    if (boxList != null && boxList.length == 4) {
      final leftNorm = boxList[0];
      final topNorm = boxList[1];
      final rightNorm = boxList[2];
      final bottomNorm = boxList[3];

      final boxWidth = (rightNorm - leftNorm) * original.width;
      final boxHeight = (bottomNorm - topNorm) * original.height;

      // Add 14% safety padding margin around the bounding box
      final marginX = (boxWidth * 0.14).round();
      final marginY = (boxHeight * 0.14).round();

      final x = ((leftNorm * original.width) - marginX)
          .clamp(0, original.width - 1)
          .toInt();
      final y = ((topNorm * original.height) - marginY)
          .clamp(0, original.height - 1)
          .toInt();
      final w = (boxWidth + marginX * 2).clamp(1, original.width - x).toInt();
      final h = (boxHeight + marginY * 2).clamp(1, original.height - y).toInt();

      cropped = img.copyCrop(original, x: x, y: y, width: w, height: h);
    } else {
      // Center square crop fallback
      final side = original.width < original.height
          ? original.width
          : original.height;
      final x = ((original.width - side) / 2).toInt();
      final y = ((original.height - side) / 2).toInt();
      cropped = img.copyCrop(original, x: x, y: y, width: side, height: side);
    }

    final resized = img.copyResize(
      cropped,
      width: _targetSize,
      height: _targetSize,
      interpolation: img.Interpolation.linear,
    );

    // Create die-cut sticker canvas with alpha channel
    final sticker = img.Image(
      width: _targetSize,
      height: _targetSize,
      numChannels: 4,
    );

    const cx = _targetSize / 2.0;
    const cy = _targetSize / 2.0;
    const cornerR = _targetSize * 0.22;
    const halfW = (_targetSize / 2.0) - 8.0;
    const halfH = (_targetSize / 2.0) - 8.0;

    for (var y = 0; y < _targetSize; y++) {
      for (var x = 0; x < _targetSize; x++) {
        final qx = (x - cx).abs() - (halfW - cornerR);
        final qy = (y - cy).abs() - (halfH - cornerR);
        final dx = math.max(0.0, qx);
        final dy = math.max(0.0, qy);
        final dist = math.sqrt(dx * dx + dy * dy) - cornerR;

        if (dist > 0.0) {
          // Transparent background outside sticker die-cut boundary
          sticker.setPixelRgba(x, y, 0, 0, 0, 0);
        } else if (dist > -_borderThickness) {
          // White die-cut vinyl sticker border
          sticker.setPixelRgba(x, y, 255, 255, 255, 255);
        } else {
          if (asSilhouette) {
            // Dark mystery silhouette color
            sticker.setPixelRgba(x, y, 26, 34, 40, 255);
          } else {
            final pixel = resized.getPixel(x, y);
            sticker.setPixelRgba(
              x,
              y,
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              255,
            );
          }
        }
      }
    }

    return Uint8List.fromList(img.encodePng(sticker));
  }
}
