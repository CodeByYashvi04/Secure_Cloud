import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://secure-cloud-d93x.onrender.com/api';

  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static void setToken(String token) => _token = token;
  static String? getAuthToken() => _token;
  static void setUser(Map<String, dynamic> user) => _currentUser = user;
  static void clearSession() { _token = null; _currentUser = null; }
  static Map<String, dynamic>? get currentUser => _currentUser;

  static Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) headers['x-auth-token'] = _token!;
    return headers;
  }

  /// Safely decode a response map.
  static Map<String, dynamic> _safeMap(http.Response r) {
    try {
      final d = jsonDecode(r.body);
      if (d is Map<String, dynamic>) return d;
      return {'message': d.toString()};
    } catch (_) {
      return {'message': 'Unexpected server response (status ${r.statusCode}). Please try again.'};
    }
  }

  /// Safely decode a response list.
  static List<dynamic> _safeList(http.Response r) {
    try {
      final d = jsonDecode(r.body);
      if (d is List) return d;
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── AUTH ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/auth/login'),
          headers: _headers, body: jsonEncode({'email': email, 'password': password}));
      return _safeMap(r);
    } catch (_) {
      return {'message': 'Could not reach server. Check your internet connection.'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/auth/register'),
          headers: _headers, body: jsonEncode({'name': name, 'email': email, 'password': password}));
      return _safeMap(r);
    } catch (_) {
      return {'message': 'Could not reach server. Check your internet connection.'};
    }
  }

  // ─── DASHBOARD ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/dashboard/summary'), headers: _headers);
      return _safeMap(r);
    } catch (_) {
      return {
        'stats': {'riskScore': 0, 'connectedClouds': 0, 'activeSessions': 0, 'totalAlerts': 0, 'recentActivities': []},
        'history': []
      };
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/dashboard/stats'), headers: _headers);
      return _safeMap(r);
    } catch (_) {
      return {'riskScore': 0, 'connectedClouds': 0, 'activeSessions': 0, 'totalAlerts': 0, 'recentActivities': []};
    }
  }

  static Future<List<dynamic>> getAlerts() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/dashboard/alerts'), headers: _headers);
      return _safeList(r);
    } catch (_) { return []; }
  }

  // ─── VAULT (File Upload) ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/vault/upload'));
      if (_token != null) request.headers['x-auth-token'] = _token!;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send();
      final r = await http.Response.fromStream(streamed);
      return _safeMap(r);
    } catch (e) {
      return {'message': 'Upload failed: $e'};
    }
  }

  static Future<List<dynamic>> getFiles() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/vault/files'), headers: _headers);
      return _safeList(r);
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>> deleteFile(String fileId) async {
    try {
      final r = await http.delete(Uri.parse('$baseUrl/vault/files/$fileId'), headers: _headers);
      return _safeMap(r);
    } catch (e) {
      return {'message': 'Delete failed: $e'};
    }
  }

  static Future<void> downloadFile(String fileId, String fileName) async {
    // In a real mobile app, we would use Dio to download to path_provider.
    // For this prototype, we'll simulate the download/open.
    try {
      final r = await http.get(Uri.parse('$baseUrl/vault/download/$fileId'), headers: _headers);
      if (r.statusCode == 200) {
        // Here we would write r.bodyBytes to a file and call OpenFile.open()
        print('Downloaded ${r.bodyBytes.length} bytes for $fileName');
      }
    } catch (_) {}
  }

  // ─── ANALYTICS ──────────────────────────────────────────────────────────

  static Future<List<dynamic>> getRiskHistory() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/dashboard/history'), headers: _headers);
      return _safeList(r);
    } catch (_) { return []; }
  }

  // ─── CLOUD ACCOUNTS ──────────────────────────────────────────────────────

  static Future<List<dynamic>> getCloudAccounts() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/cloud/accounts'), headers: _headers);
      return _safeList(r);
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>?> addCloudAccount(String provider, Map<String, String> credentials) async {
    try {
      final h = {..._headers, 'Content-Type': 'application/json'};
      final body = json.encode({
        'provider': provider,
        'credentials': credentials
      });
      final r = await http.post(Uri.parse('$baseUrl/cloud/accounts'), headers: h, body: body);
      
      if (r.statusCode == 200) {
        return json.decode(r.body) as Map<String, dynamic>;
      } else {
        throw Exception(json.decode(r.body)['message'] ?? 'Failed to add account');
      }
    } catch (e) {
      // Re-throw so the UI can catch and display the nice error to the user
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── ACTIVITY LOGS ───────────────────────────────────────────────────────

  static Future<List<dynamic>> getActivityLogs() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/activity/logs'), headers: _headers);
      return _safeList(r);
    } catch (_) { return []; }
  }

  static Future<void> logActivity(String action, {String service = 'App', int riskScore = 0}) async {
    try {
      await http.post(Uri.parse('$baseUrl/activity/log'),
          headers: _headers,
          body: jsonEncode({'action': action, 'service': service, 'riskScore': riskScore}));
    } catch (_) {}
  }

  // ─── ACCOUNT MANAGEMENT ────────────────────────────────────────────────
  
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/auth/forgot-password'),
          headers: _headers, body: jsonEncode({'email': email}));
      return _safeMap(r);
    } catch (_) { return {'message': 'Connection failed'}; }
  }

  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/auth/reset-password/$token'),
          headers: _headers, body: jsonEncode({'password': newPassword}));
      return _safeMap(r);
    } catch (_) { return {'message': 'Connection failed'}; }
  }

  static Future<Map<String, dynamic>> updateProfile({String? name, String? email, bool? mfa, bool? notifications}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (mfa != null) body['mfaEnabled'] = mfa;
      if (notifications != null) body['pushNotificationsEnabled'] = notifications;

      final r = await http.put(Uri.parse('$baseUrl/auth/profile'),
          headers: _headers, body: jsonEncode(body));
      final res = _safeMap(r);
      if (r.statusCode == 200 && _currentUser != null) {
        // Update local user state
        if (name != null) _currentUser!['name'] = name;
        if (email != null) _currentUser!['email'] = email;
        if (mfa != null) _currentUser!['mfaEnabled'] = mfa;
        if (notifications != null) _currentUser!['pushNotificationsEnabled'] = notifications;
      }
      return res;
    } catch (_) { return {'message': 'Update failed'}; }
  }

  static Future<Map<String, dynamic>> changePassword(String current, String newPass) async {
    try {
      final r = await http.put(Uri.parse('$baseUrl/auth/change-password'),
          headers: _headers, body: jsonEncode({'currentPassword': current, 'newPassword': newPass}));
      return _safeMap(r);
    } catch (_) { return {'message': 'Connection failed'}; }
  }

  // ─── AI ASSISTANT ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> chatWithAI(String message) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/ai/chat'),
          headers: _headers, body: jsonEncode({'message': message}));
      return _safeMap(r);
    } catch (_) {
      return {'reply': 'I am having trouble connecting to my secure neural link. Please check your internet connection.'};
    }
  }
}
