import 'package:bazio/core/router/main_wrapper.dart';
import 'package:bazio/model/listing/draft_model.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/viewmodels/auth/auth_ui_provider.dart';
import 'package:bazio/views/auth/email_verification_view.dart';
import 'package:bazio/views/auth/login_view.dart';
import 'package:bazio/views/auth/register_view.dart';
import 'package:bazio/views/detail/listing_detail_view.dart';
import 'package:bazio/views/home/widget/all_listings_by_category_view.dart';
import 'package:bazio/views/home/widget/all_listings_view.dart';
import 'package:bazio/views/message/message_view.dart';
import 'package:bazio/views/notification_view.dart';
import 'package:bazio/views/profil/page/favorite_view.dart';
import 'package:bazio/views/profil/page/sale_view.dart';
import 'package:bazio/views/profil/page/seller_profile_view.dart';
import 'package:bazio/views/profil/parametre/profil_setting_view.dart';
import 'package:bazio/views/publish/draft_view.dart';
import 'package:bazio/views/publish/publish_view.dart';
import 'package:bazio/views/review/leave_review_view.dart';
import 'package:bazio/views/review/review_view.dart';
import 'package:bazio/views/search/filter/filter_view.dart';
import 'package:bazio/views/search/widget/all_listings_from_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

//notre configuration globale de navigation
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: _AuthChangeNotifier(),

  //toute la logique pour rediriger selon si l'utilisateur est connecte ou pas
  redirect: (context, state) {
    final location = state.uri.toString();
    final user = FirebaseAuth.instance.currentUser;

    //si c'est un lien de recup de mot de passe on renvoie au login
    if (location.contains('firebaseapp.com') || location.contains('/__/auth/action')) {
      return '/login';
    }

    //on bloque l'acces aux pages sensibles si pas de user
    if (user == null) {
      if (location.startsWith('/home') || 
          location.startsWith('/publish') || 
          location.startsWith('/messages') || 
          location.startsWith('/notifications')) {
        return '/login';
      }
      return null;
    }

    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');

    //si tout est ok (verifie ou google), on sort du login/register
    if (user.emailVerified || isGoogle) {
      if (location == '/login' || location == '/register') return '/home';
      return null;
    }

    //si connecte mais mail pas verifie, on le force a verifier
    if (location.startsWith('/home') || location.startsWith('/publish')) {
      return '/verify-email';
    }
    return null;
  },

  //ce qu'on affiche si l'url n'existe pas
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Page introuvable'),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => appRouter.go('/home'),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    ),
  ),

  routes: [
    //pages d'authentification
    GoRoute(path: '/login', builder: (_, __) => const LoginView()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterView()),
    GoRoute(
      path: '/verify-email',
      builder: (_, __) => Consumer(
        builder: (context, ref, _) {
          final email = ref.watch(pendingVerificationEmailProvider) ?? '';
          return EmailVerificationView(email: email);
        },
      ),
    ),

    //le coeur de l'app avec la bottom nav
    GoRoute(path: '/home', builder: (_, __) => const MainWrapper()),

    //toute la partie publication et brouillons
    GoRoute(
      path: '/publish',
      builder: (context, state) {
        final draft = state.extra is DraftModel ? state.extra as DraftModel : null;
        return PublishView(draftToLoad: draft);
      },
    ),
    GoRoute(
      path: '/publish/edit',
      builder: (context, state) {
        final listing = state.extra as ListingModel;
        return PublishView(existingListing: listing);
      },
    ),
    GoRoute(path: '/my-drafts', builder: (_, __) => const DraftView()),

    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsView()),

    //gestion du profil et historique
    GoRoute(path: '/profile-settings', builder: (_, __) => const ProfileSettingsView()),
    GoRoute(path: '/favorites', builder: (_, __) => const FavoritesView()),
    GoRoute(path: '/my-sales', builder: (_, __) => const MySalesView()),
    GoRoute(path: '/my-reviews', builder: (_, __) => const MyReviewsView()),

    //voir le profil d'un autre utilisateur et lui laisser un avis
    GoRoute(
      path: '/seller/:sellerId',
      builder: (context, state) {
        final sellerId = state.pathParameters['sellerId']!;
        final sellerName = state.uri.queryParameters['sellerName'] ?? 'Vendeur';
        final listingId = state.uri.queryParameters['listingId'] ?? '';
        final listingTitle = state.uri.queryParameters['listingTitle'] ?? '';
        return SellerProfileView(
          sellerId: sellerId,
          sellerName: sellerName,
          listingId: listingId,
          listingTitle: listingTitle,
        );
      },
    ),
    GoRoute(
      path: '/leave-review/:sellerId',
      builder: (context, state) {
        final sellerId = state.pathParameters['sellerId']!;
        final sellerName = state.uri.queryParameters['sellerName'] ?? 'Vendeur';
        final listingId = state.uri.queryParameters['listingId'] ?? '';
        final listingTitle = state.uri.queryParameters['listingTitle'] ?? '';
        return LeaveReviewView(
          sellerId: sellerId,
          sellerName: sellerName,
          listingId: listingId,
          listingTitle: listingTitle,
        );
      },
    ),

    //recherche et details d'une annonce
    GoRoute(
      path: '/all-listings',
      builder: (context, state) {
        final sort = state.uri.queryParameters['sort'];
        return AllListingsView.fromSort(sort);
      },
    ),
    GoRoute(
      path: '/category/:value',
      builder: (context, state) {
        final value = state.pathParameters['value']!;
        return AllListingsByCategoryView.fromParams(value);
      },
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (context, state) => ListingDetailView(
        listingId: state.pathParameters['id']!,
        disableSellerLink:
            state.uri.queryParameters['disableSeller'] == 'true',
      ),
    ),
    GoRoute(
      path: '/search-results',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final results = (extra['results'] as List?)?.cast<ListingModel>() ?? [];
        final query = extra['query'] as String? ?? '';
        return AllListingsFromSearch(results: results, query: query);
      },
    ),
    GoRoute(path: '/filters', builder: (_, __) => const FilterView()),

    //la messagerie privee
    GoRoute(
      path: '/messages/:chatId',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final listingTitle = Uri.decodeComponent(state.uri.queryParameters['listingTitle'] ?? 'Discussion');
        return MessageView(chatId: chatId, listingTitle: listingTitle);
      },
    ),
  ],
);

//on ecoute les changements de firebase pour rafraichir le router auto
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
}