// Subtitle Studio v3 - Urban Dictionary Widget
//
// This widget provides access to the Urban Dictionary API for slang and informal definitions.
// It supports English slang terms and provides multiple definitions with examples.
//
// Key Features:
// - Real-time API search via unofficial Urban Dictionary API
// - Multiple definitions with examples and contributors
// - Copy functionality for definitions
// - Case-sensitive and strict matching options
// - Clean, modern UI following app design patterns
//
// API Documentation:
// Base URL: https://unofficialurbandictionaryapi.com/api/search
// Parameters: term, strict, matchCase, limit, page, multiPage

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:dio/dio.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';

/// Model class for Urban Dictionary entry
class UrbanDictionaryEntry {
  final String word;
  final String meaning;
  final String example;
  final String contributor;
  final String date;

  UrbanDictionaryEntry({
    required this.word,
    required this.meaning,
    required this.example,
    required this.contributor,
    required this.date,
  });

  factory UrbanDictionaryEntry.fromJson(Map<String, dynamic> json) {
    return UrbanDictionaryEntry(
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
      example: json['example'] ?? '',
      contributor: json['contributor'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

/// Urban Dictionary search widget
class UrbanDictionaryWidget extends StatefulWidget {
  /// Callback when user selects a definition
  final Function(String) onSelectTranslation;
  
  /// Initial search term to populate the search field
  final String? initialSearchTerm;

  const UrbanDictionaryWidget({
    super.key,
    required this.onSelectTranslation,
    this.initialSearchTerm,
  });

  @override
  State<UrbanDictionaryWidget> createState() => _UrbanDictionaryWidgetState();
}

class _UrbanDictionaryWidgetState extends State<UrbanDictionaryWidget> {
  // Controllers
  late TextEditingController _searchController;
  
  // State variables
  bool _isLoading = false;
  List<UrbanDictionaryEntry> _searchResults = [];
  bool _strictSearch = false; // Only exact matches
  bool _caseSensitiveSearch = false; // Case sensitive search
  final int _limit = 10; // Number of results to fetch
  
  // Constants
  static const String _baseUrl = 'https://unofficialurbandictionaryapi.com/api/search';
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    
    // Set initial search term if provided
    if (widget.initialSearchTerm != null && widget.initialSearchTerm!.isNotEmpty) {
      _searchController.text = widget.initialSearchTerm!;
      // Perform initial search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Perform search using Urban Dictionary API
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
      final dio = Dio();
      
      // Build query parameters
      final queryParams = {
        'term': query,
        'strict': _strictSearch.toString(),
        'matchCase': _caseSensitiveSearch.toString(),
        'multiPage': 'false',
        'limit': _limit.toString(),
      };

      logInfo('Urban Dictionary API request: $_baseUrl with params: $queryParams');

      final response = await dio.get(_baseUrl, queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['found'] == true && data['data'] != null) {
          final List<dynamic> entries = data['data'];
          final results = entries
              .map((entry) => UrbanDictionaryEntry.fromJson(entry))
              .toList();
          
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
          
          logInfo('Urban Dictionary search completed: ${results.length} results');
        } else {
          setState(() {
            _searchResults = [];
            _isLoading = false;
          });
          logInfo('Urban Dictionary search: No results found for "$query"');
        }
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      logError('Urban Dictionary search failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        SnackbarHelper.showError(context, 'Search failed: ${e.toString()}');
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
    
    return SafeArea(
      child: Container(
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
                    
                    const SizedBox(height: 20),
                    
                    // Search field
                    _buildSearchField(isDark, primaryColor, onSurfaceColor, borderColor),
                    
                    // Search button under the text field
                    _buildSearchButton(primaryColor, onSurfaceColor),
                    
                    // Search filter options
                    _buildSearchFilters(onSurfaceColor),
                    
                    const SizedBox(height: 16),
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
      ),
    );
  }

  /// Build the header section
  Widget _buildHeader(Color primaryColor, Color mutedColor, Color onSurfaceColor) {
    return Container(
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
              Icons.forum,
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
                  'Urban Dictionary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Slang words and phrases',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Powered by Urban Dictionary',
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
          labelText: 'Search terms',
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
              value: _strictSearch,
              onChanged: (value) {
                setState(() {
                  _strictSearch = value ?? false;
                });
              },
              title: Text(
                'Exact match',
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
              onChanged: (value) {
                setState(() {
                  _caseSensitiveSearch = value ?? false;
                });
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

  /// Build the search results list
  Widget _buildResultsList(bool isDark, Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
    if (_searchResults.isEmpty) {
      return Center(
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
                  ? 'Enter a slang term to search'
                  : 'No results found',
              style: TextStyle(
                color: onSurfaceColor.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
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
  Widget _buildResultItem(UrbanDictionaryEntry entry, bool isDark, Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
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
            // Word and copy button
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    entry.word,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                // Copy button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _copyToClipboard(entry.meaning),
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
            
            const SizedBox(height: 12),
            
            // Definition
            SelectableText(
              entry.meaning,
              style: TextStyle(
                fontSize: 15,
                color: onSurfaceColor,
                height: 1.4,
              ),
            ),
            
            // Example (if available)
            if (entry.example.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: onSurfaceColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: onSurfaceColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      entry.example,
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceColor.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Contributor and date
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 14,
                  color: onSurfaceColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.contributor,
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurfaceColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: onSurfaceColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurfaceColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
