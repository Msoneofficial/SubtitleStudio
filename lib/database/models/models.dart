import 'package:isar_community/isar.dart';

part 'models.g.dart';

// Force regeneration by adding a comment
// Generated file rebuild attempt

/// Sorting options for session list
enum SessionSortOption {
  lastOpened,  // Default: Sort by last edited/opened (most recent first)
  lastCreated, // Sort by creation date (newest first)
  name,        // Sort by file name (alphabetically)
  nameDesc,    // Sort by file name (reverse alphabetically)
}

@collection
class Preferences {
  Id id = Isar.autoIncrement; // Auto-generated ID for each subtitle document.

  late int? lastEditedSession; //ID of last edited session.
  late String? themeMode; // Theme mode preference
  bool autoSave; // Whether to automatically save the changes to the database.
  
  // MSone features
  bool msoneEnabled = false;
  List<String> colorHistory = [];
  bool floatingControlsEnabled = false;
  bool showOriginalLine = false;
  bool autoSaveWithNavigation = false;
  bool saveToFileEnabled = false;
  bool msoneDictionaryEnabled = false;
  bool hideVideoOnKeyboard = false;
  bool olamWholeWordSearch = false;
  bool olamCaseSensitiveSearch = false;
  bool showOriginalTextField = true;
  bool autoResizeOnKeyboard = true;
  bool showAllComments = false;
  
  // Translator information
  String? translatorName;
  String? translatorEmail;
  String? translatorContactId;
  
  // Olam dictionary
  String? olamLastUpdateDate;
  
  // Subtitle settings
  int maxLineLength = 32;
  String? subtitleFontPath;
  double subtitleFontSize = 16.0;
  double editScreenResizeRatio = 0.35;
  double editLineResizeRatio = 0.35;
  double mobileVideoResizeRatio = 0.4;
  int skipDurationSeconds = 10;
  double primarySubtitleVerticalPosition = 0.0;
  double secondarySubtitleVerticalPosition = 0.0;
  double videoVolume = 100.0;
  bool showSubtitleBackground;
  
  // Layout preferences
  String switchLayout = 'layout1';
  
  // App font settings
  String? appFontPath;
  String? appFontName;
  
  // File system
  String? lastUsedDirectory;
  
  // Checkpoint system
  int maxCheckpoints = 25;
  int snapshotInterval = 10;
  String checkpointStrategy = 'hybrid';
  
  // AI Features
  String? geminiApiKey;
  String geminiModel = 'models/gemini-2.5-flash'; // Default model
  String? aiExplanationPrompt; // Custom prompt for AI explanation
  int? aiExplanationContextLines = 3; // Number of context lines (default 3)

  // Waveform settings
  int? waveformMaxPixels; // Maximum pixels for detailed view (default: 500000)
  int? waveformSampleRateFactor; // Sample rate downsampling factor (default: 16)
  double? waveformZoomMultiplier; // Zoom level multiplier (default: 1.35)

  // Session sorting
  @enumerated
  SessionSortOption sessionSortOption = SessionSortOption.lastOpened; // Default sorting option

  // Constructor
  Preferences({
    this.lastEditedSession,
    required this.autoSave,
    this.themeMode,
    this.msoneEnabled = false,
    this.colorHistory = const [],
    this.floatingControlsEnabled = false,
    this.showOriginalLine = false,
    this.autoSaveWithNavigation = false,
    this.saveToFileEnabled = false,
    this.msoneDictionaryEnabled = false,
    this.hideVideoOnKeyboard = false,
    this.olamWholeWordSearch = false,
    this.olamCaseSensitiveSearch = false,
    this.showOriginalTextField = true,
    this.autoResizeOnKeyboard = true,
    this.showAllComments = false,
    this.translatorName,
    this.translatorEmail,
    this.translatorContactId,
    this.olamLastUpdateDate,
    this.maxLineLength = 32,
    this.subtitleFontPath,
    this.subtitleFontSize = 16.0,
    this.editScreenResizeRatio = 0.35,
    this.editLineResizeRatio = 0.35,
    this.mobileVideoResizeRatio = 0.4,
    this.skipDurationSeconds = 10,
    this.primarySubtitleVerticalPosition = 0.0,
    this.secondarySubtitleVerticalPosition = 0.0,
    this.showSubtitleBackground = true,
    this.videoVolume = 100.0,
    this.switchLayout = 'layout1',
    this.appFontPath,
    this.appFontName,
    this.lastUsedDirectory,
    this.maxCheckpoints = 25,
    this.snapshotInterval = 10,
    this.checkpointStrategy = 'hybrid',
    this.geminiApiKey,
    this.geminiModel = 'models/gemini-2.5-flash',
    this.aiExplanationPrompt,
    this.aiExplanationContextLines = 3,
    this.waveformMaxPixels,
    this.waveformSampleRateFactor,
    this.waveformZoomMultiplier,
    this.sessionSortOption = SessionSortOption.lastOpened,
  });
}

@collection
class Session {
  Id id = Isar.autoIncrement; // Auto-incremented ID.

  late String fileName; // Name of the subtitle file.

  int? lastEditedIndex; // Nullable to indicate if it hasn't been edited yet.

  late int subtitleCollectionId; // Store the ID of the subtitle collection.
  
  bool editMode = false; // Default to false (translation mode)
  
  String? projectFilePath; // Path/URI to the associated .msone project file

  // Constructor
  Session({
    required this.fileName,
    this.lastEditedIndex,
    required this.subtitleCollectionId,
    this.editMode = false,
    this.projectFilePath,
  });
}

@collection
class SubtitleCollection {
  // Renamed from Subtitle
  Id id = Isar.autoIncrement;
  late String fileName;
  late String? filePath;
  late String? originalFileUri; // Store original file URI for future SAF use
  late String encoding;
  late List<SubtitleLine> lines;
  String? macOsSrtBookmark; // Base64 encoded security-scoped bookmark for the SRT file on macOS

  SubtitleCollection({
    required this.fileName,
    this.filePath,
    this.originalFileUri,
    required this.encoding,
    required this.lines,
    this.macOsSrtBookmark,
  });
}

@embedded
class SubtitleLine {
  late int index; // Index of the subtitle line.
  late String startTime; // Start time of the subtitle.
  late String endTime; // End time of the subtitle.
  late String original; // Original text of the subtitle.
  String? edited; // Nullable edited text.
  bool marked = false; // Whether this line is marked by the user
  String? comment; // Optional comment for marked lines
  bool resolved = false; // Whether the comment is resolved

  // Remove required parameters from the constructor
  SubtitleLine();
}

/// Dictionary entries for EN-ML and ML-EN translations
@collection
class DictionaryEntry {
  Id id = Isar.autoIncrement;
  late String word; // English word or Malayalam word
  late String meaning; // Translation or meaning
  late String partOfSpeech; // Parts of speech like {n}, {v}, etc.
  late String dictionaryType; // 'EN-ML', 'ML-EN', or 'ML-ML'

  DictionaryEntry({
    required this.word,
    required this.meaning,
    required this.partOfSpeech,
    required this.dictionaryType,
  });
}

/// Checkpoint system for undo/redo functionality
/// Uses delta-based storage to minimize space consumption
@collection
class Checkpoint {
  Id id = Isar.autoIncrement;
  
  late int sessionId; // Link to the editing session
  late int subtitleCollectionId; // Link to subtitle collection
  
  late DateTime timestamp; // When this checkpoint was created
  late String operationType; // 'edit', 'delete', 'add', 'split', 'merge', 'effect', 'manual', 'snapshot'
  late String description; // Human-readable description (e.g., "Deleted line 5")
  
  int? parentCheckpointId; // Previous checkpoint (null for initial state)
  late bool isActive; // Is this checkpoint the current active one?
  
  // Checkpoint Type: 'delta' or 'snapshot'
  late String checkpointType; // 'delta' = stores changes only, 'snapshot' = stores full state
  
  // Store only the changes (delta) for delta checkpoints
  late List<SubtitleLineDelta> deltas;
  
  // Store full state (snapshot) for snapshot checkpoints
  // This is used every 10 checkpoints or at branch points for accuracy
  late List<SubtitleLine> snapshot;
  
  // Metadata for the operation
  late String? metadata; // JSON string for additional operation-specific data
  
  Checkpoint({
    required this.sessionId,
    required this.subtitleCollectionId,
    required this.timestamp,
    required this.operationType,
    required this.description,
    this.parentCheckpointId,
    this.isActive = true,
    this.checkpointType = 'delta', // Default to delta
    required this.deltas,
    required this.snapshot,
    this.metadata,
  });
}

/// Represents a change to a single subtitle line
/// Stores minimal data needed to undo/redo an operation
@embedded
class SubtitleLineDelta {
  late String changeType; // 'add', 'modify', 'delete'
  late int lineIndex; // Index of the affected line
  
  // Before state (for undo)
  SubtitleLine? beforeState;
  
  // After state (for redo)
  SubtitleLine? afterState;
  
  SubtitleLineDelta();
}

/// Video-specific preferences for each subtitle collection
/// Stores settings that are tied to a specific video file
@collection
class VideoPreferences {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late int subtitleCollectionId; // Link to the subtitle collection
  
  String? videoPath; // Path to the associated video file
  String? macOsBookmark; // Base64 encoded security-scoped bookmark for macOS
  String? selectedAudioTrackId; // ID of the selected audio track
  String? selectedAudioTrackTitle; // Title of the selected audio track for display
  String? selectedAudioTrackLanguage; // Language of the selected audio track
  
  String? secondarySubtitlePath; // Path to secondary subtitle file
  bool secondaryIsOriginal = false; // Whether secondary subtitle uses original text
  
  // Waveform cache data
  String? waveformPcmPath; // Path to cached PCM file
  int? waveformSampleRate; // Sample rate (e.g., 44100)
  int? waveformTotalSamples; // Total number of samples
  int? waveformChannels; // Number of channels (typically 1 for mono)
  DateTime? waveformGeneratedAt; // When the waveform was generated
  
  // Waveform zoom preferences
  int? waveformZoomIndex; // Horizontal zoom level index
  double? waveformVerticalZoom; // Vertical zoom level (amplitude)
  
  VideoPreferences({
    required this.subtitleCollectionId,
    this.videoPath,
    this.macOsBookmark,
    this.selectedAudioTrackId,
    this.selectedAudioTrackTitle,
    this.selectedAudioTrackLanguage,
    this.secondarySubtitlePath,
    this.secondaryIsOriginal = false,
    this.waveformPcmPath,
    this.waveformSampleRate,
    this.waveformTotalSamples,
    this.waveformChannels,
    this.waveformGeneratedAt,
    this.waveformZoomIndex,
    this.waveformVerticalZoom,
  });
}

/// Tutorial completion status for different screens
@collection
class TutorialStatus {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String screenName; // Name of the screen/tutorial
  
  bool hasSeenTutorial = false; // Whether the user has completed the tutorial
  
  TutorialStatus({
    required this.screenName,
    this.hasSeenTutorial = false,
  });
}
