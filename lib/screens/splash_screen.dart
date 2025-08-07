import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare_plus/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.mediumAnimationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    // Check if user is already logged in
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthState();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if user is already logged in
  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is already logged in, navigate to home screen
      Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
    } else {
      // User is not logged in, navigate to login screen
      Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder - replace with actual logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appDescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}