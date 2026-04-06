import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signUp(String name, String email, String password) async {
    try {
      //deconnexion google preventive pour eviter les conflits de session
      await GoogleSignIn().signOut();
      await _auth.signOut();

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      await user!.updateDisplayName(name);

      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'provider': 'password',
      });

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw e.code;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      //on deconnecte direct si l email n est pas valide pour forcer le flow de verif
      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        throw 'email-not-verified';
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw e.code;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw 'cancelled';

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;

      //creation du doc seulement si c est la premiere fois
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'email': user.email,
          'provider': 'google',
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      await GoogleSignIn().signOut();
      throw e.code;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'no-current-user';

      //reload obligatoire pour rafraichir le cache firebase
      await user.reload();
      final refreshed = _auth.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        throw 'email-already-verified';
      }

      await refreshed?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw e.code;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> logOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  User? getCurrentUser() => _auth.currentUser;
}