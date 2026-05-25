import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    return snap.data();
  }

  Future<void> upsertProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required int birthYear,
    required String phoneNumber,
    String? email,
    String? displayName,
  }) async {
    await _userDoc(uid).set(
      {
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'birthYear': birthYear,
        'phoneNumber': phoneNumber,
        if (email != null) 'email': email,
        if (displayName != null) 'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

