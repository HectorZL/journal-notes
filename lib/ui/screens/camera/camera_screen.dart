import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notas_animo/utils/error_handler.dart';

class CameraScreen extends StatefulWidget {
  final Function(File) onImageCaptured;

  const CameraScreen({Key? key, required this.onImageCaptured}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isLoading = true;
  int _selectedCamera = 0;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    await ErrorHandler.runWithErrorHandling(
      context: context,
      action: () async {
        _cameras = await availableCameras();
        if (_cameras == null || _cameras!.isEmpty) {
          throw Exception('No cameras available');
        }

        if (_selectedCamera >= _cameras!.length) {
          _selectedCamera = 0;
        }

        _controller = CameraController(
          _cameras![_selectedCamera],
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        await _controller!.setFlashMode(FlashMode.off);
        
        if (!mounted) return;
        
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      },
      errorMessage: 'Error al inicializar la cámara',
      popOnError: true,
    );
  }

  Future<void> _disposeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    setState(() {
      _isCameraInitialized = false;
      _isLoading = true;
    });
    
    await _disposeCamera();
    
    setState(() {
      _selectedCamera = (_selectedCamera + 1) % _cameras!.length;
    });
    
    await _initializeCamera();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isCameraInitialized || _isLoading) return;

    await ErrorHandler.runWithErrorHandling(
      context: context,
      action: () async {
        setState(() => _isLoading = true);
        
        final XFile image = await _controller!.takePicture();
        final File imageFile = File(image.path);
        
        if (!mounted) return;
        
        // Save the picture to the application directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await imageFile.copy('${appDir.path}/$fileName');
        
        if (mounted) {
          widget.onImageCaptured(savedImage);
          Navigator.of(context).pop(savedImage);
        }
      },
      errorMessage: 'Error al tomar la foto',
      popOnError: false,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomar Foto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.switch_camera),
              onPressed: _isLoading ? null : _switchCamera,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isCameraInitialized
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: CameraPreview(_controller!),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            heroTag: 'capture',
                            onPressed: _isLoading ? null : _takePicture,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Icon(Icons.camera_alt),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text('No se pudo inicializar la cámara'),
                ),
    );
  }
}
