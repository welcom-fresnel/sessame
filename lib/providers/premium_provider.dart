import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumProvider extends ChangeNotifier {
  static const String _premiumKey = 'is_premium';
  static const int premiumPriceXaf = 650;

  bool _isPremium = false;
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;

  PremiumProvider() {
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final snap = await _firestore.collection('users').doc(uid).get();
        final remotePremium = snap.data()?['isPremium'];
        if (remotePremium is bool) {
          _isPremium = remotePremium;
          await prefs.setBool(_premiumKey, remotePremium);
        }
      }
    } catch (e) {
      print('Erreur lors du chargement du statut premium: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activatePremiumForTesting() async {
    _isPremium = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, true);
      await _syncPremiumStatusToFirestore(true);
    } catch (e) {
      print('Erreur lors de l\'activation premium: $e');
    }
  }

  Future<void> deactivatePremiumForTesting() async {
    _isPremium = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, false);
      await _syncPremiumStatusToFirestore(false);
    } catch (e) {
      print('Erreur lors de la désactivation premium: $e');
    }
  }

  Future<void> _syncPremiumStatusToFirestore(bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'isPremium': value,
      'premiumPriceXaf': premiumPriceXaf,
      'premiumUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
