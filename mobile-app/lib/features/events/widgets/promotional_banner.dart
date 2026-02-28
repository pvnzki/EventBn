import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

class PromotionalBanner extends StatelessWidget {
  final PageController controller;
  final List<String> bannerImages;
  final bool imagesPreloaded;
  final ValueChanged<int> onPageChanged;

  const PromotionalBanner({
    super.key,
    required this.controller,
    required this.bannerImages,
    required this.imagesPreloaded,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 180,
        child: PageView.builder(
          controller: controller,
          onPageChanged: onPageChanged,
          physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
          allowImplicitScrolling: true, // pre-renders adjacent pages
          itemCount: bannerImages.length,
          itemBuilder: (context, index) {
            return Container(
              key: ValueKey('banner_$index'),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: imagesPreloaded
                      ? Image.asset(
                          bannerImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          // Keep decoded image in memory for instant display
                          cacheWidth: 800,
                          errorBuilder: (context, error, stackTrace) {
                            return _BannerError(index: index);
                          },
                        )
                      : const _BannerLoading(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BannerError extends StatelessWidget {
  final int index;
  const _BannerError({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.7),
            Theme.of(context).primaryColor.withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white.withOpacity(0.8),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Banner ${index + 1}',
              style: TextStyle(
                fontFamily: kFontFamily,
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerLoading extends StatelessWidget {
  const _BannerLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.3),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withOpacity(0.8),
          ),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class BannerPageIndicators extends StatelessWidget {
  final int count;
  final int currentIndex;

  const BannerPageIndicators({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            boxShadow: currentIndex == index
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
