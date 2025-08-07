import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/user_model.dart';
import 'package:medicare_plus/services/auth_service.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/utils/localization_provider.dart';
import 'package:medicare_plus/utils/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  
  String? _gender;
  String? _preferredLanguage;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  UserModel? _userModel;
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final isConnected = await connectivityService.checkConnectivity();
      
      if (!isConnected) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No internet connection. Please check your connection and try again.';
          });
        }
        return;
      }

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'You must be logged in to view your profile';
          });
        }
        return;
      }

      final userModel = await _authService.getUserData(currentUser.uid);
      
      if (mounted) {
        setState(() {
          _userModel = userModel;
          _isLoading = false;
          _populateFormFields();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile: $e';
        });
      }
    }
  }

  void _populateFormFields() {
    if (_userModel == null) return;
    
    _nameController.text = _userModel!.name ?? '';
    _emailController.text = _userModel!.email ?? '';
    _ageController.text = _userModel!.age?.toString() ?? '';
    _heightController.text = _userModel!.height?.toString() ?? '';
    _weightController.text = _userModel!.weight?.toString() ?? '';
    _allergiesController.text = _userModel!.allergies?.join(', ') ?? '';
    _medicalHistoryController.text = _userModel!.medicalHistory ?? '';
    
    setState(() {
      _gender = _userModel!.gender;
      _preferredLanguage = _userModel!.preferredLanguage;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final isConnected = await connectivityService.checkConnectivity();
      
      if (!isConnected) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'No internet connection. Please check your connection and try again.';
        });
        return;
      }

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'You must be logged in to update your profile';
        });
        return;
      }

      // Parse numeric values
      int? age;
      double? height;
      double? weight;
      
      if (_ageController.text.isNotEmpty) {
        age = int.tryParse(_ageController.text);
      }
      
      if (_heightController.text.isNotEmpty) {
        height = double.tryParse(_heightController.text);
      }
      
      if (_weightController.text.isNotEmpty) {
        weight = double.tryParse(_weightController.text);
      }

      // Update user model
      final updatedUser = UserModel(
        id: _userModel!.id,
        name: _nameController.text.trim(),
        email: _userModel!.email, // Email cannot be changed
        age: age,
        gender: _gender,
        allergies: _allergiesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        medicalHistory: _medicalHistoryController.text.trim(),
        height: height,
        weight: weight,
        preferredLanguage: _preferredLanguage,
        createdAt: _userModel!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _authService.updateUserData(updatedUser);

      // Update display name in Firebase Auth
      await _authService.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        setState(() {
          _isSaving = false;
          _userModel = updatedUser;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to update profile: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final connectivityService = Provider.of<ConnectivityService>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: StreamBuilder<bool>(
        stream: connectivityService.connectionStream,
        builder: (context, snapshot) {
          final isConnected = snapshot.data ?? true;
          
          if (!isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No internet connection',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadUserProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadUserProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
                          child: Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDarkMode ? Colors.grey[900]! : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email (disabled)
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    enabled: false, // Email cannot be changed
                  ),
                  const SizedBox(height: 16),

                  // Age
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      prefixIcon: const Icon(Icons.calendar_today),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final age = int.tryParse(value);
                        if (age == null) {
                          return 'Please enter a valid age';
                        }
                        if (age < 0 || age > 120) {
                          return 'Please enter a valid age between 0 and 120';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    items: _genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _gender = newValue;
                      });
                    },
                    hint: const Text('Select Gender'),
                  ),
                  const SizedBox(height: 24),

                  // Medical Information
                  Text(
                    'Medical Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Height
                  TextFormField(
                    controller: _heightController,
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
                      prefixIcon: const Icon(Icons.height),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final height = double.tryParse(value);
                        if (height == null) {
                          return 'Please enter a valid height';
                        }
                        if (height < 0 || height > 300) {
                          return 'Please enter a valid height between 0 and 300 cm';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Weight
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final weight = double.tryParse(value);
                        if (weight == null) {
                          return 'Please enter a valid weight';
                        }
                        if (weight < 0 || weight > 500) {
                          return 'Please enter a valid weight between 0 and 500 kg';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Allergies
                  TextFormField(
                    controller: _allergiesController,
                    decoration: InputDecoration(
                      labelText: 'Allergies',
                      prefixIcon: const Icon(Icons.health_and_safety_outlined),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      hintText: 'e.g., Peanuts, Penicillin',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Medical History
                  TextFormField(
                    controller: _medicalHistoryController,
                    decoration: InputDecoration(
                      labelText: 'Medical History',
                      prefixIcon: const Icon(Icons.medical_information_outlined),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      hintText: 'e.g., Asthma, Diabetes',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Preferences
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Preferred Language
                  DropdownButtonFormField<String>(
                    value: _preferredLanguage,
                    decoration: InputDecoration(
                      labelText: 'Preferred Language',
                      prefixIcon: const Icon(Icons.language),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    items: localizationProvider.supportedLanguages.map((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(localizationProvider.getLanguageName(language)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _preferredLanguage = newValue;
                      });
                    },
                    hint: const Text('Select Language'),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Profile'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(AppConstants.smallPadding),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Privacy Note
                  Container(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your personal information is securely stored and will only be used to improve your experience with Medicare+.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}