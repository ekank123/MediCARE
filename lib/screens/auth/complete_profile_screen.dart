import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/services/auth_service.dart';
import 'package:medicare_plus/models/user_model.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  // Form controllers
  final _ageController = TextEditingController();
  String _selectedGender = 'Prefer not to say';
  final _medicalHistoryController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _preferredLanguage = 'English';
  List<String> _allergiesList = [];
  final _newAllergyController = TextEditingController();

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  final List<String> _languageOptions = [
    'English',
    'Hindi',
    'Bengali',
    'Telugu',
    'Marathi',
    'Tamil',
    'Urdu',
    'Gujarati',
    'Kannada',
    'Malayalam',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _authService.getUserProfile(user.uid);
        if (userData != null) {
          setState(() {
            _currentUser = userData;
            // Pre-fill form fields if data exists
            if (userData.age != null) {
              _ageController.text = userData.age.toString();
            }
            if (userData.gender != null) {
              _selectedGender = userData.gender!;
            }
            if (userData.allergies != null) {
              _allergiesList = List<String>.from(userData.allergies!);
            }
            if (userData.medicalHistory != null) {
              _medicalHistoryController.text = userData.medicalHistory!;
            }
            if (userData.height != null) {
              _heightController.text = userData.height.toString();
            }
            if (userData.weight != null) {
              _weightController.text = userData.weight.toString();
            }
            if (userData.preferredLanguage != null) {
              _preferredLanguage = userData.preferredLanguage!;
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Get existing user data or create new model
        UserModel updatedUser = _currentUser ?? UserModel(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          createdAt: DateTime.now(),
        );

        // Allergies are already stored in _allergiesList, no need to process from text

        // Update with form data
        updatedUser = updatedUser.copyWith(
          age: _ageController.text.isNotEmpty ? int.parse(_ageController.text) : null,
          gender: _selectedGender,
          allergies: _allergiesList.isNotEmpty ? _allergiesList : null,
          medicalHistory: _medicalHistoryController.text,
          height: _heightController.text.isNotEmpty ? double.parse(_heightController.text) : null,
          weight: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
          preferredLanguage: _preferredLanguage,
          updatedAt: DateTime.now(),
        );

        // Save to Firestore
        await _authService.updateUserProfile(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          
          // Navigate to home screen
          Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to update profile: ${e.toString()}';
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

  // Add a new allergy to the list
  void _addAllergy() {
    final newAllergy = _newAllergyController.text.trim();
    if (newAllergy.isNotEmpty && !_allergiesList.contains(newAllergy)) {
      setState(() {
        _allergiesList.add(newAllergy);
        _newAllergyController.clear();
      });
    }
  }

  // Remove an allergy from the list
  void _removeAllergy(String allergy) {
    setState(() {
      _allergiesList.remove(allergy);
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _medicalHistoryController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _newAllergyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
      ),
      body: _isLoading && _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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

                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This information helps us provide better health recommendations. All data is kept private and secure.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Age field
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.calendar_today),
                          hintText: 'Enter your age',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final age = int.tryParse(value);
                            if (age == null) {
                              return 'Please enter a valid number';
                            }
                            if (age < 0 || age > 120) {
                              return 'Please enter a valid age';
                            }
                          }
                          return null; // Age is optional
                        },
                      ),
                      const SizedBox(height: 16),

                      // Gender dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: _genderOptions.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedGender = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Height field
                      TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          prefixIcon: Icon(Icons.height),
                          hintText: 'Enter your height in centimeters',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final height = double.tryParse(value);
                            if (height == null) {
                              return 'Please enter a valid number';
                            }
                            if (height < 50 || height > 250) {
                              return 'Please enter a valid height';
                            }
                          }
                          return null; // Height is optional
                        },
                      ),
                      const SizedBox(height: 16),

                      // Weight field
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                          hintText: 'Enter your weight in kilograms',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final weight = double.tryParse(value);
                            if (weight == null) {
                              return 'Please enter a valid number';
                            }
                            if (weight < 1 || weight > 500) {
                              return 'Please enter a valid weight';
                            }
                          }
                          return null; // Weight is optional
                        },
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Medical Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Allergies input section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Allergies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _newAllergyController,
                                  keyboardType: TextInputType.text,
                                  decoration: const InputDecoration(
                                    hintText: 'Add an allergy',
                                    prefixIcon: Icon(Icons.health_and_safety_outlined),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  ),
                                  onFieldSubmitted: (_) => _addAllergy(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _addAllergy,
                                icon: const Icon(Icons.add_circle),
                                color: Theme.of(context).primaryColor,
                                tooltip: 'Add allergy',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allergiesList.map((allergy) {
                              return Chip(
                                label: Text(allergy),
                                deleteIcon: const Icon(Icons.cancel, size: 18),
                                onDeleted: () => _removeAllergy(allergy),
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Medical history field
                      TextFormField(
                        controller: _medicalHistoryController,
                        keyboardType: TextInputType.text,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Medical History',
                          prefixIcon: Icon(Icons.history),
                          hintText: 'Any relevant medical conditions (optional)',
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Preferences',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Language preference
                      DropdownButtonFormField<String>(
                        value: _preferredLanguage,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Language',
                          prefixIcon: Icon(Icons.language),
                        ),
                        items: _languageOptions.map((language) {
                          return DropdownMenuItem(
                            value: language,
                            child: Text(language),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _preferredLanguage = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Profile'),
                      ),
                      const SizedBox(height: 16),

                      // Skip button
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pushReplacementNamed(
                                  AppConstants.homeRoute,
                                );
                              },
                        child: const Text('Skip for now'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}