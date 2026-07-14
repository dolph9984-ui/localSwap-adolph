import 'dart:ui';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/viewmodels/messaging/chat_notifier.dart';
import 'package:bazio/views/home/home_view.dart';
import 'package:bazio/views/message/message_view.dart';
import 'package:bazio/views/profil/profil_view.dart';
import 'package:bazio/views/search/search_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// trigger pour activer le clavier de recherche depuis n'importe quelle page
class SearchFocusTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

final searchFocusTriggerProvider =
    NotifierProvider<SearchFocusTriggerNotifier, int>(SearchFocusTriggerNotifier.new);

//on gere l'index de la navigation ici pour savoir quelle page afficher
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final navigationIndexProvider =
    NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);

//le wrapper qui contient la barre de navigation et le contenu changeant
class MainWrapper extends ConsumerWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    //on recupere le nombre de messages non lus pour le badge
    final unreadChats = ref.watch(unreadChatsCountProvider);

    final pages = [
      const HomeView(),
      const SearchView(),
      const MessagesView(),
      const ProfileView(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false, //empeche la barre de remonter avec le clavier
      body: Stack(
        children: [
          IndexedStack(index: index, children: pages),

          if (!keyboardVisible) ...[ 

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                  child: Container(
                    // Un très léger voile clair pour adoucir les éléments en arrière-plan
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              //on bloque les clics fantomes derriere la navbar
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, 
                child: _buildCustomBottomBar(context, ref, index, unreadChats),
              ),
            ),
          ],
        ],
      ),
    );
  }

  //construction de la barre flottante en forme de pilule
  Widget _buildCustomBottomBar(
      BuildContext context, WidgetRef ref, int currentIndex, int unreadChats) {
    const barBgColor = Color(0xFFEFF2F5);

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 12.0),
      child: SizedBox(
        height: 85,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            //le corps de la barre (le fond gris clair)
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

            //le petit socle rond pour le bouton central
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

            //les icones de navigation disposees de chaque cote du bouton plus
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
                  const SizedBox(width: 65), //on laisse la place au bouton central
                  _buildNavItemWithBadge(
                    ref, 2, currentIndex,
                    'assets/icones/message_outline.svg',
                    'assets/icones/message_filled.svg',
                    unreadChats,
                  ),
                  _buildNavItem(ref, 3, currentIndex,
                      'assets/icones/profile_outline.svg',
                      'assets/icones/profile_filled.svg'),
                ],
              ),
            ),

            //le bouton central bleu pour publier une annonce
            Positioned(
              bottom: 10,
              child: GestureDetector(
                onTap: () => context.go('/publish'),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: AppColors.bleu,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
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

  //helper pour construire une icone simple (change de couleur si active)
  Widget _buildNavItem(
    WidgetRef ref,
    int itemIndex,
    int currentIndex,
    String outline,
    String filled,
  ) {
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

  //pareil que buildNavItem mais avec un badge rouge pour les notifications
  Widget _buildNavItemWithBadge(
    WidgetRef ref,
    int itemIndex,
    int currentIndex,
    String outline,
    String filled,
    int badgeCount,
  ) {
    final isActive = currentIndex == itemIndex;

    return GestureDetector(
      onTap: () =>
          ref.read(navigationIndexProvider.notifier).setIndex(itemIndex),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset(
            isActive ? filled : outline,
            height: 32,
            width: 32,
            colorFilter: ColorFilter.mode(
              isActive ? AppColors.primary : const Color(0xFF6B7C8A),
              BlendMode.srcIn,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.rouge,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}