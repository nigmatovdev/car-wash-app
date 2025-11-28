import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/inputs/custom_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String? _selectedRole;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      Helpers.showErrorSnackBar(
        context,
        'Please accept the Terms & Conditions',
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Clear previous errors
    authProvider.clearError();
    
    final success = await authProvider.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      role: _selectedRole ?? 'customer',
    );

    if (!mounted) return;

    if (success) {
      // Navigate to home
      context.go(RouteConstants.home);
    } else {
      // Show error message
      final error = authProvider.errorMessage;
      if (error != null) {
        Helpers.showErrorSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                enabled: !authProvider.isLoading,
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
                enabled: !authProvider.isLoading,
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
                enabled: !authProvider.isLoading,
              ),

              const SizedBox(height: 16),

              // Phone Field
              CustomTextField(
                label: 'Phone',
                hint: 'Enter your phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                enabled: !authProvider.isLoading,
              ),

              const SizedBox(height: 16),

              // Address Field
              CustomTextField(
                label: 'Address',
                hint: 'Enter your address',
                controller: _addressController,
                maxLines: 2,
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Address',
                ),
                prefixIcon: const Icon(Icons.location_on_outlined),
                enabled: !authProvider.isLoading,
              ),

              const SizedBox(height: 16),

              // Password Field
              CustomTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: (value) => Validators.minLength(
                  value,
                  6,
                  fieldName: 'Password',
                ),
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                enabled: !authProvider.isLoading,
              ),

              const SizedBox(height: 16),

              // Confirm Password Field
              CustomTextField(
                label: 'Confirm Password',
                hint: 'Confirm your password',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                validator: (value) => Validators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                enabled: !authProvider.isLoading,
              ),

              const SizedBox(height: 16),

              // Role Selector (Optional)
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role (Optional)',
                  prefixIcon: Icon(Icons.work_outline),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'customer',
                    child: Text('Customer'),
                  ),
                  DropdownMenuItem(
                    value: 'washer',
                    child: Text('Washer'),
                  ),
                ],
                onChanged: authProvider.isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
              ),

              const SizedBox(height: 16),

              // Terms & Conditions Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: authProvider.isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: authProvider.isLoading
                          ? null
                          : () {
                              setState(() {
                                _acceptTerms = !_acceptTerms;
                              });
                            },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              const TextSpan(
                                text: 'I agree to the ',
                              ),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sign Up Button
              PrimaryButton(
                text: 'Sign Up',
                onPressed: authProvider.isLoading ? null : _handleRegister,
                isLoading: authProvider.isLoading,
              ),

              const SizedBox(height: 24),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () {
                            context.push(RouteConstants.login);
                          },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
