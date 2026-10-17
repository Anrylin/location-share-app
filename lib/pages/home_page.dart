import 'package:flutter/material.dart';

import '../app_state.dart';
import 'map_page.dart';

/// LinkUp 风格守护首页：双方头像 + 距离 + 设备状态 + 实时位置/轨迹入口。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState.instance.startLocation();
    });
  }

  String _fmtDist(double m) {
    if (m < 1000) return '${m.round()} 米';
    return '${(m / 1000).toStringAsFixed(2)} 公里';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9BE7FF), Color(0xFF5ECBFA)],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (context, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        // 双方头像与状态
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Text('😊', style: TextStyle(fontSize: 22))),
                              const SizedBox(width: 10),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.username ?? '我', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(s.myStatusText, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ]),
                            ]),
                            Row(children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(s.peerName ?? '等待对方', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(s.peerStatusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ]),
                              const SizedBox(width: 10),
                              const CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Text('🦌', style: TextStyle(fontSize: 22))),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(s.hasPeer ? _fmtDist(s.dist) : '--', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('我们的距离', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.25), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            s.hasPeer ? '对方${s.peerStatusText}' : '等待对方加入…（配对码 ${s.roomCode ?? ''}）',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // 白色功能卡片区
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('守护', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF573E2E))),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: _card(Icons.location_on, '实时位置', '查看对方当前位置',
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _card(Icons.route, '轨迹', '查看移动轨迹', () {})),
                          ]),
                          const SizedBox(height: 20),
                          Text('设备状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF573E2E))),
                          const SizedBox(height: 12),
                          Row(children: [
                            _chip('我 · ${s.myStatusText}', s.moving ? const Color(0xFF4CAF50) : const Color(0xFF6ADAFC)),
                            const SizedBox(width: 10),
                            _chip(
                              s.hasPeer ? '对方 · ${s.peerStatusText}' : '对方 · 未加入',
                              s.hasPeer
                                  ? (s.peerStatusText == '离线'
                                      ? Colors.grey
                                      : (s.peerMoving == true ? const Color(0xFF4CAF50) : const Color(0xFF6ADAFC)))
                                  : Colors.grey,
                            ),
                          ]),
                          const Spacer(),
                          Row(children: [
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.grey),
                              onPressed: () => AppState.instance.logout(),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _card(IconData icon, String title, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF0FAFF), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFF6ADAFC), size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
