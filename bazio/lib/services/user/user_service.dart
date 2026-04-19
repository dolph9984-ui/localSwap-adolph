import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  //on recupere les infos du profil et on transforme la date pour pas galerer avec les types firestore
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
    }
    return data;
  }

  //on met a jour le nom et le tel dans firestore et dans la partie auth de firebase
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Non authentifié');

    await user.updateDisplayName(name);
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
      await user.reload();
    }

    final updates = <String, dynamic>{
      'name': name,
      'phone': phone,
      'photoUrl': ?photoUrl,
    };

    await _firestore.collection('users').doc(uid).update(updates);
  }

  //envoi de l'image sur le storage pour recuperer le lien public
  Future<String> uploadAvatar({required String uid, required File file}) async {
    final ref = _storage.ref().child('avatars').child('$uid.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  //pour recuperer rapidement la date de creation du compte
  Future<DateTime?> getCreatedAt(String uid) async {
    final data = await getUserProfile(uid);
    final ts = data['createdAt'] as Timestamp?;
    return ts?.toDate();
  }

  //ici c'est pour gerer la localisation de l'utilisateur
  //on va chercher la ville et les coordonnees gps enregistrees
  Future<Map<String, dynamic>> getLocation(String uid) async {
    final data = await getUserProfile(uid);
    return {
      'locationLat': data['locationLat'],
      'locationLng': data['locationLng'],
      'locationCity': data['locationCity'],
    };
  }

  //on sauvegarde la position de l'utilisateur dans son document firestore
  Future<void> saveLocation(String uid, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(uid).update(updates);
  }
}

final userServiceProvider = Provider<UserService>((_) => UserService());