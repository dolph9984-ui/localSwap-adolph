import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

//erreurs personnalisées pour l'app
class AuthException implements Exception {
  final String code;
  const AuthException(this.code);

  @override
  String toString() => code;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //creation de compte avec email et nom
  Future<void> signUp(String name, String email, String password) async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      await user!.updateDisplayName(name);

      //on stocke les infos du profil dans firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'provider': 'password',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw e.code;
    } catch (e) {
      throw e.toString();
    }
  }

  //connexion classique par email
  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      //on bloque si l'email n'est pas encore validé
      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        throw const AuthException('email-not-verified');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw e.code;
    } catch (e) {
      rethrow;
    }
  }

  //connexion via le bouton google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw const AuthException('cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;

      await user.reload();
      final refreshedUser = _auth.currentUser!;

      final email = refreshedUser.email ??
          refreshedUser.providerData.firstOrNull?.email ??
          googleUser.email;

      final doc = await _firestore
          .collection('users')
          .doc(refreshedUser.uid)
          .get();

      //cree le profil s'il n'existe pas encore
      if (!doc.exists) {
        await _firestore.collection('users').doc(refreshedUser.uid).set({
          'name': refreshedUser.displayName ?? googleUser.displayName,
          'email': email,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        //met a jour les infos manquantes si besoin
        final updates = <String, dynamic>{};
        if (doc.data()?['email'] == null) {
          updates['email'] = email;
        }
        if (doc.data()?['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        }
        if (updates.isNotEmpty) {
          await _firestore
              .collection('users')
              .doc(refreshedUser.uid)
              .update(updates);
        }
      }

      return refreshedUser;
    } on FirebaseAuthException catch (e) {
      await GoogleSignIn().signOut();
      throw e.code;
    } catch (e) {
      rethrow;
    }
  }

  //renvoie le lien de validation par mail
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AuthException('no-current-user');

      await user.reload();
      final refreshed = _auth.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        throw const AuthException('email-already-verified');
      }

      await refreshed?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw e.code;
    } catch (e) {
      rethrow;
    }
  }

  //deconnecte l'utilisateur partout
  Future<void> logOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  User? getCurrentUser() => _auth.currentUser;

  //actualise le statut de verification de l'email
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  //supprime le compte en cas d'annulation de l'inscription
  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {}
  }
}