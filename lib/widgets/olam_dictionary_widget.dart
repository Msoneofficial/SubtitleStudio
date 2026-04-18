// Subtitle Studio v3 - Olam Dictionary Widget
//
// This widget provides a comprehensive dictionary interface for the Olam dictionary database.
// It supports three translation modes:
// 1. EN-ML: English to Malayalam
// 2. ML-EN: Malayalam to English  
// 3. ML-ML: Malayalam to Malayalam
//
// Key Features:
// - Fullscreen bottom modal sheet interface
// - Search functionality with real-time results
// - Three-tab segment control for different dictionary types
// - Database update functionality with progress tracking
// - Download and extract dictionary files from olam.in
// - Offline search through local Isar database
// - Text selection for inserting translations
//
// Technical Implementation:
// - Uses Dio for downloading tar.gz files
// - Archive package for extracting compressed files
// - Isar database for fast local search
// - Debounced search to improve performance
// - Progress indicators for download operations

import 'dart:io';
import 'dart:convert'; // For utf8 and latin1 encoding/decoding
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';
import 'package:subtitle_studio/main.dart'; // For isar global instance

/// Dictionary widget for Olam offline dictionary lookup
class OlamDictionaryWidget extends StatefulWidget {
  /// Callback when user selects a translation
  final Function(String) onSelectTranslation;
  
  /// Initial search term to populate the search field
  final String? initialSearchTerm;

  const OlamDictionaryWidget({
    super.key,
    required this.onSelectTranslation,
    this.initialSearchTerm,
  });

  @override
  State<OlamDictionaryWidget> createState() => _OlamDictionaryWidgetState();
}

class _OlamDictionaryWidgetState extends State<OlamDictionaryWidget>
    with TickerProviderStateMixin {
  // Controllers
  late TextEditingController _searchController;
  late TabController _tabController;
  
  // State variables
  bool _isLoading = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  List<DictionaryEntry> _searchResults = [];
  String _selectedTab = 'EN-ML'; // Current dictionary type
  int _databaseEntryCount = 0; // Track database entries
  String _lastUpdateDate = 'Never'; // Last update date
  bool _shouldShowUpdateNotification = false; // Whether to show update notification
  bool _wholeWordSearch = false; // Search for whole words only
  bool _caseSensitiveSearch = false; // Case sensitive search
  
  // Constants
  static const String _enmlUrl = 'https://olam.in/files/enml.tar.gz';
  static const String _datukUrl = 'https://olam.in/files/datuk.tar.gz';
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
    
    // Set initial search term if provided
    if (widget.initialSearchTerm != null) {
      _searchController.text = widget.initialSearchTerm!;
      // Perform initial search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
    
    // Check database entry count
    _checkDatabaseCount();
    
    // Load last update date and check if update is needed
    _loadLastUpdateDate();
    
    // Load search filter preferences
    _loadSearchFilters();
    
    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        String newTab;
        switch (_tabController.index) {
          case 0:
            newTab = 'EN-ML';
            break;
          case 1:
            newTab = 'ML-EN';
            break;
          case 2:
            newTab = 'ML-ML';
            break;
          default:
            newTab = 'EN-ML';
        }
        
        if (_selectedTab != newTab) {
          setState(() {
            _selectedTab = newTab;
          });
          // Re-search with new tab selection
          if (_searchController.text.isNotEmpty) {
            _performSearch();
          }
        }
      }
    });
  }

  /// Check how many entries are in the database
  Future<void> _checkDatabaseCount() async {
    try {
      final count = await isar.dictionaryEntrys.count();
      setState(() {
        _databaseEntryCount = count;
      });
      logInfo('Dictionary database contains $count entries');
      
      // Only test if database is empty to avoid interference
      if (count == 0) {
        await _testDatabaseFunctionality();
      } else {
        // Verify database integrity
        await _verifyDatabaseIntegrity();
      }
    } catch (e) {
      logError('Error checking database count: $e');
    }
  }

  /// Test if database operations work
  Future<void> _testDatabaseFunctionality() async {
    try {
      // Only test if database is empty to avoid clearing existing data
      if (_databaseEntryCount > 0) {
        logInfo('Database already contains data, skipping test');
        return;
      }
      
      // Test inserting a single entry
      final testEntry = DictionaryEntry(
        word: 'test',
        meaning: 'പരീക്ഷ',
        partOfSpeech: 'n',
        dictionaryType: 'EN-ML',
      );
      
      await isar.writeTxn(() async {
        await isar.dictionaryEntrys.put(testEntry);
      });
      
      final countAfterTest = await isar.dictionaryEntrys.count();
      logInfo('Database count after test insert: $countAfterTest');
      
      // Only clean up the specific test entry, not all data
      if (countAfterTest == 1) {
        await isar.writeTxn(() async {
          await isar.dictionaryEntrys.delete(testEntry.id);
        });
        logInfo('Cleaned up test entry');
      } else {
        logInfo('Not clearing database - contains actual data');
      }
      
      logInfo('Database test completed');
    } catch (e) {
      logError('Database test failed: $e');
    }
  }

  /// Verify database integrity and Unicode handling
  Future<void> _verifyDatabaseIntegrity() async {
    try {
      final count = await isar.dictionaryEntrys.count();
      logInfo('Total entries in database: $count');
      
      if (count > 0) {
        // Use the search functions to get sample entries
        final sampleEntries = await searchDictionaryByWord('', 'EN-ML');
        final limitedSample = sampleEntries.take(5).toList();
        
        logInfo('Sample entries for Unicode verification:');
        for (var entry in limitedSample) {
          logInfo('Word: "${entry.word}" | Meaning: "${entry.meaning}"');
          
          // Check for corrupted UTF-8 sequences like "à´¹àµ¼à´·àµ»"
          final hasCorruptedChars = entry.meaning.contains('à´') || entry.meaning.contains('àµ');
          if (hasCorruptedChars) {
            logError('⚠️ CORRUPTED UTF-8 detected in: "${entry.meaning}"');
          }
          
          // Check if meaning has proper Unicode characters (Malayalam)
          if (entry.meaning.isNotEmpty) {
            final hasUnicode = entry.meaning.runes.any((rune) => rune > 127);
            final malayalamRange = entry.meaning.runes.any((rune) => rune >= 0x0D00 && rune <= 0x0D7F);
            logInfo('Entry has Unicode: $hasUnicode, Malayalam range: $malayalamRange');
          }
        }
        
        // Count entries by type
        final enmlEntries = await searchDictionaryByWord('', 'EN-ML');
        final mlmlEntries = await searchDictionaryByWord('', 'ML-ML');
        logInfo('EN-ML entries: ${enmlEntries.length}');
        logInfo('ML-ML entries: ${mlmlEntries.length}');
      }
    } catch (e) {
      logError('Error verifying database integrity: $e');
    }
  }

  /// Load last update date from shared preferences
  Future<void> _loadLastUpdateDate() async {
    try {
      final lastUpdate = await PreferencesModel.getOlamLastUpdateDate();
      
      String displayDate = 'Never';
      if (lastUpdate != null) {
        try {
          final date = DateTime.parse(lastUpdate);
          final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          displayDate = '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
        } catch (e) {
          logError('Error parsing saved date: $e');
        }
      }
      
      setState(() {
        _lastUpdateDate = displayDate;
        _shouldShowUpdateNotification = _checkIfUpdateNeeded(lastUpdate);
      });
    } catch (e) {
      logError('Error loading last update date: $e');
    }
  }

  /// Load search filter preferences
  Future<void> _loadSearchFilters() async {
    try {
      final wholeWordSearch = await PreferencesModel.getOlamWholeWordSearch();
      final caseSensitiveSearch = await PreferencesModel.getOlamCaseSensitiveSearch();
      
      setState(() {
        _wholeWordSearch = wholeWordSearch;
        _caseSensitiveSearch = caseSensitiveSearch;
      });
    } catch (e) {
      logError('Error loading search filters: $e');
    }
  }

  /// Check if database update is needed (source updates on 2nd of every month)
  bool _checkIfUpdateNeeded(String? lastUpdateString) {
    if (lastUpdateString == null) return true;
    
    try {
      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();
      
      // Find the last 2nd of the month
      DateTime lastUpdateDate;
      if (now.day >= 2) {
        // This month's 2nd has passed
        lastUpdateDate = DateTime(now.year, now.month, 2);
      } else {
        // This month's 2nd hasn't passed, check last month
        lastUpdateDate = DateTime(now.year, now.month - 1, 2);
      }
      
      // If last update was before the most recent 2nd, suggest update
      return lastUpdate.isBefore(lastUpdateDate);
    } catch (e) {
      logError('Error parsing last update date: $e');
      return true;
    }
  }

  /// Save last update date to shared preferences
  Future<void> _saveLastUpdateDate() async {
    try {
      final now = DateTime.now();
      await PreferencesModel.setOlamLastUpdateDate(now.toIso8601String());
      
      // Format date for display (e.g., "Dec 25, 2024")
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final formattedDate = '${monthNames[now.month - 1]} ${now.day}, ${now.year}';
      
      setState(() {
        _lastUpdateDate = formattedDate;
        _shouldShowUpdateNotification = false;
      });
    } catch (e) {
      logError('Error saving last update date: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Perform search in the local dictionary database
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<DictionaryEntry> results = [];
      
      switch (_selectedTab) {
        case 'EN-ML':
          // Search English word, return Malayalam meaning
          results = await searchDictionaryByWord(query, 'EN-ML', 
                                                wholeWord: _wholeWordSearch, 
                                                caseSensitive: _caseSensitiveSearch);
          break;
          
        case 'ML-EN':
          // Search Malayalam meaning, return English word
          results = await searchDictionaryByMeaning(query, 'EN-ML', 
                                                   wholeWord: _wholeWordSearch, 
                                                   caseSensitive: _caseSensitiveSearch);
          break;
          
        case 'ML-ML':
          // Search Malayalam word, return Malayalam meaning
          results = await searchDictionaryByWord(query, 'ML-ML', 
                                                wholeWord: _wholeWordSearch, 
                                                caseSensitive: _caseSensitiveSearch);
          break;
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      logError('Error searching dictionary: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackbarHelper.showError(context, 'Search failed: $e');
      }
    }
  }

  /// Copy text to clipboard with user feedback
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        SnackbarHelper.showSuccess(
          context, 
          'Copied to clipboard',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      logError('Error copying to clipboard: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to copy text');
      }
    }
  }

  /// Download and update dictionary database
  Future<void> _updateDictionary() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      logInfo('Starting dictionary database update...');
      
      // Clear existing dictionary entries
      await clearDictionaryEntries();

      // Download and process EN-ML dictionary
      await _downloadAndProcessDictionary(_enmlUrl, 'enml', 'EN-ML');
      
      // Download and process ML-ML dictionary  
      await _downloadAndProcessDictionary(_datukUrl, 'datuk', 'ML-ML');

      SnackbarHelper.showSuccess(
        context, 
        'Dictionary updated successfully!',
        duration: const Duration(seconds: 3),
      );
      
      logInfo('Dictionary database update completed successfully');
      
      // Save the update date
      await _saveLastUpdateDate();
      
      // Refresh database count
      await _checkDatabaseCount();
    } catch (e) {
      logError('Dictionary update failed: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Update failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  /// Download and process a single dictionary file
  Future<void> _downloadAndProcessDictionary(
      String url, String expectedFileName, String dictionaryType) async {
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();
    final downloadPath = '${tempDir.path}/$expectedFileName.tar.gz';

    try {
      // Download file with progress tracking
      await dio.download(
        url,
        downloadPath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = (received / total) * 0.5; // First 50% is download
            });
          }
        },
      );

      logInfo('Downloaded $expectedFileName.tar.gz');

      // Extract and process the file
      await _extractAndProcessFile(downloadPath, expectedFileName, dictionaryType);

      // Clean up downloaded file
      final downloadFile = File(downloadPath);
      if (await downloadFile.exists()) {
        await downloadFile.delete();
      }

      if (mounted) {
        setState(() {
          _downloadProgress += 0.5; // Second 50% is processing
        });
      }
    } catch (e) {
      logError('Failed to download/process $expectedFileName: $e');
      rethrow;
    }
  }

  /// Extract tar.gz file and process dictionary content
  Future<void> _extractAndProcessFile(
      String archivePath, String expectedFileName, String dictionaryType) async {
    final file = File(archivePath);
    final bytes = await file.readAsBytes();
    
    logInfo('Archive file size: ${bytes.length} bytes');

    // Decompress gzip first
    final gzipDecoder = GZipDecoder();
    final tarBytes = gzipDecoder.decodeBytes(bytes);
    
    logInfo('Decompressed tar size: ${tarBytes.length} bytes');

    // Extract tar archive
    final tarArchive = TarDecoder().decodeBytes(tarBytes);
    
    logInfo('Tar archive contains ${tarArchive.files.length} files');
    
    for (final tarFile in tarArchive) {
      logInfo('File in archive: ${tarFile.name}, isFile: ${tarFile.isFile}, size: ${tarFile.size}');
      
      // Check for both direct filename and files/filename patterns
      if ((tarFile.name == expectedFileName || tarFile.name == 'files/$expectedFileName') && tarFile.isFile) {
        // Proper UTF-8 decoding to handle Malayalam Unicode characters
        String content;
        try {
          // First try UTF-8 decoding
          content = utf8.decode(tarFile.content as List<int>);
        } catch (e) {
          // Fallback to Latin-1 if UTF-8 fails, then re-encode to UTF-8
          logError('UTF-8 decode failed, trying fallback: $e');
          final latin1Content = latin1.decode(tarFile.content as List<int>);
          content = utf8.decode(latin1.encode(latin1Content));
        }
        
        logInfo('Found target file ${tarFile.name}, content length: ${content.length}');
        
        // Log first few lines to verify Unicode is preserved
        final lines = content.split('\n');
        logInfo('Total lines in file: ${lines.length}');
        for (int i = 0; i < lines.length && i < 3; i++) {
          logInfo('Line $i: ${lines[i]}');
          // Check if line contains Malayalam characters
          if (lines[i].runes.any((rune) => rune > 127)) {
            logInfo('✓ Line $i contains Unicode characters');
          }
        }
        
        await _processDictionaryContent(content, dictionaryType);
        break;
      }
    }
  }

  /// Process dictionary file content and store in database
  Future<void> _processDictionaryContent(String content, String dictionaryType) async {
    final lines = content.split('\n');
    final entries = <DictionaryEntry>[];
    
    logInfo('Processing ${lines.length} lines for $dictionaryType dictionary');
    
    int processedLines = 0;
    int skippedLines = 0;
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      try {
        final entry = _parseDictionaryLine(line, dictionaryType);
        if (entry != null) {
          entries.add(entry);
          processedLines++;
        } else {
          skippedLines++;
        }
      } catch (e) {
        // Skip malformed lines
        skippedLines++;
        if (skippedLines <= 10) { // Only log first 10 errors
          logInfo('Skipping malformed line: $line - Error: $e');
        }
        continue;
      }
    }

    logInfo('Parsed ${entries.length} valid entries for $dictionaryType (processed: $processedLines, skipped: $skippedLines)');

    if (entries.isNotEmpty) {
      // Use helper function for batch insert
      await addDictionaryEntries(entries);
      logInfo('Successfully stored ${entries.length} $dictionaryType dictionary entries in database');
      
      // Verify the data was actually inserted
      final countAfterInsert = await isar.dictionaryEntrys.count();
      logInfo('Database count after insert: $countAfterInsert');
    } else {
      logError('No valid entries found for $dictionaryType dictionary');
    }
  }

  /// Parse a single dictionary line into a DictionaryEntry
  DictionaryEntry? _parseDictionaryLine(String line, String dictionaryType) {
    // Skip header line
    if (line.trim().startsWith('from_content') || line.trim().isEmpty) {
      return null;
    }
    
    // Expected format: word\t{pos}\tmeaning
    final parts = line.split('\t');
    if (parts.length < 2) {
      return null;
    }
    
    String word, meaning, partOfSpeech = '';
    
    if (parts.length >= 3) {
      // Format: word\t{pos}\tmeaning
      word = parts[0].trim();
      partOfSpeech = parts[1].trim().replaceAll(RegExp(r'[{}]'), ''); // Remove curly braces
      meaning = parts[2].trim();
    } else {
      // Format: word\tmeaning (no part of speech)
      word = parts[0].trim();
      meaning = parts[1].trim();
    }

    if (word.isEmpty || meaning.isEmpty) return null;

    // Clean up text - remove extra whitespace but preserve Unicode characters
    word = word.replaceAll(RegExp(r'\s+'), ' ').trim();
    meaning = meaning.replaceAll(RegExp(r'\s+'), ' ').trim();
    partOfSpeech = partOfSpeech.replaceAll(RegExp(r'\s+'), ' ').trim();

    return DictionaryEntry(
      word: word,
      meaning: meaning,
      partOfSpeech: partOfSpeech,
      dictionaryType: dictionaryType,
    );
  }

  /// Build the main widget UI
  @override
  Widget build(BuildContext context) {
    // Dynamic color variables for adaptive theming
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);
    
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Sticky header section
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header section
                  _buildHeader(primaryColor, mutedColor, onSurfaceColor),
                  
                  const SizedBox(height: 5),
                  
                  // Search field
                  _buildSearchField(isDark, primaryColor, onSurfaceColor, borderColor),
                  
                  // Search button under the text field
                  _buildSearchButton(primaryColor, onSurfaceColor),
                  
                  // Search filter options
                  _buildSearchFilters(onSurfaceColor),
                  
                  // Update button above the segmented menu
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: _buildUpdateButton(
                      isDark, primaryColor, surfaceColor, onSurfaceColor
                      )
                      ),
                  
                  // Tab segments
                  _buildTabBar(isDark, primaryColor, onSurfaceColor, borderColor),
                ],
              ),
            ),
          ),
          
          // Scrollable results section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildResultsList(isDark, primaryColor, surfaceColor, onSurfaceColor),
          ),
        ],
      ),
    );
  }

  /// Build the header section
  Widget _buildHeader(Color primaryColor, Color mutedColor, Color onSurfaceColor) {
    return SafeArea(
      bottom: false,
      child: Container(
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
                Icons.book,
                color: onSurfaceColor.withValues(alpha: 0.8),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olam Dictionary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Offline English-Malayalam Dictionary',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last updated: $_lastUpdateDate',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the search input field
  Widget _buildSearchField(bool isDark, Color primaryColor, Color onSurfaceColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search ${_getSearchHint()}',
          prefixIcon: Icon(
            Icons.search,
            color: onSurfaceColor.withValues(alpha: 0.6),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                  icon: Icon(
                    Icons.close,
                    color: onSurfaceColor.withValues(alpha: 0.6),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: onSurfaceColor.withValues(alpha: 0.6),
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _performSearch(),
        onChanged: (value) {
          // Update UI to show/hide clear button
          setState(() {});
        },
      ),
    );
  }

  /// Build the search button
  Widget _buildSearchButton(Color primaryColor, Color onSurfaceColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _performSearch,
          icon: const Icon(Icons.search, color: Colors.white),
          label: const Text(
            'Search',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  /// Build search filter controls
  Widget _buildSearchFilters(Color onSurfaceColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: CheckboxListTile(
              value: _wholeWordSearch,
              onChanged: (value) async {
                if (mounted) {
                  setState(() {
                    _wholeWordSearch = value ?? false;
                  });
                  await PreferencesModel.setOlamWholeWordSearch(_wholeWordSearch);
                }
              },
              title: Text(
                'Whole word',
                style: TextStyle(
                  fontSize: 13,
                  color: onSurfaceColor.withValues(alpha: 0.8),
                ),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          Expanded(
            child: CheckboxListTile(
              value: _caseSensitiveSearch,
              onChanged: (value) async {
                if (mounted) {
                  setState(() {
                    _caseSensitiveSearch = value ?? false;
                  });
                  await PreferencesModel.setOlamCaseSensitiveSearch(_caseSensitiveSearch);
                }
              },
              title: Text(
                'Case sensitive',
                style: TextStyle(
                  fontSize: 13,
                  color: onSurfaceColor.withValues(alpha: 0.8),
                ),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
    );
  }

  /// Get search hint text based on selected tab
  String _getSearchHint() {
    switch (_selectedTab) {
      case 'EN-ML':
        return 'English word';
      case 'ML-EN':
        return 'Malayalam word';
      case 'ML-ML':
        return 'Malayalam word';
      default:
        return 'word';
    }
  }

  /// Build the tab bar for dictionary types
  Widget _buildTabBar(bool isDark, Color primaryColor, Color onSurfaceColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? onSurfaceColor.withValues(alpha: 0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem('EN-ML', 0, 'English → Malayalam', primaryColor, onSurfaceColor),
          ),
          Expanded(
            child: _buildTabItem('ML-EN', 1, 'Malayalam → English', primaryColor, onSurfaceColor),
          ),
          Expanded(
            child: _buildTabItem('ML-ML', 2, 'Malayalam → Malayalam', primaryColor, onSurfaceColor),
          ),
        ],
      ),
    );
  }

  /// Build individual tab item with animation
  Widget _buildTabItem(String tabKey, int index, String tooltip, Color primaryColor, Color onSurfaceColor) {
    final isSelected = _selectedTab == tabKey;
    
    return GestureDetector(
      onTap: () {
        if (_tabController.index != index) {
          _tabController.animateTo(index);
          setState(() {
            _selectedTab = tabKey;
          });
          // Re-search with new tab selection
          if (_searchController.text.isNotEmpty) {
            _performSearch();
          }
        }
      },
      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected 
                ? primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected 
                  ? Colors.white
                  : onSurfaceColor.withValues(alpha: 0.7),
              letterSpacing: isSelected ? 0.5 : 0,
            ),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.05 : 1.0,
                child: Text(
                  tabKey,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the update button with progress indicator
  Widget _buildUpdateButton(bool isDark, Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
    final buttonText = _isDownloading
        ? 'Updating... ${(_downloadProgress * 100).toInt()}%'
        : (_shouldShowUpdateNotification ? 'Update Available' : 'Update Dictionary');
    
    final textColor = _shouldShowUpdateNotification ? Colors.orange.withValues(alpha: 0.5) : onSurfaceColor.withValues(alpha: 0.5);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: _isDownloading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _downloadProgress,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: onSurfaceColor,
                    ),
                  ),
                ],
              )
            : TextButton.icon(
                onPressed: _updateDictionary,
                icon: Icon(
                  _shouldShowUpdateNotification ? Icons.warning : Icons.cloud_download,
                  color: textColor,
                ),
                label: Text(
                  buttonText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      ),
    );
  }

  /// Build the search results list
  Widget _buildResultsList(bool isDark, Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
    if (_searchResults.isEmpty) {
      return SafeArea(
        top: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: onSurfaceColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'Enter a word to search'
                    : 'No results found',
                style: TextStyle(
                  color: onSurfaceColor.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24), // Add bottom padding
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final entry = _searchResults[index];
        return _buildResultItem(entry, isDark, primaryColor, surfaceColor, onSurfaceColor);
      },
    );
  }

  /// Build a single result item
  Widget _buildResultItem(DictionaryEntry entry, bool isDark, Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
    final isReverseSearch = _selectedTab == 'ML-EN';
    final primaryText = isReverseSearch ? entry.meaning : entry.word;
    final secondaryText = isReverseSearch ? entry.word : entry.meaning;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? onSurfaceColor.withValues(alpha: 0.1) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    primaryText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceColor,
                    ),
                  ),
                ),
                if (entry.partOfSpeech.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: onSurfaceColor.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      entry.partOfSpeech,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: onSurfaceColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Copy button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _copyToClipboard(isReverseSearch ? entry.word : entry.meaning),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.copy,
                        size: 18,
                        color: onSurfaceColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              secondaryText,
              style: TextStyle(
                fontSize: 14,
                color: onSurfaceColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
