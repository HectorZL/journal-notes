import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:email_validator/email_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_animo/providers/accessibility_provider.dart';
import 'package:notas_animo/services/face_recognition_service.dart';
import 'package:notas_animo/services/auth_service.dart';
import 'package:notas_animo/services/navigation_service.dart';
import 'package:notas_animo/services/url_service.dart';
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
  //final _ngrokUrlController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showAccessibilitySettings = false;
  File? _profileImage;
  bool _isVerifyingFace = false;
  bool _isFaceVerified = false;

  /*@override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final savedUrl = await UrlService.getNgrokUrl();
    if (savedUrl != null) {
      setState(() {
        _ngrokUrlController.text = savedUrl;
      });
    }
  }*/

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    //_ngrokUrlController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _verifyFace() async {
    /*if (_ngrokUrlController.text.isEmpty) {
      _showErrorSnackBar('Por favor ingresa la URL del servidor');
      return;
    }

    if (Uri.tryParse(_ngrokUrlController.text)!.hasAbsolutePath ?? true) {
      _showErrorSnackBar('URL inválida. Asegúrate de que sea una URL válida (debe comenzar con http:// o https://)');
      return;
    }
    */
    if (_profileImage == null) {
      _showErrorSnackBar('Por favor, toma una foto de perfil primero');
      return;
    }

    if (mounted) {
      setState(() {
        _isVerifyingFace = true;
      });
    }

    try {
      String grokurl = 'http://localhost:8080';
      final faceService = FaceRecognitionService(baseUrl: grokurl);
      final result = await faceService.verifyFace(_profileImage!);
      
      if (mounted) {
        setState(() {
          _isVerifyingFace = false;
          if (result['isRegistered'] == true) {
            _isFaceVerified = false;
            _showErrorSnackBar(result['message'] ?? 'Este rostro ya está registrado');
          } else if (result['success'] == true) {
            _isFaceVerified = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rostro verificado correctamente. Puedes continuar con el registro.'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            _isFaceVerified = false;
            _showErrorSnackBar(result['message'] ?? 'Error al verificar el rostro');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingFace = false;
          _isFaceVerified = false;
        });
        _showErrorSnackBar('Error al conectar con el servidor: $e');
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Save the URL before proceeding
    /*if (_ngrokUrlController.text.isNotEmpty) {
      await UrlService.saveNgrokUrl(_ngrokUrlController.text);
    }

    // Verify server URL is provided and valid
    if (_ngrokUrlController.text.isEmpty) {
      _showErrorSnackBar('Por favor ingresa la URL del servidor');
      return;
    }

    if (Uri.tryParse(_ngrokUrlController.text)!.hasAbsolutePath ?? true) {
      _showErrorSnackBar('URL inválida. Asegúrate de que sea una URL válida (debe comenzar con http:// o https://)');
      return;
    }*/
    
    // Verify that a profile picture was taken
    /*if (_profileImage == null) {
      _showErrorSnackBar('Por favor, toma una foto de perfil');
      return;
    }*/
      
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Verify passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Las contraseñas no coinciden');
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = ref.read(authServiceProvider);
      
      // Register the user with face verification
      debugPrint('Iniciando registro con imagen facial...');
      final result = await authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        profileImage: _profileImage,
        // apiBaseUrl: _ngrokUrlController.text,
        faceImage: _profileImage, // Pass the profile image as face image
      );

      debugPrint('Resultado del registro: ${result.toString()}');

      if (result['success'] == true && mounted) {
        // Save accessibility settings
        final notifier = ref.read(accessibilityProvider.notifier);
        await notifier.updateSettings(ref.read(accessibilityProvider));
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro exitoso'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Navigate to home screen
        final navService = ref.read(navigationServiceProvider);
        navService.navigateToHome(context);
      } else {
        _showErrorSnackBar(result['message'] ?? 'Error desconocido al registrarse');
      }
    } catch (e) {
      debugPrint('Error durante el registro: $e');
      _showErrorSnackBar('Ocurrió un error al registrarse. Por favor, verifica tu conexión e inténtalo de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _takeProfilePicture() async {
    try {
      final image = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            onImageCaptured: (File image) {
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

      if (image != null && mounted) {
        setState(() {
          _profileImage = image;
          _isFaceVerified = false; // Reset face verification when a new image is taken
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al capturar la imagen: $e');
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
                          backgroundColor: colorScheme.surfaceContainerHighest,
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
             /* TextFormField(
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
                  if (Uri.tryParse(value)!.hasAbsolutePath ?? true) {
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
              */const SizedBox(height: 24),
              
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
