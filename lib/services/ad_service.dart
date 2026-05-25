import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/home_ad.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static const String _backendUrl = 'https://sessame.onrender.com';

  Future<HomeAd?> getHomeSummaryAd() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/api/ads/home-summary'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final adJson = decoded['ad'];
      if (adJson is! Map<String, dynamic>) return null;

      final ad = HomeAd.fromJson(adJson);
      return ad.isDisplayable ? ad : null;
    } catch (_) {
      return null;
    }
  }
}
