import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_logger.dart';

/// A comprehensive feedback widget for user feedback and bug reports
/// 
/// Features:
/// - Multiple feedback categories (Bug Report, Feature Request, General Feedback)
/// - User information collection (Name, Email)
/// - Optional log file attachment
/// - Automatic system information collection
/// - Email composition using mailto
/// - In-app feedback submission without leaving the app
class FeedbackWidget extends StatefulWidget {
  const FeedbackWidget({super.key});

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _feedbackController = TextEditingController();
  
  // Form state
  String _selectedCategory = 'Bug Report';
  bool _includeLogs = true;
  bool _isLoading = false;
  String? _exportedLogPath;
  List<File> _attachedScreenshots = [];
  
  // Email configuration
  static const String _developerEmail = 'quadbitlab@gmail.com';
  
  // Telegram Bot Configuration
  static const String _telegramBotToken = '8465375001:AAGHKG7HzG3UYipW19utNPiHUYdwIIXXKb0';
  static const String _telegramChannelId = '-1002618985489';
  
  // Categories
  final List<String> _categories = [
    'Bug Report',
    'Feature Request',
    'General Feedback',
    'Performance Issue',
    'UI/UX Feedback',
    'Crash Report',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  /// Collect device and app information for debugging
  Future<Map<String, String>> _collectSystemInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      Map<String, String> systemInfo = {
        'App Name': packageInfo.appName,
        'Version': '${packageInfo.version}+${packageInfo.buildNumber}',
        'Package': packageInfo.packageName,
        'Platform': Platform.operatingSystem,
        'Platform Version': Platform.operatingSystemVersion,
      };
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        systemInfo.addAll({
          'Device': '${androidInfo.manufacturer} ${androidInfo.model}',
          'Android Version': 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})',
          'Brand': androidInfo.brand,
          'Hardware': androidInfo.hardware,
          'Supported ABIs': androidInfo.supportedAbis.join(', '),
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        systemInfo.addAll({
          'Device': '${iosInfo.name} (${iosInfo.model})',
          'iOS Version': '${iosInfo.systemName} ${iosInfo.systemVersion}',
          'Device Model': iosInfo.utsname.machine,
        });
      }
      
      return systemInfo;
    } catch (e) {
      await AppLogger.instance.error('Failed to collect system info: $e', context: 'FeedbackWidget._collectSystemInfo');
      return {
        'Error': 'Failed to collect system information',
        'Platform': Platform.operatingSystem,
      };
    }
  }

  /// Prepare logs for attachment if requested
  Future<void> _prepareLogs() async {
    if (!_includeLogs) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      _exportedLogPath = await AppLogger.instance.exportLogsToFile();
      
      await AppLogger.instance.info('Log file prepared for feedback: $_exportedLogPath', context: 'FeedbackWidget._prepareLogs');
    } catch (e) {
      await AppLogger.instance.error('Failed to prepare logs for feedback: $e', context: 'FeedbackWidget._prepareLogs');
      _exportedLogPath = null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Pick screenshots from device gallery
  Future<void> _pickScreenshots() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        dialogTitle: 'Select Screenshots',
      );

      if (result != null && result.files.isNotEmpty) {
        final newScreenshots = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        setState(() {
          _attachedScreenshots.addAll(newScreenshots);
        });

        _showSnackBar(
          'Added ${newScreenshots.length} screenshot(s). Total: ${_attachedScreenshots.length}',
          Colors.green,
        );

        await AppLogger.instance.info(
          'Screenshots added to feedback: ${newScreenshots.length} files',
          context: 'FeedbackWidget._pickScreenshots'
        );
      }
    } catch (e, stackTrace) {
      await AppLogger.instance.error(
        'Failed to pick screenshots: $e',
        stackTrace: stackTrace,
        context: 'FeedbackWidget._pickScreenshots'
      );
      _showSnackBar('Failed to pick screenshots: $e', Colors.red);
    }
  }

  /// Remove a specific screenshot
  void _removeScreenshot(int index) {
    setState(() {
      final removedFile = _attachedScreenshots.removeAt(index);
      _showSnackBar(
        'Screenshot removed: ${removedFile.path.split('/').last}',
        Colors.orange,
      );
    });
  }

  /// Check if user information is mandatory for the selected category
  bool _isUserInfoMandatory() {
    return ['Bug Report', 'Performance Issue', 'Crash Report'].contains(_selectedCategory);
  }

  /// Compose email body with feedback and system information
  Future<String> _composeEmailBody() async {
    final systemInfo = await _collectSystemInfo();
    final timestamp = DateTime.now().toIso8601String();
    
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Subtitle Studio - ${_selectedCategory}');
    buffer.writeln('Submitted: $timestamp');
    buffer.writeln('${'-' * 50}');
    buffer.writeln();
    
    // User Information
    if (_nameController.text.isNotEmpty) {
      buffer.writeln('User Name: ${_nameController.text}');
    }
    if (_emailController.text.isNotEmpty) {
      buffer.writeln('User Email: ${_emailController.text}');
    }
    buffer.writeln();
    
    // Feedback Content
    buffer.writeln('Category: $_selectedCategory');
    buffer.writeln();
    buffer.writeln('Feedback:');
    buffer.writeln(_feedbackController.text);
    buffer.writeln();
    
    // System Information
    buffer.writeln('${'-' * 50}');
    buffer.writeln('SYSTEM INFORMATION');
    buffer.writeln('${'-' * 50}');
    
    for (final entry in systemInfo.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    
    // Log information
    if (_includeLogs && _exportedLogPath != null) {
      buffer.writeln();
      buffer.writeln('${'-' * 50}');
      buffer.writeln('LOG INFORMATION');
      buffer.writeln('${'-' * 50}');
      buffer.writeln('Log file attached: ${_exportedLogPath!.split('/').last}');
      buffer.writeln('Log file path: $_exportedLogPath');
      
      try {
        final logStats = await AppLogger.instance.getLogStats();
        buffer.writeln('Total log files: ${logStats['totalFiles'] ?? 'Unknown'}');
        buffer.writeln('Total log size: ${logStats['totalSizeReadable'] ?? 'Unknown'}');
        if (logStats['newestLog'] != null) {
          buffer.writeln('Latest log: ${DateTime.parse(logStats['newestLog']).toLocal()}');
        }
      } catch (e) {
        buffer.writeln('Note: Could not retrieve log statistics');
      }
    }

    // Screenshot information
    if (_attachedScreenshots.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${'-' * 50}');
      buffer.writeln('SCREENSHOTS ATTACHED');
      buffer.writeln('${'-' * 50}');
      for (int i = 0; i < _attachedScreenshots.length; i++) {
        final screenshot = _attachedScreenshots[i];
        buffer.writeln('${i + 1}. ${screenshot.path.split('/').last}');
      }
      buffer.writeln('Total screenshots: ${_attachedScreenshots.length}');
    }
    
    return buffer.toString();
  }

  /// Send feedback via email or share with attachments
  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackBar('Please enter your feedback', Colors.red);
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Prepare logs if needed
      if (_includeLogs) {
        await _prepareLogs();
      }
      
      // Compose email
      final emailBody = await _composeEmailBody();
      
      // Check if we have attachments (logs or screenshots)
      final hasAttachments = (_includeLogs && _exportedLogPath != null) || _attachedScreenshots.isNotEmpty;
      
      if (hasAttachments) {
        // Use share method for attachments (more reliable)
        await _shareWithAttachments(emailBody);
      } else {
        // Use mailto for text-only feedback (opens email client directly)
        await _sendViaEmail(emailBody);
      }
    } catch (e, stackTrace) {
      await AppLogger.instance.error('Failed to send feedback: $e', stackTrace: stackTrace, context: 'FeedbackWidget._sendFeedback');
      
      // Try share as final fallback
      try {
        final emailBody = await _composeEmailBody();
        await _shareWithAttachments(emailBody);
      } catch (shareError) {
        _showSnackBar('Failed to send feedback: $e', Colors.red);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Send feedback directly to Telegram channel
  Future<void> _sendToTelegram() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackBar('Please enter your feedback', Colors.red);
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Prepare logs if needed
      if (_includeLogs) {
        await _prepareLogs();
      }
      
      // Collect system information
      final systemInfo = await _collectSystemInfo();
      final timestamp = DateTime.now().toLocal();
      
      // Create stylized message
      final message = await _createTelegramMessage(systemInfo, timestamp);
      
      // Prepare files for upload
      final files = <File>[];
      if (_includeLogs && _exportedLogPath != null) {
        files.add(File(_exportedLogPath!));
      }
      files.addAll(_attachedScreenshots);
      
      if (files.isNotEmpty) {
        // Send with attachments
        await _sendTelegramWithFiles(message, files);
      } else {
        // Send text only
        await _sendTelegramMessage(message);
      }
      
      _showSnackBar('Feedback sent to developer successfully!', Colors.green, duration: 5);
      _clearForm();
      
    } catch (e, stackTrace) {
      await AppLogger.instance.error('Failed to send feedback to Telegram: $e', stackTrace: stackTrace, context: 'FeedbackWidget._sendToTelegram');
      _showSnackBar('Failed to send feedback: $e', Colors.red, duration: 5);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Create stylized Telegram message
  Future<String> _createTelegramMessage(Map<String, String> systemInfo, DateTime timestamp) async {
    final categoryEmoji = _getCategoryEmoji(_selectedCategory);
    final buffer = StringBuffer();
    
    // Header with emoji and category
    buffer.writeln('$categoryEmoji <b>Subtitle Studio - $_selectedCategory</b>');
    buffer.writeln();
    
    // Timestamp
    buffer.writeln('📅 <b>Submitted:</b> ${timestamp.toString().split('.').first}');
    buffer.writeln();
    
    // User Information (if provided)
    if (_nameController.text.isNotEmpty || _emailController.text.isNotEmpty) {
      buffer.writeln('👤 <b>User Information:</b>');
      if (_nameController.text.isNotEmpty) {
        buffer.writeln('  • Name: ${_nameController.text}');
      }
      if (_emailController.text.isNotEmpty) {
        buffer.writeln('  • Email: ${_emailController.text}');
      }
      buffer.writeln();
    }
    
    // Feedback Content
    buffer.writeln('💬 <b>Feedback:</b>');
    buffer.writeln(_feedbackController.text);
    buffer.writeln();
    
    // System Information
    buffer.writeln('📱 <b>System Information:</b>');
    buffer.writeln('  • App: ${systemInfo['App Name']} v${systemInfo['Version']}');
    buffer.writeln('  • Platform: ${systemInfo['Platform']} ${systemInfo['Platform Version']}');
    if (systemInfo['Device'] != null) {
      buffer.writeln('  • Device: ${systemInfo['Device']}');
    }
    if (systemInfo['Android Version'] != null) {
      buffer.writeln('  • OS: ${systemInfo['Android Version']}');
    } else if (systemInfo['iOS Version'] != null) {
      buffer.writeln('  • OS: ${systemInfo['iOS Version']}');
    }
    buffer.writeln();
    
    // Attachments info
    if (_includeLogs || _attachedScreenshots.isNotEmpty) {
      buffer.writeln('📎 <b>Attachments:</b>');
      if (_includeLogs && _exportedLogPath != null) {
        buffer.writeln('  • Log file: ${_exportedLogPath!.split('/').last}');
      }
      if (_attachedScreenshots.isNotEmpty) {
        buffer.writeln('  • Screenshots: ${_attachedScreenshots.length} file(s)');
      }
      buffer.writeln();
    }
    
    // Hashtags for categorization
    buffer.writeln('#${_selectedCategory.replaceAll(' ', '')} #MSoneSubEditor #Feedback');
    
    return buffer.toString();
  }

  /// Get emoji for feedback category
  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Bug Report':
        return '🐛';
      case 'Feature Request':
        return '💡';
      case 'General Feedback':
        return '💬';
      case 'Performance Issue':
        return '⚡';
      case 'UI/UX Feedback':
        return '🎨';
      case 'Crash Report':
        return '💥';
      default:
        return '📝';
    }
  }

  /// Send text-only message to Telegram
  Future<void> _sendTelegramMessage(String message) async {
    final uri = Uri.parse('https://api.telegram.org/bot$_telegramBotToken/sendMessage');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'chat_id': _telegramChannelId,
        'text': message,
        'parse_mode': 'HTML',
      }),
    );

    if (response.statusCode != 200) {
      final responseData = json.decode(response.body);
      throw Exception('Telegram API error: ${responseData['description'] ?? 'Unknown error'}');
    }
  }

  /// Send message with files to Telegram
  Future<void> _sendTelegramWithFiles(String message, List<File> files) async {
    if (files.length == 1) {
      // Send single file with caption
      await _sendSingleFileToTelegram(message, files.first);
    } else {
      // Send message first, then files
      await _sendTelegramMessage(message);
      
      // Send each file separately
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = file.path.split('/').last;
        final caption = 'Attachment ${i + 1}/${files.length}: $fileName';
        await _sendSingleFileToTelegram(caption, file);
      }
    }
  }

  /// Send single file to Telegram
  Future<void> _sendSingleFileToTelegram(String caption, File file) async {
    final uri = Uri.parse('https://api.telegram.org/bot$_telegramBotToken/sendDocument');
    
    final request = http.MultipartRequest('POST', uri);
    request.fields['chat_id'] = _telegramChannelId;
    request.fields['caption'] = caption;
    request.fields['parse_mode'] = 'HTML';
    
    request.files.add(await http.MultipartFile.fromPath(
      'document',
      file.path,
      filename: file.path.split('/').last,
    ));

    final response = await request.send();
    
    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      final responseData = json.decode(responseBody);
      throw Exception('Telegram API error: ${responseData['description'] ?? 'Unknown error'}');
    }
  }

  /// Send via email client (for text-only feedback)
  Future<void> _sendViaEmail(String emailBody) async {
    try {
      // Create mailto URL with developer email pre-filled
      final subject = Uri.encodeComponent('Subtitle Studio - $_selectedCategory');
      final body = Uri.encodeComponent(emailBody);
      
      // Try different mailto URL formats for better compatibility
      final mailtoUrl = 'mailto:$_developerEmail?subject=$subject&body=$body';
      
      final uri = Uri.parse(mailtoUrl);
      
      // Try to launch with different modes for better compatibility
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        // Try with platform default mode if external application fails
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      
      if (launched) {
        // Log the feedback submission
        await AppLogger.instance.info(
          'Feedback submitted via email - Category: $_selectedCategory, Include Logs: $_includeLogs, Screenshots: ${_attachedScreenshots.length}',
          context: 'FeedbackWidget._sendFeedback'
        );
        
        // Show detailed success message
        _showSnackBar(
          'Email opened successfully!',
          Colors.green,
          duration: 5,
        );
        _clearForm();
      } else {
        // Fallback to share if email client is not available
        await _shareWithAttachments(emailBody);
      }
    } catch (e) {
      // Fallback to share method
      await _shareWithAttachments(emailBody);
    }
  }

  /// Share with attachments (recommended method for files)
  Future<void> _shareWithAttachments(String emailBody) async {
    try {
      final files = <XFile>[];
      
      // Add log file if available
      if (_includeLogs && _exportedLogPath != null) {
        files.add(XFile(_exportedLogPath!));
      }

      // Add screenshots if available
      for (final screenshot in _attachedScreenshots) {
        files.add(XFile(screenshot.path));
      }
      
      // Prepare email content with recipient information
      final emailContent = '''To: $_developerEmail
Subject: Subtitle Studio - $_selectedCategory

$emailBody''';
      
      // Share with files if available, otherwise just text
      if (files.isNotEmpty) {
        await Share.shareXFiles(
          files,
          text: emailContent,
          subject: 'Subtitle Studio - $_selectedCategory',
        );
        
        // Log the feedback submission
        await AppLogger.instance.info(
          'Feedback shared with attachments - Category: $_selectedCategory, Include Logs: $_includeLogs, Screenshots: ${_attachedScreenshots.length}',
          context: 'FeedbackWidget._shareWithAttachments'
        );
        
        _showSnackBar(
          'Feedback shared with ${files.length} attachment(s)!',
          Colors.green,
          duration: 6,
        );
      } else {
        await Share.share(
          emailContent,
          subject: 'Subtitle Studio - $_selectedCategory',
        );
        
        _showSnackBar('Feedback shared successfully!', Colors.green);
      }
      
      _clearForm();
    } catch (e) {
      _showSnackBar('Failed to share feedback: $e', Colors.red);
    }
  }

  /// Clear the form after successful submission
  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _feedbackController.clear();
    setState(() {
      _selectedCategory = 'Bug Report';
      _includeLogs = true;
      _exportedLogPath = null;
      _attachedScreenshots.clear();
    });
  }

  /// Show SnackBar that works properly in modal sheets
  void _showSnackBar(String message, Color backgroundColor, {int duration = 4}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  backgroundColor == Colors.red ? Icons.error : 
                  backgroundColor == Colors.green ? Icons.check_circle :
                  backgroundColor == Colors.orange ? Icons.warning :
                  Icons.info,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(Duration(seconds: duration), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Send Feedback',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve Subtitle Studio by sharing your feedback, reporting bugs, or suggesting new features.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Loading indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            
            if (!_isLoading) ...[
              // Category Selection
              Text(
                'Category *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(category),
                              size: 20,
                              color: _getCategoryColor(category),
                            ),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        // Clear validation errors when category changes
                        _formKey.currentState?.validate();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // User Information Section
              Text(
                _isUserInfoMandatory() 
                  ? 'Your Information (Required for this category)'
                  : 'Your Information (Optional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _isUserInfoMandatory() ? 'Your Name *' : 'Your Name',
                  hintText: _isUserInfoMandatory() 
                    ? 'Enter your name (required for bug reports)'
                    : 'Enter your name (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                textInputAction: TextInputAction.next,
                validator: _isUserInfoMandatory() ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required for ${_selectedCategory.toLowerCase()}';
                  }
                  return null;
                } : null,
              ),
              const SizedBox(height: 12),
              
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: _isUserInfoMandatory() ? 'Your Email *' : 'Your Email',
                  hintText: _isUserInfoMandatory()
                    ? 'Enter your email (required for bug reports)'
                    : 'Enter your email (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (_isUserInfoMandatory()) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required for ${_selectedCategory.toLowerCase()}';
                    }
                  }
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Feedback Content
              Text(
                'Your Feedback *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  hintText: _getFeedbackHint(),
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your feedback';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more detailed feedback (at least 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Log inclusion option
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _includeLogs,
                      onChanged: (value) {
                        setState(() {
                          _includeLogs = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Include Log Files',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Include app logs to help developers diagnose issues (recommended for bug reports)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Screenshots section
              Text(
                'Screenshots (Optional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Add screenshots to help explain the issue or show what you\'re referring to',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _pickScreenshots,
                          icon: const Icon(Icons.add_a_photo, size: 18),
                          label: const Text('Add Screenshots'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange[700],
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    if (_attachedScreenshots.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attached Screenshots (${_attachedScreenshots.length}):',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(_attachedScreenshots.length, (index) {
                              final screenshot = _attachedScreenshots[index];
                              final fileName = screenshot.path.split('/').last;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.image, size: 16, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeScreenshot(index),
                                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      color: Colors.red[600],
                                      tooltip: 'Remove screenshot',
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Developer Contact Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send feedback to:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _developerEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          await Clipboard.setData(ClipboardData(text: _developerEmail));
                          _showSnackBar('Email copied to clipboard!', Colors.green);
                        } catch (e) {
                          _showSnackBar('Failed to copy email', Colors.red);
                        }
                      },
                      icon: Icon(Icons.copy, color: Colors.blue[700], size: 18),
                      tooltip: 'Copy email address',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Send to Telegram button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendToTelegram,
                  icon: const Icon(Icons.telegram),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Email button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendFeedback,
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use "Send" to report directly to the developer via Telegram. Use "Email" to share via your email app. You can copy the email address above if needed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get appropriate icon for feedback category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Bug Report':
        return Icons.bug_report;
      case 'Feature Request':
        return Icons.lightbulb_outline;
      case 'General Feedback':
        return Icons.feedback;
      case 'Performance Issue':
        return Icons.speed;
      case 'UI/UX Feedback':
        return Icons.design_services;
      case 'Crash Report':
        return Icons.error_outline;
      default:
        return Icons.feedback;
    }
  }

  /// Get appropriate color for feedback category
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bug Report':
        return Colors.red;
      case 'Feature Request':
        return Colors.green;
      case 'General Feedback':
        return Colors.blue;
      case 'Performance Issue':
        return Colors.orange;
      case 'UI/UX Feedback':
        return Colors.purple;
      case 'Crash Report':
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }

  /// Get appropriate hint text for feedback based on category
  String _getFeedbackHint() {
    switch (_selectedCategory) {
      case 'Bug Report':
        return 'Describe the bug you encountered. Include steps to reproduce the issue, what you expected to happen, and what actually happened.';
      case 'Feature Request':
        return 'Describe the feature you would like to see added. Explain how it would improve your experience with the app.';
      case 'General Feedback':
        return 'Share your thoughts about the app. What do you like? What could be improved?';
      case 'Performance Issue':
        return 'Describe the performance issue you experienced. When does it occur? How does it affect your usage?';
      case 'UI/UX Feedback':
        return 'Share your thoughts about the user interface and user experience. What works well? What could be improved?';
      case 'Crash Report':
        return 'Describe what you were doing when the app crashed. Include any error messages you saw.';
      default:
        return 'Enter your feedback here...';
    }
  }
}
