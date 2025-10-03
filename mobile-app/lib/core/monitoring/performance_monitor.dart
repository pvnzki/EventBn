import 'dart:async';
import 'dart:math';

/// Performance monitoring service that tracks app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Monitoring state
  bool _isMonitoring = false;
  Timer? _monitoringTimer;

  // Metrics storage
  final List<double> _responseTimes = [];
  final List<double> _memoryUsage = [];
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheAttempts = {};
  int _activeConnections = 0;

  // Configuration
  static const int _maxMetricsHistory = 100;
  static const Duration _monitoringInterval = Duration(seconds: 30);

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _collectMetrics();
    });
    
    print('📊 [PERFORMANCE_MONITOR] Started monitoring');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    
    print('📊 [PERFORMANCE_MONITOR] Stopped monitoring');
  }

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Record API response time
  void recordResponseTime(Duration duration) {
    final timeMs = duration.inMilliseconds.toDouble();
    _responseTimes.add(timeMs);
    
    // Keep only recent metrics
    if (_responseTimes.length > _maxMetricsHistory) {
      _responseTimes.removeAt(0);
    }
  }

  /// Record cache hit or miss
  void recordCacheEvent(String cacheType, bool isHit) {
    _cacheAttempts[cacheType] = (_cacheAttempts[cacheType] ?? 0) + 1;
    
    if (isHit) {
      _cacheHits[cacheType] = (_cacheHits[cacheType] ?? 0) + 1;
    }
  }

  /// Update active connection count
  void updateActiveConnections(int count) {
    _activeConnections = count;
  }

  /// Get current performance metrics
  Map<String, dynamic> getMetrics() {
    return {
      'monitoring_active': _isMonitoring,
      'avg_response_time': _calculateAverageResponseTime(),
      'min_response_time': _responseTimes.isEmpty ? 0 : _responseTimes.reduce(min),
      'max_response_time': _responseTimes.isEmpty ? 0 : _responseTimes.reduce(max),
      'memory_usage_mb': _getCurrentMemoryUsage(),
      'cache_hit_rate': _calculateOverallCacheHitRate(),
      'cache_details': _getCacheDetails(),
      'active_connections': _activeConnections,
      'metrics_count': _responseTimes.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get detailed performance report
  Map<String, dynamic> getDetailedReport() {
    final metrics = getMetrics();
    
    return {
      ...metrics,
      'response_time_distribution': _getResponseTimeDistribution(),
      'memory_trend': _getMemoryTrend(),
      'performance_score': _calculatePerformanceScore(),
      'recommendations': _generateRecommendations(),
    };
  }

  /// Collect current metrics
  void _collectMetrics() {
    // Simulate memory usage collection
    final memoryMb = _simulateMemoryUsage();
    _memoryUsage.add(memoryMb);
    
    // Keep only recent memory metrics
    if (_memoryUsage.length > _maxMetricsHistory) {
      _memoryUsage.removeAt(0);
    }
  }

  /// Calculate average response time
  double _calculateAverageResponseTime() {
    if (_responseTimes.isEmpty) return 0.0;
    
    final sum = _responseTimes.reduce((a, b) => a + b);
    return sum / _responseTimes.length;
  }

  /// Calculate overall cache hit rate
  double _calculateOverallCacheHitRate() {
    final totalHits = _cacheHits.values.fold(0, (sum, hits) => sum + hits);
    final totalAttempts = _cacheAttempts.values.fold(0, (sum, attempts) => sum + attempts);
    
    if (totalAttempts == 0) return 0.0;
    return (totalHits / totalAttempts) * 100;
  }

  /// Get cache details by type
  Map<String, Map<String, dynamic>> _getCacheDetails() {
    final details = <String, Map<String, dynamic>>{};
    
    for (final cacheType in _cacheAttempts.keys) {
      final hits = _cacheHits[cacheType] ?? 0;
      final attempts = _cacheAttempts[cacheType] ?? 0;
      final hitRate = attempts > 0 ? (hits / attempts) * 100 : 0.0;
      
      details[cacheType] = {
        'hits': hits,
        'attempts': attempts,
        'hit_rate': hitRate,
      };
    }
    
    return details;
  }

  /// Get current memory usage (simulated)
  double _getCurrentMemoryUsage() {
    if (_memoryUsage.isNotEmpty) {
      return _memoryUsage.last;
    }
    return _simulateMemoryUsage();
  }

  /// Simulate memory usage for demonstration
  double _simulateMemoryUsage() {
    // Simulate memory usage between 50-200 MB
    final random = Random();
    return 50.0 + (random.nextDouble() * 150.0);
  }

  /// Get response time distribution
  Map<String, int> _getResponseTimeDistribution() {
    final distribution = <String, int>{
      'fast_0_100ms': 0,
      'medium_100_500ms': 0,
      'slow_500_1000ms': 0,
      'very_slow_1000ms+': 0,
    };
    
    for (final time in _responseTimes) {
      if (time <= 100) {
        distribution['fast_0_100ms'] = distribution['fast_0_100ms']! + 1;
      } else if (time <= 500) {
        distribution['medium_100_500ms'] = distribution['medium_100_500ms']! + 1;
      } else if (time <= 1000) {
        distribution['slow_500_1000ms'] = distribution['slow_500_1000ms']! + 1;
      } else {
        distribution['very_slow_1000ms+'] = distribution['very_slow_1000ms+']! + 1;
      }
    }
    
    return distribution;
  }

  /// Get memory usage trend
  List<Map<String, dynamic>> _getMemoryTrend() {
    return _memoryUsage.asMap().entries.map((entry) {
      return {
        'index': entry.key,
        'memory_mb': entry.value,
      };
    }).toList();
  }

  /// Calculate overall performance score (0-100)
  double _calculatePerformanceScore() {
    double score = 100.0;
    
    // Deduct points for slow response times
    final avgResponseTime = _calculateAverageResponseTime();
    if (avgResponseTime > 1000) {
      score -= 30;
    } else if (avgResponseTime > 500) {
      score -= 15;
    } else if (avgResponseTime > 200) {
      score -= 5;
    }
    
    // Deduct points for low cache hit rate
    final cacheHitRate = _calculateOverallCacheHitRate();
    if (cacheHitRate < 50) {
      score -= 20;
    } else if (cacheHitRate < 70) {
      score -= 10;
    }
    
    // Deduct points for high memory usage
    final memoryUsage = _getCurrentMemoryUsage();
    if (memoryUsage > 300) {
      score -= 20;
    } else if (memoryUsage > 200) {
      score -= 10;
    }
    
    return score.clamp(0.0, 100.0);
  }

  /// Generate performance recommendations
  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    
    final avgResponseTime = _calculateAverageResponseTime();
    final cacheHitRate = _calculateOverallCacheHitRate();
    final memoryUsage = _getCurrentMemoryUsage();
    
    if (avgResponseTime > 500) {
      recommendations.add('Consider optimizing API responses or improving network conditions');
    }
    
    if (cacheHitRate < 70) {
      recommendations.add('Improve caching strategy to increase cache hit rate');
    }
    
    if (memoryUsage > 200) {
      recommendations.add('Monitor memory usage and consider reducing cache sizes');
    }
    
    if (_activeConnections > 10) {
      recommendations.add('Consider connection pooling to reduce active connections');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Performance is optimal! Keep up the good work.');
    }
    
    return recommendations;
  }

  /// Reset all metrics
  void resetMetrics() {
    _responseTimes.clear();
    _memoryUsage.clear();
    _cacheHits.clear();
    _cacheAttempts.clear();
    _activeConnections = 0;
    
    print('📊 [PERFORMANCE_MONITOR] Metrics reset');
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    resetMetrics();
  }
}