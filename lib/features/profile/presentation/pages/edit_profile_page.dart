import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/inputs/custom_text_field.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _selectedImage;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final profileProvider = context.read<ProfileProvider>();
    final user = profileProvider.user;
    
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _avatarUrl = user.avatar;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(context, 'Failed to take photo: $e');
      }
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_selectedImage != null || _avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _avatarUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profileProvider = context.read<ProfileProvider>();
    
    // TODO: Upload image if _selectedImage is not null
    // For now, we'll just update the profile without image upload
    // In production, you would upload the image to a storage service first
    
    final success = await profileProvider.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      avatar: _selectedImage != null ? 'uploaded_url_here' : _avatarUrl,
    );

    if (mounted) {
      if (success) {
        Helpers.showSuccessSnackBar(context, 'Profile updated successfully');
        context.pop();
      } else {
        Helpers.showErrorSnackBar(
          context,
          profileProvider.errorMessage ?? 'Failed to update profile',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // Profile Picture Picker
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null) as ImageProvider?,
                      child: _selectedImage == null && _avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: InkWell(
                          onTap: _showImagePickerOptions,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // First Name Field
              CustomTextField(
                label: 'First Name',
                hint: 'Enter your first name',
                controller: _firstNameController,
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'First name',
                ),
                prefixIcon: const Icon(Icons.person_outlined),
                enabled: !profileProvider.isLoading,
              ),

              const SizedBox(height: 16),

              // Last Name Field
              CustomTextField(
                label: 'Last Name',
                hint: 'Enter your last name',
                controller: _lastNameController,
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Last name',
                ),
                prefixIcon: const Icon(Icons.person_outlined),
                enabled: !profileProvider.isLoading,
              ),

              const SizedBox(height: 16),

              // Email Field
              CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                prefixIcon: const Icon(Icons.email_outlined),
                enabled: !profileProvider.isLoading,
              ),

              const SizedBox(height: 16),

              // Phone Field
              CustomTextField(
                label: 'Phone Number',
                hint: 'Enter your phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Phone is optional
                  }
                  return Validators.phone(value);
                },
                prefixIcon: const Icon(Icons.phone_outlined),
                enabled: !profileProvider.isLoading,
              ),

              const SizedBox(height: 32),

              // Save Button
              PrimaryButton(
                text: 'Save Changes',
                onPressed: profileProvider.isLoading ? null : _saveChanges,
                isLoading: profileProvider.isLoading,
                width: double.infinity,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

