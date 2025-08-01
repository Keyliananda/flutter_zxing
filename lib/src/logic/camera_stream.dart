part of 'zxing.dart';

IsolateUtils? isolateUtils;

/// Starts reading barcode from the camera
Future<void> zxingStartCameraProcessing() async {
  isolateUtils = IsolateUtils();
  await isolateUtils?.startReadingBarcode();
}

/// Stops reading barcode from the camera
void zxingStopCameraProcessing() => isolateUtils?.stopReadingBarcode();

Future<dynamic> zxingProcessCameraImage(
        CameraImage image, DecodeParams params) =>
    _inference(IsolateData(image, params));

/// Runs inference in another isolate
Future<dynamic> _inference(IsolateData isolateData) async {
  try {
    final ReceivePort responsePort = ReceivePort();
    isolateUtils?.sendPort
        ?.send(isolateData..responsePort = responsePort.sendPort);
    final dynamic results = await responsePort.first;
    return results;
  } catch (e) {
    print('Camera inference error: $e');
    return Code(error: 'Camera processing failed: $e');
  }
}
