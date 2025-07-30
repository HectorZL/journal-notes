import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  final Function(File) onImageCaptured;

  const CameraScreen({Key? key, required this.onImageCaptured}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _hasError = false;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableTracking: true,
      enableLandmarks: true,
      enableClassification: true,
      minFaceSize: 0.15,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isCameraInitialized = false;
        });
      }
      rethrow;
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isDetecting) return;

    setState(() => _isDetecting = true);

    try {
      final XFile picture = await _controller!.takePicture();
      final File imageFile = File(picture.path);
      
      // Convert to input image for face detection
      final inputImage = InputImage.fromFilePath(picture.path);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se detectó ningún rostro. Por favor, intente de nuevo.')),
        );
        setState(() => _isDetecting = false);
        return;
      }

      // Get the largest face (most likely the main subject)
      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * a.boundingBox.height));
      final Face face = faces.first;

      // Process and crop the image
      final croppedFile = await _cropImage(imageFile, face);
      
      if (!mounted) return;
      
      // Call the callback with the cropped image
      widget.onImageCaptured(croppedFile);
      
      // Close the camera screen and return the image
      if (mounted) {
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar la imagen: ${e.toString()}')),
      );
      setState(() => _isDetecting = false);
    }
  }

  Future<File> _cropImage(File originalImage, Face face) async {
    // Load the image
    final image = img.decodeImage(await originalImage.readAsBytes())!;
    
    // Get face coordinates
    final double x = face.boundingBox.left;
    final double y = face.boundingBox.top;
    final double width = face.boundingBox.width;
    final double height = face.boundingBox.height;
    
    // Add some padding around the face
    final double padding = 0.4; // 40% padding
    final double paddingX = width * padding;
    final double paddingY = height * padding;
    
    // Calculate crop area with padding
    int cropX = (x - paddingX).clamp(0, image.width - 1).toInt();
    int cropY = (y - paddingY).clamp(0, image.height - 1).toInt();
    int cropWidth = (width + 2 * paddingX).toInt();
    int cropHeight = (height + 2 * paddingY).toInt();
    
    // Ensure we don't go out of bounds
    if (cropX + cropWidth > image.width) {
      cropWidth = image.width - cropX;
    }
    if (cropY + cropHeight > image.height) {
      cropHeight = image.height - cropY;
    }
    
    // Crop the image
    final croppedImage = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );
    
    // Save the cropped image
    final directory = await getTemporaryDirectory();
    final String path = '${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File croppedFile = File(path);
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));
    
    return croppedFile;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomar Foto de Perfil'),
        centerTitle: true,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError || _hasError) {
              return Center(child: Text('Error al inicializar la cámara'));
            }
            return Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    width: 250,
                    height: 350,
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _takePicture,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
