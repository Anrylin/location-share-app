import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_state.dart';

/// 实时位置地图（数据来自 AppState，首页负责持续上报与轮询）。
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('实时位置')),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final my = s.myLat != null && s.myLng != null ? LatLng(s.myLat!, s.myLng!) : null;
          final peer = s.peerLat != null && s.peerLng != null ? LatLng(s.peerLat!, s.peerLng!) : null;
          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: my ?? peer ?? const LatLng(35.0, 105.0),
                  initialZoom: (my != null || peer != null) ? 13 : 3,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.linkupclone.location',
                  ),
                  MarkerLayer(markers: [
                    if (my != null)
                      Marker(point: my, width: 34, height: 34, child: const Icon(Icons.my_location, color: Color(0xFF6ADAFC), size: 32)),
                    if (peer != null)
                      Marker(point: peer, width: 34, height: 34, child: const Icon(Icons.location_on, color: Color(0xFF573E2E), size: 34)),
                  ]),
                  if (my != null && peer != null)
                    PolylineLayer(polylines: [
                      Polyline(points: [my, peer], strokeWidth: 3, color: const Color(0xFF6ADAFC)),
                    ]),
                ],
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.hasPeer ? _fmtDist(s.dist) : '--',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF573E2E))),
                              Text(s.hasPeer ? '对方（${s.peerName ?? ''}）：${s.peerStatusText}' : '等待对方…',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.heart_broken_outlined, color: s.hasPeer ? const Color(0xFF6ADAFC) : Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmtDist(double m) {
    if (m < 1000) return '${m.round()} 米';
    return '${(m / 1000).toStringAsFixed(2)} 公里';
  }
}
