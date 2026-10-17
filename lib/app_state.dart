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
  String serverUrl = ApiClient.instance.baseUrl;

  bool get joined => roomCode != null && memberId != null;

  Future<void> boot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      roomCode = prefs.getString('roomCode');
      memberId = prefs.getString('memberId');
      name = prefs.getString('name');
      final s = prefs.getString('serverUrl');
      if (s != null && s.isNotEmpty) serverUrl = s;
      api.baseUrl = serverUrl;
    } catch (_) {}
    notifyListeners();
  }

  /// 修改后端地址（改隧道地址后无需重新编译）。
  Future<void> setServer(String url) async {
    var u = url.trim();
    if (u.isEmpty) return;
    if (!u.startsWith('http')) u = 'http://$u';
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    serverUrl = u;
    api.baseUrl = u;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('serverUrl', u);
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
