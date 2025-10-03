import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Advanced image optimization service with progressive loading,
/// smart caching, and adaptive quality management
class ImageOptimizationService {
  static final ImageOptimizationService _instance =
      ImageOptimizationService._internal();
  factory ImageOptimizationService() => _instance;
  ImageOptimizationService._internal();

  // Network optimization
  final http.Client _httpClient = http.Client();

  // Configuration
  static const int _thumbnailSize = 300;
  static const int _mediumSize = 800;
  static const int _maxFullSize = 1920;

  /// Get optimized image widget with progressive loading
  Widget getOptimizedImage({
    required String url,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableProgressiveLoading = true,
    ImageQuality quality = ImageQuality.auto,
  }) {
    if (url.isEmpty) {
      return errorWidget ?? _buildDefaultErrorWidget(width, height);
    }

    // Determine optimal image size based on display size
    final optimalSize = _calculateOptimalSize(width, height, quality);
    final optimizedUrl = _buildOptimizedUrl(url, optimalSize);

    if (enableProgressiveLoading) {
      return _buildProgressiveImage(
        originalUrl: url,
        optimizedUrl: optimizedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    } else {
      return _buildStandardCachedImage(
        url: optimizedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }
  }

  /// Build progressive loading image (thumbnail -> full quality)
  Widget _buildProgressiveImage({
    required String originalUrl,
    required String optimizedUrl,
    required double width,
    required double height,
    required BoxFit fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Stack(
      children: [
        // Thumbnail layer (loads first)
        _buildCachedNetworkImage(
          url: _buildOptimizedUrl(originalUrl, _thumbnailSize),
          width: width,
          height: height,
          fit: fit,
          placeholder: placeholder ?? _buildShimmerPlaceholder(width, height),
          errorWidget: errorWidget,
          memCacheHeight: (_thumbnailSize * height / width).round(),
          memCacheWidth: _thumbnailSize,
        ),

        // Full quality layer (loads second)
        _buildCachedNetworkImage(
          url: optimizedUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder:
              const SizedBox.shrink(), // No placeholder for second layer
          errorWidget: const SizedBox.shrink(),
          memCacheHeight: height.round(),
          memCacheWidth: width.round(),
        ),
      ],
    );
  }

  /// Build standard cached image
  Widget _buildStandardCachedImage({
    required String url,
    required double width,
    required double height,
    required BoxFit fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return _buildCachedNetworkImage(
      url: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder ?? _buildShimmerPlaceholder(width, height),
      errorWidget: errorWidget ?? _buildDefaultErrorWidget(width, height),
      memCacheHeight: height.round(),
      memCacheWidth: width.round(),
    );
  }

  /// Build CachedNetworkImage with optimizations
  Widget _buildCachedNetworkImage({
    required String url,
    required double width,
    required double height,
    required BoxFit fit,
    Widget? placeholder,
    Widget? errorWidget,
    int? memCacheWidth,
    int? memCacheHeight,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) =>
          placeholder ?? _buildShimmerPlaceholder(width, height),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildDefaultErrorWidget(width, height),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      httpHeaders: {
        'Cache-Control': 'max-age=86400', // 24 hours
        'Accept': 'image/webp,image/jpeg,image/png,*/*',
      },
      useOldImageOnUrlChange: true,
      filterQuality: FilterQuality.medium,
    );
  }

  /// Calculate optimal image size based on display requirements
  int _calculateOptimalSize(double width, double height, ImageQuality quality) {
    final maxDimension = width > height ? width : height;
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final targetSize = (maxDimension * devicePixelRatio).round();

    switch (quality) {
      case ImageQuality.low:
        return (targetSize * 0.5).round().clamp(200, 600);
      case ImageQuality.medium:
        return (targetSize * 0.75).round().clamp(400, _mediumSize);
      case ImageQuality.high:
        return targetSize.clamp(600, _maxFullSize);
      case ImageQuality.auto:
        // Auto quality based on image size and connection
        if (targetSize <= 400) return targetSize.clamp(200, 600);
        if (targetSize <= 800) return targetSize.clamp(400, _mediumSize);
        return targetSize.clamp(600, _maxFullSize);
    }
  }

  /// Build optimized URL with size parameters
  String _buildOptimizedUrl(String originalUrl, int maxSize) {
    // If URL already has optimization parameters, don't modify
    if (originalUrl.contains('w=') ||
        originalUrl.contains('h=') ||
        originalUrl.contains('size=')) {
      return originalUrl;
    }

    // For external URLs, try to add optimization parameters
    final uri = Uri.tryParse(originalUrl);
    if (uri == null) return originalUrl;

    // Common image optimization patterns
    if (uri.host.contains('cloudinary')) {
      return _addCloudinaryOptimizations(originalUrl, maxSize);
    } else if (uri.host.contains('imgix')) {
      return _addImgixOptimizations(originalUrl, maxSize);
    } else if (uri.host.contains('amazonaws') || uri.host.contains('s3')) {
      return _addS3Optimizations(originalUrl, maxSize);
    } else {
      // For custom backend, add standard size parameter
      return _addStandardOptimizations(originalUrl, maxSize);
    }
  }

  /// Add Cloudinary optimizations
  String _addCloudinaryOptimizations(String url, int maxSize) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments.toList();

    // Insert transformation parameters after version
    if (pathSegments.length >= 2) {
      pathSegments.insert(
          pathSegments.length - 1, 'c_fill,w_$maxSize,q_auto,f_auto');
      return uri.replace(pathSegments: pathSegments).toString();
    }

    return url;
  }

  /// Add Imgix optimizations
  String _addImgixOptimizations(String url, int maxSize) {
    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);

    queryParams['w'] = maxSize.toString();
    queryParams['auto'] = 'format,compress';
    queryParams['q'] = '85';

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Add S3/AWS optimizations (if using Lambda@Edge or similar)
  String _addS3Optimizations(String url, int maxSize) {
    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);

    queryParams['w'] = maxSize.toString();
    queryParams['q'] = '85';
    queryParams['format'] = 'auto';

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Add standard optimizations
  String _addStandardOptimizations(String url, int maxSize) {
    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);

    queryParams['size'] = maxSize.toString();
    queryParams['quality'] = '85';

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Build shimmer placeholder
  Widget _buildShimmerPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  /// Build default error widget
  Widget _buildDefaultErrorWidget(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: (width * 0.2).clamp(24, 48),
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Image unavailable',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Preload images for better performance
  Future<void> preloadImages(List<String> urls, BuildContext context) async {
    for (final url in urls) {
      try {
        // Preload thumbnail first
        final thumbnailUrl = _buildOptimizedUrl(url, _thumbnailSize);
        await precacheImage(CachedNetworkImageProvider(thumbnailUrl), context);

        // Then preload medium quality
        final mediumUrl = _buildOptimizedUrl(url, _mediumSize);
        await precacheImage(CachedNetworkImageProvider(mediumUrl), context);
      } catch (e) {
        print('⚠️ [IMAGE_PRELOAD] Failed to preload $url: $e');
      }
    }
  }

  /// Clear image caches
  void clearImageCache() {
    // Clear CachedNetworkImage cache
    DefaultCacheManager().emptyCache();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_network_image': 'Using DefaultCacheManager',
      'optimization_active': true,
      'progressive_loading': true,
    };
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
    clearImageCache();
  }
}

/// Image quality levels
enum ImageQuality {
  low,
  medium,
  high,
  auto,
}
