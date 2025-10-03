import 'package:http/http.dart' as http;

/// High-performance HTTP connection pool with keep-alive and connection reuse
class ConnectionPool {
  static const int _maxConnections = 10;
  static const Duration _idleTimeout = Duration(minutes: 5);
  
  final List<_PooledClient> _availableClients = [];
  final List<_PooledClient> _busyClients = [];
  final Map<String, DateTime> _hostLastUsed = {};
  
  /// Get an HTTP client from the pool
  http.Client getClient() {
    // Clean up expired connections first
    _cleanupExpiredConnections();
    
    // Try to get an available client
    if (_availableClients.isNotEmpty) {
      final pooledClient = _availableClients.removeAt(0);
      _busyClients.add(pooledClient);
      pooledClient.lastUsed = DateTime.now();
      return _WrappedClient(pooledClient, this);
    }
    
    // Create new client if pool not full
    if (_getTotalConnections() < _maxConnections) {
      final client = _createOptimizedClient();
      final pooledClient = _PooledClient(client, DateTime.now());
      _busyClients.add(pooledClient);
      return _WrappedClient(pooledClient, this);
    }
    
    // Pool is full, create a temporary client
    print('⚠️ [POOL] Connection pool full, creating temporary client');
    return _createOptimizedClient();
  }

  /// Create an optimized HTTP client with keep-alive and compression
  http.Client _createOptimizedClient() {
    final client = http.Client();
    
    // Note: Advanced HTTP client configuration would require
    // platform-specific implementations or third-party packages
    // For now, we use the standard client with connection pooling logic
    
    return client;
  }

  /// Return a client to the pool
  void _returnClient(_PooledClient pooledClient) {
    _busyClients.remove(pooledClient);
    
    // Only add back to pool if it's not too old
    final age = DateTime.now().difference(pooledClient.created);
    if (age < const Duration(hours: 1) && _availableClients.length < _maxConnections) {
      pooledClient.lastUsed = DateTime.now();
      _availableClients.add(pooledClient);
    } else {
      // Client is too old or pool is full, dispose it
      pooledClient.client.close();
    }
  }

  /// Clean up expired connections
  void _cleanupExpiredConnections() {
    final now = DateTime.now();
    
    // Clean up available clients
    _availableClients.removeWhere((pooledClient) {
      final age = now.difference(pooledClient.lastUsed);
      if (age > _idleTimeout) {
        pooledClient.client.close();
        return true;
      }
      return false;
    });
    
    // Clean up busy clients that are too old (this shouldn't happen normally)
    _busyClients.removeWhere((pooledClient) {
      final age = now.difference(pooledClient.created);
      if (age > const Duration(hours: 2)) {
        pooledClient.client.close();
        print('⚠️ [POOL] Cleaned up stale busy client');
        return true;
      }
      return false;
    });
  }

  /// Get total number of connections
  int _getTotalConnections() {
    return _availableClients.length + _busyClients.length;
  }

  /// Get connection pool statistics
  Map<String, dynamic> getStats() {
    return {
      'availableConnections': _availableClients.length,
      'busyConnections': _busyClients.length,
      'totalConnections': _getTotalConnections(),
      'maxConnections': _maxConnections,
      'hostLastUsed': _hostLastUsed,
    };
  }

  /// Dispose all connections
  void dispose() {
    for (final pooledClient in _availableClients) {
      pooledClient.client.close();
    }
    for (final pooledClient in _busyClients) {
      pooledClient.client.close();
    }
    _availableClients.clear();
    _busyClients.clear();
    _hostLastUsed.clear();
  }
}

/// Internal class to track pooled clients
class _PooledClient {
  final http.Client client;
  final DateTime created;
  DateTime lastUsed;
  
  _PooledClient(this.client, this.created) : lastUsed = created;
}

/// Wrapper client that returns itself to the pool when closed
class _WrappedClient extends http.BaseClient {
  final _PooledClient _pooledClient;
  final ConnectionPool _pool;
  bool _closed = false;
  
  _WrappedClient(this._pooledClient, this._pool);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_closed) {
      throw StateError('HTTP client has been closed');
    }
    
    // Add performance headers
    request.headers.putIfAbsent('Connection', () => 'keep-alive');
    request.headers.putIfAbsent('Accept-Encoding', () => 'gzip, deflate');
    
    return _pooledClient.client.send(request);
  }

  @override
  void close() {
    if (!_closed) {
      _closed = true;
      _pool._returnClient(_pooledClient);
    }
  }
}