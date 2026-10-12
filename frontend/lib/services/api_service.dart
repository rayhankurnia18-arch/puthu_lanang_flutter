import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<List<MenuItem>> getMenu() async {
    final r = await http.get(Uri.parse('$baseUrl/menu')).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw Exception('Gagal mengambil menu');
    
    final List<dynamic> data = jsonDecode(r.body) as List<dynamic>;
    return data.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/user-login'), 
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode({'no_whatsapp': phone, 'password': password})
    );
    
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Login gagal');
    }
    return body;
  }

  static Future<Map<String, dynamic>> register(String name, String phone, String password) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/user-register'), 
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode({'nama': name, 'no_whatsapp': phone, 'password': password})
    );
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400) throw Exception(body['message'] ?? 'Registrasi gagal');
    return body;
  }

  static Future<Map<String, dynamic>> sendOtp(String phone, {String type = 'register'}) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'no_whatsapp': phone,
        'type': type,
      }),
    );
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal mengirim OTP');
    return body;
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otpCode,
    String? name,
    String? password,
    required bool isRegister,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'no_whatsapp': phone,
        'otp_code': otpCode,
        'nama': name ?? '',
        'password': password ?? '',
        'is_register': isRegister,
      }),
    );
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400) throw Exception(body['message'] ?? 'Verifikasi OTP gagal');
    return body;
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String phone,
    required String otpCode,
    required String newPassword,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'no_whatsapp': phone,
        'otp_code': otpCode,
        'new_password': newPassword,
      }),
    );
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal mengubah password');
    return body;
  }

  static Future<Map<String, dynamic>> createOrder({
    required String name, 
    required String phone, 
    required String pickupTime, 
    required String pickupDate, 
    required List<Map<String, dynamic>> items, 
    required int total, 
    String notes = ''
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/orders'), 
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'pickupTime': pickupTime,
        'pickupDate': pickupDate,
        'items': items,
        'total': total,
        'notes': notes
      })
    );
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400) throw Exception(body['error'] ?? 'Pesanan gagal');
    return body;
  }
}