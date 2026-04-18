import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:subtitle_studio/utils/app_info.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';

class HelpScreen extends StatefulWidget {
  final String? initialCategoryId;
  
  const HelpScreen({super.key, this.initialCategoryId});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String _searchQuery = '';
  int _selectedCategoryIndex = -1; // -1 means show all
  
  List<HelpCategory> get _categories {
    List<HelpCategory> baseCategories = [
    HelpCategory(
      id: 'getting-started',
      title: 'Getting Started',
      icon: Icons.rocket_launch_outlined,
      color: const Color(0xFF4CAF50),
      sections: [
        HelpSection(
          title: 'Welcome to Subtitle Studio',
          content: '''
Subtitle Studio is a powerful subtitle editing application designed to make subtitle creation and editing simple and efficient.

Key Features:
• Create new SRT subtitle files from scratch
• Import existing SRT subtitle files
• Extract subtitles from video files
• Edit subtitle timing and text with video synchronization
• Apply rich text formatting and colors
• Video player integration for precise editing
• Auto-save functionality
• Find and replace text across subtitles
• Split and merge subtitle lines
• Subtitle synchronization tools
• MSone community integration
          ''',
          steps: [
            'Install the app on your device',
            'Open the app to see the Home screen',
            'Tap the Menu button at the bottom right corner (rectangle button) to start',
            'Choose from Create, Extract, Import, Open or View options',
          ],
        ),
        HelpSection(
          title: 'Understanding the Interface',
          content: '''
The app has three main screens:

1. Home Screen: View recent sessions and quick actions
2. Edit Screen: Timeline view for subtitle editing with video player
3. Edit Subtitle Screen: Detailed text editing with formatting tools and video player

Each screen is optimized for different aspects of subtitle creation and editing.
          ''',
          steps: [
            'Home Screen: Central hub with recent files and quick actions',
            'Edit Screen: Timeline-based editing with video synchronization',
            'Edit Subtitle Screen: Line-by-line text editing and formatting',
            'Settings: App preferences and MSone configurations',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'creating-subtitles',
      title: 'Creating Subtitles',
      icon: Icons.add_circle_outline,
      color: const Color(0xFF9C27B0),
      sections: [
        HelpSection(
          title: 'Creating a New Subtitle File',
          content: '''
Start creating SRT subtitles from scratch with our intuitive creation wizard.
          ''',
          steps: [
            'Tap the Menu button on Home screen',
            'Select "Create" (green button)',
            'Enter the subtitle file name',
            'Slect the output folder for the new file',
            'Select the encoding format (UTF-8 recommended)',
            'Tap "Create Subtitle" button to start editing',
          ],
        ),
        HelpSection(
          title: 'Adding Subtitle Lines',
          content: '''
Add new subtitle entries with precise timing control and video synchronization.
          ''',
          steps: [
            'In Edit screen, tap the "Add Subtitle Line" button',
            'Set start time for the subtitle',
            'Set end time for the subtitle duration',
            'Enter the subtitle text in the dialog',
            'Tap "Save" button to add the line',
            'The new line appears in the subtitle list',
            'Repeat for additional subtitle lines',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'importing-files',
      title: 'Importing Files',
      icon: Icons.file_upload_outlined,
      color: const Color(0xFF2196F3),
      sections: [
        HelpSection(
          title: 'Opening Existing Subtitle Files',
          content: '''
Import SRT subtitle files from your device storage.

Supported Format:
• SRT (SubRip) - The industry standard subtitle format
          ''',
          steps: [
            'Tap the Menu button',
            'Select "Open"',
            'Browse and select your SRT subtitle file',
            'Choose the import options',
            'Tap "Import Subtitle" button',
            'Wait for import to complete',
            'File opens automatically in Edit screen',
          ],
        ),
        HelpSection(
          title: 'Extracting Subtitles from Videos',
          content: '''
Extract embedded subtitles (soft coded) directly from video files.
          ''',
          steps: [
            'Tap the Menu button',
            'Select "Extract"',
            'Choose "Select Video File"',
            'Pick a video with embedded subtitles',
            'Choose import options',
            'Tap "Select Subtitle Tracks"',
            'Select the subtitle track to extract',
            'File opens automatically in Edit screen',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'editing-features',
      title: 'Edit Screen Features',
      icon: Icons.edit_outlined,
      color: const Color(0xFFFF9800),
      sections: [
        HelpSection(
          title: 'Video Player Integration',
          content: '''
The Edit screen features an integrated video player for precise subtitle timing.

Video Player Features:
• Load video files (MP4, MKV, AVI)
• Play/pause controls
• Seek to specific timestamps
• Video-subtitle synchronization
• Show/hide video player toggle
          ''',
          steps: [
            'Tap Menu (three horizontal lines) → Load Video to select a video file',
            'Use play/pause controls in the video player',
            'Tap any subtitle line to seek video to that timestamp',
            'Use the video toggle button on the top to show/hide the player',
          ],
        ),
        HelpSection(
          title: 'Timeline Navigation & Editing',
          content: '''
Navigate and edit subtitles efficiently using the timeline interface.
          ''',
          steps: [
            'Scroll through the subtitle timeline vertically',
            'Double tap or swipe right on any subtitle line to edit it in Edit Subtitle screen',
            'Long-press lines to select subtitle operations',
            'Tap any subtitle line to jump video to that timestamp',
          ],
        ),
//         HelpSection(
//           title: 'Toolbar Functions',
//           content: '''
// Access essential editing tools from the main toolbar.
//           ''',
//           steps: [
//             'Tap "+" button (plus icon) to add new subtitle lines',
//             'Use Theme Switcher (palette icon) to change app appearance',
//             'Tap Menu (three horizontal lines) for additional options',
//             'Access Help from the Menu for documentation',
//           ],
//         ),
        HelpSection(
          title: 'Menu Options',
          content: '''
Comprehensive editing tools available in the popup menu.

Available Functions:
• Load/Unload Video
• Export File
• Go to Line
• Find & Replace
• Show MArked Lines
• Load Secondary Subtitles
• Sync Subtitles
• Insert Banners
• Malayalam Text Normalization (MSone)
• Submit to MSone (MSone)
• Help & Documentation
          ''',
          steps: [
            'Tap Menu (three horizontal lines) to open popup menu',
            'Select "Load Video" to add video synchronization',
            'Use "Export File" to save your completed subtitles',
            'Try "Go to Line" to jump to specific subtitle numbers',
            'Use "Find & Replace" for bulk text operations',
            'Show "Marked Lines" to view bookmarked subtitles',
            'Load secondary subtitles in the video player for reference',
            'Access "Sync Subtitles" for timing adjustments',
            'Insert promotional banners using "Insert Banners" option (Enable MSone features in the settings first)',
            'Use "Malayalam Text Normalization" for text quality improvements (Enable MSone features in the settings first)',
            'Submit your subtitles to the MSone community using "Submit to MSone" (Enable MSone features in the settings first)',
            'Access "Help & Documentation" for more information',
          ],
        ),
        HelpSection(
          title: 'Batch Operations',
          content: '''
Perform operations on multiple subtitle lines simultaneously.

Available Functions:
• Edit
• Add Line
• Select
• Copy
• Mark Line
• Delete
          ''',
          steps: [
            'Long-press a subtitle line to open the menu',
            'Tap "Edit" to go to Edit Subtitle screen for selected line',
            'Choose "Add Line" to insert a new subtitle line',
            'Choose "Select" to enter selection mode',
            'Apply bulk operations like copy, delete, or time shifts',
            'Use "Mark Line" to bookmark important subtitles',
            'Use "Shift Times" to adjust timing for selected lines',
          ],
        ),
        HelpSection(
          title: 'Auto-Save Feature',
          content: '''
Your work is automatically saved to prevent data loss.
          ''',
          steps: [
            'Changes are saved automatically as you edit',
            'No manual save required for basic editing',
            'Export when you want to create the final SRT file',
            'Session data persists between app launches',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'edit-subtitle-features',
      title: 'Edit Subtitle Screen Features',
      icon: Icons.text_fields_outlined,
      color: const Color.fromARGB(255, 250, 68, 36),
      sections: [
        HelpSection(
          title: 'Text Editing & Formatting',
          content: '''
Comprehensive text editing with rich formatting options.

Available Formatting:
• Bold, Italic, Underline
• Text colors with color picker
• Text positioning (left, center, right)
• HTML tag support
• Color history for recent colors
          ''',
          steps: [
            'Tap the text field to edit subtitle content',
            'Select text and use formatting buttons in toolbar',
            'Tap color palette to change text colors',
            'Use position buttons to align text',
            'Apply bold (B), italic (I), underline (U) formatting',
            'Remove all formatting with the clear format button',
          ],
        ),
        HelpSection(
          title: 'Timing Controls',
          content: '''
Precise timing adjustment with multiple input methods.
          ''',
          steps: [
            'Tap start/end time fields to edit times',
            'Use hour:minute:second.millisecond format',
            'Use video player position for timing reference',
          ],
        ),
        HelpSection(
          title: 'Line Operations',
          content: '''
Additional operations for subtitle line management.
          ''',
          steps: [
            'Tap "Split" button to divide subtitle into multiple lines',
            'Use "Merge" button to combine with adjacent lines',
            'Tap "Delete" button to remove the current line',
            'Navigate and auto save the edits with previous/next buttons',
            'Save changes with the save button',
          ],
        ),
        HelpSection(
          title: 'Video Synchronization',
          content: '''
Perfect timing with integrated video playback.
          ''',
          steps: [
            'Load a video file in Edit screen first',
            'Video player shows current subtitle overlay',
            'Use video controls to find perfect timing',
            'Adjust start/end times while watching video',
            'Test subtitle timing with video playback',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'checkpoint-system',
      title: 'Edit History',
      icon: Icons.history,
      color: const Color(0xFF00BCD4),
      sections: [
        HelpSection(
          title: 'Understanding Edit History',
          content: '''
Edit History is a powerful undo/redo feature that automatically tracks all changes made to your subtitle project. Think of it as a complete timeline that lets you review and go back to any point in your editing journey.

Key Concepts:
• Changes are automatically tracked as you edit
• Each entry stores the exact state of affected subtitle lines
• You can go back to any previous point with a single tap
• History is preserved when you save your project
• Two types: Regular changes (track specific edits) and Full Backups (complete state)

Benefits:
• Undo any mistake, even after saving
• Review your editing timeline
• Restore previous versions of specific lines
• Experiment freely knowing you can always go back
• Compare different versions side by side
          ''',
          steps: [
            'Changes are tracked automatically as you edit',
            'Access history via Menu → Edit History',
            'Review the timeline of all changes made',
            'Tap any point to see what changed',
            'Go back to previous versions when needed',
            'History is saved with your project file',
          ],
        ),
        HelpSection(
          title: 'When Changes Are Recorded',
          content: '''
The system automatically records your changes during these operations:

Automatic History Tracking:
• Time Changes: When you modify start/end times
• Line Deletion: Before deleting any subtitle line(s)
• Line Addition: When adding new subtitle lines
• Line Splitting: When splitting a subtitle into multiple parts
• Line Merging: When combining multiple lines
• Text Effects: When applying formatting or effects
• Batch Operations: When performing bulk edits
• Banner Insertion: When adding promotional banners

Initial State:
• A full backup is created when you first open a project
• This ensures you can always return to the original state
          ''',
          steps: [
            'Edit any subtitle timing → Automatically recorded',
            'Delete one or more lines → State saved before deletion',
            'Add new subtitle lines → Addition is tracked',
            'Split or merge lines → Changes are recorded',
            'Apply text effects → Formatting changes are tracked',
            'Perform batch operations → Full state is preserved',
            'Open project for first time → Initial backup created',
            'Insert banners → Banner additions are tracked',
          ],
        ),
        HelpSection(
          title: 'Accessing Edit History',
          content: '''
View and manage your editing history through the Edit History interface.
          ''',
          steps: [
            'Open Edit screen for your project',
            'Tap Menu (three horizontal lines)',
            'Select "Edit History" from the menu',
            'Or use keyboard shortcut: Ctrl + H (if available)',
            'The history timeline appears showing all recorded changes',
            'Tap the Help button (?) in the header for more information',
          ],
        ),
        HelpSection(
          title: 'Understanding the History Timeline',
          content: '''
The history interface shows a chronological list of all changes made to your project.

Timeline Display:
• Most recent changes appear at the top
• Each entry shows operation type and timestamp
• Description provides details about what changed
• Current position is highlighted with amber indicator
• Connected timeline shows the flow of changes

Change Information:
• Operation Type: What action was performed (e.g., "Edited line", "Deleted line", "Added line")
• Timestamp: When the change was made (e.g., "2m ago", "1h ago")
• Description: Details about affected lines
• Type Indicators: Regular change (blue circle), Save Point (purple bookmark), or Full Backup (orange save icon)
          ''',
          steps: [
            'Open Edit History from the menu',
            'Scroll through the timeline of changes',
            'Tap any point to see details and undo to that point',
            'View operation descriptions for each change',
            'Current position is marked with amber highlight',
            'Identify which lines were modified',
          ],
        ),
        HelpSection(
          title: 'Going Back in History',
          content: '''
Return to any previous state of your subtitle project with a single tap.

How It Works:
• Select the point in history you want to return to
• Review what changed at that point
• Tap "Undo to Here" to go back to that state
• All affected subtitle lines are updated
• All changes after that point remain in history
• You can move forward again if needed

Safety Features:
• Going back preserves all forward history
• You never lose any work - just move positions
• Can undo to any point in the timeline
• Current position is always clearly marked with amber highlight
          ''',
          steps: [
            'Open Edit History',
            'Browse through your timeline of changes',
            'Tap the point you want to return to',
            'Tap "Undo to Here" button',
            'Review what will change',
            'Confirm to apply the undo',
            'Subtitle lines are updated to that previous state',
            'You can continue editing from that point',
          ],
        ),
        HelpSection(
          title: 'Regular Changes vs Full Backups',
          content: '''
The system uses two types of history records for efficiency and reliability.

Regular Changes (Most Common):
• Store only what actually changed (before/after states)
• Efficient storage for individual edits
• Track specific line modifications
• Used for: time changes, deletions, additions, splits, merges
• Show precise before/after comparison
• Indicated by blue circle icon in timeline

Full Backups (Complete Snapshots):
• Store complete state of all subtitle lines at that moment
• Created at project initialization and periodically
• Provide complete recovery points
• Ensure data integrity
• Enable faster restoration over long timespans
• Created when you tap the Save Point button (orange icon)
• Indicated by orange save icon in timeline

The system automatically chooses the appropriate type based on your actions.
          ''',
          steps: [
            'Regular changes save space by storing only what changed',
            'Full backups provide complete safety recovery points',
            'Both types can be restored using "Undo to Here"',
            'System manages record types automatically',
            'You can create Save Points manually for important moments',
          ],
        ),
        HelpSection(
          title: 'What Information Is Tracked',
          content: '''
Each point in your edit history stores detailed information for precise restoration.

Tracked Information:
• Line Index: Position of the subtitle line
• Start Time: Beginning timestamp
• End Time: Ending timestamp
• Original Text: Source language text
• Edited Text: Translation or edited version
• Marked Status: Whether line was bookmarked
• Comments: Any notes attached to the line
• Resolved Status: Comment resolution state
• Speaker Assignment: Character/speaker identification

This comprehensive tracking ensures perfect restoration of all aspects of your subtitles when you undo to any point.
          ''',
          steps: [
            'Every history entry preserves complete line state',
            'Timing information is precisely tracked',
            'Both original and edited text are saved',
            'Marks and comments are preserved',
            'Undoing applies all saved attributes',
          ],
        ),
        HelpSection(
          title: 'Edit History and Project Files',
          content: '''
Your edit history is an integral part of your project and is preserved across sessions.

Project Integration:
• Edit history is saved in .msone project files
• Automatically included when you save project (Ctrl+E)
• Restored when you import/open project files
• Preserved across app sessions
• No separate backup needed

Storage:
• History uses efficient storage format
• Compressed with project data
• Minimal impact on file size
• Full history preserved indefinitely
• All changes, Save Points, and Full Backups are kept
          ''',
          steps: [
            'Edit your subtitles (history recorded automatically)',
            'Save project using Menu → Save Project or Ctrl+E',
            'Edit history is saved in the .msone file',
            'Close and reopen the project anytime',
            'All history is restored automatically',
            'Continue working with full history intact',
            'Share .msone files with others (includes edit history)',
          ],
        ),
        HelpSection(
          title: 'Best Practices',
          content: '''
Tips for getting the most out of the edit history system.
          ''',
          steps: [
            'Let the system automatically track changes - no manual action needed',
            'Review your edit history periodically to track your progress',
            'Create Save Points (tap orange button) before major changes',
            'Save project regularly (Ctrl+E) to preserve your history',
            'Don\'t worry about making mistakes - you can always undo',
            'Experiment with different edits knowing you can go back',
            'Use history to compare different timing approaches',
            'Undo to previous state if bulk operations don\'t work out',
            'Keep .msone project files to maintain full edit history',
          ],
        ),
        HelpSection(
          title: 'Common Use Cases',
          content: '''
Practical scenarios where edit history saves the day.
          ''',
          steps: [
            'Accidentally deleted multiple lines → Undo to before deletion',
            'Applied wrong time shift to all subtitles → Undo to previous timing',
            'Want to try different sync approaches → Undo and experiment',
            'Made text changes you want to undo → Find the point before edits',
            'Merged lines but changed your mind → Undo to before merge',
            'Applied formatting that didn\'t work out → Revert to clean text',
            'Want to see what changed during editing session → Review timeline',
            'Collaborating and need to review changes → Check edit history',
          ],
        ),
        HelpSection(
          title: 'Troubleshooting',
          content: '''
Common questions and solutions for the edit history system.
          ''',
          steps: [
            'Q: Why don\'t I see any history? → Make some edits first, or project is new',
            'Q: Can I delete old history entries? → Not currently, they use minimal space',
            'Q: Does history slow down the app? → No, system is optimized for performance',
            'Q: What if I undo to the wrong point? → Just undo to a different point',
            'Q: Is my history backed up? → Yes, when you save the project file',
            'Q: Can I export without history? → Use Export File instead of Save Project',
            'Q: Does history work on mobile? → Yes, fully supported on all platforms',
            'Q: Is there a limit to history? → No limit, all changes tracked indefinitely',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'waveform-features',
      title: 'Audio Waveform',
      icon: Icons.graphic_eq_outlined,
      color: const Color(0xFF00BCD4),
      sections: [
        HelpSection(
          title: 'What is Audio Waveform?',
          content: '''
The Audio Waveform is a powerful visual tool that displays the audio amplitude of your video as a graphical representation. This feature helps you create perfectly timed subtitles by showing you exactly when dialogue, sound effects, or music occurs in the audio track.

Benefits:
• See audio patterns visually - identify speech, silence, and sound effects
• Create precise subtitle timing based on actual audio
• Detect scene changes and dialogue breaks
• Work more efficiently without constant video playback
• Identify where subtitles should start and end
• Spot timing errors at a glance
• Professional-grade editing capability

The waveform appears as a horizontal bar below or within your subtitle timeline, showing peaks (loud audio) and valleys (quiet audio or silence).
          ''',
          steps: [
            'Load a video file in Edit screen first',
            'Tap the waveform button in the app bar (equals icon with bars)',
            'Wait for audio extraction and waveform generation',
            'The waveform appears showing audio amplitude over time',
            'Use zoom controls to see more or less detail',
            'Scroll horizontally to navigate through the audio',
          ],
        ),
        HelpSection(
          title: 'Generating the Waveform',
          content: '''
The first time you enable the waveform for a video, the app needs to extract and process the audio data. This is a one-time process that creates a cached representation for future use.

Generation Process:
• Audio is extracted from your video file
• Waveform data is calculated and optimized
• Multiple zoom levels are pre-generated
• Data is cached for instant loading next time
• Progress is shown during generation

Time Required:
• Depends on video length and device performance
• Typical 2-hour movie: 1-3 minutes on mobile, faster on desktop
• The app remains responsive during generation
• You can continue other work while it processes
• Generated waveform is saved permanently

Multi-Track Audio Support:
• If video has multiple audio tracks (languages, commentary, etc.)
• The waveform uses your selected audio track from video player
• Change audio track and regenerate to see different track's waveform
• Useful for multi-language subtitling projects
          ''',
          steps: [
            'Load video file via Menu → Load Video',
            'Tap waveform button in app bar (may show "Generate Waveform")',
            'Wait for audio extraction to complete',
            'Progress indicator shows generation status',
            'Once complete, waveform appears automatically',
            'For multi-track videos: select audio track in video player first',
            'Waveform is cached and loads instantly next time',
          ],
        ),
        HelpSection(
          title: 'Understanding the Waveform Display',
          content: '''
The waveform visualization provides rich information about your audio content.

Visual Elements:
• Blue waveform bars: Audio amplitude (height = loudness)
• Orange highlighting: Currently active subtitle region
• Teal/green subtitle boxes: Individual subtitle time ranges
• White text in boxes: Subtitle text or index numbers
• Vertical playhead: Current video position (red/white line)
• Time indicators: Horizontal and vertical zoom percentages

Audio Patterns to Recognize:
• High peaks: Loud dialogue, music, or sound effects
• Flat/low areas: Silence or very quiet background noise
• Consistent patterns: Continuous speech
• Sudden spikes: Sound effects, scene changes
• Gaps between patterns: Natural pauses in dialogue
• Rhythmic patterns: Music or repetitive sounds

Using Audio Visual Cues:
• Start subtitles just before dialogue peaks begin
• End subtitles when dialogue peaks end
• Use silence gaps to split long dialogues
• Align subtitles with natural speech patterns
• Avoid placing subtitles during pure silence
          ''',
          steps: [
            'Observe waveform amplitude (height) for audio loudness',
            'High peaks indicate dialogue or loud sounds',
            'Flat areas show silence or background noise',
            'Currently playing subtitle is highlighted in orange',
            'Your subtitle boxes appear as overlays on the waveform',
            'Zoom in to see fine audio details',
            'Zoom out for overall scene structure',
          ],
        ),
        HelpSection(
          title: 'Waveform Controls & Navigation',
          content: '''
Control how you view and interact with the waveform visualization.

Zoom Controls:
• Horizontal Zoom: See more or less time range
  - Zoom in: See seconds with fine detail
  - Zoom out: See minutes or entire movie
  - Multiple zoom levels available (20+ levels)
  
• Vertical Zoom: Adjust waveform height
  - Zoom in: Make quiet sounds more visible
  - Zoom out: Focus on loud sounds only
  - Helps when audio has low volume
  - Default 170% height for good visibility

Navigation:
• Horizontal scroll: Move through timeline
• Tap subtitle overlay: Jump video to that position
• Playhead follows video position automatically
• Auto-scroll keeps playhead centered during playback
• Manual scroll disables auto-scroll temporarily

Display Options:
• Show/Hide waveform: Toggle visibility with app bar button
• Waveform visibility state is saved per project
• Desktop: 240px height for larger screens
• Mobile: 180px height optimized for smaller screens
          ''',
          steps: [
            'Use "-" button to zoom out horizontally (see more time)',
            'Use "+" button to zoom in horizontally (see more detail)',
            'Adjust vertical zoom with up/down controls',
            'Scroll waveform left/right to navigate timeline',
            'Tap subtitle boxes to seek video to that position',
            'Toggle waveform visibility with app bar button',
            'Zoom percentage displayed at top corners',
          ],
        ),
        HelpSection(
          title: 'Working with Subtitle Overlays',
          content: '''
Subtitle boxes are displayed directly on the waveform, showing timing and text in context with the audio.

Subtitle Display:
• Each subtitle appears as a colored box on the waveform
• Box length = subtitle duration
• Box position = subtitle timing
• Text shown inside box when space permits
• Index number shown for narrow boxes (<20px wide)
• Currently active subtitle highlighted in orange
• Font sizes: 10-12px based on available space

Color Coding:
• Teal boxes (#00695C): Regular subtitle lines
• Green boxes (#2E7D32): Alternate subtitle lines
• Orange highlight (#F4A361): Currently playing subtitle
• White/light text: Ensures readability on colored boxes

Box Interactions:
• Boxes update in real-time as you edit
• Timing changes reflect immediately
• Text changes appear instantly
• Deletions remove boxes immediately
• New subtitles create new boxes
• Split operations show multiple smaller boxes
          ''',
          steps: [
            'View your subtitle timing as colored boxes',
            'Wide boxes show subtitle text inside',
            'Narrow boxes show index numbers (e.g., "#15")',
            'Active subtitle during playback highlights in orange',
            'Edit subtitles and see waveform boxes update instantly',
            'Use subtitle boxes to visualize overall timing',
            'Identify overlapping or gap issues visually',
          ],
        ),
        HelpSection(
          title: 'Creating Perfect Subtitle Timing',
          content: '''
Use the waveform to create professional, precisely-timed subtitles that sync perfectly with dialogue.

Timing Strategy:
• Look for dialogue peaks in the waveform
• Start subtitle just before peak begins (0.1-0.2s early)
• End subtitle when peak ends or next dialogue starts
• Leave small gaps between subtitles for readability
• Align with natural speech rhythm visible in waveform

Best Practices:
• Zoom in for precise timing of individual lines
• Use waveform to detect overlapping subtitles
• Look for silence gaps to split long dialogues
• Match subtitle length to speech duration
• Start/end subtitles at audio peaks, not in silence
• Use consistent timing patterns throughout movie

Common Timing Scenarios:
• Continuous dialogue: Minimal gap between subtitles
• Questions and answers: Small gap for breath/pause
• Scene changes: Larger gap, visible in waveform
• Background music: Waveform shows music vs dialogue
• Overlapping speech: Multiple audio peaks visible
• Whispers: Low amplitude peaks, zoom vertically to see
          ''',
          steps: [
            'Play video and observe waveform patterns',
            'Zoom in to see individual dialogue peaks clearly',
            'Adjust subtitle start to match dialogue beginning',
            'Adjust subtitle end to match dialogue ending',
            'Use silence gaps between peaks to split subtitles',
            'Preview timing by clicking subtitle boxes',
            'Fine-tune based on waveform visual feedback',
            'Check that subtitles don\'t extend into silence',
          ],
        ),
        HelpSection(
          title: 'Waveform Performance & Caching',
          content: '''
Understanding how waveform data is stored and managed for optimal performance.

Caching System:
• Waveform data cached automatically after first generation
• Cache tied to your subtitle collection/project
• Instant loading on subsequent sessions
• No re-generation needed unless you regenerate manually
• Cache includes all zoom levels and audio data

Storage:
• PCM audio data stored in temporary directory
• Cached per video file and subtitle project
• Minimal storage impact (few MB per video)
• Cache automatically managed by the app
• Old cache cleaned when changing videos

Regeneration:
• Use Menu → Regenerate Waveform to rebuild
• Needed if: audio track changed, cache corrupted, or manual refresh desired
• Old cache is cleared before regeneration
• New cache created from currently selected audio track
          ''',
          steps: [
            'First time: Generate waveform (one-time process)',
            'Subsequent times: Instant loading from cache',
            'To rebuild: Menu → Regenerate Waveform',
            'Cache clears automatically when needed',
            'No manual cache management required',
          ],
        ),
        HelpSection(
          title: 'Multi-Track Audio Selection',
          content: '''
Videos often contain multiple audio tracks (different languages, commentary, audio descriptions). The waveform can be generated from any audio track you select.

How Multi-Track Works:
• Video player detects all available audio tracks
• Select your preferred track via video player controls
• Waveform automatically uses your selected track
• Selection is saved with your project
• Regenerate waveform if you switch audio tracks

Common Use Cases:
• Multi-language movies: Generate waveform for your target language
• Director's commentary: Use original audio track, not commentary
• Audio descriptions: Select main audio, not description track
• Dual audio anime: Choose Japanese or English track
• Multiple mix versions: Select the correct audio mix

Track Selection:
• Audio track selection done in video player
• Look for audio/track icon in video controls
• Selected track is remembered per project
• Waveform uses saved track automatically
• Change track and regenerate for different waveform
          ''',
          steps: [
            'Load video with multiple audio tracks',
            'Open video player audio track selector',
            'Choose the audio track you want to subtitle',
            'Generate or regenerate waveform',
            'Waveform extracts from your selected track',
            'Selection saved with your project',
            'To use different track: select in player, then regenerate waveform',
          ],
        ),
        HelpSection(
          title: 'Troubleshooting Waveform Issues',
          content: '''
Common issues and their solutions when working with waveforms.
          ''',
          steps: [
            'Waveform not generating: Check video file has audio track',
            'Generation failed: Try regenerating from menu',
            'Wrong audio track: Change audio in video player, regenerate waveform',
            'Waveform doesn\'t match audio: Ensure correct audio track selected',
            'Cache issues: Use Regenerate Waveform to rebuild',
            'Slow generation: Normal for long videos, be patient',
            'Waveform disappeared: Toggle visibility button in app bar',
            'Can\'t see quiet audio: Increase vertical zoom',
            'Too much detail: Zoom out horizontally',
            'Subtitle boxes not showing: Ensure subtitles exist in that time range',
            'Performance issues: Close other apps, reduce zoom level',
          ],
        ),
        HelpSection(
          title: 'Tips for Effective Waveform Use',
          content: '''
Pro tips to maximize your efficiency with the waveform feature.
          ''',
          steps: [
            'Generate waveform before starting subtitle timing work',
            'Use horizontal zoom liberally - experiment with different levels',
            'Zoom in for precise frame-accurate timing',
            'Zoom out to see overall structure and pacing',
            'Look for visual patterns that repeat (recurring sounds/music)',
            'Use vertical zoom when working with quiet audio',
            'Enable waveform on desktop for larger display area',
            'Compare subtitle boxes to audio peaks for timing validation',
            'Use waveform to spot missing subtitles (gaps in dialogue)',
            'Toggle waveform off when not needed to reduce visual clutter',
            'Let waveform generate in background while doing other tasks',
            'Save project regularly - waveform cache is saved with it',
            'For multi-language work: verify correct audio track first',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'advanced-features',
      title: 'Advanced Features',
      icon: Icons.settings_outlined,
      color: const Color(0xFFE91E63),
      sections: [
        HelpSection(
          title: 'Find & Replace',
          content: '''
Search and replace text across all subtitle lines.
          ''',
          steps: [
            'Go to Edit screen and tap Menu (three horizontal lines)',
            'Select "Find & Replace"',
            'Enter search text in the find field',
            'Enter replacement text in the replace field',
            'Choose to replace one instance or all occurrences',
            'Use case-sensitive option if needed',
          ],
        ),
        HelpSection(
          title: 'Subtitle Synchronization',
          content: '''
Adjust timing for entire subtitle tracks.
          ''',
          steps: [
            'Access Menu → Subtitle Sync',
            'Choose sync method (shift all, first/last sync)',
            'Enter time offset in seconds',
            'Apply sync to align subtitles with video',
          ],
        ),
        HelpSection(
          title: 'Go to Line',
          content: '''
Quick navigation to specific subtitle lines.
          ''',
          steps: [
            'Access Menu → Go to Line',
            'Enter line number or use slider',
            'Tap "Jump" button to navigate to that line',
            'Video seeks to that subtitle timestamp if loaded',
          ],
        ),
        
        HelpSection(
          title: 'Split & Merge Operations',
          content: '''
Divide long lines or combine short ones.
          ''',
          steps: [
            'For Split: In Edit Subtitle screen, tap "Split" button',
            'Choose split point in the text',
            'Adjust timing for each part',
            'For Merge: Select adjacent lines and use merge option',
            'Combined timing spans both original lines',
          ],
        ),
        HelpSection(
          title: 'Export Options',
          content: '''
Save your completed subtitles as SRT files.
          ''',
          steps: [
            'Complete your subtitle editing',
            'Tap Menu → Export File in Edit screen',
            'Choose save location on your device',
            'Enter filename for the SRT file',
            'Select encoding format (UTF-8 recommended)',
            'Confirm export to save the file',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'msone-features',
      title: 'MSone Exclusive Features',
      icon: Icons.language_outlined,
      color: const Color(0xFF4CAF50),
      sections: [
        HelpSection(
          title: 'About MSone Community',
          content: '''
MSone is a group that began its journey on October 28, 2012, with the mission of creating subtitles for foreign language films. The name "MSone" stands for "Malayalam Subtitles for Everyone."

This initiative empowers cinema enthusiasts who encounter language barriers to fully immerse themselves in films by easily downloading and utilizing subtitles from MSone. We started by offering subtitles for classic English films, and as our popularity grew, we gradually expanded to include subtitles for Indian language films beyond Malayalam. Today, we are proud to provide subtitles for Tamil films as well.

As MSone celebrates over 12 years of its journey, we take pride in having shaped the cinematic experiences of Malayali movie lovers. We grew out of our love for cinema, without expecting any material rewards from the services we provide. Our strength lies in our Facebook group, which boasts over 1,50,000 members, along with tens of thousands of others who enjoy films with MSone subtitles sourced from our website and various platforms.

Film societies across Kerala use subtitles from MSone for film screenings and popularise our group. This enables us to reach all strata of society, eliminating language as a barrier to enjoying cinema. We are proud to be a part of this endeavor.
          ''',
          steps: [
            'Enable MSone features in Settings',
            'Join the MSone Facebook community',
            'Follow MSone subtitle release announcements',
            'Contribute Malayalam subtitles to help the community',
            'Download subtitles from MSone website',
          ],
        ),
        HelpSection(
          title: 'Malayalam Text Normalization',
          content: '''
Specialized tool for improving Malayalam text quality and consistency.

Features:
• Unicode normalization
• Character correction
• Diacritic handling
• Text standardization
          ''',
          steps: [
            'Enable MSone features in Settings first',
            'Go to Edit screen and tap Menu (three horizontal lines)',
            'Select "Malayalam Text Normalization"',
            'Apply to subtitle',
            'Review changes',
          ],
        ),
        HelpSection(
          title: 'Submit to MSone',
          content: '''
Contribute your subtitle work to the MSone community database.
          ''',
          steps: [
            'Complete your subtitle project',
            'Ensure Malayalam text is properly normalized',
            'Access Menu → Submit to MSone',
            'Fill in movie information and details',
            'Upload subtitle files',
            'Submit for community review and approval',
          ],
        ),
        HelpSection(
          title: 'Insert Banners',
          content: '''
Add MSone branding and information banners to subtitles.

Banner Types:
• Beginning banner with MSone credits
• Middle banner for intermission
• End banner with contact information
          ''',
          steps: [
            'Enable MSone features in Settings',
            'Access banner configuration in Edit screen',
            'Choose banner positions and content',
            'Customize banner text and timing',
            'Preview banners with video playback',
            'Apply banners to the subtitle file',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'tips-tricks',
      title: 'Tips & Tricks',
      icon: Icons.lightbulb_outline,
      color: const Color(0xFFFF5722),
      sections: [
        HelpSection(
          title: 'Productivity Tips',
          content: '''
Make your subtitle editing workflow more efficient.
          ''',
          steps: [
            'Use batch processing for large subtitle files',
            'Use color coding for different speakers',
            'Leverage auto-save to prevent data loss',

          ],
        ),
        HelpSection(
          title: 'Quality Guidelines',
          content: '''
Best practices for creating professional subtitles.

Guidelines:
• Keep lines under 2 seconds duration
• Use clear, concise language
• Use proper punctuation and capitalization
• Maintain consistent styling throughout
• Ensure good contrast for readability
• Test on different screen sizes
          ''',
          steps: [
            'Read subtitles aloud to check timing',
            'Use short, concise sentences',
            'Avoid overlapping subtitles',
            'Use appropriate line breaks',
            'Check for spelling and grammar errors',
            'Use MSone normalization for Malayalam text',
            'Use consistent formatting styles',
            'Test subtitles with different video players',
            'Check subtitle readability on various devices',
            'Use MSone website for reference and guidelines',
            'Preview on different background colors',
            'Test with actual video content',
            'Get feedback from other users',
            'Follow accessibility guidelines',
          ],
        ),
      ],
    ),
    HelpCategory(
      id: 'troubleshooting',
      title: 'Troubleshooting',
      icon: Icons.help_outline,
      color: const Color.fromARGB(255, 244, 9, 56),
      sections: [
        HelpSection(
          title: 'Common Issues',
          content: '''
Solutions to frequently encountered problems.
          ''',
          steps: [
            'If app crashes: Clear cache and restart',
            'Subtitle not loading: Check file format and encoding',
            'Import fails: Check file format and size',
            'Timing issues: Verify frame rate settings',
            'Export problems: Check available storage',
            'Performance: Close other apps to free memory',
            'Video playback issues: Ensure video format is supported',
            'Subtitle synchronization problems: Check timing settings',
            'General app issues: Restart the app or device',
            'Network issues: Check your internet connection',
            'File format issues: Ensure compatibility with supported formats',
            'Other issues: Consult the FAQ or community forums',
          ],
        ),
        HelpSection(
          title: 'Getting Support',
          content: '''
How to get help when you need it.
          ''',
          steps: [
            'Check this help documentation first',
            'Use the in-app feedback system',
            'Report bugs through Settings > Feedback',
            'Join the MSone community forums',
            'Contact support via email if needed',
          ],
        ),
      ],
    ),
  ];

    // Add keyboard shortcuts category only on desktop platforms
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      // Platform-specific key names
      final isMac = defaultTargetPlatform == TargetPlatform.macOS;
      final primaryKey = isMac ? 'Cmd' : 'Ctrl';
      final playPauseKey = isMac ? 'Shift + Space' : 'Ctrl + Space';
      final fullscreenKey = isMac ? 'Cmd + F11' : 'F11';
      final helpKey = isMac ? 'Cmd + Shift + H' : 'Ctrl + H';
      
      baseCategories.add(
        HelpCategory(
          id: 'keyboard-shortcuts',
          title: 'Keyboard Shortcuts',
          icon: Icons.keyboard_outlined,
          color: const Color(0xFF9C27B0),
          sections: [
            HelpSection(
              title: 'General Shortcuts',
              content: '''
Essential shortcuts that work across the application.
              ''',
              steps: [
                '$primaryKey + S: Save current subtitle',
                '$playPauseKey: Play/pause video',
                'Shift + Delete: Delete current subtitle line or selection',
                '$helpKey: Show help screen',
                'Alt + S: Open settings',
                '$primaryKey + Backspace: Go back to previous screen',
              ],
            ),
            HelpSection(
              title: 'Home Screen Shortcuts',
              content: '''
Quick actions available from the home screen.
              ''',
              steps: [
                '$primaryKey + O: Open/import SRT file',
                '$primaryKey + P: Import MSone project file',
                '$primaryKey + E: Extract subtitles from video',
                '$primaryKey + N: Create new subtitle file',
                '$helpKey: Show help screen',
                'Alt + S: Open settings',
              ],
            ),
            HelpSection(
              title: 'Main Subtitle List Screen',
              content: '''
Shortcuts available in the main subtitle editing screen with video timeline.
              ''',
              steps: [
                '$primaryKey + S: Save current subtitle',
                '$playPauseKey: Play/pause video',
                '$primaryKey + C: Copy selected lines (selection mode) or highlighted line (normal mode)',
                '$primaryKey + Enter: Edit current/highlighted line',
                '$primaryKey + M: Mark/Unmark current/highlighted line',
                '$primaryKey + Shift + M: Mark current/highlighted line and open Comments',
                '$primaryKey + F: Find and replace text',
                '$primaryKey + J: Go to specific line number',
                '$primaryKey + E: Save/export project',
                '$fullscreenKey: Toggle video fullscreen mode',
                '$primaryKey +Shift + L: Show marked lines sheet',
                '$primaryKey + Left Click: Toggle selection mode for subtitle lines',
                'Shift + Delete: Delete selected subtitle lines',
                '$primaryKey + Backspace: Go back to home screen',
                '$helpKey: Show help screen',
                'Alt + S: Open settings',
              ],
            ),
            HelpSection(
              title: 'Individual Line Edit Screen',
              content: '''
Shortcuts available when editing a specific subtitle line with video player.
              ''',
              steps: [
                '$primaryKey + S: Save current subtitle',
                '$primaryKey + . (period): Navigate to next subtitle line',
                '$primaryKey + , (comma): Navigate to previous subtitle line',
                '$primaryKey + B: Apply bold formatting to selected text',
                '$primaryKey + I: Apply italic formatting to selected text',
                'Alt + C: Open color picker/formatting menu',
                'Alt + V: Paste original text to edited field (translation mode only)',
                '$primaryKey + M: Mark current line',
                '$primaryKey + Shift + M: Mark current line and open Comments',
                '$primaryKey +Shift + L: Show marked lines sheet',
                '$primaryKey + J: Jump to specific line number',
                '$primaryKey + /: Sync subtitle with current video position',
                '$primaryKey + Alt + V: Split subtitle line',
                'Alt + L: Merge with next subtitle line',
                'Shift + Delete: Delete current subtitle line',
                '$primaryKey + Backspace: Go back to subtitle list screen',
                '$helpKey: Show help screen',
                'Alt + S: Open settings',
              ],
            ),
            HelpSection(
              title: 'Video Player Controls',
              content: '''
Video playback and repeat mode controls for precise subtitle editing.
              ''',
              steps: [
                '$playPauseKey: Play/pause video',
                '$fullscreenKey: Toggle fullscreen mode (available in both Edit screens)',
                '$primaryKey + R: Toggle repeat mode (Individual Edit Screen only)',
                '$primaryKey + Shift + R: Toggle repeat range mode (Individual Edit Screen only)',
              ],
            ),
            HelpSection(
              title: 'Dictionary & Language Tools',
              content: '''
Quick access to language-specific dictionary suggestions while editing.
              ''',
              steps: [
                'Alt + M: Open Msone Dictionary',
                'Alt + O: Open Olam Dictionary',
                'Alt + U: Open Urban Dictionary',
              ],
            ),
            HelpSection(
              title: 'Tips & Usage Notes',
              content: '''
Important information about keyboard shortcuts usage.
              ''',
              steps: [
                isMac 
                  ? 'On macOS, Cmd (⌘) key is used instead of Ctrl for most shortcuts'
                  : 'On Windows/Linux, Ctrl key is used as the primary modifier',
                'All shortcuts work when the application window is focused',
                'Text formatting shortcuts work only when editing subtitle text',
                'Navigation shortcuts (. and ,) work in the individual line editing screen',
                'Selection shortcuts work in the main subtitle list screen',
                'Dictionary shortcuts work only in the individual line edit screen',
                'Video player shortcuts work when video is loaded',
                'Repeat mode features are only available in Individual Line Edit Screen',
                'Fullscreen mode ($fullscreenKey) is available in both Edit screens when video is loaded',
                'Repeat range mode sets a ±2 subtitle range around the current subtitle',
                'Shift + Delete has debounce protection to prevent accidental deletions',
                'If no line is highlighted, some shortcuts will use the first available line',
                'Dictionary suggestions require active internet connection',
                '$primaryKey + Backspace provides quick navigation back to previous screens',
                'Video sync ($primaryKey + /) sets subtitle timing to current video position',
                'Marked lines can be quickly accessed with $primaryKey + Alt + M',
                '$primaryKey + C intelligently copies: selected lines in selection mode, or the highlighted line in normal mode',
              ],
            ),
          ],
        ),
      );
    }

    return baseCategories;
  }

  List<HelpCategory> get _filteredCategories {
    if (_searchQuery.isEmpty && _selectedCategoryIndex == -1) {
      return _categories;
    }
    
    if (_selectedCategoryIndex != -1) {
      return [_categories[_selectedCategoryIndex]];
    }
    
    return _categories.where((category) {
      final categoryMatch = category.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final sectionMatch = category.sections.any((section) =>
          section.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          section.content.toLowerCase().contains(_searchQuery.toLowerCase()));
      return categoryMatch || sectionMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    
    // If initialCategoryId is provided, select that category
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categoryIndex = _categories.indexWhere(
          (category) => category.id == widget.initialCategoryId,
        );
        if (categoryIndex != -1) {
          setState(() {
            _selectedCategoryIndex = categoryIndex;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String categoryId) {
    setState(() {
      _selectedCategoryIndex = _categories.indexWhere((cat) => cat.id == categoryId);
    });
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
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
      
      if (!launched) {
        // Show error message if URL couldn't be opened
        if (mounted) {
          SnackbarHelper.showError(context, 'Could not open website. Please check your internet connection.');
        }
      }
    } catch (e) {
      // Show error message for invalid URL
      if (mounted) {
        SnackbarHelper.showError(context, 'Could not open website. Invalid URL.');
      }
    }
  }

  Widget _buildStepText(String step, BuildContext context) {
    // Check if this step contains "MSone website"
    if (step.contains('MSone website')) {
      // Split the text and create clickable link
      final parts = step.split('MSone website');
      return RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: parts[0]),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => _launchUrl('https://malayalamsubtitles.org/'),
                child: Text(
                  'MSone website',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    decoration: TextDecoration.underline,
                    decorationColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    }
    
    // Return normal text for other steps
    return Text(
      step,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Documentation', style: Theme.of(context).textTheme.titleLarge),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          IconButton(
            onPressed: () => _showQuickNavigation(),
            icon: Icon(Icons.menu_book_outlined, color: Theme.of(context).colorScheme.onSurface,),
            tooltip: 'Quick Navigation',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchSection(),
            _buildCategoryFilter(),
            Expanded(
              child: _buildHelpContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How can we help you?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for features, guides, or solutions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _selectedCategoryIndex = -1; // Reset category filter when searching
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final scrollController = ScrollController();
    
    return SizedBox(
      height: 60,
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            // Convert vertical scroll to horizontal scroll
            final offset = event.scrollDelta.dy;
            scrollController.position.moveTo(
              scrollController.offset + offset,
              curve: Curves.linear,
            );
          }
        },
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
            scrollbars: false,
          ),
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length + 1, // +1 for "All" option
            itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip(
              'All',
              Icons.apps,
              Theme.of(context).primaryColor,
              _selectedCategoryIndex == -1,
              () {
                setState(() {
                  _selectedCategoryIndex = -1;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            );
          }
          
          final category = _categories[index - 1];
          final isSelected = _selectedCategoryIndex == index - 1;
          
          return _buildCategoryChip(
            category.title,
            category.icon,
            category.color,
            isSelected,
            () {
              setState(() {
                _selectedCategoryIndex = index - 1;
                _searchController.clear();
                _searchQuery = '';
              });
            },
          );
        },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpContent() {
    final filteredCategories = _filteredCategories;
    
    if (filteredCategories.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredCategories.length,
      itemBuilder: (context, categoryIndex) {
        final category = filteredCategories[categoryIndex];
        return _buildCategoryCard(category, categoryIndex);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(HelpCategory category, int categoryIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: _selectedCategoryIndex == categoryIndex || _searchQuery.isNotEmpty,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            category.icon,
            color: category.color,
            size: 24,
          ),
        ),
        title: Text(
          category.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: category.sections.map((section) => _buildSectionCard(section, category.color)).toList(),
      ),
    );
  }

  Widget _buildSectionCard(HelpSection section, Color categoryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          section.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: categoryColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.content.isNotEmpty) ...[
                  Text(
                    section.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (section.steps.isNotEmpty) ...[
                  Text(
                    'Step-by-step guide:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...section.steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStepText(step, context),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickNavigation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.7,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Navigation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return ListTile(
                      leading: Icon(
                        category.icon,
                        color: category.color,
                      ),
                      title: Text(category.title),
                      subtitle: Text('${category.sections.length} sections'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollToCategory(category.id);
                      },
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subtitle Studio v${AppInfo.version}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Professional Subtitle Editing Tool',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<HelpSection> sections;

  HelpCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.sections,
  });
}

class HelpSection {
  final String title;
  final String content;
  final List<String> steps;

  HelpSection({
    required this.title,
    required this.content,
    this.steps = const [],
  });
}
