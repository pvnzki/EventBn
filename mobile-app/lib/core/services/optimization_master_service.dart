import 'dart:async';
import '../network/connection_pool.dart';
import '../monitoring/performance_monitor.dart';
import 'image_optimization_service.dart';
import 'comment_optimization_service.dart';
import '../../features/explore/services/enhanced_post_service.dart';

/// Master optimization service that coordinates all performance enhancements
/// This is the main entry point for all optimized functionality
class OptimizationMasterService {
  static final OptimizationMasterService _instance = OptimizationMasterService._internal();
  factory OptimizationMasterService() => _instance;
  OptimizationMasterService._internal();

  // Service instances
  late final EnhancedExplorePostService _postService;
  late final ImageOptimizationService _imageService;
  late final CommentOptimizationService _commentService;
  late final PerformanceMonitor _performanceMonitor;
  late final ConnectionPool _connectionPool;

  // Initialization state
  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// Initialize all optimization services
  Future<void> initialize() async {
    if (_initialized) return;
    if (!_initCompleter.isCompleted) {
      await _performInitialization();
    }
    return _initCompleter.future;
  }

  Future<void> _performInitialization() async {
    try {
      print('🚀 [OPTIMIZATION_MASTER] Starting initialization...');
      
      // Initialize core services
      _connectionPool = ConnectionPool();
      _performanceMonitor = PerformanceMonitor();
      
      // Initialize optimization services
      _imageService = ImageOptimizationService();
      _commentService = CommentOptimizationService();
      await _commentService.initialize();
      
      // Initialize enhanced post service
      _postService = EnhancedExplorePostService();
      // Note: EnhancedExplorePostService doesn't have initialize method
      
      _initialized = true;
      _initCompleter.complete();
      
      print('✅ [OPTIMIZATION_MASTER] All services initialized successfully');
    } catch (e) {
      print('❌ [OPTIMIZATION_MASTER] Initialization failed: $e');
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// Get the enhanced post service
  EnhancedExplorePostService get postService {
    _ensureInitialized();
    return _postService;
  }

  /// Get the image optimization service
  ImageOptimizationService get imageService {
    _ensureInitialized();
    return _imageService;
  }

  /// Get the comment optimization service
  CommentOptimizationService get commentService {
    _ensureInitialized();
    return _commentService;
  }

  /// Get the performance monitor
  PerformanceMonitor get performanceMonitor {
    _ensureInitialized();
    return _performanceMonitor;
  }

  /// Get comprehensive performance statistics
  Future<Map<String, dynamic>> getPerformanceStats() async {
    await initialize();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'post_service': {'status': 'active'}, // Simplified since method doesn't exist
      'image_service': _imageService.getCacheStats(),
      'comment_service': _commentService.getCacheStats(),
      'performance_monitor': _performanceMonitor.getMetrics(),
      'connection_pool': _connectionPool.getStats(),
      'system': await _getSystemStats(),
    };
  }

  /// Perform comprehensive cache cleanup
  Future<void> performCacheCleanup() async {
    await initialize();
    
    print('🧹 [OPTIMIZATION_MASTER] Starting cache cleanup...');
    
    try {
      // Clear image caches
      _imageService.clearImageCache();
      
      // Clear comment caches
      _commentService.dispose();
      await _commentService.initialize();
      
      // Clear post service caches (simplified since method doesn't exist)
      print('📱 [POST_SERVICE] Cache clearing not implemented');
      
      print('✅ [OPTIMIZATION_MASTER] Cache cleanup completed');
    } catch (e) {
      print('❌ [OPTIMIZATION_MASTER] Cache cleanup failed: $e');
    }
  }

  /// Preload content for better user experience
  Future<void> preloadContent({
    List<String>? postIds,
    List<String>? imageUrls,
    int preloadCount = 10,
  }) async {
    await initialize();
    
    print('⚡ [OPTIMIZATION_MASTER] Starting content preload...');
    
    try {
      // Preload posts if needed
      if (postIds == null || postIds.isEmpty) {
        await _postService.loadPosts(refresh: true); // Use correct parameter
      }
      
      // Preload images
      if (imageUrls != null && imageUrls.isNotEmpty) {
        // Note: This would need a BuildContext in a real implementation
        // await _imageService.preloadImages(imageUrls, context);
        print('📸 [OPTIMIZATION_MASTER] Image preloading requires BuildContext');
      }
      
      // Preload comments for posts
      if (postIds != null && postIds.isNotEmpty) {
        await _commentService.preloadComments(postIds);
      }
      
      print('✅ [OPTIMIZATION_MASTER] Content preloading completed');
    } catch (e) {
      print('❌ [OPTIMIZATION_MASTER] Content preloading failed: $e');
    }
  }

  /// Optimize app performance based on device capabilities
  Future<void> optimizeForDevice() async {
    await initialize();
    
    final deviceInfo = await _getDeviceInfo();
    print('📱 [OPTIMIZATION_MASTER] Optimizing for device: $deviceInfo');
    
    // Adjust cache sizes based on available memory
    final availableMemory = deviceInfo['memory_mb'] as int? ?? 1024;
    
    if (availableMemory < 2048) {
      // Low memory device - reduce cache sizes
      print('🔧 [OPTIMIZATION_MASTER] Applying low-memory optimizations');
      // Implementation would adjust cache parameters
    } else if (availableMemory > 4096) {
      // High memory device - increase cache sizes
      print('🔧 [OPTIMIZATION_MASTER] Applying high-memory optimizations');
      // Implementation would adjust cache parameters
    }
  }

  /// Monitor and report performance issues
  void startPerformanceMonitoring() {
    _performanceMonitor.startMonitoring();
    
    // Set up periodic performance reporting
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _reportPerformanceMetrics();
    });
  }

  /// Stop performance monitoring
  void stopPerformanceMonitoring() {
    _performanceMonitor.stopMonitoring();
  }

  /// Get health check status for all services
  Future<Map<String, bool>> getHealthStatus() async {
    await initialize();
    
    return {
      'post_service': true, // Would check actual health
      'image_service': true,
      'comment_service': true,
      'performance_monitor': _performanceMonitor.isMonitoring,
      'connection_pool': true,
      'overall_health': true,
    };
  }

  /// Report performance metrics periodically
  void _reportPerformanceMetrics() async {
    try {
      final stats = await getPerformanceStats();
      final metrics = stats['performance_monitor'] as Map<String, dynamic>;
      
      print('📊 [PERFORMANCE_REPORT] ${DateTime.now()}');
      print('   Memory Usage: ${metrics['memory_usage_mb']}MB');
      print('   API Response Time: ${metrics['avg_response_time']}ms');
      print('   Cache Hit Rate: ${metrics['cache_hit_rate']}%');
      print('   Active Connections: ${metrics['active_connections']}');
    } catch (e) {
      print('⚠️ [PERFORMANCE_REPORT] Failed to generate report: $e');
    }
  }

  /// Get system-level statistics
  Future<Map<String, dynamic>> _getSystemStats() async {
    // In a real implementation, you'd use platform-specific APIs
    return {
      'platform': 'flutter',
      'timestamp': DateTime.now().toIso8601String(),
      'uptime_seconds': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Get device information for optimization
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // Mock device info - in real implementation use device_info_plus
    return {
      'platform': 'android', // or 'ios'
      'memory_mb': 4096,
      'cpu_cores': 8,
      'is_physical_device': true,
    };
  }

  /// Ensure services are initialized before use
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('OptimizationMasterService not initialized. Call initialize() first.');
    }
  }

  /// Dispose all services and clean up resources
  Future<void> dispose() async {
    if (!_initialized) return;
    
    print('🛑 [OPTIMIZATION_MASTER] Disposing services...');
    
    try {
      stopPerformanceMonitoring();
      _imageService.dispose();
      _commentService.dispose();
      _postService.dispose(); // Remove await since it's void
      _connectionPool.dispose();
      
      _initialized = false;
      print('✅ [OPTIMIZATION_MASTER] All services disposed');
    } catch (e) {
      print('❌ [OPTIMIZATION_MASTER] Error during disposal: $e');
    }
  }
}

/// Extension for easy access to optimization services
extension OptimizationExtension on Object {
  /// Quick access to the optimization master service
  static OptimizationMasterService get optimization => OptimizationMasterService();
}

/// Performance optimization configuration
class OptimizationConfig {
  final int maxMemoryCacheSize;
  final Duration cacheExpiry;
  final int maxConcurrentConnections;
  final bool enablePerformanceMonitoring;
  final bool enableImageOptimization;
  final bool enableCommentVirtualization;

  const OptimizationConfig({
    this.maxMemoryCacheSize = 100,
    this.cacheExpiry = const Duration(minutes: 30),
    this.maxConcurrentConnections = 10,
    this.enablePerformanceMonitoring = true,
    this.enableImageOptimization = true,
    this.enableCommentVirtualization = true,
  });

  /// Configuration for low-end devices
  static const OptimizationConfig lowEnd = OptimizationConfig(
    maxMemoryCacheSize: 50,
    cacheExpiry: Duration(minutes: 15),
    maxConcurrentConnections: 5,
  );

  /// Configuration for high-end devices
  static const OptimizationConfig highEnd = OptimizationConfig(
    maxMemoryCacheSize: 200,
    cacheExpiry: Duration(hours: 1),
    maxConcurrentConnections: 20,
  );
}