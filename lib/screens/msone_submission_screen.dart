import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class MsoneSubmissionScreen extends StatefulWidget {
  final String submissionType; // 'main' or 'fresher'
  final int subtitleCollectionId;

  const MsoneSubmissionScreen({
    super.key,
    required this.submissionType,
    required this.subtitleCollectionId,
  });

  @override
  State<MsoneSubmissionScreen> createState() => _MsoneSubmissionScreenState();
}

class _MsoneSubmissionScreenState extends State<MsoneSubmissionScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form keys for validation
  final GlobalKey<FormState> _translatorFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _movieFormKey = GlobalKey<FormState>();
  
  // Form controllers for step 1 (Translator Info)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactIdController = TextEditingController();
  bool _saveForFuture = false;
  
  // Form controllers for step 2 (Movie Info)
  final TextEditingController _movieNameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _torrentInfoController = TextEditingController();
  final TextEditingController _imdbLinkController = TextEditingController();
  final TextEditingController _synopsisController = TextEditingController();

  // File selection state for step 3
  String? _translatedSubtitlePath;
  String? _translatedSubtitleSafUri; // SAF URI for Android file reading
  String? _originalSubtitlePath;
  String? _originalSubtitleSafUri; // SAF URI for Android file reading
  String? _msoneFilePath; // Path to .msone project file
  String? _msoneFileSafUri; // SAF URI for .msone file on Android
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _contactIdController.dispose();
    _movieNameController.dispose();
    _yearController.dispose();
    _torrentInfoController.dispose();
    _imdbLinkController.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final name = await PreferencesModel.getTranslatorName();
    final email = await PreferencesModel.getTranslatorEmail();
    final contactId = await PreferencesModel.getTranslatorContactId();
    
    if (mounted) {
      setState(() {
        _nameController.text = name ?? '';
        _emailController.text = email ?? '';
        _contactIdController.text = contactId ?? '';
      });
    }
  }

  Future<void> _saveTranslatorData() async {
    if (_saveForFuture) {
      await PreferencesModel.setTranslatorName(_nameController.text);
      await PreferencesModel.setTranslatorEmail(_emailController.text);
      await PreferencesModel.setTranslatorContactId(_contactIdController.text);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Year is required';
    }
    final year = int.tryParse(value);
    if (year == null || year < 1800 || year > DateTime.now().year + 5) {
      return 'Please enter a valid year';
    }
    return null;
  }

  String? _validateImdbLink(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IMDB link is required';
    }
    if (!RegExp(r'^https?://(www\.|m\.)?imdb\.com/title/tt\d+/?.*$').hasMatch(value)) {
      return 'Please enter a valid IMDB link';
    }
    return null;
  }

  Future<void> _selectFile(String fileType) async {
    try {
      // No permissions needed when using SAF (Storage Access Framework)
      final fileInfo = await FilePickerSAF.pickFileWithInfo(
        context: context,
        title: 'Select ${fileType.capitalize()} Subtitle File',
        allowedExtensions: ['.srt', '.vtt', '.ass', '.sub', '.txt'],
      );
      
      if (fileInfo != null) {
        final displayPath = fileInfo['displayPath'];
        final safUri = fileInfo['safUri'];
        
        setState(() {
          if (fileType == 'translated') {
            _translatedSubtitlePath = displayPath;
            _translatedSubtitleSafUri = safUri;
            // Clear .msone file when individual files are selected
            _msoneFilePath = null;
            _msoneFileSafUri = null;
          } else if (fileType == 'original') {
            _originalSubtitlePath = displayPath;
            _originalSubtitleSafUri = safUri;
            // Clear .msone file when individual files are selected
            _msoneFilePath = null;
            _msoneFileSafUri = null;
          }
        });
        
        // Debug print to verify file paths are set
        
        SnackbarHelper.showSuccess(
          context,
          '${fileType.capitalize()} subtitle file selected successfully',
        );
      }
    } catch (e) {
      SnackbarHelper.showError(
        context,
        'Error selecting file: $e',
      );
    }
  }

  Future<void> _selectMsoneFile() async {
    try {
      // No permissions needed when using SAF (Storage Access Framework)
      final fileInfo = await FilePickerSAF.pickFileWithInfo(
        context: context,
        title: 'Select Msone Project File',
        allowedExtensions: ['.msone'],
      );
      
      if (fileInfo != null) {
        final displayPath = fileInfo['displayPath'];
        final safUri = fileInfo['safUri'];
        
        setState(() {
          _msoneFilePath = displayPath;
          _msoneFileSafUri = safUri;
          // Clear individual files when .msone is selected
          _translatedSubtitlePath = null;
          _translatedSubtitleSafUri = null;
          _originalSubtitlePath = null;
          _originalSubtitleSafUri = null;
        });
        
        // Debug print to verify file paths are set
        
        SnackbarHelper.showSuccess(
          context,
          'Msone project file selected successfully',
        );
      }
    } catch (e) {
      SnackbarHelper.showError(
        context,
        'Error selecting Msone file: $e',
      );
    }
  }

  /// Read file content using SAF URI on Android or file path on other platforms
  Future<Uint8List?> _readFileContent(String? filePath, String? safUri) async {
    if (Platform.isAndroid && safUri != null) {
      // Use SAF URI on Android
      try {
        final methodChannel = const MethodChannel('org.malayalamsubtitles.studio/intent');
        final bytes = await methodChannel.invokeMethod<Uint8List>('readFileFromContentUri', {
          'uri': safUri,
        });
        return bytes;
      } on PlatformException catch (e) {
        throw Exception('Failed to read file via SAF: ${e.message}');
      }
    } else if (filePath != null) {
      // Use traditional file path on other platforms
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        throw Exception('File not found: $filePath');
      }
    } else {
      throw Exception('No file path or SAF URI available');
    }
  }

  Future<void> _submitToMsone() async {
    // Debug prints for troubleshooting
    
    if (!_canSubmit()) {
      // Check which specific validation is failing
      final step0Valid = _translatorFormKey.currentState?.validate() ?? false;
      final step1Valid = _movieFormKey.currentState?.validate() ?? false;
      final step2Valid = (_msoneFilePath != null) || (_translatedSubtitlePath != null && _originalSubtitlePath != null);
      
      String errorMessage = 'Please complete all required fields:\n';
      if (!step0Valid) errorMessage += '• Translator information\n';
      if (!step1Valid) errorMessage += '• Movie information\n';
      if (!step2Valid) errorMessage += '• Either a .msone project file OR both translated and original subtitle files';
      
      SnackbarHelper.showError(
        context,
        errorMessage,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save translator data if checkbox is checked
      await _saveTranslatorData();
      
      // Prepare files for submission as attachments
      final files = <Map<String, String>>[];
      
      if (_msoneFilePath != null) {
        // Msone file submission mode - submit only .msone file
        final msoneBytes = await _readFileContent(_msoneFilePath, _msoneFileSafUri);
        if (msoneBytes != null) {
          final fileName = path.basename(_msoneFilePath!);
          files.add({
            'name': fileName,
            'data': base64Encode(msoneBytes),
          });
        }
      } else {
        // Individual files submission mode - submit translated + original files
        // Read and encode translated subtitle file
        if (_translatedSubtitlePath != null) {
          final translatedBytes = await _readFileContent(_translatedSubtitlePath, _translatedSubtitleSafUri);
          if (translatedBytes != null) {
            final fileName = path.basename(_translatedSubtitlePath!);
            files.add({
              'name': fileName,
              'data': base64Encode(translatedBytes),
            });
          }
        }
        
        // Read and encode original subtitle file
        if (_originalSubtitlePath != null) {
          final originalBytes = await _readFileContent(_originalSubtitlePath, _originalSubtitleSafUri);
          if (originalBytes != null) {
            final fileName = path.basename(_originalSubtitlePath!);
            files.add({
              'name': fileName,
              'data': base64Encode(originalBytes),
            });
          }
        }
      }

      // Determine mail type based on submission type
      final mailType = widget.submissionType == 'main' ? 'main' : 'fresher';
      
      // Prepare submission data according to API format
      final submissionData = {
        'to': mailType,
        'subject': '${_movieNameController.text} (${_yearController.text})',
        'message': '<b>Movie Name:</b> ${_movieNameController.text} ${_yearController.text}<br>'
                   '<b>Translator Name:</b> ${_nameController.text}<br>'
                   '<b>Email:</b> ${_emailController.text}<br>'
                   '<b>Telegram ID:</b> ${_contactIdController.text}<br>'
                   '<b>Torrent Info:</b> ${_torrentInfoController.text}<br>'
                   '<b>IMDB Link:</b> ${_imdbLinkController.text}<br>'
                   '<b>Synopsis:</b> <p>${_synopsisController.text}</p><br><br>'
                   'Submitted from <i><b>Subtitle Studio</b></i>',
        'headers': ['Content-Type: text/html; charset=UTF-8'],
        'attachments': files,
      };      // Debug print the data being sent
      
      // Submit to API
      final response = await http.post(
        Uri.parse('https://malayalamsubtitles.org/wp-json/msone-app/v1/send-email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(submissionData),
      );
      
      // Debug print the response

      if (response.statusCode == 200) {
        setState(() {
          _isSubmitting = false;
        });
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submission Successful',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your submission has been sent to Msone successfully!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Close submission screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'OK',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      SnackbarHelper.showError(
        context,
        'Submission failed: $e',
      );
    }
  }

  bool _canSubmit() {
    // Don't validate forms here to avoid side effects, just check if forms can be validated
    // and files are selected
    final step0Valid = _nameController.text.trim().isNotEmpty && 
                      _emailController.text.trim().isNotEmpty && 
                      _contactIdController.text.trim().isNotEmpty &&
                      _validateEmail(_emailController.text) == null;
    
    final step1Valid = _movieNameController.text.trim().isNotEmpty && 
                      _yearController.text.trim().isNotEmpty && 
                      _torrentInfoController.text.trim().isNotEmpty && 
                      _imdbLinkController.text.trim().isNotEmpty &&
                      _synopsisController.text.trim().isNotEmpty &&
                      _validateYear(_yearController.text) == null &&
                      _validateImdbLink(_imdbLinkController.text) == null;
    
    // Step 2: Files validation - either .msone file OR both translated and original files
    final step2Valid = (_msoneFilePath != null) || 
                       (_translatedSubtitlePath != null && _originalSubtitlePath != null);
    
    return step0Valid && step1Valid && step2Valid;
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0:
        return _translatorFormKey.currentState?.validate() ?? false;
      case 1:
        return _movieFormKey.currentState?.validate() ?? false;
      case 2:
        return _translatedSubtitlePath != null && _originalSubtitlePath != null;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_canProceedFromStep(_currentStep)) {
        if (_currentStep == 0) {
          _saveTranslatorData();
        }
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        String errorMessage;
        if (_currentStep == 0 || _currentStep == 1) {
          errorMessage = 'Please fill in all required fields';
        } else {
          errorMessage = 'Please select both translated and original subtitle files';
        }
        
        SnackbarHelper.showWarning(
          context,
          errorMessage,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit to Msone - ${widget.submissionType == 'main' ? 'Existing Translator' : 'Fresher'}',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red, fontSize: 16),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 2,
        shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.1),
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Enhanced Progress indicator with labels
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  Theme.of(context).primaryColor.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= _currentStep 
                              ? Theme.of(context).primaryColor 
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: i <= _currentStep ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStepLabel('Translator Info', 0),
                    _buildStepLabel('Movie Info', 1),
                    _buildStepLabel('File Selection', 2),
                  ],
                ),
              ],
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTranslatorInfoStep(),
                _buildMovieInfoStep(),
                _buildFileSelectionStep(),
              ],
            ),
          ),
          
          // Enhanced Navigation buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSubmitting ? null : _previousStep,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios,
                                    size: 18,
                                    color: _isSubmitting 
                                      ? Theme.of(context).disabledColor
                                      : Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Previous',
                                    style: TextStyle(
                                      color: _isSubmitting 
                                        ? Theme.of(context).disabledColor
                                        : Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: _isSubmitting 
                            ? [
                                Theme.of(context).disabledColor,
                                Theme.of(context).disabledColor,
                              ]
                            : [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withValues(alpha: 0.8),
                              ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: !_isSubmitting ? [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSubmitting 
                            ? null 
                            : _currentStep < 2 
                              ? _nextStep 
                              : _submitToMsone,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isSubmitting)
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                else ...[
                                  Text(
                                    _currentStep < 2 ? 'Next' : 'Submit',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentStep < 2 ? Icons.arrow_forward_ios : Icons.send,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                                if (_isSubmitting) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    _currentStep < 2 ? 'Processing...' : 'Submitting...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          ],
        ),
      );
    
  }

  Widget _buildStepLabel(String label, int stepIndex) {
    final isActive = stepIndex <= _currentStep;
    final isCurrent = stepIndex == _currentStep;
    
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
        color: isActive 
          ? Theme.of(context).primaryColor 
          : Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _buildTranslatorInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _translatorFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.blue.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Translator Information',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tell us about yourself',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Form fields with enhanced styling
            _buildStyledTextField(
              controller: _nameController,
              label: 'Translator name in Malayalam',
              hint: 'Enter your name as you want it to appear',
              icon: Icons.person,
              isRequired: true,
              validator: (value) => _validateRequired(value, 'Name'),
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            
            _buildStyledTextField(
              controller: _emailController,
              label: 'E-mail',
              hint: 'your.email@example.com',
              icon: Icons.email,
              isRequired: true,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 20),
            
            _buildStyledTextField(
              controller: _contactIdController,
              label: 'Contact ID',
              hint: 'Telegram or any other contact method',
              icon: Icons.contact_phone,
              isRequired: true,
              validator: (value) => _validateRequired(value, 'Contact ID'),
              color: Colors.purple,
            ),
            const SizedBox(height: 32),
            
            // Save for future checkbox with better styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: _saveForFuture,
                      onChanged: (value) {
                        setState(() {
                          _saveForFuture = value ?? false;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save data for future use',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your information will be saved for future submissions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '* Required fields',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _movieFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.1),
                    Colors.purple.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.movie_outlined,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Movie Information',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Details about the movie',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.purple.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildStyledTextField(
              controller: _movieNameController,
              label: 'Name of the movie',
              hint: 'Enter the movie title',
              icon: Icons.movie,
              isRequired: true,
              validator: (value) => _validateRequired(value, 'Movie name'),
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            
            _buildStyledTextField(
              controller: _yearController,
              label: 'Year',
              hint: 'e.g., 2024',
              icon: Icons.calendar_today,
              isRequired: true,
              keyboardType: TextInputType.number,
              validator: _validateYear,
              color: Colors.teal,
            ),
            const SizedBox(height: 20),
            
            _buildStyledTextField(
              controller: _torrentInfoController,
              label: 'Torrent info',
              hint: 'Torrent or telegram link',
              icon: Icons.download,
              isRequired: true,
              validator: (value) => _validateRequired(value, 'Torrent info'),
              color: Colors.indigo,
            ),
            const SizedBox(height: 20),
            
            _buildStyledTextField(
              controller: _imdbLinkController,
              label: 'IMDB Link',
              hint: 'https://www.imdb.com/title/tt...',
              icon: Icons.link,
              isRequired: true,
              keyboardType: TextInputType.url,
              validator: _validateImdbLink,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 20),
            
            _buildStyledTextField(
              controller: _synopsisController,
              label: 'Synopsis',
              hint: 'Brief description of the movie in Malayalam',
              icon: Icons.description,
              isRequired: true,
              maxLines: 4,
              validator: (value) => _validateRequired(value, 'Synopsis'),
              color: Colors.green,
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '* Required fields',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: color,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildFileSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.1),
                  Colors.green.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File Selection',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose one option: Submit a .msone project file OR submit both original and translated subtitle files',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Option 1: Msone Project File
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _msoneFilePath != null 
                ? Colors.purple.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _msoneFilePath != null 
                  ? Colors.purple.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Option 1: Submit Msone Project File',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _msoneFilePath != null ? Colors.purple.shade700 : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload your complete .msone project file',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEnhancedFileSelectionButton(
                  title: 'Select Msone Project File',
                  subtitle: _msoneFilePath != null 
                    ? 'Selected: ${path.basename(_msoneFilePath!)}'
                    : 'Choose your .msone project file',
                  icon: Icons.folder_special,
                  gradientColors: [Colors.purple, Colors.purple.shade700],
                  isSelected: _msoneFilePath != null,
                  isRequired: false,
                  onTap: _selectMsoneFile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // OR Divider
          Row(
            children: [
              Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(height: 20),
          
          // Option 2: Individual Files
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_translatedSubtitlePath != null || _originalSubtitlePath != null)
                ? Colors.blue.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_translatedSubtitlePath != null || _originalSubtitlePath != null)
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Option 2: Submit Individual Subtitle Files',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: (_translatedSubtitlePath != null || _originalSubtitlePath != null)
                      ? Colors.blue.shade700 : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload both translated and original subtitle files separately',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
          
          _buildEnhancedFileSelectionButton(
            title: 'Select Translated subtitle',
            subtitle: _translatedSubtitlePath != null 
              ? 'Selected: ${path.basename(_translatedSubtitlePath!)}'
              : 'Choose the translated subtitle file (required)',
            icon: Icons.subtitles,
            gradientColors: [Colors.blue, Colors.blue.shade700],
            isSelected: _translatedSubtitlePath != null,
            isRequired: true,
            onTap: () => _selectFile('translated'),
          ),
          const SizedBox(height: 12),
          
          _buildEnhancedFileSelectionButton(
            title: 'Select original subtitle',
            subtitle: _originalSubtitlePath != null 
              ? 'Selected: ${path.basename(_originalSubtitlePath!)}'
              : 'Choose the original subtitle file (required)',
            icon: Icons.subtitles_outlined,
            gradientColors: [Colors.orange, Colors.orange.shade700],
            isSelected: _originalSubtitlePath != null,
            isRequired: true,
            onTap: () => _selectFile('original'),
          ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '* Required files',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFileSelectionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isRequired = false,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected 
              ? gradientColors.first.withValues(alpha: 0.2)
              : Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isSelected 
                ? LinearGradient(
                    colors: [
                      gradientColors.first.withValues(alpha: 0.1),
                      gradientColors.last.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
              color: !isSelected ? Theme.of(context).colorScheme.surface : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                  ? gradientColors.first.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected 
                        ? gradientColors
                        : [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            gradientColors.first,
                          ),
                        ),
                      )
                    : Icon(
                        isSelected ? Icons.check_circle : icon,
                        color: isSelected 
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                  ? gradientColors.first
                                  : null,
                              ),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ),
                          if (isRequired) ...[
                            const SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected 
                            ? gradientColors.first.withValues(alpha: 0.8)
                            : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                if (!isLoading)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
