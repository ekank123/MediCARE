import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/services/scan_service.dart';
import 'package:medicare_plus/models/scan_model.dart';
import 'package:medicare_plus/screens/scan/scan_result_screen.dart';
import 'package:provider/provider.dart';
import 'package:medicare_plus/utils/theme_provider.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';

class EyeScanScreen extends StatefulWidget {
  const EyeScanScreen({super.key});

  @override
  State<EyeScanScreen> createState() => _EyeScanScreenState();
}

class _EyeScanScreenState extends State<EyeScanScreen> {
  final ScanService _scanService = ScanService();
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;
  bool _isConnected = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  void _checkConnectivity() {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    _isConnected = connectivityService.hasConnection;
    
    connectivityService.connectionStream.listen((hasConnection) {
      setState(() {
        _isConnected = hasConnection;
      });
    });
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null) {
          setState(() {
            _imageFile = croppedFile;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to crop image: $e';
      });
      return null;
    }
  }

  Future<void> _analyzeImage() async {
    // Validate form if no image is provided
    if (_imageFile == null && (_symptomsController.text.isEmpty || !_formKey.currentState!.validate())) {
      setState(() {
        _errorMessage = 'Please provide an image or describe your symptoms';
      });
      return;
    }

    if (!_isConnected) {
      setState(() {
        _errorMessage = 'You are offline. Please connect to the internet to analyze images.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      ScanModel? scanResult;
      
      if (_imageFile != null) {
        // Analyze with image
        scanResult = await _scanService.createEyeScan(
          userId: user.uid,
          imageFile: _imageFile!,
          symptoms: _symptomsController.text.trim(),
        );
      } else {
        // Analyze with symptoms only
        scanResult = await _scanService.createEyeScanWithoutImage(
          userId: user.uid,
          symptoms: _symptomsController.text.trim(),
        );
      }

      if (mounted && scanResult != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(scan: scanResult),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create scan. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to analyze image: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eye Scan'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message
                if (_errorMessage != null) ...[                    
                  Container(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppConstants.errorColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: AppConstants.errorColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Offline warning
                if (!_isConnected) ...[                    
                  Container(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: AppConstants.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          color: AppConstants.warningColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You are offline. Connect to the internet to analyze images.',
                            style: TextStyle(color: AppConstants.warningColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  'Take or upload a photo of your eye condition',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'For best results, ensure good lighting and focus on the affected eye',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                // Safety warning
                Container(
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  decoration: BoxDecoration(
                    color: AppConstants.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    border: Border.all(color: AppConstants.warningColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppConstants.warningColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'IMPORTANT: Never shine bright light directly into your eyes when taking photos. Use natural or ambient light only.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.warningColor,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Image preview or placeholder
                Center(
                  child: GestureDetector(
                    onTap: () => _showImageSourceOptions(context),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 60,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to add a photo',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Camera and gallery buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _getImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _getImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Symptoms description
                Text(
                  'Describe your symptoms (optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _symptomsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'E.g., Red eye, itching, discharge, blurry vision...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_imageFile == null && (value == null || value.isEmpty)) {
                      return 'Please provide symptoms if no image is uploaded';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Analyze button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _analyzeImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Analyze Condition'),
                  ),
                ),
                const SizedBox(height: 16),

                // Medical disclaimer
                Container(
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    border: Border.all(color: AppConstants.warningColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppConstants.warningColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This app provides preliminary analysis only. Always consult an ophthalmologist for proper diagnosis, especially for serious eye conditions.',
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
        ),
      ),
    );
  }

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.gallery);
                },
              ),
              if (_imageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _imageFile = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}