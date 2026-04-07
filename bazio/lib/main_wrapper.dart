import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/presentation/views/home_view.dart';
import 'package:bazio/presentation/views/message/message_view.dart';
import 'package:bazio/presentation/views/profil/profil_view.dart';
import 'package:bazio/presentation/views/publish/publish_view.dart';
import 'package:bazio/presentation/views/search/search_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

// gestion de l index pour savoir sur quelle page on est
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navigationIndexProvider = NotifierProvider<NavigationNotifier, int>(() {
  return NavigationNotifier();
});

class MainWrapper extends ConsumerWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);
    
    // on check si le clavier est sorti pour pas que la barre monte
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    // on cache la barre quand on publie pour laisser de la place
    final isPublishing = index == 2;

    final pages = [
      const HomeView(),
      const SearchView(),
      const PublishView(),
      const MessagesView(),
      const ProfileView(),
    ];

    return Scaffold(
      // evite que tout l ecran saute quand on tape du texte
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // garde les pages en mémoire pour pas perdre le scroll
          IndexedStack(index: index, children: pages),
          
          // on affiche la barre seulement si on publie pas et que le clavier est rangé
          if (!isPublishing && !keyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildCustomBottomBar(context, ref, index),
            ),
        ],
      ),
    );
  }

  // construction de la barre flottante arrondie
  Widget _buildCustomBottomBar(
      BuildContext context, WidgetRef ref, int currentIndex) {
    const barBgColor = Color(0xFFEFF2F5);

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 12.0),
      child: SizedBox(
        height: 85,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // le fond de la barre en mode pilule
            IgnorePointer(
              child: Container(
                height: 65,
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  color: barBgColor,
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),

            // le petit arrondi sous le bouton plus
            Positioned(
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: barBgColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // les icones de gauche et droite
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(ref, 0, currentIndex,
                      'assets/icones/home_outline.svg',
                      'assets/icones/home_filled.svg'),
                  _buildNavItem(ref, 1, currentIndex,
                      'assets/icones/search_outline.svg',
                      'assets/icones/search_filled.svg'),
                  const SizedBox(width: 65), // l espace pour le bouton central
                  _buildNavItem(ref, 3, currentIndex,
                      'assets/icones/message_outline.svg',
                      'assets/icones/message_filled.svg'),
                  _buildNavItem(ref, 4, currentIndex,
                      'assets/icones/profile_outline.svg',
                      'assets/icones/profile_filled.svg'),
                ],
              ),
            ),

            // le gros bouton central pour ajouter
            Positioned(
              bottom: 10,
              child: GestureDetector(
                onTap: () =>
                    ref.read(navigationIndexProvider.notifier).setIndex(2),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5))
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icones/add_filled.svg',
                      colorFilter: const ColorFilter.mode(
                          Colors.white, BlendMode.srcIn),
                      height: 35,
                      width: 35,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // helper pour les icones de la barre
  Widget _buildNavItem(WidgetRef ref, int itemIndex, int currentIndex,
      String outline, String filled) {
    final isActive = currentIndex == itemIndex;

    return GestureDetector(
      onTap: () =>
          ref.read(navigationIndexProvider.notifier).setIndex(itemIndex),
      behavior: HitTestBehavior.opaque,
      child: SvgPicture.asset(
        isActive ? filled : outline,
        height: 32,
        width: 32,
        colorFilter: ColorFilter.mode(
          isActive ? AppColors.primary : const Color(0xFF6B7C8A),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}