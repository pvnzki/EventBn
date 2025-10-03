import 'dart:async';
import 'package:flutter/material.dart';

/// Enhanced bottom sheet service that automatically preloads data
/// and provides smooth user experience without manual scrolling
class SmartBottomSheetService {
  static final SmartBottomSheetService _instance = SmartBottomSheetService._internal();
  factory SmartBottomSheetService() => _instance;
  SmartBottomSheetService._internal();

  // Cache for preloaded data
  final Map<String, dynamic> _dataCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Completer<dynamic>> _loadingTasks = {};

  // Configuration
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const Duration _preloadTimeout = Duration(seconds: 10);

  /// Preload data before showing bottom sheet
  Future<T?> preloadData<T>({
    required String cacheKey,
    required Future<T> Function() dataLoader,
    Duration? timeout,
  }) async {
    // Check if data is already cached and fresh
    final cachedData = _getCachedData<T>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    // Check if loading is already in progress
    if (_loadingTasks.containsKey(cacheKey)) {
      try {
        return await _loadingTasks[cacheKey]!.future as T?;
      } catch (e) {
        print('⚠️ [SMART_BOTTOM_SHEET] Existing load task failed: $e');
      }
    }

    // Start new loading task
    final completer = Completer<T>();
    _loadingTasks[cacheKey] = completer as Completer<dynamic>;

    try {
      print('🔄 [SMART_BOTTOM_SHEET] Preloading data for key: $cacheKey');
      
      final data = await dataLoader().timeout(
        timeout ?? _preloadTimeout,
        onTimeout: () => throw TimeoutException('Data loading timeout', _preloadTimeout),
      );

      // Cache the loaded data
      _dataCache[cacheKey] = data;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      completer.complete(data);
      print('✅ [SMART_BOTTOM_SHEET] Data preloaded successfully for key: $cacheKey');
      
      return data;
    } catch (e) {
      print('❌ [SMART_BOTTOM_SHEET] Failed to preload data for key $cacheKey: $e');
      completer.completeError(e);
      return null;
    } finally {
      _loadingTasks.remove(cacheKey);
    }
  }

  /// Show bottom sheet with preloaded data
  Future<T?> showBottomSheetWithData<T>({
    required BuildContext context,
    required String cacheKey,
    required Future<dynamic> Function() dataLoader,
    required Widget Function(BuildContext context, dynamic data, bool isLoading) builder,
    bool isScrollControlled = true,
    bool isDismissible = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
  }) async {
    // Start preloading immediately
    final preloadFuture = preloadData(
      cacheKey: cacheKey,
      dataLoader: dataLoader,
    );

    // Show bottom sheet immediately with loading state or cached data
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      shape: shape,
      builder: (context) => _SmartBottomSheetContent(
        cacheKey: cacheKey,
        preloadFuture: preloadFuture,
        builder: builder,
      ),
    );
  }

  /// Show draggable bottom sheet with preloaded data
  Widget buildDraggableSheetWithData({
    required String cacheKey,
    required Future<dynamic> Function() dataLoader,
    required Widget Function(BuildContext context, ScrollController controller, dynamic data, bool isLoading) builder,
    double initialChildSize = 0.7,
    double minChildSize = 0.5,
    double maxChildSize = 0.9,
  }) {
    // Start preloading immediately
    final preloadFuture = preloadData(
      cacheKey: cacheKey,
      dataLoader: dataLoader,
    );

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (context, scrollController) => _SmartDraggableContent(
        scrollController: scrollController,
        cacheKey: cacheKey,
        preloadFuture: preloadFuture,
        builder: builder,
      ),
    );
  }

  /// Get cached data if available and fresh
  T? _getCachedData<T>(String cacheKey) {
    if (!_dataCache.containsKey(cacheKey)) return null;
    
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return null;
    
    // Check if data is still fresh
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _dataCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      return null;
    }
    
    return _dataCache[cacheKey] as T?;
  }

  /// Clear cached data for a specific key
  void clearCache(String cacheKey) {
    _dataCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
  }

  /// Clear all cached data
  void clearAllCache() {
    _dataCache.clear();
    _cacheTimestamps.clear();
  }

  /// Check if data is currently loading
  bool isLoading(String cacheKey) {
    return _loadingTasks.containsKey(cacheKey);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_items': _dataCache.length,
      'loading_tasks': _loadingTasks.length,
      'cache_keys': _dataCache.keys.toList(),
    };
  }
}

/// Smart bottom sheet content with automatic data loading
class _SmartBottomSheetContent extends StatefulWidget {
  final String cacheKey;
  final Future<dynamic> preloadFuture;
  final Widget Function(BuildContext context, dynamic data, bool isLoading) builder;

  const _SmartBottomSheetContent({
    required this.cacheKey,
    required this.preloadFuture,
    required this.builder,
  });

  @override
  State<_SmartBottomSheetContent> createState() => _SmartBottomSheetContentState();
}

class _SmartBottomSheetContentState extends State<_SmartBottomSheetContent> {
  dynamic _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      // Check for immediately available cached data
      final cachedData = SmartBottomSheetService()._getCachedData(widget.cacheKey);
      if (cachedData != null) {
        setState(() {
          _data = cachedData;
          _isLoading = false;
        });
        return;
      }

      // Wait for preload to complete
      final data = await widget.preloadFuture;
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      print('❌ [SMART_BOTTOM_SHEET] Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _loadData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return widget.builder(context, _data, _isLoading);
  }
}

/// Smart draggable content with automatic data loading
class _SmartDraggableContent extends StatefulWidget {
  final ScrollController scrollController;
  final String cacheKey;
  final Future<dynamic> preloadFuture;
  final Widget Function(BuildContext context, ScrollController controller, dynamic data, bool isLoading) builder;

  const _SmartDraggableContent({
    required this.scrollController,
    required this.cacheKey,
    required this.preloadFuture,
    required this.builder,
  });

  @override
  State<_SmartDraggableContent> createState() => _SmartDraggableContentState();
}

class _SmartDraggableContentState extends State<_SmartDraggableContent> {
  dynamic _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      // Check for immediately available cached data
      final cachedData = SmartBottomSheetService()._getCachedData(widget.cacheKey);
      if (cachedData != null) {
        setState(() {
          _data = cachedData;
          _isLoading = false;
        });
        return;
      }

      // Wait for preload to complete
      final data = await widget.preloadFuture;
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [SMART_BOTTOM_SHEET] Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.scrollController, _data, _isLoading);
  }
}

/// Extension for easy access to smart bottom sheet
extension SmartBottomSheetExtension on BuildContext {
  /// Show smart bottom sheet with preloaded data
  Future<T?> showSmartBottomSheet<T>({
    required String cacheKey,
    required Future<dynamic> Function() dataLoader,
    required Widget Function(BuildContext context, dynamic data, bool isLoading) builder,
    bool isScrollControlled = true,
  }) {
    return SmartBottomSheetService().showBottomSheetWithData<T>(
      context: this,
      cacheKey: cacheKey,
      dataLoader: dataLoader,
      builder: builder,
      isScrollControlled: isScrollControlled,
    );
  }
}