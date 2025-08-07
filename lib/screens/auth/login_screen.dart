import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';
      default:
        return 'An error occurred during login. Please try again.';
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and app name
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[                    
                    Container(
                      padding: const EdgeInsets.all(AppConstants.smallPadding),
                      decoration: BoxDecoration(
                        color: AppConstants.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppConstants.errorColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pushReplacementNamed(
                                  AppConstants.registerRoute,
                                );
                              },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social login options
                  const Text(
                    'Or sign in with',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google sign in
                      _socialLoginButton(
                        icon: Icons.g_mobiledata,
                        onPressed: () {
                          // TODO: Implement Google sign in
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Google Sign In not implemented yet'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      // Apple sign in
                      _socialLoginButton(
                        icon: Icons.apple,
                        onPressed: () {
                          // TODO: Implement Apple sign in
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Apple Sign In not implemented yet'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialLoginButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: _isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 30),
      ),
    );
  }
}