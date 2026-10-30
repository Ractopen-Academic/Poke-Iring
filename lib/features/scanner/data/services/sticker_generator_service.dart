import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../domain/entities/cat_scan_result.dart';

class StickerGeneratorService {
  static const int _targetSize = 320;

  Future<Uint8List> generateSticker({
    required Uint8List imageBytes,
    required CatScanResult scanResult,
  }) async {
    return compute(_processStickerIsolate, {
      'bytes': imageBytes,
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

      // Add 12% padding margin around the bounding box
      final marginX = (boxWidth * 0.12).round();
      final marginY = (boxHeight * 0.12).round();

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

    return Uint8List.fromList(img.encodePng(resized));
  }
}
