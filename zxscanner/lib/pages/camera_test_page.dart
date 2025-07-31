import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraTestPage extends StatefulWidget {
  const CameraTestPage({super.key});

  @override
  State<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> {
  List<CameraDescription> cameras = [];
  CameraController? controller;
  String status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        status = 'Getting available cameras...';
      });
      
      cameras = await availableCameras();
      
      setState(() {
        status = 'Found ${cameras.length} camera(s)';
      });
      
      if (cameras.isEmpty) {
        setState(() {
          status = 'No cameras found!';
        });
        return;
      }

      // Use the first camera
      final camera = cameras.first;
      setState(() {
        status = 'Initializing camera: ${camera.name}';
      });

      controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();
      
      setState(() {
        status = 'Camera ready: ${camera.name}';
      });
    } catch (e) {
      setState(() {
        status = 'Camera error: $e';
      });
      print('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
      ),
      body: Column(
        children: [
          // Status panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Text(
              status,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Camera preview
          Expanded(
            child: controller?.value.isInitialized == true
                ? CameraPreview(controller!)
                : const Center(
                    child: Text('Camera not ready'),
                  ),
          ),
        ],
      ),
    );
  }
} 