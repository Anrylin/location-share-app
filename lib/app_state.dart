import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'services/location_service.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final ApiClient api = ApiClient.instance;

  String? roomCode;
  String? memberId;
  String? name;
  String? accountToken;
  String? username;

  // 位置状态
  double? myLat, myLng, myAcc;
  int? myAt;
  bool moving = false;
  double? peerLat, peerLng;
  String? peerName;
  int? peerAt;
  bool? peerMoving;
  double dist = 0;

  StreamSubscription<Position>? _locSub;
  Timer? _pollTimer;
  Position? _lastPos;
  int? _lastPosAt;

  bool get joined => roomCode != null && memberId != null;
  bool get loggedIn => accountToken != null;
  bool get hasPeer => peerLat != null;

  bool get peerOnline {
    if (peerAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch - peerAt! < 180000;
  }

  String get peerStatusText {
    if (peerLat == null) return '等待对方…';
    if (!peerOnline) return '离线';
    return peerMoving == true ? '移动中' : '停留中';
  }

  String get myStatusText {
    if (myLat == null) return '定位中…';
    return moving ? '移动中' : '停留中';
  }

  Future<void> boot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      roomCode = prefs.getString('roomCode');
      memberId = prefs.getString('memberId');
      name = prefs.getString('name');
      accountToken = prefs.getString('accountToken');
      username = prefs.getString('username');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persistAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accountToken', accountToken ?? '');
      await prefs.setString('username', username ?? '');
    } catch (_) {}
  }

  Future<String?> register(String u, String p) async {
    try {
      final r = await api.post('/api/register', {'username': u, 'password': p});
      if (r['ok'] == true) {
        accountToken = r['token']?.toString();
        username = r['username']?.toString();
        await _persistAccount();
        notifyListeners();
        return null;
      }
      return r['error']?.toString() ?? '注册失败';
    } catch (_) {
      return '无法连接服务器，请检查网络';
    }
  }

  Future<String?> login(String u, String p) async {
    try {
      final r = await api.post('/api/login', {'username': u, 'password': p});
      if (r['ok'] == true) {
        accountToken = r['token']?.toString();
        username = r['username']?.toString();
        await _persistAccount();
        notifyListeners();
        return null;
      }
      return r['error']?.toString() ?? '登录失败';
    } catch (_) {
      return '无法连接服务器，请检查网络';
    }
  }

  Future<void> logoutAccount() async {
    accountToken = null;
    username = null;
    await _persistAccount();
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
    try {
      final r = await api.post('/api/join', {'code': '', 'name': n, 'memberId': ''});
      if (r['ok'] == true) {
        roomCode = r['room']['code']?.toString();
        memberId = r['memberId']?.toString();
        name = n;
        await _save();
        startLocation();
        notifyListeners();
        return null;
      }
      return r['error']?.toString() ?? '创建失败';
    } catch (_) {
      return '无法连接服务器，请检查网络';
    }
  }

  Future<String?> join(String code, String n) async {
    try {
      final r = await api.post('/api/join', {'code': code, 'name': n, 'memberId': ''});
      if (r['ok'] == true) {
        roomCode = code.toUpperCase();
        memberId = r['memberId']?.toString();
        name = n;
        await _save();
        startLocation();
        notifyListeners();
        return null;
      }
      return r['error']?.toString() ?? '加入失败';
    } catch (_) {
      return '无法连接服务器，请检查网络';
    }
  }

  Future<Map<String, dynamic>> report(double lat, double lng, double acc, bool moving) {
    return api.post('/api/loc', {
      'roomId': roomCode,
      'memberId': memberId,
      'lat': lat,
      'lng': lng,
      'acc': acc,
      'moving': moving,
    });
  }

  Future<Map<String, dynamic>> fetch() {
    return api.get('/api/loc?roomId=$roomCode');
  }

  void startLocation() {
    stopLocation();
    LocationService.ensurePermission().then((ok) {
      if (!ok) return;
      _locSub = LocationService.stream().listen(_onPos, onError: (_) {});
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
      _poll();
    });
  }

  void stopLocation() {
    _locSub?.cancel();
    _locSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _onPos(Position p) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastPos != null && _lastPosAt != null) {
      final dt = (now - _lastPosAt!) / 1000.0;
      if (dt > 0) {
        final d = _haversine(_lastPos!.latitude, _lastPos!.longitude, p.latitude, p.longitude);
        moving = (d / dt) > 0.6;
      }
    }
    _lastPos = p;
    _lastPosAt = now;
    myLat = p.latitude;
    myLng = p.longitude;
    myAcc = p.accuracy;
    myAt = now;
    unawaited(report(p.latitude, p.longitude, p.accuracy, moving));
    notifyListeners();
  }

  Future<void> _poll() async {
    final Map<String, dynamic> r;
    try {
      r = await fetch();
    } catch (_) {
      return;
    }
    if (r['ok'] != true) return;
    final room = r['room'] as Map<String, dynamic>;
    final members = (room['members'] as List?) ?? const [];
    final locs = (room['locations'] as Map<String, dynamic>?) ?? const {};
    final peer = members.whereType<Map<String, dynamic>>().where((m) => m['id'] != memberId).toList();
    if (peer.isNotEmpty) {
      peerName = peer.first['name']?.toString();
      final pl = locs[peer.first['id']];
      if (pl is Map) {
        peerLat = (pl['lat'] as num).toDouble();
        peerLng = (pl['lng'] as num).toDouble();
        peerAt = (pl['at'] as num?)?.toInt();
        peerMoving = pl['moving'] == true;
      }
    }
    if (myLat != null && peerLat != null && myLng != null && peerLng != null) {
      dist = _haversine(myLat!, myLng!, peerLat!, peerLng!);
    }
    notifyListeners();
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    double toRad(double x) => x * math.pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) * math.cos(toRad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * R * math.asin(math.sqrt(a));
  }

  Future<void> logout() async {
    stopLocation();
    roomCode = null;
    memberId = null;
    name = null;
    myLat = null;
    myLng = null;
    myAcc = null;
    myAt = null;
    moving = false;
    peerLat = null;
    peerLng = null;
    peerName = null;
    peerAt = null;
    peerMoving = null;
    dist = 0;
    _lastPos = null;
    _lastPosAt = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('roomCode');
      await prefs.remove('memberId');
      await prefs.remove('name');
    } catch (_) {}
    notifyListeners();
  }
}
