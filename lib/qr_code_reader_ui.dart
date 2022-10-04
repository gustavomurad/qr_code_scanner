import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:qr_code_scanner/scanner_utils.dart';
import 'package:qr_code_scanner/window_painter.dart';

import 'media_size_clipper.dart';

class QRCodeReaderUI extends StatefulWidget {
  const QRCodeReaderUI({super.key});

  @override
  State<QRCodeReaderUI> createState() => _QRCodeReaderUIState();
}

class _QRCodeReaderUIState extends State<QRCodeReaderUI> {
  late CameraController _cameraController;
  final BarcodeScanner _barcodeDetector =
      GoogleMlKit.vision.barcodeScanner([BarcodeFormat.qrCode]);

  @override
  void dispose() async {
    _disposeCameraAndScanner();
    super.dispose();
  }

  void _disposeCameraAndScanner() async {
    if (_cameraController.value.isStreamingImages) {
      await _cameraController.stopImageStream();
    }
    await _barcodeDetector.close();
    await _cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          FutureBuilder<void>(
            future: _initCameraAndScanner(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                final scale = 1 /
                    (_cameraController.value.aspectRatio *
                        mediaSize.aspectRatio);
                return ClipRect(
                  clipper: MediaSizeClipper(mediaSize),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: CameraPreview(_cameraController),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Container(
            constraints: const BoxConstraints.expand(),
            child: CustomPaint(
              painter: WindowPainter(
                windowSize: const Size(320, 320),
                outerFrameColor: Colors.black.withOpacity(0.8),
                closeWindow: false,
                innerFrameStrokeWidth: 10,
                innerFrameColor: Colors.amber,
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 10,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initCameraAndScanner() async {
    final camera = await ScannerUtils.getCamera(CameraLensDirection.back);
    await _openCamera(camera);
    await _startStreamingImagesToScanner(camera.sensorOrientation);
  }

  Future<void> _openCamera(CameraDescription camera) async {
    final ResolutionPreset preset =
        defaultTargetPlatform == TargetPlatform.android
            ? ResolutionPreset.high
            : ResolutionPreset.high;

    _cameraController = CameraController(camera, preset);

    await _cameraController.initialize();
  }

  Future<void> _startStreamingImagesToScanner(int sensorOrientation) async {
    bool isDetecting = false;
    final MediaQueryData data = MediaQuery.of(context);

    _cameraController.startImageStream((CameraImage image) {
      if (isDetecting) {
        return;
      }

      isDetecting = true;

      ScannerUtils.detect(
        image: image,
        detectInImage: _barcodeDetector.processImage,
        imageRotation: sensorOrientation,
      ).then(
        (dynamic result) {
          _handleResult(
            barcodes: result,
            data: data,
            imageSize: Size(image.width.toDouble(), image.height.toDouble()),
          );
        },
      ).whenComplete(() => isDetecting = false);
    });
  }

  void _handleResult({
    required List<Barcode> barcodes,
    required MediaQueryData data,
    required Size imageSize,
  }) {
    if (!_cameraController.value.isStreamingImages) {
      return;
    }

    final EdgeInsets padding = data.padding;
    final double maxLogicalHeight =
        data.size.height - padding.top - padding.bottom;

    // Width & height are flipped from CameraController.previewSize on iOS
    final double imageHeight = defaultTargetPlatform == TargetPlatform.iOS
        ? imageSize.height
        : imageSize.width;

    final double imageScale = imageHeight / maxLogicalHeight;
    final double halfWidth = imageScale * 320 / 2;
    final double halfHeight = imageScale * 320 / 2;

    final Offset center = imageSize.center(Offset.zero);
    final Rect validRect = Rect.fromLTRB(
      center.dx - halfWidth,
      center.dy - halfHeight,
      center.dx + halfWidth,
      center.dy + halfHeight,
    );

    for (Barcode barcode in barcodes) {
      final Rect intersection = validRect.intersect(barcode.boundingBox!);

      bool doesContain = intersection == barcode.boundingBox;
      doesContain = true;
      if (doesContain) {
        _cameraController.stopImageStream();
        Navigator.of(context).pop('Text in QR => ${barcode.rawValue}');
      }
    }
  }
}
