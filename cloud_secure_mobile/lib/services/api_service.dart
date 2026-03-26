import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use your computer's local IP address so the phone can connect
  static const String baseUrl = 'http://192.168.1.35:5000/api'; 

  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-auth-token': ?_token,
      };

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection Error: $e'};
    }
  }

  static Future<List<dynamic>> getAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/alerts'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }
}
