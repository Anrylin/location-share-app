import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final ApiClient api = ApiClient.instance;

  String? roomCode;
  String? memberId;
  String? name;

  bool get joined => roomCode != null && memberId != null;

  Future<void> boot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      roomCode = prefs.getString('roomCode');
      memberId = prefs.getString('memberId');
      name = prefs.getString('name');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('roomCode', roomCode ?? '');
      await prefs.setString('memberId', memberId ?? '');
      await prefs.setString('name', name ?? '');
    } catch (_) {}
  }

  Future<String?> create(String n) async {
    final r = await api.post('/api/join', {'code': '', 'name': n, 'memberId': ''});
    if (r['ok'] == true) {
      roomCode = r['room']['code']?.toString();
      memberId = r['memberId']?.toString();
      name = n;
      await _save();
      notifyListeners();
      return null;
    }
    return r['error']?.toString() ?? '创建失败';
  }

  Future<String?> join(String code, String n) async {
    final r = await api.post('/api/join', {'code': code, 'name': n, 'memberId': ''});
    if (r['ok'] == true) {
      roomCode = code.toUpperCase();
      memberId = r['memberId']?.toString();
      name = n;
      await _save();
      notifyListeners();
      return null;
    }
    return r['error']?.toString() ?? '加入失败';
  }

  Future<Map<String, dynamic>> report(double lat, double lng, double acc) {
    return api.post('/api/loc', {
      'roomId': roomCode,
      'memberId': memberId,
      'lat': lat,
      'lng': lng,
      'acc': acc,
    });
  }

  Future<Map<String, dynamic>> fetch() {
    return api.get('/api/loc?roomId=$roomCode');
  }

  Future<void> logout() async {
    roomCode = null;
    memberId = null;
    name = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('roomCode');
      await prefs.remove('memberId');
      await prefs.remove('name');
    } catch (_) {}
    notifyListeners();
  }
}
