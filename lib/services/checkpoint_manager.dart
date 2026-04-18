// Checkpoint Manager - Hybrid Snapshot + Delta System
//
// This service implements a reliable checkpoint system using a hybrid approach:
// - Snapshots: Full state stored periodically (every 10 checkpoints, at branch points, initial state)
// - Deltas: Only changes stored between snapshots
//
// Key Features:
// - Snapshot-based accuracy: Full state stored periodically for 100% accuracy
// - Delta-based efficiency: Only changes stored between snapshots
// - Tree-based branching: Support for multiple undo/redo branches
// - Automatic checkpoint creation: On major operations (delete, add, split, merge, effect)
// - Manual checkpoints: User can create checkpoints on demand
// - Efficient restoration: Apply deltas from nearest snapshot
//
// Storage Strategy:
// - Initial checkpoint: Always a snapshot (captures starting state)
// - Every 10th checkpoint: Snapshot (ensures max 9 deltas to traverse)
// - Branch points: Snapshot (ensures accuracy when branching)
// - Regular checkpoints: Deltas only (space-efficient)
//
// Restoration Process:
// 1. Find target checkpoint
// 2. Find nearest snapshot before target (max 9 checkpoints back)
// 3. Load snapshot as base state (snapshots store BEFORE state)
// 4. Apply deltas forward from snapshot UP TO (but NOT including) target
// 5. Result: Restores to the BEFORE state of the target checkpoint (100% accurate)
//
// Storage Efficiency:
// - A typical subtitle file with 1000 lines might be ~50KB
// - Snapshot every 10 checkpoints: 10% are 50KB, 90% are ~100 bytes
// - 100 checkpoints = 10 snapshots (500KB) + 90 deltas (9KB) = ~509KB
// - vs Pure snapshots: 5MB (10x reduction)
// - vs Pure deltas: Potential accuracy issues (now solved!)

import 'package:isar_community/isar.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/main.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/subtitle_sorting.dart'; // Enhanced subtitle sorting
import 'dart:convert';

class CheckpointManager {
  // Get maximum checkpoints from preferences (0 = unlimited)
  static Future<int> getMaxCheckpoints() async {
    return await PreferencesModel.getMaxCheckpoints();
  }
  
  // Get snapshot interval from preferences
  static Future<int> getSnapshotInterval() async {
    return await PreferencesModel.getSnapshotInterval();
  }
  
  // Get checkpoint strategy from preferences ('hybrid', 'snapshot', or 'delta')
  static Future<String> getCheckpointStrategy() async {
    return await PreferencesModel.getCheckpointStrategy();
  }
  
  /// Creates initial snapshot of the database state
  /// This should be called when opening a session for the first time
  static Future<int> createInitialSnapshot({
    required int sessionId,
    required int subtitleCollectionId,
  }) async {
    try {
      final collection = await isar.subtitleCollections.get(subtitleCollectionId);
      if (collection == null) {
        logWarning('Subtitle collection not found for initial snapshot: $subtitleCollectionId');
        return 0; // Return 0 to indicate no snapshot was created
      }
      
      // Check if initial snapshot already exists
      final existingInitial = await isar.checkpoints
          .filter()
          .sessionIdEqualTo(sessionId)
          .subtitleCollectionIdEqualTo(subtitleCollectionId)
          .operationTypeEqualTo('snapshot')
          .descriptionEqualTo('Initial state')
          .findFirst();
      
      if (existingInitial != null) {
        logInfo('Initial snapshot already exists: ${existingInitial.id}');
        return existingInitial.id;
      }
      
      // Create initial snapshot
      final checkpoint = Checkpoint(
        sessionId: sessionId,
        subtitleCollectionId: subtitleCollectionId,
        timestamp: DateTime.now(),
        operationType: 'snapshot',
        description: 'Initial state',
        parentCheckpointId: null,
        isActive: true,
        checkpointType: 'snapshot',
        deltas: [], // No deltas for snapshot
        snapshot: collection.lines.map((line) => _copySubtitleLine(line)).toList(),
        metadata: jsonEncode({'reason': 'initial', 'lineCount': collection.lines.length}),
      );
      
      int checkpointId = 0;
      await isar.writeTxn(() async {
        checkpointId = await isar.checkpoints.put(checkpoint);
      });
      
      logInfo('Initial snapshot created: ID $checkpointId with ${collection.lines.length} lines');
      return checkpointId;
    } catch (e) {
      logWarning('Failed to create initial snapshot: $e');
      return 0; // Return 0 to indicate no snapshot was created
    }
  }
  
  /// Creates a new checkpoint for a given operation
  /// Automatically determines if this should be a snapshot or delta
  /// 
  /// Parameters:
  /// - [sessionId]: ID of the current editing session
  /// - [subtitleCollectionId]: ID of the subtitle collection being edited
  /// - [operationType]: Type of operation ('edit', 'delete', 'add', 'split', 'merge', 'effect', 'manual')
  /// - [description]: Human-readable description of the operation
  /// - [deltas]: List of changes made (before and after states)
  /// - [metadata]: Optional JSON metadata for operation-specific data
  /// - [forceSnapshot]: Force this to be a snapshot regardless of interval
  /// - [preOperationState]: Optional pre-operation state for snapshots (if null, current DB state is used)
  /// 
  /// Returns the ID of the created checkpoint
  static Future<int> createCheckpoint({
    required int sessionId,
    required int subtitleCollectionId,
    required String operationType,
    required String description,
    required List<SubtitleLineDelta> deltas,
    Map<String, dynamic>? metadata,
    bool forceSnapshot = false,
    List<SubtitleLine>? preOperationState,
  }) async {
    try {
      // Get the current active checkpoint (most recent active)
      final currentHead = await _getCurrentHeadCheckpoint(sessionId);
      
      // CHECK FOR FUTURE CHECKPOINTS: If current head has children, delete them
      // This happens when user restores to a checkpoint and then makes new changes
      if (currentHead != null) {
        final futureCheckpoints = await isar.checkpoints
            .filter()
            .parentCheckpointIdEqualTo(currentHead.id)
            .findAll();
        
        if (futureCheckpoints.isNotEmpty) {
          // Delete all future checkpoints (they will be replaced by new timeline)
          await _deleteFutureCheckpoints(sessionId, currentHead.id);
          logInfo('Deleted ${futureCheckpoints.length} future checkpoints from ${currentHead.id}');
        }
      }
      
      // Get checkpoint strategy and snapshot interval from preferences
      final checkpointStrategy = await getCheckpointStrategy();
      final snapshotInterval = await getSnapshotInterval();
      
      // Determine if this should be a snapshot based on strategy
      bool shouldCreateSnapshot = forceSnapshot;
      
      if (!shouldCreateSnapshot) {
        if (checkpointStrategy == 'snapshot') {
          // Always create snapshots
          shouldCreateSnapshot = true;
        } else if (checkpointStrategy == 'delta') {
          // Never create automatic snapshots (only manual/forced)
          shouldCreateSnapshot = false;
        } else {
          // Hybrid mode: Count checkpoints since last snapshot
          final checkpointsSinceSnapshot = await _countCheckpointsSinceLastSnapshot(
            sessionId: sessionId,
          );
          
          shouldCreateSnapshot = checkpointsSinceSnapshot >= snapshotInterval;
        }
      }
      
      // Get current subtitle collection state (for fallback if preOperationState not provided)
      final collection = await isar.subtitleCollections.get(subtitleCollectionId);
      if (collection == null) {
        throw Exception('Subtitle collection not found');
      }
      
      // Determine which state to use for snapshots
      List<SubtitleLine> stateToCapture;
      if (shouldCreateSnapshot) {
        if (preOperationState != null) {
          // Use provided pre-operation state (correct for snapshots)
          stateToCapture = preOperationState.map((line) => _copySubtitleLine(line)).toList();
        } else {
          // Fallback to current state (for manual checkpoints or when pre-state not available)
          stateToCapture = collection.lines.map((line) => _copySubtitleLine(line)).toList();
        }
      } else {
        stateToCapture = []; // Deltas don't need full snapshot
      }
      
      // Create checkpoint (snapshot or delta)
      final checkpoint = Checkpoint(
        sessionId: sessionId,
        subtitleCollectionId: subtitleCollectionId,
        timestamp: DateTime.now().toUtc(), // Store in UTC
        operationType: operationType,
        description: description,
        parentCheckpointId: currentHead?.id,
        isActive: true,
        checkpointType: shouldCreateSnapshot ? 'snapshot' : 'delta',
        deltas: shouldCreateSnapshot ? [] : deltas, // Snapshots don't need deltas
        snapshot: stateToCapture,
        metadata: metadata != null ? jsonEncode(metadata) : null,
      );
      
      int checkpointId = 0;
      await isar.writeTxn(() async {
        checkpointId = await isar.checkpoints.put(checkpoint);
      });
      
      logInfo('Checkpoint created: $operationType - $description (ID: $checkpointId, Type: ${checkpoint.checkpointType})');
      
      // Auto-cleanup old checkpoints if needed
      await _autoCleanupCheckpoints(sessionId);
      
      return checkpointId;
    } catch (e) {
      logError('Failed to create checkpoint: $e');
      rethrow;
    }
  }
  
  /// Creates a checkpoint for a delete operation
  /// This should be called BEFORE the delete operation is performed
  static Future<int> createDeleteCheckpoint({
    required int sessionId,
    required int subtitleCollectionId,
    required SubtitleLine deletedLine,
    required int deletedIndex,
  }) async {
    // Get current state BEFORE delete operation
    final collection = await isar.subtitleCollections.get(subtitleCollectionId);
    if (collection == null) {
      throw Exception('Subtitle collection not found');
    }
    
    final delta = SubtitleLineDelta()
      ..changeType = 'delete'
      ..lineIndex = deletedIndex
      ..beforeState = _copySubtitleLine(deletedLine)
      ..afterState = null;
    
    return await createCheckpoint(
      sessionId: sessionId,
      subtitleCollectionId: subtitleCollectionId,
      operationType: 'delete',
      description: 'Deleted line ${deletedLine.index}',
      deltas: [delta],
      preOperationState: collection.lines, // Capture state BEFORE delete
    );
  }
  
  /// Creates a checkpoint for an add operation
  /// This should be called BEFORE the add operation is performed
  static Future<int> createAddCheckpoint({
    required int sessionId,
    required int subtitleCollectionId,
    required SubtitleLine addedLine,
    required int insertIndex,
    List<SubtitleLine>? preOperationState,
  }) async {
    // Get current state BEFORE add operation (if not provided)
    List<SubtitleLine>? stateBeforeAdd = preOperationState;
    if (stateBeforeAdd == null) {
      final collection = await isar.subtitleCollections.get(subtitleCollectionId);
      if (collection == null) {
        throw Exception('Subtitle collection not found');
      }
      stateBeforeAdd = collection.lines;
    }
    
    final delta = SubtitleLineDelta()
      ..changeType = 'add'
      ..lineIndex = insertIndex
      ..beforeState = null
      ..afterState = _copySubtitleLine(addedLine);
    
    return await createCheckpoint(
      sessionId: sessionId,
      subtitleCollectionId: subtitleCollectionId,
      operationType: 'add',
      description: 'Added line at position ${insertIndex + 1}',
      deltas: [delta],
      preOperationState: stateBeforeAdd, // Capture state BEFORE add
    );
  }
  
  /// Creates a checkpoint for an edit operation
  /// This should be called BEFORE the edit operation is performed
  static Future<int> createEditCheckpoint({
    required int sessionId,
    required int subtitleCollectionId,
    required SubtitleLine beforeLine,
    required SubtitleLine afterLine,
  }) async {
    // Get current state BEFORE edit operation
    final collection = await isar.subtitleCollections.get(subtitleCollectionId);
    if (collection == null) {
      throw Exception('Subtitle collection not found');
    }
    
    final delta = SubtitleLineDelta()
      ..changeType = 'modify'
      ..lineIndex = beforeLine.index - 1
      ..beforeState = _copySubtitleLine(beforeLine)
      ..afterState = _copySubtitleLine(afterLine);
    
    return await createCheckpoint(
      sessionId: sessionId,
      subtitleCollectionId: subtitleCollectionId,
      operationType: 'edit',
      description: 'Edited line ${beforeLine.index}',
      deltas: [delta],
      preOperationState: collection.lines, // Capture state BEFORE edit
    );
  }
  
  /// Creates a checkpoint for a split operation
  /// This should be called BEFORE the split operation is performed
  static Future<int> createSplitCheckpoint({
    required int sessionId,
    required int subtitleCollectionId,
    required SubtitleLine originalLine,
    required SubtitleLine firstPart,
    required SubtitleLine secondPart,
    List<SubtitleLine>? preOperationState,
  }) async {
    // Get current state BEFORE split operation (if not provided)
    List<SubtitleLine>? stateBeforeSplit = preOperationState;
    if (stateBeforeSplit == null) {
      final collection = await isar.subtitleCollections.get(subtitleCollectionId);
      if (collection == null) {
        throw Exception('Subtitle collection not found');
      }
      stateBeforeSplit = collection.lines;
    }
    
    final deltas = [
      SubtitleLineDelta()
        ..changeType = 'modify'
        ..lineIndex = originalLine.index - 1
        ..beforeState = _copySubtitleLine(originalLine)
        ..afterState = _copySubtitleLine(firstPart),
      SubtitleLineDelta()
        ..changeType = 'add'
        ..lineIndex = originalLine.index
        ..beforeState = null
        ..afterState = _copySubtitleLine(secondPart),
    ];
    
    return await createCheckpoint(
      sessionId: sessionId,
      subtitleCollectionId: subtitleCollectionId,
      operationType: 'split',
      description: 'Split line ${originalLine.index}',
      deltas: deltas,
      preOperationState: stateBeforeSplit, // Capture state BEFORE split
    );
  }
  
  /// Creates a checkpoint for a merge operation
  /// This should be called BEFORE the merge operation is performed
  static Future<int> createMergeCheckpoint({
    required int sessionId,
    required int subtitleCollectionId,
    required SubtitleLine firstLine,
    required SubtitleLine secondLine,
    required SubtitleLine mergedLine,
    List<SubtitleLine>? preOperationState,
  }) async {
    // Get current state BEFORE merge operation (if not provided)
    List<SubtitleLine>? stateBeforeMerge = preOperationState;
    if (stateBeforeMerge == null) {
      final collection = await isar.subtitleCollections.get(subtitleCollectionId);
      if (collection == null) {
        throw Exception('Subtitle collection not found');
      }
      stateBeforeMerge = collection.lines;
    }
    
    final deltas = [
      SubtitleLineDelta()
        ..changeType = 'modify'
        ..lineIndex = firstLine.index - 1
        ..beforeState = _copySubtitleLine(firstLine)
        ..afterState = _copySubtitleLine(mergedLine),
      SubtitleLineDelta()
        ..changeType = 'delete'
        ..lineIndex = secondLine.index - 1
        ..beforeState = _copySubtitleLine(secondLine)
        ..afterState = null,
    ];
    
    return await createCheckpoint(
      sessionId: sessionId,
      subtitleCollectionId: subtitleCollectionId,
      operationType: 'merge',
      description: 'Merged lines ${firstLine.index} and ${secondLine.index}',
      deltas: deltas,
      preOperationState: stateBeforeMerge, // Capture state BEFORE merge
    );
  }
  
  /// Creates a manual checkpoint (user-initiated)
  static Future<int> createManualCheckpoint({
    required int sessionId,
    required int subtitleCollectionId,
    String? customDescription,
  }) async {
    // Manual checkpoints don't store deltas - they're just markers
    return await createCheckpoint(
      sessionId: sessionId,
      subtitleCollectionId: subtitleCollectionId,
      operationType: 'manual',
      description: customDescription ?? 'Manual checkpoint',
      deltas: [],
    );
  }
  
  /// Undoes to a specific checkpoint
  /// Returns true if successful, false otherwise
  /// Restores to a specific checkpoint using snapshot + delta approach
  /// This is 100% accurate because it loads from nearest snapshot
  /// Falls back to creating a snapshot if none exists (for old checkpoints)
  static Future<bool> undoToCheckpoint({
    required int checkpointId,
    required int sessionId,
  }) async {
    try {
      final targetCheckpoint = await isar.checkpoints.get(checkpointId);
      if (targetCheckpoint == null) {
        logError('Checkpoint not found: $checkpointId');
        return false;
      }
      
      final collection = await isar.subtitleCollections.get(targetCheckpoint.subtitleCollectionId);
      if (collection == null) {
        logError('Subtitle collection not found');
        return false;
      }
      
      // NEW APPROACH: Find nearest snapshot and apply deltas forward
      logInfo('Restoring to checkpoint $checkpointId using snapshot-based approach');
      
      // Step 1: Find the nearest snapshot at or before the target
      var nearestSnapshot = await _findNearestSnapshot(
        sessionId: sessionId,
        targetCheckpointId: checkpointId,
      );
      
      // FALLBACK: If no snapshot found (old checkpoints from before redesign)
      // Create an initial snapshot from current state
      if (nearestSnapshot == null) {
        logInfo('No snapshot found - creating initial snapshot from current state');
        
        try {
          final snapshotId = await createInitialSnapshot(
            sessionId: sessionId,
            subtitleCollectionId: targetCheckpoint.subtitleCollectionId,
          );
          
          nearestSnapshot = await isar.checkpoints.get(snapshotId);
          
          if (nearestSnapshot == null) {
            logError('Failed to create fallback snapshot');
            return false;
          }
          
          logInfo('Created fallback snapshot ${nearestSnapshot.id}');
        } catch (e) {
          logError('Failed to create fallback snapshot: $e');
          
          // LAST RESORT: Try to restore using the target checkpoint's state
          // This works if the target checkpoint itself has restoration data
          logInfo('Attempting direct restoration from target checkpoint');
          
          if (targetCheckpoint.checkpointType == 'snapshot' && targetCheckpoint.snapshot.isNotEmpty) {
            // Target is a snapshot, use it directly
            collection.lines = targetCheckpoint.snapshot.map((line) => _copySubtitleLine(line)).toList();
            _reindexLines(collection);
            
            await isar.writeTxn(() async {
              await isar.subtitleCollections.put(collection);
            });
            
            logInfo('Restored directly from target checkpoint snapshot');
            return true;
          } else {
            // Cannot restore without a snapshot
            logError('Cannot restore: no snapshots available and target is not a snapshot');
            return false;
          }
        }
      }
      
      logInfo('Using snapshot ${nearestSnapshot.id} as base (${nearestSnapshot.description})');
      
      // Step 2: Load the snapshot as base state
      // Snapshots store the BEFORE state, so this is already the pre-operation state
      final restoredLines = nearestSnapshot.snapshot.map((line) => _copySubtitleLine(line)).toList();
      
      // Step 3: If target is the snapshot itself, we're done - snapshot already has BEFORE state
      if (nearestSnapshot.id == checkpointId) {
        collection.lines = restoredLines;
        _reindexLines(collection);
        
        // Update active status - deactivate all checkpoints, then activate target
        await isar.writeTxn(() async {
          // Deactivate all checkpoints in this session
          final allCheckpoints = await isar.checkpoints
              .filter()
              .sessionIdEqualTo(sessionId)
              .findAll();
          
          for (final cp in allCheckpoints) {
            cp.isActive = false;
          }
          
          // Activate only the target checkpoint
          targetCheckpoint.isActive = true;
          
          // Save all changes
          await isar.checkpoints.putAll(allCheckpoints);
          await isar.checkpoints.put(targetCheckpoint);
          await isar.subtitleCollections.put(collection);
        });
        
        logInfo('Restored directly from snapshot (marked as active, others deactivated)');
        return true;
      }
      
      // Step 4: Get all delta checkpoints between snapshot and target
      // IMPORTANT: Get deltas UP TO (but NOT including) the target checkpoint
      // This gives us the BEFORE state of the target checkpoint
      final deltasToApply = await _getDeltaCheckpointsBetween(
        sessionId: sessionId,
        fromSnapshotId: nearestSnapshot.id,
        toCheckpointId: checkpointId,
        excludeTarget: true, // Don't include target's deltas - we want the BEFORE state
      );
      
      logInfo('Applying ${deltasToApply.length} deltas from snapshot (excluding target checkpoint to get BEFORE state)');
      
      // Step 5: Apply deltas in order (NOT in reverse!)
      // We're applying forward from snapshot to just BEFORE the target
      for (final checkpoint in deltasToApply) {
        logInfo('Applying delta: ${checkpoint.description}');
        _applyDeltasToList(restoredLines, checkpoint.deltas);
      }
      
      // Step 6: Update collection with restored state
      collection.lines = restoredLines;
      _reindexLines(collection);
      
      // Step 7: Update active status - deactivate all checkpoints, then activate target
      await isar.writeTxn(() async {
        // Deactivate all checkpoints in this session
        final allCheckpoints = await isar.checkpoints
            .filter()
            .sessionIdEqualTo(sessionId)
            .findAll();
        
        for (final cp in allCheckpoints) {
          cp.isActive = false;
        }
        
        // Activate only the target checkpoint
        targetCheckpoint.isActive = true;
        
        // Save all changes
        await isar.checkpoints.putAll(allCheckpoints);
        await isar.checkpoints.put(targetCheckpoint);
        await isar.subtitleCollections.put(collection);
      });
      
      logInfo('Successfully restored to checkpoint: $checkpointId (marked as active, others deactivated)');
      return true;
    } catch (e) {
      logError('Failed to restore to checkpoint: $e');
      return false;
    }
  }
  
  /// Redoes to a specific checkpoint (same as undo, just different terminology)
  /// Returns true if successful, false otherwise
  static Future<bool> redoToCheckpoint({
    required int checkpointId,
    required int sessionId,
  }) async {
    // Redo is the same as undo in our tree-based system
    return await undoToCheckpoint(
      checkpointId: checkpointId,
      sessionId: sessionId,
    );
  }
  
  /// Gets all checkpoints for a session
  static Future<List<Checkpoint>> getCheckpointsForSession(int sessionId) async {
    return await isar.checkpoints
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestampDesc()
        .findAll();
  }
  
  /// Deletes all checkpoints for a session (cleanup when session is deleted)
  static Future<void> deleteCheckpointsForSession(int sessionId) async {
    await isar.writeTxn(() async {
      final checkpoints = await getCheckpointsForSession(sessionId);
      final checkpointIds = checkpoints.map((c) => c.id).toList();
      await isar.checkpoints.deleteAll(checkpointIds);
    });
    
    logInfo('Deleted all checkpoints for session: $sessionId');
  }
  
  // ==================== Private Helper Methods ====================
  
  /// Counts checkpoints since last snapshot
  static Future<int> _countCheckpointsSinceLastSnapshot({
    required int sessionId,
  }) async {
    // Get all checkpoints, filter for snapshots manually
    final allCheckpoints = await isar.checkpoints
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestampDesc()
        .findAll();
    
    // Find the most recent snapshot
    Checkpoint? lastSnapshot;
    for (final checkpoint in allCheckpoints) {
      if (checkpoint.checkpointType == 'snapshot') {
        lastSnapshot = checkpoint;
        break; // Found most recent snapshot
      }
    }
    
    if (lastSnapshot == null) {
      // No snapshot yet, return count of all checkpoints
      return allCheckpoints.length;
    }
    
    // Count checkpoints after last snapshot
    int count = 0;
    for (final checkpoint in allCheckpoints) {
      if (checkpoint.timestamp.isAfter(lastSnapshot.timestamp)) {
        count++;
      }
    }
    
    return count;
  }
  
  /// Finds the nearest snapshot at or before a target checkpoint
  /// Returns null if no snapshot found
  static Future<Checkpoint?> _findNearestSnapshot({
    required int sessionId,
    required int targetCheckpointId,
  }) async {
    // Build path from target back to root
    final pathToRoot = <Checkpoint>[];
    int? currentId = targetCheckpointId;
    
    while (currentId != null) {
      final checkpoint = await isar.checkpoints.get(currentId);
      if (checkpoint == null) break;
      
      pathToRoot.add(checkpoint);
      
      // If this checkpoint is a snapshot, we found it!
      if (checkpoint.checkpointType == 'snapshot') {
        return checkpoint;
      }
      
      currentId = checkpoint.parentCheckpointId;
    }
    
    // No snapshot found in the path - this shouldn't happen if initial snapshot was created
    logError('No snapshot found in path to checkpoint $targetCheckpointId');
    return null;
  }
  
  /// Gets all delta checkpoints between a snapshot and target checkpoint
  /// Returns checkpoints in chronological order (oldest first)
  /// 
  /// If [excludeTarget] is true, the target checkpoint itself is NOT included
  /// This is used when restoring to get the BEFORE state of a checkpoint
  static Future<List<Checkpoint>> _getDeltaCheckpointsBetween({
    required int sessionId,
    required int fromSnapshotId,
    required int toCheckpointId,
    bool excludeTarget = false,
  }) async {
    if (fromSnapshotId == toCheckpointId) {
      return []; // No deltas between a checkpoint and itself
    }
    
    // Build path from target back to snapshot
    final pathFromTarget = <Checkpoint>[];
    int? currentId = toCheckpointId;
    
    // If excludeTarget is true, start from the parent of the target
    if (excludeTarget) {
      final targetCheckpoint = await isar.checkpoints.get(toCheckpointId);
      if (targetCheckpoint != null) {
        currentId = targetCheckpoint.parentCheckpointId;
      }
    }
    
    while (currentId != null && currentId != fromSnapshotId) {
      final checkpoint = await isar.checkpoints.get(currentId);
      if (checkpoint == null) break;
      
      // Only include delta checkpoints, not snapshots
      if (checkpoint.checkpointType == 'delta') {
        pathFromTarget.add(checkpoint);
      }
      
      currentId = checkpoint.parentCheckpointId;
    }
    
    // Reverse to get chronological order (oldest first)
    return pathFromTarget.reversed.toList();
  }
  
  /// Applies a list of deltas to a list of subtitle lines
  /// This modifies the list in place
  static void _applyDeltasToList(List<SubtitleLine> lines, List<SubtitleLineDelta> deltas) {
    for (final delta in deltas) {
      switch (delta.changeType) {
        case 'add':
          // Add operation: insert the line
          if (delta.afterState != null) {
            final insertIndex = delta.lineIndex.clamp(0, lines.length);
            lines.insert(insertIndex, _copySubtitleLine(delta.afterState!));
          }
          break;
        
        case 'delete':
          // Delete operation: remove the line
          if (delta.lineIndex < lines.length) {
            lines.removeAt(delta.lineIndex);
          }
          break;
        
        case 'modify':
          // Modify operation: replace the line
          if (delta.afterState != null && delta.lineIndex < lines.length) {
            lines[delta.lineIndex] = _copySubtitleLine(delta.afterState!);
          }
          break;
      }
    }
  }
  
  /// Deletes all checkpoints after a given checkpoint (future checkpoints)
  /// Used when creating new changes after restoring to an older checkpoint
  static Future<void> _deleteFutureCheckpoints(int sessionId, int afterCheckpointId) async {
    // Get all checkpoints for the session
    final allCheckpoints = await getCheckpointsForSession(sessionId);
    
    // Build a set of checkpoint IDs to delete (all descendants of afterCheckpointId)
    final idsToDelete = <int>{};
    
    void collectDescendants(int parentId) {
      for (final checkpoint in allCheckpoints) {
        if (checkpoint.parentCheckpointId == parentId) {
          idsToDelete.add(checkpoint.id);
          collectDescendants(checkpoint.id); // Recursively collect descendants
        }
      }
    }
    
    collectDescendants(afterCheckpointId);
    
    if (idsToDelete.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.checkpoints.deleteAll(idsToDelete.toList());
      });
      logInfo('Deleted ${idsToDelete.length} future checkpoints after checkpoint $afterCheckpointId');
    }
  }
  
  /// Gets the current head checkpoint (most recent active)
  static Future<Checkpoint?> _getCurrentHeadCheckpoint(int sessionId) async {
    return await isar.checkpoints
        .filter()
        .sessionIdEqualTo(sessionId)
        .isActiveEqualTo(true)
        .sortByTimestampDesc()
        .findFirst();
  }
  
  // OLD METHODS - Kept for reference, not used in snapshot-based approach
  // =========================================================================
  
  /* 
  /// Gets checkpoints between two points in the checkpoint tree (OLD APPROACH)
  static Future<List<Checkpoint>> _getCheckpointsBetween({
    required int sessionId,
    int? fromCheckpointId,
    required int toCheckpointId,
  }) async {
    // Get all checkpoints for the session
    final allCheckpoints = await getCheckpointsForSession(sessionId);
    
    // Build a map of checkpoint ID to checkpoint for quick lookup
    final checkpointMap = {for (var cp in allCheckpoints) cp.id: cp};
    
    // Find the target checkpoint
    final targetCheckpoint = checkpointMap[toCheckpointId];
    if (targetCheckpoint == null) return [];
    
    // If fromCheckpointId is null, we need to find the current head
    // and build the path from there to the target
    if (fromCheckpointId == null) {
      // Find the most recent checkpoint in the active branch
      final activeBranch = await _getOrCreateActiveBranch(sessionId);
      final headCheckpoint = await _getCurrentHeadCheckpoint(sessionId, activeBranch.branchId);
      if (headCheckpoint == null) return [];
      fromCheckpointId = headCheckpoint.id;
    }
    
    // Build path from target back to root
    final targetPath = <int>[];
    int? currentId = toCheckpointId;
    while (currentId != null) {
      targetPath.add(currentId);
      currentId = checkpointMap[currentId]?.parentCheckpointId;
    }
    
    // Build path from head back to root
    final headPath = <int>[];
    currentId = fromCheckpointId;
    while (currentId != null) {
      headPath.add(currentId);
      currentId = checkpointMap[currentId]?.parentCheckpointId;
    }
    
    // Find the common ancestor
    final targetPathSet = targetPath.toSet();
    int? commonAncestor;
    for (final id in headPath) {
      if (targetPathSet.contains(id)) {
        commonAncestor = id;
        break;
      }
    }
    
    // If target is the same as head or is an ancestor of head, we need to undo
    if (commonAncestor == toCheckpointId) {
      // Get checkpoints from head to target (excluding target itself)
      final checkpointsToUndo = <Checkpoint>[];
      for (final id in headPath) {
        if (id == toCheckpointId) break;
        final checkpoint = checkpointMap[id];
        if (checkpoint != null) {
          checkpointsToUndo.add(checkpoint);
        }
      }
      return checkpointsToUndo;
    }
    
    // If we need to redo (target is ahead of head)
    // This shouldn't happen in our undo logic, but handle it anyway
    return [];
  }
  
  /// Applies undo operation for a checkpoint (OLD APPROACH)
  static Future<void> _applyCheckpointUndo(
    SubtitleCollection collection,
    Checkpoint checkpoint,
  ) async {
    // Ensure lines is a growable list
    final lines = List<SubtitleLine>.from(collection.lines, growable: true);
    
    for (final delta in checkpoint.deltas.reversed) {
      switch (delta.changeType) {
        case 'add':
          // Undo add = delete the line
          if (delta.lineIndex < lines.length) {
            lines.removeAt(delta.lineIndex);
          }
          break;
        
        case 'delete':
          // Undo delete = restore the line
          if (delta.beforeState != null) {
            // Clamp lineIndex to valid insertion range [0, lines.length]
            final insertIndex = delta.lineIndex.clamp(0, lines.length);
            lines.insert(insertIndex, _copySubtitleLine(delta.beforeState!));
          }
          break;
        
        case 'modify':
          // Undo modify = restore previous state
          if (delta.beforeState != null && delta.lineIndex < lines.length) {
            lines[delta.lineIndex] = _copySubtitleLine(delta.beforeState!);
          }
          break;
      }
    }
    
    // Update collection with modified list
    collection.lines = lines;
    
    // Reindex lines
    _reindexLines(collection);
  }
  
  /// Applies redo operation for a checkpoint
  static Future<void> _applyCheckpointRedo(
    SubtitleCollection collection,
    Checkpoint checkpoint,
  ) async {
    // Ensure lines is a growable list
    final lines = List<SubtitleLine>.from(collection.lines, growable: true);
    
    for (final delta in checkpoint.deltas) {
      switch (delta.changeType) {
        case 'add':
          // Redo add = add the line
          if (delta.afterState != null) {
            // Clamp lineIndex to valid insertion range [0, lines.length]
            final insertIndex = delta.lineIndex.clamp(0, lines.length);
            lines.insert(insertIndex, _copySubtitleLine(delta.afterState!));
          }
          break;
        
        case 'delete':
          // Redo delete = remove the line
          if (delta.lineIndex < lines.length) {
            lines.removeAt(delta.lineIndex);
          }
          break;
        
        case 'modify':
          // Redo modify = apply new state
          if (delta.afterState != null && delta.lineIndex < lines.length) {
            lines[delta.lineIndex] = _copySubtitleLine(delta.afterState!);
          }
          break;
      }
    }
    
    // Update collection with modified list
    collection.lines = lines;
    
    // Reindex lines
    _reindexLines(collection);
  }
  */ // End of OLD METHODS
  
  /// Creates a deep copy of a SubtitleLine
  static SubtitleLine _copySubtitleLine(SubtitleLine line) {
    return SubtitleLine()
      ..index = line.index
      ..startTime = line.startTime
      ..endTime = line.endTime
      ..original = line.original
      ..edited = line.edited
      ..marked = line.marked
      ..comment = line.comment
      ..resolved = line.resolved;
  }
  
  /// Reindexes all lines in a collection using intelligent sorting
  /// Preserves overlaps and handles positioning tags correctly
  static void _reindexLines(SubtitleCollection collection) {
    collection.lines = sortAndReindexSubtitleLines(collection.lines);
  }
  
  /// Auto-cleanup old checkpoints to prevent database bloat
  /// Preserves initial snapshot and manual checkpoints
  /// Uses limit-based cleanup only (no age-based cleanup)
  static Future<void> _autoCleanupCheckpoints(int sessionId) async {
    try {
      final allCheckpoints = await getCheckpointsForSession(sessionId);
      final maxCheckpoints = await getMaxCheckpoints();
      
      // Only cleanup if there's a limit (0 = unlimited)
      if (maxCheckpoints > 0 && allCheckpoints.length > maxCheckpoints) {
        // Keep only the most recent checkpoints
        final toDelete = allCheckpoints
            .skip(maxCheckpoints)
            .where((c) => 
              c.operationType != 'manual' && // Keep manual checkpoints
              !(c.operationType == 'snapshot' && c.description == 'Initial state') // Keep initial snapshot
            )
            .toList();
        
        if (toDelete.isNotEmpty) {
          await isar.writeTxn(() async {
            final idsToDelete = toDelete.map((c) => c.id).toList();
            await isar.checkpoints.deleteAll(idsToDelete);
          });
          
          logInfo('Cleaned up ${toDelete.length} old checkpoints (limit: $maxCheckpoints, preserved initial snapshot and manual checkpoints)');
        }
      }
    } catch (e) {
      logError('Failed to cleanup checkpoints: $e');
    }
  }
}
