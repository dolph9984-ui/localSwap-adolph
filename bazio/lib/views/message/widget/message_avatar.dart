import 'package:bazio/core/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bazio/main.dart';
import 'package:flutter/material.dart';

class MessageAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double size;

  const MessageAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                memCacheWidth: 80,
                cacheManager: AppImageCacheManager(),
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallback(),
                errorWidget: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  //avatar de remplacement avec les initiales si pas de photo
  Widget _fallback() => Container(
        color: AppColors.bleu.withOpacity(0.15),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: AppColors.bleu,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.36,
            ),
          ),
        ),
      );
}

String buildInitials(String name) {
  if (name.trim().isEmpty) return '?';
  return name
      .trim()
      .split(' ')
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}
