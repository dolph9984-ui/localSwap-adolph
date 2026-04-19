import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//service pour gerer la liste de favoris
class FavoritesService {
  final _firestore = FirebaseFirestore.instance;

  //recupere le dossier de favoris de l'utilisateur actuellement connecte
  CollectionReference<Map<String, dynamic>>? _col() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  //cible les favoris d'un utilisateur specifique via son id
  CollectionReference<Map<String, dynamic>> _colForUid(String uid) {
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  //ecoute en temps reel la liste des id d'annonces mises en favoris
  Stream<List<String>> favoritesStream(String uid) {
    return _colForUid(uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  //ajoute l'annonce aux favoris si elle n'y est pas, ou l'enleve si elle y est deja
  Future<void> toggleFavorite(String listingId) async {
    final col = _col();
    if (col == null) return;
    
    final doc = col.doc(listingId);
    final snap = await doc.get();
    
    if (snap.exists) {
      await doc.delete();
    } else {
      await doc.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }
}

//permet d'injecter et d'utiliser ce service partout dans l'appli avec Riverpod
final favoritesServiceProvider =
    Provider<FavoritesService>((_) => FavoritesService());