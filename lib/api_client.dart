import 'dart:convert';

import 'package:http/http.dart' as http;

/// 统一 API 客户端，与 location-share/server.js 后端对接。
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// 后端地址，可用 --dart-define=API_BASE=... 覆盖；
  /// 也可在 App 里运行时修改（AppState.setServer），存到本地。
  /// Android 模拟器访问宿主机请用 http://10.0.2.2:8788
  String baseUrl =
      const String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8788');

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(_u(path), headers: _headers);
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(
      _u(path),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> out;
    try {
      final dynamic data = jsonDecode(utf8.decode(res.bodyBytes));
      out = data is Map<String, dynamic> ? data : {'raw': data};
    } catch (_) {
      out = {};
    }
    out['_status'] = res.statusCode;
    return out;
  }
}
