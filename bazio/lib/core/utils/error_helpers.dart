import 'dart:io';
import 'package:bazio/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

//traduit les erreurs techniques en phrases pour l'utilisateur
String humanizeError(dynamic e) {
  final msg = e.toString().toLowerCase();

  //erreurs personnalisées de notre service auth
  if (e is AuthException) {
    switch (e.code) {
      case 'email-not-verified':
        return 'Veuillez vérifier votre email avant de vous connecter';
      case 'cancelled':
        return '';
      case 'no-current-user':
        return 'Aucun utilisateur connecté';
      case 'email-already-verified':
        return 'Email déjà vérifié';
    }
  }

  //soucis de connexion internet ou timeout
  if (e is SocketException ||
      msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused') ||
      msg.contains('connection reset') ||
      msg.contains('no address associated') ||
      msg.contains('no internet')) {
    return 'Pas de connexion Internet. Vérifiez votre réseau et réessayez.';
  }

  if (msg.contains('timeout') || msg.contains('timed out')) {
    return 'La connexion a expiré. Vérifiez votre réseau et réessayez.';
  }

  //erreurs firebase auth via le code texte
  switch (e.toString()) {
    case 'invalid-credential':
      return 'Email ou mot de passe incorrect';
    case 'email-already-in-use':
      return 'Un compte existe déjà avec cet email';
    case 'weak-password':
      return 'Le mot de passe est trop court (minimum 6 caractères)';
    case 'network-request-failed':
      return 'Pas de connexion internet';
    case 'too-many-requests':
      return 'Trop de tentatives, réessayez plus tard';
    case 'invalid-email':
      return 'Adresse email invalide';
    case 'user-not-found':
      return 'Aucun compte associé à cet email';
    case 'wrong-password':
      return 'Mot de passe incorrect';
    case 'user-disabled':
      return 'Ce compte a été désactivé';
  }

  //erreurs firestore et base de données
  if (e is FirebaseException) {
    switch (e.code) {
      case 'unavailable':
      case 'network-request-failed':
        return 'Pas de connexion Internet. Vérifiez votre réseau et réessayez.';
      case 'permission-denied':
        return 'Accès refusé. Vous n\'êtes pas autorisé à effectuer cette action.';
      case 'unauthenticated':
        return 'Session expirée. Veuillez vous reconnecter.';
      case 'not-found':
        return 'Élément introuvable. Il a peut-être été supprimé.';
      case 'already-exists':
        return 'Cet élément existe déjà.';
      case 'cancelled':
        return 'Opération annulée.';
      case 'resource-exhausted':
        return 'Trop de requêtes. Réessayez dans quelques instants.';
      case 'storage/canceled':
        return 'Upload annulé.';
      case 'storage/unknown':
      case 'storage/retry-limit-exceeded':
        return 'Erreur lors de l\'upload. Vérifiez votre connexion.';
      case 'storage/quota-exceeded':
        return 'Espace de stockage insuffisant.';
    }
  }

  //doublon de sécurité pour les erreurs auth spécifiques
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte associé à cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte.';
      case 'weak-password':
        return 'Le mot de passe est trop faible (minimum 6 caractères).';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'network-request-failed':
        return 'Pas de connexion Internet. Vérifiez votre réseau.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
    }
  }

  if (e is FirebaseException && e.plugin == 'firebase_storage') {
    return 'Erreur lors de l\'upload. Vérifiez votre connexion et réessayez.';
  }

  if (msg == 'cancelled' || msg == 'canceled') return '';

  //on nettoie le message si c'est une exception standard
  if (e is Exception) {
    final clean = e.toString().replaceFirst('Exception: ', '').trim();
    if (clean.isNotEmpty) return clean;
  }

  if (e is String && e.trim().isNotEmpty) return e.trim();

  return 'Une erreur inattendue est survenue. Réessayez.';
}