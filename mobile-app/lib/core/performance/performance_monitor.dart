import 'dart:collection';

/// Performance monitoring and metrics collection system
class PerformanceMonitor {
  final Map<String, List<int>> _metrics = {};
  final Map<String, DateTime> _operationStarts = {};
  final Map<String, int> _counters = {};
  final Map<String, String> _errors = {};
  final Queue<Map<String, dynamic>> _recentEvents = Queue();
  
  static const int _maxEvents = 1000;
  static const int _maxMetricHistory = 100;

  /// Start monitoring an operation
  void startOperation(String operationId) {
    _operationStarts[operationId] = DateTime.now();
  }

  /// End monitoring an operation and record duration
  void endOperation(String operationId) {
    final startTime = _operationStarts.remove(operationId);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      recordMetric('${operationId}_duration_ms', duration);
    }
  }

  /// Record a performance metric
  void recordMetric(String metricName, int value) {
    _metrics.putIfAbsent(metricName, () => <int>[]);
    _metrics[metricName]!.add(value);
    
    // Keep only recent metrics to prevent memory growth
    if (_metrics[metricName]!.length > _maxMetricHistory) {
      _metrics[metricName]!.removeAt(0);
    }
    
    _addEvent('metric', {
      'name': metricName,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Record a cache hit
  void recordCacheHit(String cacheType) {
    _counters['${cacheType}_hits'] = (_counters['${cacheType}_hits'] ?? 0) + 1;
    _addEvent('cache_hit', {
      'type': cacheType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Record a cache miss
  void recordCacheMiss(String cacheType) {
    _counters['${cacheType}_misses'] = (_counters['${cacheType}_misses'] ?? 0) + 1;
    _addEvent('cache_miss', {
      'type': cacheType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Record an error
  void recordError(String errorType, String errorMessage) {
    _errors[errorType] = errorMessage;
    _counters['${errorType}_count'] = (_counters['${errorType}_count'] ?? 0) + 1;
    _addEvent('error', {
      'type': errorType,
      'message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Add an event to the recent events queue
  void _addEvent(String eventType, Map<String, dynamic> data) {
    _recentEvents.add({
      'type': eventType,
      'data': data,
    });
    
    // Keep queue size under control
    while (_recentEvents.length > _maxEvents) {
      _recentEvents.removeFirst();
    }
  }

  /// Get comprehensive performance metrics
  Map<String, dynamic> getMetrics() {
    final now = DateTime.now();
    
    return {
      'timestamp': now.toIso8601String(),
      'metrics': _getMetricSummaries(),
      'counters': Map.from(_counters),
      'errors': Map.from(_errors),
      'cache_stats': _getCacheStats(),
      'performance_summary': _getPerformanceSummary(),
      'recent_events': _recentEvents.toList(),
    };
  }

  /// Get metric summaries with statistics
  Map<String, Map<String, dynamic>> _getMetricSummaries() {
    final summaries = <String, Map<String, dynamic>>{};
    
    for (final entry in _metrics.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        values.sort();
        summaries[entry.key] = {
          'count': values.length,
          'min': values.first,
          'max': values.last,
          'avg': values.reduce((a, b) => a + b) / values.length,
          'median': values[values.length ~/ 2],
          'p95': values[(values.length * 0.95).floor()],
          'recent': values.take(10).toList(),
        };
      }
    }
    
    return summaries;
  }

  /// Get cache performance statistics
  Map<String, dynamic> _getCacheStats() {
    final cacheStats = <String, dynamic>{};
    final cacheTypes = <String>{};
    
    // Extract cache types from counters
    for (final key in _counters.keys) {
      if (key.contains('_hits') || key.contains('_misses')) {
        final type = key.replaceAll('_hits', '').replaceAll('_misses', '');
        cacheTypes.add(type);
      }
    }
    
    // Calculate hit rates for each cache type
    for (final type in cacheTypes) {
      final hits = _counters['${type}_hits'] ?? 0;
      final misses = _counters['${type}_misses'] ?? 0;
      final total = hits + misses;
      
      cacheStats[type] = {
        'hits': hits,
        'misses': misses,
        'total_requests': total,
        'hit_rate': total > 0 ? (hits / total * 100).toStringAsFixed(2) : '0',
      };
    }
    
    return cacheStats;
  }

  /// Get overall performance summary
  Map<String, dynamic> _getPerformanceSummary() {
    final loadTimes = _metrics['load_posts_duration_ms'] ?? [];
    final networkFetches = _counters['network_fetch_count'] ?? 0;
    final totalCacheHits = _counters.entries
        .where((e) => e.key.contains('_hits'))
        .map((e) => e.value)
        .fold(0, (a, b) => a + b);
    
    return {
      'avg_load_time_ms': loadTimes.isNotEmpty 
          ? (loadTimes.reduce((a, b) => a + b) / loadTimes.length).toStringAsFixed(2)
          : 'N/A',
      'total_network_fetches': networkFetches,
      'total_cache_hits': totalCacheHits,
      'performance_score': _calculatePerformanceScore(),
    };
  }

  /// Calculate overall performance score (0-100)
  int _calculatePerformanceScore() {
    int score = 100;
    
    // Penalize for high load times
    final loadTimes = _metrics['load_posts_duration_ms'] ?? [];
    if (loadTimes.isNotEmpty) {
      final avgLoadTime = loadTimes.reduce((a, b) => a + b) / loadTimes.length;
      if (avgLoadTime > 1000) score -= 20;
      else if (avgLoadTime > 500) score -= 10;
    }
    
    // Penalize for high error rates
    final totalErrors = _counters.entries
        .where((e) => e.key.contains('_count'))
        .map((e) => e.value)
        .fold(0, (a, b) => a + b);
    if (totalErrors > 10) score -= 30;
    else if (totalErrors > 5) score -= 15;
    
    // Bonus for high cache hit rates
    final cacheStats = _getCacheStats();
    var totalHitRate = 0.0;
    var cacheTypeCount = 0;
    
    for (final stats in cacheStats.values) {
      final hitRate = double.tryParse(stats['hit_rate'].toString()) ?? 0;
      totalHitRate += hitRate;
      cacheTypeCount++;
    }
    
    if (cacheTypeCount > 0) {
      final avgHitRate = totalHitRate / cacheTypeCount;
      if (avgHitRate > 80) score += 10;
      else if (avgHitRate > 60) score += 5;
    }
    
    return score.clamp(0, 100);
  }

  /// Clear all metrics and reset
  void reset() {
    _metrics.clear();
    _operationStarts.clear();
    _counters.clear();
    _errors.clear();
    _recentEvents.clear();
  }

  /// Start monitoring with a specific tag
  void startMonitoring(String tag) {
    _addEvent('monitoring_started', {
      'tag': tag,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Dispose the performance monitor
  void dispose() {
    reset();
  }

  /// Get human-readable performance report
  String getPerformanceReport() {
    final metrics = getMetrics();
    final summary = metrics['performance_summary'];
    final cacheStats = metrics['cache_stats'];
    
    final buffer = StringBuffer();
    buffer.writeln('=== Performance Report ===');
    buffer.writeln('Performance Score: ${summary['performance_score']}/100');
    buffer.writeln('Average Load Time: ${summary['avg_load_time_ms']}ms');
    buffer.writeln('Network Fetches: ${summary['total_network_fetches']}');
    buffer.writeln('Cache Hits: ${summary['total_cache_hits']}');
    buffer.writeln();
    
    if (cacheStats.isNotEmpty) {
      buffer.writeln('Cache Performance:');
      for (final entry in cacheStats.entries) {
        final stats = entry.value;
        buffer.writeln('  ${entry.key}: ${stats['hit_rate']}% hit rate (${stats['hits']}/${stats['total_requests']})');
      }
    }
    
    return buffer.toString();
  }
}