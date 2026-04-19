import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bazio/main.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ListingGallery extends StatefulWidget {
  final List<String> imageUrls;
  const ListingGallery({super.key, required this.imageUrls});

  @override
  State<ListingGallery> createState() => _ListingGalleryState();
}

class _ListingGalleryState extends State<ListingGallery> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.imageUrls.length;

    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          if (imageCount > 0)
            PageView.builder(
              controller: _pageController,
              itemCount: imageCount,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: widget.imageUrls[i],
                memCacheWidth: 480,
                cacheManager: AppImageCacheManager(),
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => _emptyImage(),
              ),
            )
          else
            _emptyImage(),

          //indicateurs de page seulement s'il y a plusieurs images
          if (imageCount > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    imageCount.clamp(0, 7),
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentIndex ? 22 : 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i == _currentIndex
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  //compteur numero/total
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/$imageCount',
                      style: AppTextStyles.captionBold.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyImage() {
    return Container(
      color: AppColors.bgOp,
      child: const Center(
        child: Icon(Icons.image_not_supported, color: AppColors.bleu, size: 48),
      ),
    );
  }
}
