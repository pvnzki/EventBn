import 'dart:collection';

/// High-performance memory cache with LRU eviction and TTL support
class MemoryCache<K, V> {
  final int maxSize;
  final Duration? defaultTtl;

  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();
  final Map<K, DateTime> _accessTimes = {};

  MemoryCache({
    required this.maxSize,
    this.defaultTtl,
  });

  /// Put a value in the cache
  void put(K key, V value, {Duration? ttl}) {
    final expiryTime = ttl != null || defaultTtl != null
        ? DateTime.now().add(ttl ?? defaultTtl!)
        : null;

    _cache[key] = _CacheEntry(value, expiryTime);
    _accessTimes[key] = DateTime.now();

    _evictIfNeeded();
  }

  /// Get a value from the cache
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if expired
    if (entry.expiryTime != null && DateTime.now().isAfter(entry.expiryTime!)) {
      remove(key);
      return null;
    }

    // Update access time for LRU
    _accessTimes[key] = DateTime.now();

    // Move to end (most recently used)
    final value = _cache.remove(key)!;
    _cache[key] = value;

    return value.data;
  }

  /// Check if key exists and is not expired
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.expiryTime != null && DateTime.now().isAfter(entry.expiryTime!)) {
      remove(key);
      return false;
    }

    return true;
  }

  /// Remove a key from cache
  void remove(K key) {
    _cache.remove(key);
    _accessTimes.remove(key);
  }

  /// Clear all cache entries
  void clear() {
    _cache.clear();
    _accessTimes.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'maxSize': maxSize,
      'loadFactor': _cache.length / maxSize,
      'keys': _cache.keys.toList(),
    };
  }

  /// Evict least recently used items if cache is full
  void _evictIfNeeded() {
    while (_cache.length > maxSize) {
      // Find the least recently used item
      K? oldestKey;
      DateTime? oldestTime;

      for (final entry in _accessTimes.entries) {
        if (oldestTime == null || entry.value.isBefore(oldestTime)) {
          oldestTime = entry.value;
          oldestKey = entry.key;
        }
      }

      if (oldestKey != null) {
        remove(oldestKey);
      } else {
        // Fallback: remove first item
        final firstKey = _cache.keys.first;
        remove(firstKey);
      }
    }
  }

  /// Get all values (for debugging)
  List<V> get values => _cache.values.map((e) => e.data).toList();

  /// Get cache size
  int get size => _cache.length;

  /// Check if cache is empty
  bool get isEmpty => _cache.isEmpty;

  /// Check if cache is full
  bool get isFull => _cache.length >= maxSize;
}

/// Internal cache entry with optional expiry
class _CacheEntry<V> {
  final V data;
  final DateTime? expiryTime;

  _CacheEntry(this.data, this.expiryTime);
}
