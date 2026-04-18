import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/utils/saf_path_converter.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/subtitle_parser.dart';
import 'package:subtitle_studio/widgets/marked_lines_sheet.dart';
import 'package:subtitle_studio/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';

class ProjectSettingsSheet extends StatefulWidget {
  final Session session;
  final SubtitleCollection subtitleCollection;
  final VoidCallback onProjectUpdated;
  final Function(List<SimpleSubtitleLine>)? onSecondarySubtitlesLoaded;
  final Function()? onSecondarySubtitlesCleared;
  final VoidCallback? onSaveProject;
  final VoidCallback? onLoadVideo; // Add callback for video loading

  const ProjectSettingsSheet({
    super.key,
    required this.session,
    required this.subtitleCollection,
    required this.onProjectUpdated,
    this.onSecondarySubtitlesLoaded,
    this.onSecondarySubtitlesCleared,
    this.onSaveProject,
    this.onLoadVideo, // Add to constructor
  });

  @override
  State<ProjectSettingsSheet> createState() => _ProjectSettingsSheetState();
}

class _ProjectSettingsSheetState extends State<ProjectSettingsSheet> with WidgetsBindingObserver {
  late TextEditingController _projectNameController;
  late TextEditingController _srtFileNameController;
  late String _selectedEncoding;
  String? _videoPath;
  String? _secondarySubtitlePath;
  bool _isSecondaryFromOriginal = false;
  bool _isLoading = true;
  Map<String, dynamic>? _sessionInfo;
  List<SubtitleLine> _markedLines = [];
  Timer? _refreshTimer;

  final List<String> _availableEncodings = [
    'UTF-8',
    'UTF-16',
    'ISO-8859-1',
    'Windows-1252',
    'ASCII',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _projectNameController = TextEditingController(text: widget.session.fileName);
    _srtFileNameController = TextEditingController(text: widget.subtitleCollection.fileName);
    _selectedEncoding = widget.subtitleCollection.encoding;
    _loadProjectData();
    
    // Start periodic refresh to detect external changes
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _stopPeriodicRefresh();
    WidgetsBinding.instance.removeObserver(this);
    _projectNameController.dispose();
    _srtFileNameController.dispose();
    super.dispose();
  }

  /// Start a timer to periodically check for external changes
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _refreshDataSilently();
      }
    });
  }

  /// Stop the periodic refresh timer
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh data when app resumes (user might have returned from file picker)
      _refreshDataSilently();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when the widget's dependencies change (like when modal regains focus)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshDataSilently();
      }
    });
  }

  /// Silently refresh data without showing loading indicator
  Future<void> _refreshDataSilently() async {
    if (!mounted) return;
    
    try {
      bool hasChanges = false;
      
      // Check video path
      final currentVideoPath = await PreferencesModel.getVideoPath(widget.session.subtitleCollectionId);
      if (currentVideoPath != _videoPath) {
        _videoPath = currentVideoPath;
        hasChanges = true;
      }
      
      // Check secondary subtitle settings
      final currentSecondaryPath = await PreferencesModel.getSecondarySubtitlePath(widget.session.subtitleCollectionId);
      final currentIsOriginal = await PreferencesModel.getSecondaryIsOriginal(widget.session.subtitleCollectionId);
      
      if (currentSecondaryPath != _secondarySubtitlePath || currentIsOriginal != _isSecondaryFromOriginal) {
        _secondarySubtitlePath = currentSecondaryPath;
        _isSecondaryFromOriginal = currentIsOriginal;
        hasChanges = true;
      }
      
      // Check session info (for project file path)
      final session = await isar.sessions.get(widget.session.id);
      if (session != null && session.projectFilePath != widget.session.projectFilePath) {
        widget.session.projectFilePath = session.projectFilePath;
        hasChanges = true;
      }
      
      // Check marked lines count (avoid loading full list unless necessary)
      final currentMarkedLines = await getMarkedSubtitleLines(widget.session.subtitleCollectionId);
      if (currentMarkedLines.length != _markedLines.length) {
        _markedLines = currentMarkedLines;
        hasChanges = true;
      }
      
      // Only trigger setState if there are actual changes
      if (hasChanges && mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently fail to avoid disrupting user experience
      if (kDebugMode) {
        print('Error silently refreshing project settings data: $e');
      }
    }
  }

  /// Public method to refresh video path from external calls
  Future<void> refreshVideoPath() async {
    await _loadVideoPath();
    // Force UI update
    if (mounted) {
      setState(() {});
    }
  }

  /// Force refresh video path with multiple attempts
  Future<void> forceRefreshVideoPath() async {
    for (int i = 0; i < 5; i++) {
      await _loadVideoPath();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Public method to refresh all project data from external calls
  Future<void> refreshAllData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Reload all data
      await _loadProjectData();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showSnackBar(
          context,
          'Error refreshing project data: $e',
          backgroundColor: Colors.red,
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

  /// Public method to refresh secondary subtitle data
  Future<void> refreshSecondarySubtitleData() async {
    if (!mounted) return;
    
    try {
      _secondarySubtitlePath = await PreferencesModel.getSecondarySubtitlePath(widget.session.subtitleCollectionId);
      _isSecondaryFromOriginal = await PreferencesModel.getSecondaryIsOriginal(widget.session.subtitleCollectionId);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showSnackBar(
          context,
          'Error refreshing secondary subtitle data: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  /// Public method to refresh session info (for project file path changes)
  Future<void> refreshSessionInfo() async {
    if (!mounted) return;
    
    try {
      // Refresh session from database
      final session = await isar.sessions.get(widget.session.id);
      if (session != null) {
        // Update the widget's session data if needed
        widget.session.projectFilePath = session.projectFilePath;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showSnackBar(
          context,
          'Error refreshing session info: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadProjectData() async {
    try {
      // Load session info
      _sessionInfo = await _getSessionInfo();
      
      // Load video path
      _videoPath = await PreferencesModel.getVideoPath(widget.session.subtitleCollectionId);
      
      // Load secondary subtitle settings
      _secondarySubtitlePath = await PreferencesModel.getSecondarySubtitlePath(widget.session.subtitleCollectionId);
      _isSecondaryFromOriginal = await PreferencesModel.getSecondaryIsOriginal(widget.session.subtitleCollectionId);
      
      // Load marked lines
      _markedLines = await getMarkedSubtitleLines(widget.session.subtitleCollectionId);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showSnackBar(
          context,
          'Error loading project data: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getSessionInfo() async {
    try {
      final subtitleLines = await fetchSubtitleLines(widget.subtitleCollection.id);
      final editedCount = subtitleLines.where((line) => line.edited != null && line.edited!.isNotEmpty).length;
      final totalLines = subtitleLines.length;
      final progress = totalLines > 0 ? editedCount / totalLines : 0.0;
      
      // Language detection with codes - same as HomeScreen
      Set<String> detectedLanguageCodes = {'EN'}; // Default English
      
      // Check for common non-Latin scripts
      for (final line in subtitleLines.take(10)) { // Check first 10 lines for performance
        final text = line.original + (line.edited ?? '');
        if (_containsScript(text, 'Malayalam')) detectedLanguageCodes.add('ML');
        if (_containsScript(text, 'Hindi')) detectedLanguageCodes.add('HI');
        if (_containsScript(text, 'Arabic')) detectedLanguageCodes.add('AR');
        if (_containsScript(text, 'Chinese')) detectedLanguageCodes.add('ZH');
        if (_containsScript(text, 'Japanese')) detectedLanguageCodes.add('JA');
        if (_containsScript(text, 'Korean')) detectedLanguageCodes.add('KO');
        if (_containsScript(text, 'Russian')) detectedLanguageCodes.add('RU');
      }
      
      return {
        'totalLines': totalLines,
        'editedLines': editedCount,
        'lastEditedIndex': widget.session.lastEditedIndex ?? 1,
        'progress': progress,
        'languageCodes': detectedLanguageCodes.join('/'),
        'languages': detectedLanguageCodes.toList(),
      };
    } catch (e) {
      return {
        'totalLines': 0,
        'editedLines': 0,
        'lastEditedIndex': 1,
        'progress': 0.0,
        'languageCodes': 'EN',
        'languages': ['EN'],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic color variables for adaptive theming
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                        color: onSurfaceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: onSurfaceColor.withValues(alpha: 0.7),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Project Settings",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Manage project configuration and files",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                            ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Project Statistics at the top
                          _buildProjectStatsSection(),
                          const SizedBox(height: 24),
                          _buildBasicInfoSection(),
                          const SizedBox(height: 24),
                          _buildFileManagementSection(),
                          const SizedBox(height: 24),
                          _buildMediaPathsSection(),
                          const SizedBox(height: 24),
                          _buildEncodingSection(),
                          const SizedBox(height: 24),
                          _buildMarkedLinesSection(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      )
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information', Icons.info_outline, Colors.blue),
        _buildEditableField(
          'Project Name',
          _projectNameController,
          'Enter project name',
          onChanged: (value) {
            // Auto-save project name changes
          },
        ),
      ],
    );
  }

  Widget _buildFileManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('File Management', Icons.folder_outlined, Colors.orange),
        
        // SRT File Path
        _buildPathCard(
          'SRT File',
          widget.subtitleCollection.filePath,
          'No SRT file path available',
          Icons.subtitles,
          Colors.blue,
          onLocate: _locateSrtFile,
          onReplace: null, // SRT files are managed through other workflows
          onClear: null,   // SRT files shouldn't be cleared
          showReplaceButton: false, // Don't show Replace button for SRT files
        ),
        
        const SizedBox(height: 12),
        
        // Project File Path
        _buildPathCard(
          'Project File',
          _getDisplayProjectFilePath(),
          'No project file saved',
          Icons.description,
          Colors.teal,
          onLocate: _locateProjectFile,
          onReplace: _saveProjectFile, // Save project when "Add" is pressed
          onClear: null,   // Project files shouldn't be cleared
          showReplaceButton: false, // Don't show Replace/Add button for Project files
        ),
      ],
    );
  }

  Widget _buildMediaPathsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Media Paths', Icons.video_library_outlined, Colors.purple),
        
        // Video Path
        _buildPathCard(
          'Video File',
          _getDisplayVideoFilePath(),
          'No video file loaded',
          Icons.video_file,
          Colors.purple,
          onLocate: _locateVideoFile,
          onReplace: _replaceVideoFile,
          onClear: _clearVideoFile,
        ),
        
        const SizedBox(height: 12),
        
        // Secondary Subtitle Path
        _buildPathCard(
          'Secondary Subtitle',
          _isSecondaryFromOriginal 
            ? 'Original text (loaded from current subtitles)' 
            : _getDisplaySecondarySubtitlePath(),
          'No secondary subtitle loaded',
          Icons.subtitles,
          Colors.green,
          onLocate: _isSecondaryFromOriginal ? null : _locateSecondarySubtitle,
          onReplace: _replaceSecondarySubtitle,
          onClear: _clearSecondarySubtitle,
          isOriginalText: _isSecondaryFromOriginal,
        ),
      ],
    );
  }

  Widget _buildEncodingSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Text Encoding', Icons.text_format, Colors.indigo),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Character Encoding',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedEncoding,
                    isExpanded: true,
                    items: _availableEncodings.map((encoding) {
                      return DropdownMenuItem(
                        value: encoding,
                        child: Text(encoding),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedEncoding = value;
                        });
                        _updateEncoding(value);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectStatsSection() {
    if (_sessionInfo == null) return const SizedBox.shrink();
    
    final stats = _sessionInfo!;
    final progress = stats['progress'] as double;
    final totalLines = stats['totalLines'] as int;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Project Statistics', Icons.analytics_outlined, Colors.teal),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Editing Progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Stats Grid (total lines, last edited, language)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      Icons.format_list_numbered,
                      'Total Lines',
                      '$totalLines',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      Icons.edit_note,
                      'Edited Lines',
                      '${stats['editedLines'] ?? 0}',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      Icons.edit_location,
                      'Last Edited Line',
                      widget.session.lastEditedIndex != null 
                        ? '#${widget.session.lastEditedIndex! + 1}'
                        : 'None',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      Icons.language,
                      'Language',
                      _detectLanguage(),
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 65, // Fixed height to keep all stat cards the same size
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle long text
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle long text
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkedLinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Marked Lines', Icons.bookmark_added, Colors.red),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showMarkedLines,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bookmark_added,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bookmarked Lines',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_markedLines.length} line${_markedLines.length == 1 ? '' : 's'} marked',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Changes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    String hint, {
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPathCard(
    String title,
    String? path,
    String emptyText,
    IconData icon,
    Color color, {
    VoidCallback? onLocate,
    VoidCallback? onReplace,
    VoidCallback? onClear,
    bool isOriginalText = false,
    bool showReplaceButton = true,
  }) {
    final hasPath = path != null && path.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasPath ? path : emptyText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hasPath 
                ? Theme.of(context).textTheme.bodyMedium?.color 
                : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontStyle: hasPath ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          if (hasPath || isOriginalText) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onLocate != null)
                  TextButton.icon(
                    onPressed: onLocate,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Locate'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                if (showReplaceButton && onReplace != null)
                  TextButton.icon(
                    onPressed: onReplace,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Replace'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: Colors.orange,
                    ),
                  ),
                if (onClear != null)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onReplace,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                foregroundColor: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Detects the language from subtitle content - same as HomeScreen
  String _detectLanguage() {
    if (_sessionInfo == null) return 'Unknown';
    return _sessionInfo!['languageCodes'] ?? 'EN';
  }

  bool _containsScript(String text, String script) {
    switch (script) {
      case 'Malayalam':
        return RegExp(r'[\u0D00-\u0D7F]').hasMatch(text);
      case 'Hindi':
        return RegExp(r'[\u0900-\u097F]').hasMatch(text);
      case 'Arabic':
        return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
      case 'Chinese':
        return RegExp(r'[\u4E00-\u9FFF]').hasMatch(text);
      case 'Japanese':
        return RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').hasMatch(text);
      case 'Korean':
        return RegExp(r'[\uAC00-\uD7AF]').hasMatch(text);
      case 'Russian':
        return RegExp(r'[\u0400-\u04FF]').hasMatch(text);
      default:
        return false;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    SnackbarHelper.showSnackBar(
      context,
      'Copied to clipboard',
      backgroundColor: Colors.green,
    );
  }

  /// Get display path for project file with proper URI decoding for Android
  String? _getDisplayProjectFilePath() {
    final projectFilePath = widget.session.projectFilePath;
    if (projectFilePath == null) return null;
    
    String displayPath = projectFilePath;
    
    // For Android SAF URIs, decode to show human-readable path
    if (Platform.isAndroid && projectFilePath.startsWith('content://')) {
      try {
        // Use SafPathConverter for correct SAF URI to path conversion
        final decodedPath = SafPathConverter.normalizePath(projectFilePath);
        if (kDebugMode) {
          print('ProjectSettings _getDisplayProjectFilePath: originalPath=$projectFilePath, correctedPath=$decodedPath');
        }
        
        if (decodedPath != projectFilePath && 
            decodedPath.contains('/') && 
            !decodedPath.startsWith('content://')) {
          displayPath = decodedPath;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding project file URI: $e');
        }
      }
    }
    
    // Ensure the path includes the filename - if it doesn't end with .msone, add it
    if (!displayPath.toLowerCase().endsWith('.msone')) {
      // If the path is just a directory, try to append a filename based on the subtitle file
      final baseName = widget.session.fileName.replaceAll(RegExp(r'\.[^.]*$'), ''); // Remove extension
      if (baseName.isNotEmpty) {
        if (displayPath.endsWith('/') || displayPath.endsWith('\\')) {
          displayPath = '$displayPath$baseName.msone';
        } else {
          displayPath = '$displayPath${Platform.isWindows ? '\\' : '/'}$baseName.msone';
        }
      }
    }
    
    return displayPath;
  }

  /// Get display path for video file with proper URI decoding for Android
  String? _getDisplayVideoFilePath() {
    if (_videoPath == null) return null;
    
    String displayPath = _videoPath!;
    
    // For Android SAF URIs, decode to show human-readable path
    if (Platform.isAndroid && _videoPath!.startsWith('content://')) {
      try {
        // Use SafPathConverter for correct SAF URI to path conversion
        final decodedPath = SafPathConverter.normalizePath(_videoPath!);
        if (kDebugMode) {
          print('ProjectSettings _getDisplayVideoFilePath: originalPath=$_videoPath, correctedPath=$decodedPath');
        }
        
        // Check if the decoded path contains a filename (has an extension)
        if (decodedPath.isNotEmpty && !decodedPath.startsWith('content://')) {
          displayPath = decodedPath;
          
          // Clean up malformed paths that contain "primary:" pattern
          if (displayPath.contains('primary:')) {
            if (kDebugMode) {
              print('Found primary: pattern in decoded path, cleaning...');
            }
            
            // Split by "primary:" and take everything after the last occurrence
            final parts = displayPath.split('primary:');
            if (parts.length > 1) {
              displayPath = parts.last; // Take everything after the last "primary:"
              
              // Remove leading slash if present
              if (displayPath.startsWith('/')) {
                displayPath = displayPath.substring(1);
              }
              
              if (kDebugMode) {
                print('Cleaned path after removing primary:: $displayPath');
              }
            }
          }
          
          // If the cleaned path doesn't contain a filename, try to extract it from the original URI
          if (!displayPath.contains('.') || displayPath.endsWith('/') || displayPath.endsWith('\\')) {
            if (kDebugMode) {
              print('Path appears to be missing filename, attempting extraction from URI');
            }
            
            // Try to extract filename from the original URI
            try {
              final uri = Uri.parse(_videoPath!);
              
              // Method 1: Check query parameters for displayName
              final displayName = uri.queryParameters['displayName'];
              if (displayName != null && displayName.contains('.')) {
                if (displayPath.endsWith('/') || displayPath.endsWith('\\')) {
                  displayPath = '$displayPath$displayName';
                } else {
                  displayPath = '$displayPath${Platform.isWindows ? '\\' : '/'}$displayName';
                }
                if (kDebugMode) {
                  print('Added filename from URI displayName: $displayPath');
                }
              } else {
                // Method 2: Check path segments for filename
                if (uri.pathSegments.isNotEmpty) {
                  for (int i = uri.pathSegments.length - 1; i >= 0; i--) {
                    if (uri.pathSegments[i].contains('.')) {
                      final filename = uri.pathSegments[i];
                      if (displayPath.endsWith('/') || displayPath.endsWith('\\')) {
                        displayPath = '$displayPath$filename';
                      } else {
                        displayPath = '$displayPath${Platform.isWindows ? '\\' : '/'}$filename';
                      }
                      if (kDebugMode) {
                        print('Added filename from URI path segments: $displayPath');
                      }
                      break;
                    }
                  }
                }
              }
            } catch (uriError) {
              if (kDebugMode) {
                print('Error extracting filename from URI: $uriError');
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding video file URI: $e');
        }
        // Keep original if decoding fails
        displayPath = _videoPath!;
      }
    }
    
    if (kDebugMode) {
      print('Final video display path: $displayPath');
    }
    
    return displayPath;
  }

  /// Get display path for secondary subtitle file with proper URI decoding for Android
  String? _getDisplaySecondarySubtitlePath() {
    if (_secondarySubtitlePath == null) return null;
    
    String displayPath = _secondarySubtitlePath!;
    
    // For Android SAF URIs, decode to show human-readable path
    if (Platform.isAndroid && _secondarySubtitlePath!.startsWith('content://')) {
      try {
        // Use SafPathConverter for correct SAF URI to path conversion
        final decodedPath = SafPathConverter.normalizePath(_secondarySubtitlePath!);
        if (kDebugMode) {
          print('ProjectSettings _getDisplaySecondarySubtitlePath: originalPath=$_secondarySubtitlePath, correctedPath=$decodedPath');
        }
        
        // Check if the decoded path contains a filename (has an extension)
        if (decodedPath.isNotEmpty && !decodedPath.startsWith('content://')) {
          displayPath = decodedPath;
          
          // Clean up malformed paths that contain "primary:" pattern
          if (displayPath.contains('primary:')) {
            if (kDebugMode) {
              print('Found primary: pattern in decoded path, cleaning...');
            }
            
            // Split by "primary:" and take everything after the last occurrence
            final parts = displayPath.split('primary:');
            if (parts.length > 1) {
              displayPath = parts.last; // Take everything after the last "primary:"
              
              // Remove leading slash if present
              if (displayPath.startsWith('/')) {
                displayPath = displayPath.substring(1);
              }
              
              if (kDebugMode) {
                print('Cleaned path after removing primary:: $displayPath');
              }
            }
          }
          
          // If the cleaned path doesn't contain a filename, try to extract it from the original URI
          if (!displayPath.contains('.') || displayPath.endsWith('/') || displayPath.endsWith('\\')) {
            if (kDebugMode) {
              print('Path appears to be missing filename, attempting extraction from URI');
            }
            
            // Try to extract filename from the original URI
            try {
              final uri = Uri.parse(_secondarySubtitlePath!);
              
              // Method 1: Check query parameters for displayName
              final displayName = uri.queryParameters['displayName'];
              if (displayName != null && displayName.contains('.')) {
                if (displayPath.endsWith('/') || displayPath.endsWith('\\')) {
                  displayPath = '$displayPath$displayName';
                } else {
                  displayPath = '$displayPath${Platform.isWindows ? '\\' : '/'}$displayName';
                }
                if (kDebugMode) {
                  print('Added filename from URI displayName: $displayPath');
                }
              } else {
                // Method 2: Check path segments for filename
                if (uri.pathSegments.isNotEmpty) {
                  for (int i = uri.pathSegments.length - 1; i >= 0; i--) {
                    if (uri.pathSegments[i].contains('.')) {
                      final filename = uri.pathSegments[i];
                      if (displayPath.endsWith('/') || displayPath.endsWith('\\')) {
                        displayPath = '$displayPath$filename';
                      } else {
                        displayPath = '$displayPath${Platform.isWindows ? '\\' : '/'}$filename';
                      }
                      if (kDebugMode) {
                        print('Added filename from URI path segments: $displayPath');
                      }
                      break;
                    }
                  }
                }
              }
            } catch (uriError) {
              if (kDebugMode) {
                print('Error extracting filename from URI: $uriError');
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding secondary subtitle file URI: $e');
        }
        // Keep original if decoding fails
        displayPath = _secondarySubtitlePath!;
      }
    }
    
    if (kDebugMode) {
      print('Final secondary subtitle display path: $displayPath');
    }
    
    return displayPath;
  }

  /// Helper method to extract filename from SAF URI
  /// Opens the file location in the system file manager
  Future<void> _openFileLocation(String filePath) async {
    try {
      if (Platform.isAndroid) {
        _showAndroidFileLocationDialog(filePath);
      } else {
        await _openDesktopFileLocation(filePath);
      }
    } catch (e) {
      _showFileLocationErrorDialog(filePath, e.toString());
    }
  }

  /// Show file location dialog for Android with modern design
  void _showAndroidFileLocationDialog(String filePath) {
    // Determine if this is a SAF URI and get display path
    final bool isSafUri = filePath.startsWith('content://');
    String displayPath = filePath;
    
    if (isSafUri) {
      try {
        // Use SafPathConverter for correct SAF URI to path conversion
        displayPath = SafPathConverter.normalizePath(filePath);
        
        if (kDebugMode) {
          print('AndroidFileLocationDialog: originalPath=$filePath, correctedPath=$displayPath');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error in AndroidFileLocationDialog path conversion: $e');
        }
        // Keep original if decoding fails
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSafUri ? Icons.security : Icons.folder_open,
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
                          'File Location',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isSafUri ? 'Secure Storage Location' : 'Local File Path',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // File path section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'File Path',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      displayPath,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Information section
              if (isSafUri) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About Storage Access Framework',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This file is securely managed by Android\'s Storage Access Framework (SAF). '
                        'The location shown above represents the actual file path on your device\'s storage. '
                        'SAF ensures secure access while maintaining proper file permissions.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Direct File Access',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This file is stored in a directly accessible location on your device. '
                        'The path shown above is the exact location where the file resides.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _copyToClipboard(displayPath);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Path'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle desktop file location opening
  Future<void> _openDesktopFileLocation(String filePath) async {
    final file = File(filePath);
    final directory = file.parent.path;
    
    if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', filePath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', filePath]);
    } else if (Platform.isLinux) {
      // Try to open the parent directory
      final uri = Uri.file(directory);
      await launchUrl(uri);
    }
    
    SnackbarHelper.showSnackBar(
      context,
      'File location opened in file manager',
      backgroundColor: Colors.green,
    );
  }

  /// Show error dialog for file location access
  void _showFileLocationErrorDialog(String filePath, String error) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with error icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unable to Open Location',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'File manager could not be opened',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // File path section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'File Path',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      filePath,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Error section
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Error Details',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _copyToClipboard(filePath);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Path'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _locateVideoFile() async {
    if (_videoPath != null) {
      await _openFileLocation(_videoPath!);
    }
  }

  Future<void> _replaceVideoFile() async {
    // Use the EditScreen's video loading function instead of the crashing one
    if (widget.onLoadVideo != null) {
      try {
        // Store the current path to check for changes
        final oldPath = _videoPath;
        
        // First, trigger setState to show loading state
        if (mounted) {
          setState(() {
            // Optionally show a loading indicator
          });
        }
        
        widget.onLoadVideo!();
        
        // Immediately start polling for path changes with more frequent checks
        bool pathChanged = false;
        for (int attempt = 0; attempt < 40; attempt++) { // Increased attempts
          await Future.delayed(const Duration(milliseconds: 150)); // Shorter delay
          await _loadVideoPath();
          
          if (_videoPath != oldPath && _videoPath != null) {
            pathChanged = true;
            if (kDebugMode) {
              print('Video path changed from $oldPath to $_videoPath after ${(attempt + 1) * 150}ms');
            }
            // Immediately update UI when path changes
            if (mounted) {
              setState(() {});
            }
            break;
          }
        }
        
        if (!pathChanged) {
          // Force one more refresh after a longer delay
          await Future.delayed(const Duration(milliseconds: 1000));
          await _loadVideoPath();
          if (kDebugMode) {
            print('Final video path check: $_videoPath (changed: ${_videoPath != oldPath})');
          }
        }
        
        // Always trigger a final UI refresh
        if (mounted) {
          setState(() {});
        }
        
        // Trigger immediate refresh to update UI
        await _refreshDataSilently();
        
        // Show feedback about the result
        if (pathChanged && _videoPath != null) {
          SnackbarHelper.showSnackBar(
            context,
            'Video file updated successfully',
            backgroundColor: Colors.green,
          );
        } else if (_videoPath == null) {
          SnackbarHelper.showSnackBar(
            context,
            'Video path not found - please try again',
            backgroundColor: Colors.orange,
          );
        }
        
      } catch (e) {
        SnackbarHelper.showSnackBar(
          context,
          'Error loading video: $e',
          backgroundColor: Colors.red,
        );
      }
    } else {
      // Fallback to the previous implementation for platforms where it works
      try {
        String? videoPath;
        
        if (Platform.isAndroid) {
          final fileInfo = await PlatformFileHandler.readFile(
            mimeTypes: ['video/*'],
          );
          
          if (fileInfo != null) {
            videoPath = fileInfo.path;
          }
        } else {
          videoPath = await FilePickerSAF.pickFile(
            context: context,
            title: 'Select Video File',
            allowedExtensions: ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv'],
            pickText: 'Select Video File',
          );
        }

        if (videoPath != null) {
          await PreferencesModel.saveVideoPath(widget.session.subtitleCollectionId, videoPath);
          setState(() {
            _videoPath = videoPath;
          });
          
          SnackbarHelper.showSnackBar(
            context,
            'Video file updated successfully',
            backgroundColor: Colors.green,
          );
        }
      } catch (e) {
        SnackbarHelper.showSnackBar(
          context,
          'Error selecting video file: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  /// Reload video path from preferences
  Future<void> _loadVideoPath() async {
    try {
      final savedPath = await PreferencesModel.getVideoPath(widget.session.subtitleCollectionId);
      if (mounted) {
        final oldPath = _videoPath;
        setState(() {
          _videoPath = savedPath;
        });
        if (kDebugMode) {
          print('Video path loaded: $oldPath -> $savedPath');
          if (savedPath != null) {
            print('Video path details:');
            print('  - Full path: $savedPath');
            print('  - Contains extension: ${savedPath.contains('.')}');
            print('  - Ends with slash: ${savedPath.endsWith('/') || savedPath.endsWith('\\')}');
            print('  - Is SAF URI: ${savedPath.startsWith('content://')}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading video path: $e');
      }
    }
  }

  Future<void> _clearVideoFile() async {
    await PreferencesModel.removeVideoPath(widget.session.subtitleCollectionId);
    setState(() {
      _videoPath = null;
    });
    
    SnackbarHelper.showSnackBar(
      context,
      'Video file cleared',
      backgroundColor: Colors.orange,
    );
  }

  Future<void> _locateSecondarySubtitle() async {
    if (_secondarySubtitlePath != null) {
      await _openFileLocation(_secondarySubtitlePath!);
    }
  }

  Future<void> _locateProjectFile() async {
    if (widget.session.projectFilePath != null) {
      await _openFileLocation(widget.session.projectFilePath!);
    }
  }

  Future<void> _locateSrtFile() async {
    if (widget.subtitleCollection.filePath != null) {
      await _openFileLocation(widget.subtitleCollection.filePath!);
    }
  }

  Future<void> _saveProjectFile() async {
    if (widget.onSaveProject != null) {
      try {
        widget.onSaveProject!();
        // Trigger immediate refresh to show updated project file path
        await Future.delayed(const Duration(milliseconds: 500)); // Give time for save to complete
        await _refreshDataSilently();
        // Don't close the sheet here - let user see the success/failure feedback
        // The user can manually close the sheet when they're done
      } catch (e) {
        // Error handling is done in the EditScreen's save project method
        print('Error saving project: $e');
      }
    }
  }

  Future<void> _replaceSecondarySubtitle() async {
    // Show options: Load from file or Use original text
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Secondary Subtitle Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text('Load from File'),
              subtitle: const Text('Import subtitle from an external file'),
              onTap: () {
                Navigator.pop(context);
                _loadSecondaryFromFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Use Original Text'),
              subtitle: const Text('Display original text as secondary track'),
              onTap: () {
                Navigator.pop(context);
                _useOriginalAsSecondary();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSecondaryFromFile() async {
    try {
      String? filePath;
      String? fileContent;
      String fileName = '';
      
      if (Platform.isAndroid) {
        final fileInfo = await PlatformFileHandler.readFile(
          mimeTypes: ['text/plain', 'application/x-subrip', 'text/vtt'],
        );
        
        if (fileInfo != null) {
          filePath = fileInfo.path;
          fileContent = fileInfo.contentAsString;
          fileName = fileInfo.fileName;
        }
      } else {
        filePath = await FilePickerSAF.pickFile(
          context: context,
          title: 'Pick a Subtitle File',
          allowedExtensions: ['.srt', '.vtt', '.ass', '.ssa'],
          pickText: 'Select Subtitle File',
        );
        
        final file = File(filePath!);
        fileContent = await file.readAsString();
        fileName = file.path.split('/').last;
            }

      if (filePath != null && fileContent != null) {
        List<SimpleSubtitleLine> parsedSubtitles = [];
        if (fileName.toLowerCase().endsWith('.srt')) {
          parsedSubtitles = SubtitleParser.parseSrt(fileContent);
        } else if (fileName.toLowerCase().endsWith('.vtt')) {
          parsedSubtitles = SubtitleParser.parseVtt(fileContent);
        } else if (fileName.toLowerCase().endsWith('.ass') || fileName.toLowerCase().endsWith('.ssa')) {
          parsedSubtitles = SubtitleParser.parseAss(fileContent);
        }

        if (parsedSubtitles.isNotEmpty) {
          widget.onSecondarySubtitlesLoaded?.call(parsedSubtitles);
          await PreferencesModel.saveSecondarySubtitlePath(widget.session.subtitleCollectionId, filePath);
          await PreferencesModel.setSecondaryIsOriginal(widget.session.subtitleCollectionId, false);
          
          setState(() {
            _secondarySubtitlePath = filePath;
            _isSecondaryFromOriginal = false;
          });
          
          // Trigger immediate refresh
          await _refreshDataSilently();
          
          SnackbarHelper.showSnackBar(
            context,
            'Secondary subtitle loaded successfully',
            backgroundColor: Colors.green,
          );
        } else {
          SnackbarHelper.showSnackBar(
            context,
            'Could not parse the subtitle file',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      SnackbarHelper.showSnackBar(
        context,
        'Error loading secondary subtitle: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _useOriginalAsSecondary() async {
    List<SimpleSubtitleLine> originalTextSubtitles = [];

    for (var line in widget.subtitleCollection.lines) {
      if (line.original.isNotEmpty) {
        originalTextSubtitles.add(SimpleSubtitleLine(
          index: line.index,
          startTime: line.startTime,
          endTime: line.endTime,
          text: line.original.replaceAll('<br>', '\n'),
        ));
      }
    }

    if (originalTextSubtitles.isNotEmpty) {
      widget.onSecondarySubtitlesLoaded?.call(originalTextSubtitles);
      await PreferencesModel.setSecondaryIsOriginal(widget.session.subtitleCollectionId, true);
      await PreferencesModel.removeSecondarySubtitlePath(widget.session.subtitleCollectionId);
      
      setState(() {
        _secondarySubtitlePath = null;
        _isSecondaryFromOriginal = true;
      });
      
      // Trigger immediate refresh
      await _refreshDataSilently();
      
      SnackbarHelper.showSnackBar(
        context,
        'Using original text as secondary subtitle',
        backgroundColor: Colors.green,
      );
    } else {
      SnackbarHelper.showSnackBar(
        context,
        'No original text available',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _clearSecondarySubtitle() async {
    widget.onSecondarySubtitlesCleared?.call();
    await PreferencesModel.removeSecondarySubtitlePath(widget.session.subtitleCollectionId);
    await PreferencesModel.setSecondaryIsOriginal(widget.session.subtitleCollectionId, false);
    
    setState(() {
      _secondarySubtitlePath = null;
      _isSecondaryFromOriginal = false;
    });
    
    // Trigger immediate refresh
    await _refreshDataSilently();
    
    SnackbarHelper.showSnackBar(
      context,
      'Secondary subtitle cleared',
      backgroundColor: Colors.orange,
    );
  }

  Future<void> _updateEncoding(String encoding) async {
    try {
      widget.subtitleCollection.encoding = encoding;
      await updateSubtitleCollection(widget.subtitleCollection);
      
      SnackbarHelper.showSnackBar(
        context,
        'Encoding updated to $encoding',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      SnackbarHelper.showSnackBar(
        context,
        'Error updating encoding: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  void _showMarkedLines() async {
    // Get both marked lines and all lines with comments
    final allLinesWithComments = await getAllSubtitleLinesWithComments(widget.session.subtitleCollectionId);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => MarkedLinesSheet(
          markedLines: _markedLines,
          allLinesWithComments: allLinesWithComments,
          onLineSelected: (index) {
            // This could navigate to the specific line in the editor
            Navigator.pop(context); // Close project settings
          },
          onCommentUpdated: (index, comment) async {
            // Update comment in database and refresh marked lines
            try {
              await updateSubtitleLineComment(widget.session.subtitleCollectionId, index, comment);
              // Refresh marked lines list
              _markedLines = await getMarkedSubtitleLines(widget.session.subtitleCollectionId);
              setState(() {}); // Trigger rebuild to show updated comments
              
              SnackbarHelper.showSuccess(context, 
                comment != null ? 'Comment updated' : 'Comment deleted');
            } catch (e) {
              SnackbarHelper.showError(context, 'Failed to update comment: $e');
            }
          },
          onLineUnmarked: (index) async {
            // Unmark line and delete comment
            try {
              await unmarkSubtitleLine(widget.session.subtitleCollectionId, index);
              // Refresh marked lines list
              _markedLines = await getMarkedSubtitleLines(widget.session.subtitleCollectionId);
              setState(() {}); // Trigger rebuild to remove unmarked line
              
              SnackbarHelper.showSuccess(context, 'Line unmarked and comment deleted');
            } catch (e) {
              SnackbarHelper.showError(context, 'Failed to unmark line: $e');
            }
          },
          onResolvedUpdated: (index, resolved) async {
            // Update resolved status in database
            try {
              await updateSubtitleLineResolved(widget.session.subtitleCollectionId, index, resolved);
              // Refresh marked lines list
              _markedLines = await getMarkedSubtitleLines(widget.session.subtitleCollectionId);
              setState(() {}); // Trigger rebuild to show updated resolved status
              
              SnackbarHelper.showSuccess(context, 
                resolved ? 'Comment marked as resolved' : 'Comment marked as unresolved');
            } catch (e) {
              SnackbarHelper.showError(context, 'Failed to update resolved status: $e');
            }
          },
          onTextEdited: (index, newText) async {
            // Update edited text in database and refresh marked lines
            try {
              // Get the subtitle line from database
              final subtitle = await isar.subtitleCollections.get(widget.session.subtitleCollectionId);
              if (subtitle != null && index < subtitle.lines.length) {
                final updatedLine = subtitle.lines[index];
                updatedLine.edited = newText;
                
                // Save to database
                await saveSubtitleChangesToDatabase(
                  widget.session.subtitleCollectionId,
                  updatedLine,
                  (String time) {
                    // Parse time format "HH:mm:ss,SSS" to DateTime
                    final parts = time.split(',');
                    final hms = parts[0].split(':');
                    return DateTime(0, 1, 1, 
                      int.parse(hms[0]), 
                      int.parse(hms[1]), 
                      int.parse(hms[2]), 
                      int.parse(parts[1]));
                  },
                  sessionId: widget.session.id,
                );
                
                // Refresh marked lines list
                _markedLines = await getMarkedSubtitleLines(widget.session.subtitleCollectionId);
                setState(() {}); // Trigger rebuild to show updated text
                
                SnackbarHelper.showSuccess(context, 'Subtitle text updated');
              }
            } catch (e) {
              SnackbarHelper.showError(context, 'Failed to update subtitle text: $e');
            }
          },
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    try {
      // Save project name
      final newProjectName = _projectNameController.text.trim();
      if (newProjectName.isNotEmpty && newProjectName != widget.session.fileName) {
        final session = await isar.sessions.get(widget.session.id);
        if (session != null) {
          session.fileName = newProjectName;
          await isar.writeTxn(() async {
            await isar.sessions.put(session);
          });
        }
      }

      widget.onProjectUpdated();
      
      SnackbarHelper.showSnackBar(
        context,
        'Changes saved successfully',
        backgroundColor: Colors.green,
      );
      
      Navigator.pop(context);
    } catch (e) {
      SnackbarHelper.showSnackBar(
        context,
        'Error saving changes: $e',
        backgroundColor: Colors.red,
      );
    }
  }
}
