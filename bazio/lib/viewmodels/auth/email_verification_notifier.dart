import 'dart:async';
import 'package:bazio/services/auth/auth_service.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/auth/auth_ui_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//etat de la verification par email
class VerificationState {
  final bool verified;
  final bool isResending;
  final int resendCooldown;

  const VerificationState({
    this.verified = false,
    this.isResending = false,
    this.resendCooldown = 0,
  });

  VerificationState copyWith({bool? verified, bool? isResending, int? resendCooldown}) {
    return VerificationState(
      verified: verified ?? this.verified,
      isResending: isResending ?? this.isResending,
      resendCooldown: resendCooldown ?? this.resendCooldown,
    );
  }
}

class EmailVerificationNotifier extends Notifier<VerificationState> {
  late final AuthService _authService;
  Timer? _pollingTimer;
  Timer? _cooldownTimer;

  @override
  VerificationState build() {
    _authService = ref.read(authServiceProvider);
    //on securise les fuites memoire en coupant les timers a la destruction
    ref.onDispose(() {
      _pollingTimer?.cancel();
      _cooldownTimer?.cancel();
    });
    return const VerificationState();
  }

  //on verifie si l'utilisateur a clique sur le lien toutes les 10s
  void startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (state.verified) return;
      checkVerification();
    });
  }

  //appel a AuthService pour recharger les infos du user et voir si c'est bon
  Future<void> checkVerification() async {
    try {
      final isVerified = await _authService.reloadAndCheckVerified();
      if (isVerified) {
        await _handleVerified();
      }
    } catch (_) {}
  }

  //quand c'est verifie, on nettoie tout et on deconnecte pour forcer le login propre
  Future<void> _handleVerified() async {
    if (state.verified) return;
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();

    ref.read(successMessageProvider.notifier).set(
      'Compte créé avec succès ! Vous pouvez vous connecter.',
    );

    state = state.copyWith(verified: true);
    // delegue la deconnexion a AuthService qui gere Google + Firebase
    await _authService.logOut();
  }

  //renvoi de l'email avec gestion du cooldown de 30 secondes
  Future<String?> resendEmail() async {
    if (state.isResending || state.resendCooldown > 0) return null;
    state = state.copyWith(isResending: true);
    try {
      await _authService.resendVerificationEmail();
      state = state.copyWith(isResending: false, resendCooldown: 30);
      _startCooldown();
      return null;
    } catch (e) {
      state = state.copyWith(isResending: false);
      return 'Impossible de renvoyer l\'email';
    }
  }

  //decompte seconde par seconde pour l'interface
  void _startCooldown() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.resendCooldown <= 1) {
        t.cancel();
        state = state.copyWith(resendCooldown: 0);
      } else {
        state = state.copyWith(resendCooldown: state.resendCooldown - 1);
      }
    });
  }

  //si l'utilisateur annule, on supprime le compte cree pour pas encombrer firebase
  Future<void> cancelAndDelete() async {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    // delegue à AuthService — plus de FirebaseAuth.instance direct dans le notifier
    await _authService.deleteCurrentUser();
    await _authService.logOut();
  }
}

//le autoDispose est crucial ici pour stopper tout des que l'utilisateur quitte la page
final emailVerificationProvider = NotifierProvider.autoDispose<EmailVerificationNotifier, VerificationState>(
  EmailVerificationNotifier.new,
);
