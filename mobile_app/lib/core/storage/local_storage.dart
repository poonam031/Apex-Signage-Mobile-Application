import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user_profile';
  static const String _keyOfflineDrafts = 'offline_site_visits_drafts';

  static Future<void> saveTokens(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUser);
    if (data == null) return null;
    return jsonDecode(data);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUser);
  }

  // Offline Drafts Management for Field Workers
  static Future<void> saveOfflineSiteVisit(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> drafts = prefs.getStringList(_keyOfflineDrafts) ?? [];
    drafts.add(jsonEncode(draft));
    await prefs.setStringList(_keyOfflineDrafts, drafts);
  }

  static Future<List<Map<String, dynamic>>> getOfflineSiteVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = prefs.getStringList(_keyOfflineDrafts) ?? [];
    return drafts.map((d) => jsonDecode(d) as Map<String, dynamic>).toList();
  }

  static Future<void> clearOfflineSiteVisits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOfflineDrafts);
  }
}
