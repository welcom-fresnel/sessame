import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/home_ad.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static const String _backendUrl = 'https://sessame.onrender.com';

  Future<List<HomeAd>> getHomeSummaryAds() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/api/ads/home-summary'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode < 200 || response.statusCode >= 300) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];

      final adsJson = decoded['ads'];
      if (adsJson is List) {
        return adsJson
            .whereType<Map<String, dynamic>>()
            .map(HomeAd.fromJson)
            .where((ad) => ad.isDisplayable)
            .toList();
      }

      final adJson = decoded['ad'];
      if (adJson is Map<String, dynamic>) {
        final ad = HomeAd.fromJson(adJson);
        return ad.isDisplayable ? [ad] : [];
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  Future<HomeAd?> getHomeSummaryAd() async {
    final ads = await getHomeSummaryAds();
    return ads.isEmpty ? null : ads.first;
  }
}
