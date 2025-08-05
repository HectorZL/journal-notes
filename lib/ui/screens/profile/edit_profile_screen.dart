import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notas_animo/data/database_helper.dart';
import 'package:notas_animo/services/auth_service.dart';
import '../../widgets/base_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      
      if (user != null) {
        setState(() {
          _nameController.text = user['name'] ?? '';
          _emailController.text = user['email'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los datos del perfil: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      final authService = ref.read(authServiceProvider);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final userId = int.tryParse(currentUser['id'].toString());
        if (userId == null) throw Exception('ID de usuario no válido');
        
        // Update the user in the database
        await dbHelper.updateUser(
          userId,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );

        // Update the current user in the auth service
        await authService.updateProfile(
          userId: userId.toString(),
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );

        if (mounted) {
          Navigator.of(context).pop(true); // Return success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar los cambios: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BaseScreen(
      title: 'Editar Perfil',
      showBackButton: true,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture Placeholder
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                color: theme.colorScheme.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
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
                        if (!RegExp(r'^[^@]+@[^\s]+\.[^\s]+$').hasMatch(value)) {
                          return 'Por favor ingresa un correo electrónico válido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    FilledButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Guardar Cambios'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
