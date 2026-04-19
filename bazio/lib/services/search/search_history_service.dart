import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchHistoryService {
  final _firestore = FirebaseFirestore.instance;

  //on recupere le chemin vers l'historique de l'utilisateur
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('search_history');
  }

  //permet d'afficher les 10 dernieres recherches
  Future<List<String>> getHistory() async {
    final col = _col;
    if (col == null) return [];
    final snap = await col
        .orderBy('searchedAt', descending: true)
        .limit(10)
        .get();
    return snap.docs.map((d) => d['query'] as String).toList();
  }

  Future<void> addSearch(String query) async {
    final col = _col;
    if (col == null || query.trim().isEmpty) return;
    
    //on evite les doublons en supprimant l'ancienne recherche identique
    final existing = await col
        .where('query', isEqualTo: query.trim())
        .get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    //on ajoute la nouvelle recherche en haut de liste
    await col.add({
      'query': query.trim(),
      'searchedAt': FieldValue.serverTimestamp(),
    });

    //on fait le ménage pour garder seulement les 10 plus récents
    final all = await col
        .orderBy('searchedAt', descending: true)
        .get();
    if (all.docs.length > 10) {
      for (final doc in all.docs.skip(10)) {
        await doc.reference.delete();
      }
    }
  }

  //supprime une ligne precise
  Future<void> removeSearch(String query) async {
    final col = _col;
    if (col == null) return;
    final snap = await col.where('query', isEqualTo: query.trim()).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  //on vide tout l'historique d'un coup
  Future<void> clearHistory() async {
    final col = _col;
    if (col == null) return;
    final snap = await col.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}

final searchHistoryServiceProvider =
    Provider<SearchHistoryService>((_) => SearchHistoryService());