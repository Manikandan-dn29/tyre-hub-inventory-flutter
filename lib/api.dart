import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Api {
  //  BASE URL 
  static const String baseUrl = "http://10.0.2.2:5095/api";
  static const String imageBase = "http://10.0.2.2:5095";

  //  ENDPOINTS 
  static const String login = "$baseUrl/auth/login";
  static const String refresh = "$baseUrl/auth/refresh";

  static const String grn = "$baseUrl/grn";
  static const String issue = "$baseUrl/issue";
  static const String upload = "$baseUrl/upload";

  static const String items = "$baseUrl/master/items";
  static const String stock = "$baseUrl/master/stock";
  static const String transactions = "$baseUrl/master/transactions";
  static const String users = "$baseUrl/master/users";

  //  STORAGE KEYS 
  static const String _tokenKey = "token";
  static const String _refreshTokenKey = "refresh_token";

  //  TOKEN SAVE 
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  //  TOKEN GET 
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  //  LOGOUT 
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  //  JWT EXPIRY CHECK 
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        ),
      );

      final exp = payload['exp'];
      if (exp == null) return true;

      final expiryDate =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);

      return DateTime.now().toUtc().isAfter(expiryDate);
    } catch (e) {
      print("Token decode error: $e");
      return true;
    }
  }

  //  GET TOKEN EXPIRY TIME 
  static DateTime? getTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'];
      if (exp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  //  LOGIN STATUS 
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;
    return !isTokenExpired(token);
  }

  //  REFRESH TOKEN 
  static Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    final res = await http.post(
      Uri.parse(refresh),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "refreshToken": refreshToken,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      await saveTokens(
        data['token'],
        data['refreshToken'],
      );

      return true;
    }

    return false;
  }
    //  SAVE BOTH TOKENS 
  static Future<void> saveTokens(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }



}
