import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/chat/chat_model.dart';
import 'package:bazio/viewmodels/messaging/chat_notifier.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bazio/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

//bandeau cliquable affichant l'annonce associee a la conversation
class ListingBanner extends ConsumerWidget {
  final String chatId;
  final String listingTitle;

  const ListingBanner({
    super.key,
    required this.chatId,
    required this.listingTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref
        .watch(myChatsProvider)
        .value
        ?.firstWhere(
          (c) => c.id == chatId,
          orElse: () => ChatModel(
            id: chatId,
            participants: [],
            listingId: '',
            listingTitle: listingTitle,
            lastMessage: '',
            lastMessageSenderId: '',
            sellerId: '',
            lastUpdate: DateTime.now(),
          ),
        );
    final listingId = chat?.listingId ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: listingId.isNotEmpty
            ? () => context.push('/listing/$listingId')
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _Thumbnail(listingId: listingId),
              const SizedBox(width: 12),
              Expanded(
                child: _Info(listingId: listingId, title: listingTitle),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.grisNeutre,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends ConsumerWidget {
  final String listingId;
  const _Thumbnail({required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (listingId.isEmpty) return _placeholder();
    return ref
        .watch(listingDetailProvider(listingId))
        .when(
          data: (l) => l.imageUrls.isEmpty
              ? _placeholder()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: l.imageUrls.first,
                    memCacheWidth: 120,
                    cacheManager: AppImageCacheManager(),
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  ),
                ),
          loading: () => _placeholder(),
          error: (_, __) => _placeholder(),
        );
  }

  Widget _placeholder() => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
      Icons.image_outlined,
      color: AppColors.grisNeutre,
      size: 24,
    ),
  );
}

class _Info extends ConsumerWidget {
  final String listingId;
  final String title;
  const _Info({required this.listingId, required this.title});

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]} ',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (listingId.isEmpty) {
      return Text(
        title,
        style: AppTextStyles.bodyBold,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return ref
        .watch(listingDetailProvider(listingId))
        .when(
          data: (l) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.title,
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.blackOp,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Ar ${_fmt(l.price)}',
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          //pendant le chargement on affiche le titre du chat
          loading: () => Text(
            title,
            style: AppTextStyles.bodyBold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          error: (_, __) => Text(
            title,
            style: AppTextStyles.bodyBold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
  }
}
