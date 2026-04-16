import 'package:flutter_riverpod/flutter_riverpod.dart';

//notifiers generiques pour eviter de recreer la meme logique partout
class BoolNotifier extends Notifier<bool> {
  final bool initial;
  BoolNotifier(this.initial);

  @override
  bool build() => initial;
  
  void toggle() => state = !state;
  void setValue(bool v) => state = v;
}

class StringOrNullNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void set(String? value) => state = value;
}

//on gere la visibilite des mots de passe (login et register)
final obscureLoginPasswordProvider =
    NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(true));

final obscureRegisterPasswordProvider =
    NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(true));

final obscureConfirmPasswordProvider =
    NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(true));

//etat pour activer ou desactiver le bouton de validation du formulaire
final loginFormValidProvider =
    NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(false));

//gestion des etats de chargement pour chaque bouton d'action
//on utilise autoDispose pour reset l'etat quand on quitte l'ecran
final loginLoadingProvider =
    NotifierProvider.autoDispose<BoolNotifier, bool>(() => BoolNotifier(false));

final registerLoadingProvider =
    NotifierProvider.autoDispose<BoolNotifier, bool>(() => BoolNotifier(false));

final googleLoadingProvider =
    NotifierProvider.autoDispose<BoolNotifier, bool>(() => BoolNotifier(false));

//stockage temporaire des messages de retour et de l'email en attente
final successMessageProvider =
    NotifierProvider<StringOrNullNotifier, String?>(StringOrNullNotifier.new);

final pendingVerificationEmailProvider =
    NotifierProvider<StringOrNullNotifier, String?>(StringOrNullNotifier.new);