import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signUp(String name, String email, String password) async {
    try {
      //on s'assure qu'aucune session traine avant de creer un compte
      await GoogleSignIn().signOut();
      await _auth.signOut();

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      await user!.updateDisplayName(name);

      //on sauvegarde les infos du user dans notre base de donnees
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

  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      //on bloque la connexion si l'email n'est pas encore valide
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
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw 'cancelled';//le gars a ferme la popup

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

      final doc = await _firestore.collection('users').doc(refreshedUser.uid).get();
      
      if (!doc.exists) {
        //nouveau compte google, on l'enregistre en base
        await _firestore.collection('users').doc(refreshedUser.uid).set({
          'name': refreshedUser.displayName ?? googleUser.displayName,
          'email': email,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(), 
        });
      } else {
        final updates = <String, dynamic>{};
        if (doc.data()?['email'] == null) {
          updates['email'] = email;
        }
        //retrocompatibilite : ajoute createdAt si c'etait pas fait a l'epoque
        if (doc.data()?['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        }
        
        //on met a jour seulement s'il manque des trucs
        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(refreshedUser.uid).update(updates);
        }
      }

      return refreshedUser;
    } on FirebaseAuthException catch (e) {
      await GoogleSignIn().signOut();//on clean la session google en cas d'erreur
      throw e.code;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'no-current-user';

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