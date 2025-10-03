import 'dart:async';
import 'package:flutter/material.dart';
import 'smart_bottom_sheet_service.dart';

/// Proactive data preloader that anticipates user actions
/// and preloads data before bottom sheets are shown
class ProactiveDataPreloader {
  static final ProactiveDataPreloader _instance = ProactiveDataPreloader._internal();
  factory ProactiveDataPreloader() => _instance;
  ProactiveDataPreloader._internal();

  final SmartBottomSheetService _smartBottomSheet = SmartBottomSheetService();

  // Preloading state
  final Map<String, Timer> _preloadTimers = {};
  final Set<String> _currentlyPreloading = {};

  /// Initialize the preloader with app lifecycle awareness
  void initialize(BuildContext context) {
    print('🚀 [PROACTIVE_PRELOADER] Initialized');
    
    // Start proactive preloading based on user patterns
    _scheduleCommonPreloads();
  }

  /// Preload comments when user hovers over comment button
  void preloadCommentsOnHover(String postId, {Future<Map<String, dynamic>> Function()? dataLoader}) {
    final key = 'comments_$postId';
    
    if (_currentlyPreloading.contains(key)) return;
    
    _currentlyPreloading.add(key);
    
    // Cancel any existing timer
    _preloadTimers[key]?.cancel();
    
    // Start preloading after a short delay (user might just be scrolling)
    _preloadTimers[key] = Timer(const Duration(milliseconds: 300), () async {
      try {
        print('🔄 [PROACTIVE_PRELOADER] Preloading comments for post: $postId');
        
        if (dataLoader != null) {
          await _smartBottomSheet.preloadData(
            cacheKey: key,
            dataLoader: dataLoader,
          );
        } else {
          // Use default SmartCommentsBottomSheet loader if available
          print('⚠️ [PROACTIVE_PRELOADER] No data loader provided for comments');
        }
        
        print('✅ [PROACTIVE_PRELOADER] Comments preloaded for post: $postId');
      } catch (e) {
        print('⚠️ [PROACTIVE_PRELOADER] Failed to preload comments for $postId: $e');
      } finally {
        _currentlyPreloading.remove(key);
        _preloadTimers.remove(key);
      }
    });
  }

  /// Preload events when user navigates to create post screen
  void preloadEventsForCreatePost({Future<Map<String, dynamic>> Function()? dataLoader}) {
    const key = 'available_events';
    
    if (_currentlyPreloading.contains(key)) return;
    
    _currentlyPreloading.add(key);
    
    Timer(const Duration(milliseconds: 100), () async {
      try {
        print('🔄 [PROACTIVE_PRELOADER] Preloading events for create post');
        
        if (dataLoader != null) {
          await _smartBottomSheet.preloadData(
            cacheKey: key,
            dataLoader: dataLoader,
          );
        } else {
          print('⚠️ [PROACTIVE_PRELOADER] No data loader provided for events');
        }
        
        print('✅ [PROACTIVE_PRELOADER] Events preloaded for create post');
      } catch (e) {
        print('⚠️ [PROACTIVE_PRELOADER] Failed to preload events: $e');
      } finally {
        _currentlyPreloading.remove(key);
      }
    });
  }

  /// Preload popular content that users frequently access
  void preloadPopularContent(List<String> popularPostIds) {
    for (final postId in popularPostIds) {
      final key = 'comments_$postId';
      
      if (_currentlyPreloading.contains(key)) continue;
      
      _currentlyPreloading.add(key);
      
      // Stagger preloading to avoid overwhelming the server
      final delay = Duration(milliseconds: 500 * popularPostIds.indexOf(postId));
      
      Timer(delay, () async {
        try {
          // Preload without data since the service handles it
          await _smartBottomSheet.preloadData(
            cacheKey: key,
            dataLoader: () async => <String, dynamic>{}, // Empty data loader
          );
        } catch (e) {
          print('⚠️ [PROACTIVE_PRELOADER] Failed to preload popular content for $postId: $e');
        } finally {
          _currentlyPreloading.remove(key);
        }
      });
    }
  }

  /// Cancel preloading for a specific key
  void cancelPreloading(String key) {
    _preloadTimers[key]?.cancel();
    _preloadTimers.remove(key);
    _currentlyPreloading.remove(key);
  }

  /// Schedule common preloads based on user patterns
  void _scheduleCommonPreloads() {
    // Preload events every few minutes to keep cache fresh
    Timer.periodic(const Duration(minutes: 5), (_) {
      if (!_currentlyPreloading.contains('available_events')) {
        preloadEventsForCreatePost();
      }
    });
  }

  /// Get preloader statistics
  Map<String, dynamic> getStats() {
    return {
      'active_preloads': _currentlyPreloading.length,
      'scheduled_timers': _preloadTimers.length,
      'preloading_keys': _currentlyPreloading.toList(),
      'cache_stats': _smartBottomSheet.getCacheStats(),
    };
  }

  /// Dispose all resources
  void dispose() {
    for (final timer in _preloadTimers.values) {
      timer.cancel();
    }
    _preloadTimers.clear();
    _currentlyPreloading.clear();
    
    print('🛑 [PROACTIVE_PRELOADER] Disposed');
  }
}

/// Widget mixin that adds proactive preloading capabilities
mixin ProactivePreloadingMixin<T extends StatefulWidget> on State<T> {
  ProactiveDataPreloader get preloader => ProactiveDataPreloader();

  /// Preload comments when user might tap comment button
  void onCommentButtonHover(String postId) {
    preloader.preloadCommentsOnHover(postId);
  }

  /// Preload events when navigating to create post
  void onCreatePostNavigation() {
    preloader.preloadEventsForCreatePost();
  }

  /// Preload popular content
  void preloadPopularContent(List<String> postIds) {
    preloader.preloadPopularContent(postIds);
  }
}

/// Extension for easy access to proactive preloading
extension ProactivePreloadingExtension on BuildContext {
  /// Get the proactive data preloader
  ProactiveDataPreloader get preloader => ProactiveDataPreloader();
}