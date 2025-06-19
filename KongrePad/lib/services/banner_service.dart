import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BannerService {
  static final BannerService _instance = BannerService._internal();
  factory BannerService() => _instance;
  BannerService._internal();

  // Error handling için static değişkenler
  static DateTime? _lastBannerError;
  static const _bannerErrorThreshold = Duration(minutes: 2);
  static bool _showDefaultBanner = false;

  // Banner URL'ini al
  String? _getBannerUrl(int meetingId) {
    if (meetingId == null) return null;
    return "https://api.kongrepad.com/api/v1/meetings/$meetingId/banner";
  }

  // Banner yükleme durumunu kontrol et
  bool _shouldSkipBannerLoading() {
    // Eğer default banner gösteriliyorsa veya error threshold içindeyse skip et
    if (_showDefaultBanner ||
        (_lastBannerError != null &&
            DateTime.now().difference(_lastBannerError!) <
                _bannerErrorThreshold)) {
      return true;
    }
    return false;
  }

  // Error threshold'u güncelle
  void _updateErrorThreshold() {
    if (_lastBannerError == null ||
        DateTime.now().difference(_lastBannerError!) >= _bannerErrorThreshold) {
      _lastBannerError = DateTime.now();
      _showDefaultBanner = true;
    }
  }

  // Banner yükleme işlemi
  Future<http.Response?> loadBanner(int meetingId) async {
    // Skip kontrolü
    if (_shouldSkipBannerLoading()) {
      return null;
    }

    try {
      final token = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('token'));

      if (token == null) return null;

      final url = _getBannerUrl(meetingId);
      if (url == null) return null;

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json, image/*',
        },
      );

      // 404 hatası durumunda error threshold'u güncelle
      if (response.statusCode == 404) {
        _updateErrorThreshold();
        print(
            'Banner yükleme hatası: HTTP request failed, statusCode: 404, $url');
        return null;
      }

      // Başarılı yanıt durumunda error state'i temizle
      if (response.statusCode == 200) {
        _showDefaultBanner = false;
        _lastBannerError = null;
      }

      return response;
    } catch (e) {
      _updateErrorThreshold();
      print('Banner yükleme hatası: $e');
      return null;
    }
  }

  // Error state'i sıfırla (manuel olarak)
  void resetErrorState() {
    _showDefaultBanner = false;
    _lastBannerError = null;
  }

  // Error state durumunu kontrol et
  bool get isInErrorState => _shouldSkipBannerLoading();
}
