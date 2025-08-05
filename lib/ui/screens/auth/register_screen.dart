import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:email_validator/email_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_animo/providers/accessibility_provider.dart';
import 'package:notas_animo/services/face_recognition_service.dart';
import 'package:notas_animo/services/auth_service.dart';
import 'package:notas_animo/services/navigation_service.dart';
import 'package:notas_animo/ui/widgets/base_screen.dart';
import 'package:notas_animo/ui/widgets/accessibility_settings_widget.dart';
import 'package:notas_animo/ui/screens/camera/camera_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ngrokUrlController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showAccessibilitySettings = false;
  File? _profileImage;
  bool _isVerifyingFace = false;
  bool _isFaceVerified = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ngrokUrlController.dispose();
    super.dispose();
  }

  Future<void> _verifyFace() async {
    if (_ngrokUrlController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa la URL del servidor');
      return;
    }

    if (!FaceRecognitionService.isValidNgrokUrl(_ngrokUrlController.text)) {
      setState(() => _errorMessage = 'URL inválida. Asegúrate de que sea una URL válida (debe comenzar con http:// o https://)');
      return;
    }

    if (_profileImage == null) {
      setState(() => _errorMessage = 'Por favor, toma una foto de perfil primero');
      return;
    }

    setState(() {
      _isVerifyingFace = true;
      _errorMessage = null;
    });

    try {
      final faceService = FaceRecognitionService(baseUrl: _ngrokUrlController.text);
      final result = await faceService.verifyFace(_profileImage!);
      
      if (mounted) {
        setState(() {
          _isVerifyingFace = false;
          if (result['isRegistered'] == true) {
            _errorMessage = result['message'];
            _isFaceVerified = false;
          } else if (result['success'] == true) {
            _isFaceVerified = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Rostro verificado correctamente')),
            );
          } else {
            _errorMessage = result['message'] ?? 'Error al verificar el rostro';
            _isFaceVerified = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingFace = false;
          _errorMessage = 'Error al conectar con el servidor: $e';
          _isFaceVerified = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Verify server URL is provided and valid
    if (_ngrokUrlController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa la URL del servidor');
      return;
    }

    if (!FaceRecognitionService.isValidNgrokUrl(_ngrokUrlController.text)) {
      setState(() => _errorMessage = 'URL inválida. Asegúrate de que sea una URL válida (debe comenzar con http:// o https://)');
      return;
    }
    
    // Verify that a profile picture was taken
    if (_profileImage == null) {
      setState(() => _errorMessage = 'Por favor, toma una foto de perfil');
      return;
    }
    
    // Verify that the face has been verified
    if (!_isFaceVerified) {
      setState(() => _errorMessage = 'Por favor, verifica tu rostro antes de continuar');
      return;
    }
    
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Verify passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      
      // Register the user with face verification
      final result = await authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        profileImage: _profileImage,
        apiBaseUrl: _ngrokUrlController.text,
      );

      if (result['success'] == true && mounted) {
        // Save accessibility settings
        final notifier = ref.read(accessibilityProvider.notifier);
        await notifier.updateSettings(ref.read(accessibilityProvider));
        
        // Navigate to home screen
        final navService = ref.read(navigationServiceProvider);
        navService.navigateToHome(context);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error desconocido al registrarse';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error al registrarse. Por favor, verifica tu conexión e inténtalo de nuevo.';
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _takeProfilePicture() async {
    try {
      final image = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            onImageCaptured: (File image) {
              // Actualizamos la imagen de perfil
              if (mounted) {
                setState(() {
                  _profileImage = image;
                  _isFaceVerified = false; // Reset face verification when a new image is taken
                });
              }
            },
          ),
        ),
      );

      // Si hay una imagen devuelta, la asignamos
      if (image != null && mounted) {
        setState(() {
          _profileImage = image;
          _isFaceVerified = false; // Reset face verification when a new image is taken
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar la imagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navService = ref.read(navigationServiceProvider);
    final isDark = theme.brightness == Brightness.dark;

    return BaseScreen(
      title: 'Crear cuenta',
      showBackButton: true,
      isLoading: _isLoading || _isVerifyingFace,
      errorMessage: _errorMessage,
      onRetry: _errorMessage != null ? _register : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.surfaceVariant,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 20),
                              color: colorScheme.onPrimary,
                              onPressed: _takeProfilePicture,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profileImage == null 
                          ? 'Agrega una foto de perfil' 
                          : 'Foto lista',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (_profileImage != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isVerifyingFace ? null : _verifyFace,
                        icon: _isVerifyingFace 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : _isFaceVerified 
                                ? const Icon(Icons.verified, size: 18)
                                : const Icon(Icons.face_retouching_natural, size: 18),
                        label: Text(_isVerifyingFace 
                            ? 'Verificando...' 
                            : _isFaceVerified 
                                ? 'Rostro verificado'
                                : 'Verificar rostro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFaceVerified 
                              ? Colors.green
                              : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  if (!EmailValidator.validate(value)) {
                    return 'Por favor ingresa un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor confirma tu contraseña';
                  }
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Server URL Field
              TextFormField(
                controller: _ngrokUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL del servidor',
                  hintText: 'https://tudominio.com',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa la URL del servidor';
                  }
                  if (!FaceRecognitionService.isValidNgrokUrl(value)) {
                    return 'URL inválida. Asegúrate de que sea una URL válida (debe comenzar con http:// o https://)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa la URL de tu servidor (ej: https://tudominio.com)',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              
              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: const Text('Crear cuenta'),
              ),
              const SizedBox(height: 16),
              
              // Already have an account? Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿Ya tienes una cuenta?', style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: _isLoading ? null : () => navService.navigateToLogin(context),
                    child: const Text('Inicia sesión'),
                  ),
                ],
              ),
              
              // Toggle Accessibility Settings
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAccessibilitySettings = !_showAccessibilitySettings;
                  });
                },
                child: Text(
                  _showAccessibilitySettings 
                      ? 'Ocultar configuración de accesibilidad' 
                      : 'Mostrar configuración de accesibilidad',
                ),
              ),
              
              // Accessibility Settings
              if (_showAccessibilitySettings) ...[
                const SizedBox(height: 16),
                const AccessibilitySettingsWidget(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
