import 'package:flutter/material.dart';

import '../app_state.dart';

/// LinkUp 风格登录/注册页：天蓝渐变背景 + 白色圆角卡片 + 深棕按钮。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController();
  final _pwd = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;
  String _err = '';

  @override
  void dispose() {
    _user.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final u = _user.text.trim();
    final p = _pwd.text;
    if (u.isEmpty || p.isEmpty) {
      setState(() => _err = '请输入用户名和密码');
      return;
    }
    setState(() { _busy = true; _err = ''; });
    final err = _isLogin
        ? await AppState.instance.login(u, p)
        : await AppState.instance.register(u, p);
    if (!mounted) return;
    setState(() { _busy = false; _err = err ?? ''; });
  }

  Widget _tab(String label, bool login) {
    final selected = _isLogin == login;
    return GestureDetector(
      onTap: () => setState(() { _isLogin = login; _err = ''; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF573E2E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
                  Image.asset('assets/images/logo_white.png', height: 88),
                  const SizedBox(height: 12),
                  const Text('两个人的位置，随时可见', style: TextStyle(color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 28),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _tab('登录', true)),
                              const SizedBox(width: 8),
                              Expanded(child: _tab('注册', false)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _user,
                            decoration: InputDecoration(
                              labelText: '用户名',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pwd,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: '密码',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_err, style: const TextStyle(color: Colors.red, fontSize: 12)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _go,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF573E2E),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(_isLogin ? '登录' : '注册'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('服务器：${AppState.instance.api.baseUrl}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
