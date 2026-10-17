import 'package:flutter/material.dart';

import '../app_state.dart';

/// LinkUp 风格配对页：天蓝渐变背景 + 白色圆角卡片。
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String _err = '';

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  String get _displayName => AppState.instance.username ?? '我';

  Future<void> _run(Future<String?> Function() fn) async {
    setState(() { _busy = true; _err = ''; });
    final err = await fn();
    if (!mounted) return;
    setState(() { _busy = false; _err = err ?? ''; });
  }

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo_white.png', height: 72),
                  const SizedBox(height: 12),
                  Text('你好，$_displayName', style: const TextStyle(color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('一个人创建配对码，另一个人输入同一个码加入',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _name,
                            decoration: InputDecoration(
                              labelText: '你的名字',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() => AppState.instance
                                      .create(_name.text.trim().isEmpty ? _displayName : _name.text.trim())),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF573E2E),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('创建配对码'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('已有配对码？输入加入', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _code,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: '配对码',
                              hintText: '6 位',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() => AppState.instance
                                      .join(_code.text.trim(), _name.text.trim().isEmpty ? _displayName : _name.text.trim())),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF573E2E),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('加入'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_err, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => AppState.instance.logoutAccount(),
                    child: const Text('切换账号', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 4),
                  const Text('首次进入会请求定位权限，请选「始终允许」',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
