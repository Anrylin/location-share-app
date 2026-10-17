import 'package:flutter/material.dart';

import '../app_state.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _server = TextEditingController();
  bool _busy = false;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _server.text = AppState.instance.serverUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() fn) async {
    setState(() { _busy = true; _err = ''; });
    await AppState.instance.setServer(_server.text);
    final err = await fn();
    if (!mounted) return;
    setState(() { _busy = false; _err = err ?? ''; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('📍', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('双人位置共享',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('一个人创建配对码，另一个人输入同一个码加入',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 28),
                TextField(
                  controller: _server,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: '服务器地址（可选，默认本机）',
                    hintText: '如 https://xxx.trycloudflare.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: '你的名字', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => AppState.instance.create(_name.text.trim().isEmpty ? '我' : _name.text.trim())),
                  child: const Text('创建配对码'),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: '输入对方的配对码',
                    hintText: '6 位',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => AppState.instance.join(_code.text.trim(), _name.text.trim().isEmpty ? '我' : _name.text.trim())),
                  child: const Text('加入'),
                ),
                const SizedBox(height: 12),
                Text(_err, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                const Text(
                  '提示：首次进入会请求定位权限，请选「始终允许」以便后台持续共享。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
