import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../app_state.dart';
import '../services/location_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  LatLng? _myLoc;
  double _myAcc = 0;
  LatLng? _peerLoc;
  String? _peerName;
  int? _peerAt;
  double _dist = 0;
  bool _centered = false;

  StreamSubscription<Position>? _sub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pollTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final ok = await LocationService.ensurePermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('定位不可用，请到系统设置开启定位权限')),
        );
      }
      return;
    }
    _sub = LocationService.stream().listen(_onPosition, onError: (_) {});
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    _poll();
  }

  void _onPosition(Position p) {
    final loc = LatLng(p.latitude, p.longitude);
    setState(() {
      _myLoc = loc;
      _myAcc = p.accuracy;
    });
    if (!_centered) {
      _centered = true;
      _mapController.move(loc, 14);
    }
    unawaited(AppState.instance.report(p.latitude, p.longitude, p.accuracy));
  }

  Future<void> _poll() async {
    final Map<String, dynamic> r;
    try {
      r = await AppState.instance.fetch();
    } catch (_) {
      return;
    }
    if (!mounted || r['ok'] != true) return;
    final room = r['room'] as Map<String, dynamic>;
    final members = (room['members'] as List?) ?? const [];
    final locs = (room['locations'] as Map<String, dynamic>?) ?? const {};
    final me = AppState.instance.memberId;

    final peer = members.whereType<Map<String, dynamic>>().where((m) => m['id'] != me).toList();
    LatLng? peerLoc;
    String? peerName;
    int? peerAt;
    if (peer.isNotEmpty) {
      peerName = peer.first['name']?.toString();
      final pl = locs[peer.first['id']];
      if (pl is Map) {
        peerLoc = LatLng((pl['lat'] as num).toDouble(), (pl['lng'] as num).toDouble());
        peerAt = (pl['at'] as num?)?.toInt();
      }
    }

    setState(() {
      _peerLoc = peerLoc;
      _peerName = peerName;
      _peerAt = peerAt;
      if (_myLoc != null && _peerLoc != null) {
        _dist = _haversine(_myLoc!, _peerLoc!);
      }
    });

    if (_myLoc != null && _peerLoc != null && !_fitted) {
      _fitted = true;
      _fitBoth();
    }
  }

  bool _fitted = false;

  void _fitBoth() {
    if (_myLoc == null || _peerLoc == null) return;
    final mid = LatLng(
      (_myLoc!.latitude + _peerLoc!.latitude) / 2,
      (_myLoc!.longitude + _peerLoc!.longitude) / 2,
    );
    final zoom = _dist < 500 ? 15.0 : (_dist < 2000 ? 13.0 : (_dist < 10000 ? 12.0 : 10.0));
    _mapController.move(mid, zoom);
  }

  double _haversine(LatLng a, LatLng b) {
    const R = 6371000.0;
    final toRad = (double x) => x * math.pi / 180.0;
    final dLat = toRad(b.latitude - a.latitude);
    final dLng = toRad(b.longitude - a.longitude);
    final s = math.pow(math.sin(dLat / 2), 2) +
        math.cos(toRad(a.latitude)) * math.cos(toRad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * R * math.asin(math.sqrt(s));
  }

  String _fmtDist(double m) {
    if (m < 1000) return '${m.round()} 米';
    return '${(m / 1000).toStringAsFixed(2)} 公里';
  }

  String _fmtTime(int? ms) {
    if (ms == null) return '--';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (_myLoc != null)
        Marker(point: _myLoc!, width: 34, height: 34, child: const Icon(Icons.my_location, color: Color(0xFF4FC3F7), size: 32)),
      if (_peerLoc != null)
        Marker(point: _peerLoc!, width: 34, height: 34, child: const Icon(Icons.location_on, color: Color(0xFFE91E63), size: 34)),
    ];
    final polyline = (_myLoc != null && _peerLoc != null)
        ? Polyline(points: [_myLoc!, _peerLoc!], strokeWidth: 3, color: Colors.white)
        : null;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(35.0, 105.0),
              initialZoom: 3,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.linkupclone.location',
              ),
              MarkerLayer(markers: markers),
              if (polyline != null) PolylineLayer(polylines: [polyline]),
            ],
          ),
          // 顶部栏
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '配对码 ${AppState.instance.roomCode ?? ''}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => AppState.instance.logout(),
                      child: const Text('退出', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 底部信息
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_myLoc != null && _peerLoc != null ? _fmtDist(_dist) : '--',
                              style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(_peerLoc == null ? '等待对方位置…' : '对方（${_peerName ?? ''}）：${_fmtTime(_peerAt)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _myLoc != null && _peerLoc != null ? _fitBoth : () => _mapController.move(_myLoc ?? const LatLng(0, 0), 14),
                      icon: const Icon(Icons.center_focus_strong, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
