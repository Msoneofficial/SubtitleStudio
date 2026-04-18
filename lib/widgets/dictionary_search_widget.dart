import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:subtitle_studio/widgets/custom_text_render.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';

class DictionarySearchWidget extends StatefulWidget {
  final Function(String) onSelectTranslation;
  final String? initialSearchTerm;

  const DictionarySearchWidget({
    super.key,
    required this.onSelectTranslation,
    this.initialSearchTerm,
  });

  @override
  DictionarySearchWidgetState createState() => DictionarySearchWidgetState();
}

class DictionarySearchWidgetState extends State<DictionarySearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _translatorController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Map<int, GlobalKey> _selectableTextKeys = {};

  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _loginInProgress = false;
  String? _errorMessage;

  List<DictionaryResult> _searchResults = [];
  DictionaryPagination? _pagination;

  // ignore: constant_identifier_names
  static const String API_BASE_URL = 'https://dictapi.malayalamsubtitles.org';

  @override
  void initState() {
    super.initState();
    // Set initial search term if provided
    if (widget.initialSearchTerm != null) {
      _searchController.text = widget.initialSearchTerm!;
    }
    // Check if user is already logged in
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _translatorController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('msone_access_token');

    setState(() {
      _isLoggedIn = token != null;
    });
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Username and password are required';
      });
      return;
    }

    setState(() {
      _loginInProgress = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('msone_access_token', token);

        setState(() {
          _isLoggedIn = true;
          _loginInProgress = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid credentials';
          _loginInProgress = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _loginInProgress = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('msone_access_token');

    setState(() {
      _isLoggedIn = false;
      _searchResults = [];
      _pagination = null;
    });
  }

  Future<void> _search([int page = 1]) async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Search text is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('msone_access_token');

      if (token == null) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$API_BASE_URL/search?search=${Uri.encodeComponent(_searchController.text)}'
          '&translator=${Uri.encodeComponent(_translatorController.text)}'
          '&page=$page'
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)); // Use utf8.decode to properly handle unicode

        final newResults = (data['results'] as List)
            .map((item) => DictionaryResult.fromJson(item))
            .toList();

        setState(() {
          // Append new results to existing results if page > 1
          if (page > 1 && _searchResults.isNotEmpty) {
            _searchResults.addAll(newResults);
          } else {
            _searchResults = newResults;
          }

          _pagination = DictionaryPagination.fromJson(data['pagination']);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await _logout();
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Search failed: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), ''); // Remove HTML tags
    Clipboard.setData(ClipboardData(text: cleanText));
    SnackbarHelper.showSuccess(context, 'Copied to clipboard', duration: const Duration(seconds: 2));
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section with icon and title
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SvgPicture.asset(
                        'assets/msone.svg',
                        height: 28,
                        width: 28,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF4A90E2),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "MSone Dictionary",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Sign in to search the dictionary",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Username field
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: const Color(0xFF4A90E2),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: TextStyle(
                      color: const Color(0xFF4A90E2),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: const Color(0xFF4A90E2),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: TextStyle(
                      color: const Color(0xFF4A90E2),
                    ),
                  ),
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Login button
              Container(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loginInProgress ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loginInProgress
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Sign In",
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Column(
      children: [
        // Compact header section
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  'assets/msone.svg',
                  height: 24,
                  width: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF4A90E2),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "MSone Dictionary",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Compact logout button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: _logout,
                  icon: Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 18,
                  ),
                  tooltip: 'Logout',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ],
          ),
        ),

        // Compact search fields section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // Text search field - more compact
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Text',
                    hintText: 'Enter text to search',
                    prefixIcon: Icon(
                      Icons.search,
                      color: const Color(0xFF4A90E2),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      color: const Color(0xFF4A90E2),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Translator filter field - full width
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _translatorController,
                  decoration: InputDecoration(
                    labelText: 'Translator (Optional)',
                    hintText: 'Filter by translator',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: const Color(0xFF50C878),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      color: const Color(0xFF50C878),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Search button below text fields - full width
              Container(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _search(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Search Dictionary",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
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
        
        // Compact results info
        if (_pagination != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF50C878).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF50C878),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_pagination!.totalResults} results',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF50C878),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Flexible results list instead of Expanded
        Flexible(
          child: _buildResultsList(),
        ),
        
        // Load more button - always at bottom
        if (_pagination != null && _pagination!.hasMore)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => _search(_pagination!.page + 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4A90E2),
                side: BorderSide(color: const Color(0xFF4A90E2).withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.expand_more,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Load More Results',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsList() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.search_off,
                size: 48,
                color: const Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemBuilder: (context, index) {
        final result = _searchResults[index];

        // Create a unique key for this index if it doesn't exist
        _selectableTextKeys.putIfAbsent(index, () => GlobalKey());

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact header with translator and filename
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            color: const Color(0xFF4A90E2),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.translator,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A90E2),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Filename in scrollable container
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            result.filename,
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),

                // Compact English section
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // English time code
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: const Color(0xFF4A90E2),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.timeCodeEn,
                            style: TextStyle(
                              fontFamily: GoogleFonts.spaceMono().fontFamily,
                              color: const Color(0xFF4A90E2),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // English content with copy button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onLongPress: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (context) => Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(Icons.copy, color: const Color(0xFF4A90E2)),
                                          title: Text('Copy English text'),
                                          onTap: () {
                                            _copyToClipboard(result.englishLine);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: CustomHtmlText(
                                htmlContent: _highlightSearchTerm(
                                  result.englishLine.replaceAll('\n', '<br>'),
                                  _searchController.text,
                                ),
                                defaultStyle: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.start,
                                expanded: true,
                                selectable: true,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.copy,
                                size: 14,
                                color: const Color(0xFF4A90E2),
                              ),
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: () => _copyToClipboard(result.englishLine),
                              tooltip: 'Copy English text',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Compact Malayalam section
                InkWell(
                  onDoubleTap: () => widget.onSelectTranslation(result.translationLine),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF50C878).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF50C878).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Malayalam time code
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: const Color(0xFF50C878),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              result.timeCodeMl,
                              style: TextStyle(
                                fontFamily: GoogleFonts.spaceMono().fontFamily,
                                color: const Color(0xFF50C878),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Malayalam content with copy button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                key: _selectableTextKeys[index],
                                onLongPress: () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (context) => Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: Icon(Icons.copy, color: const Color(0xFF50C878)),
                                            title: Text('Copy Malayalam text'),
                                            onTap: () {
                                              _copyToClipboard(result.translationLine);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: CustomHtmlText(
                                  htmlContent: result.translationLine.replaceAll('\n', '<br>'),
                                  defaultStyle: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.start,
                                  expanded: true,
                                  selectable: true,
                                  focusNode: _focusNode,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF50C878).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: const Color(0xFF50C878),
                                ),
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                onPressed: () => _copyToClipboard(result.translationLine),
                                tooltip: 'Copy Malayalam text',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _highlightSearchTerm(String text, String searchTerm) {
    if (searchTerm.isEmpty) return text;

    // First try to highlight the whole phrase
    String result = text;
    final fullSearchTerm = searchTerm.trim();
    
    // Escape HTML special characters in the full search term
    final escapedFullTerm = fullSearchTerm
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
    
    // Create a case-insensitive regex pattern for the full phrase
    if (escapedFullTerm.length > 1) {
      final RegExp fullRegExp = RegExp(
        RegExp.escape(escapedFullTerm),
        caseSensitive: false,
        multiLine: true,
      );

      // Try to replace the full phrase first
      result = result.replaceAllMapped(fullRegExp, (match) {
        final matchedText = match.group(0) ?? '';
        return '<mark style="background-color: #FFC107; color: #000000;">$matchedText</mark>';
      });
    }

    // Then try individual words (fallback)
    // Split search term into words for better matching
    final searchWords = fullSearchTerm.split(RegExp(r'\s+'));
    
    // Only process individual words if there are multiple words and the full phrase wasn't found
    if (searchWords.length > 1) {
      for (final word in searchWords) {
        if (word.isEmpty || word.length < 2) continue; // Skip very short words

        // Escape HTML special characters in the search term
        final escapedWord = word
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#39;');

        // Create a case-insensitive regex pattern
        final RegExp regExp = RegExp(
          '\\b${RegExp.escape(escapedWord)}\\b', // Use word boundaries for more accurate matching
          caseSensitive: false,
          multiLine: true,
        );

        // Don't highlight words that are already inside a mark tag
        result = result.replaceAllMapped(regExp, (match) {
          final matchedText = match.group(0) ?? '';
          // Check if this match is within an existing mark tag
          final int startPos = match.start;
          final int markTagStartPos = result.lastIndexOf('<mark', startPos);
          final int markTagEndPos = result.lastIndexOf('</mark>', startPos);
          
          // If not within a mark tag, highlight it
          if (markTagStartPos == -1 || markTagEndPos > markTagStartPos) {
            return '<mark style="background-color: #FFC107; color: #000000;">$matchedText</mark>';
          }
          return matchedText; // Already highlighted, leave as is
        });
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true, // Handle keyboard properly
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _focusNode.unfocus();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              FocusManager.instance.primaryFocus?.unfocus();
              for (final key in _selectableTextKeys.values) {
                final RenderObject? renderObj = key.currentContext?.findRenderObject();
                if (renderObj != null) {
                  final TextEditingValue textEditingValue = TextEditingValue.empty;
                  final TextInputConnection connection = TextInput.attach(
                    _DummyTextInputClient(),
                    const TextInputConfiguration(),
                  );
                  connection.setEditingState(textEditingValue);
                  connection.close();
                }
              }
            });
          },
          child: _isLoggedIn ? _buildSearchForm() : _buildLoginForm(),
        ),
      ),
    );
  }
}

// Add a dummy implementation of TextInputClient
class _DummyTextInputClient implements TextInputClient {
  @override
  void updateEditingValue(TextEditingValue value) {}
  
  @override
  void performAction(TextInputAction action) {}
  
  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}
  
  @override
  void showAutocorrectionPromptRect(int start, int end) {}
  
  @override
  void connectionClosed() {}
  
  @override
  TextEditingValue? get currentTextEditingValue => null;
  
  @override
  AutofillScope? get currentAutofillScope => null;
  
  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {}
  
  @override
  void insertTextPlaceholder(Size size) {}
  
  @override
  void removeTextPlaceholder() {}
  
  @override
  void showToolbar() {}
  
  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}
  
  @override
  void performSelector(String selectorName) {}
  
  @override
  void insertContent(KeyboardInsertedContent content) {
    // Empty implementation for dummy client
  }
}

class DictionaryResult {
  final int id;
  final String filename;
  final String translator;
  final String englishLine;
  final String translationLine;
  final String timeCodeEn;
  final String timeCodeMl;

  DictionaryResult({
    required this.id,
    required this.filename,
    required this.translator,
    required this.englishLine,
    required this.translationLine,
    required this.timeCodeEn,
    required this.timeCodeMl,
  });

  factory DictionaryResult.fromJson(Map<String, dynamic> json) {
    return DictionaryResult(
      id: json['id'],
      filename: json['filename'],
      translator: json['translator_name'],
      englishLine: json['english_line'],
      translationLine: json['translation_line'],
      timeCodeEn: json['time_code_en'],
      timeCodeMl: json['time_code_ml'],
    );
  }
}

class DictionaryPagination {
  final int page;
  final int limit;
  final int totalResults;
  final bool hasMore;

  DictionaryPagination({
    required this.page,
    required this.limit,
    required this.totalResults,
    required this.hasMore,
  });

  factory DictionaryPagination.fromJson(Map<String, dynamic> json) {
    return DictionaryPagination(
      page: json['page'],
      limit: json['limit'],
      totalResults: json['total_results'],
      hasMore: json['has_more'],
    );
  }
}
