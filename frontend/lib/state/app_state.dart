import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  int tab = 0;
  bool loading = false;
  String? error;

  String userName = '';
  String phone = '';
  String? token;

  List<MenuItem> menu = const [];
  final List<CartItem> cart = [];
  Map<String, dynamic>? ticket;

  bool get loggedIn => token != null;

  int get totalItems =>
      cart.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice =>
      cart.fold(0, (sum, item) => sum + item.subtotal);

  // =========================
  // TAB NAVIGATION
  // =========================

  void setTab(int index) {
    tab = index;
    notifyListeners();
  }

  // =========================
  // RESTORE SESSION & 30-DAY CHECK
  // =========================

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();

    final loginTimeMillis = prefs.getInt('login_timestamp') ?? 0;
    if (loginTimeMillis > 0) {
      final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimeMillis);
      final differenceDays = DateTime.now().difference(loginDate).inDays;

      // Jika durasi login sudah melebihi 30 hari, lakukan logout otomatis
      if (differenceDays > 30) {
        await logout();
        return;
      }
    }

    token = prefs.getString('token');
    userName = prefs.getString('name') ?? '';
    phone = prefs.getString('phone') ?? '';

    notifyListeners();
  }

  // =========================
  // REGISTER
  // =========================

  Future<void> register(
    String name,
    String p,
    String pass,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final cleanName = name.trim();
    final cleanPhone = p.trim();
    final cleanPassword = pass.trim();

    if (cleanName.isEmpty ||
        cleanPhone.isEmpty ||
        cleanPassword.isEmpty) {
      throw Exception('Lengkapi semua data terlebih dahulu.');
    }

    if (cleanPassword.length < 6) {
      throw Exception('Password minimal 6 karakter.');
    }

    final existingPhone = prefs.getString('account_phone');

    if (existingPhone == cleanPhone) {
      throw Exception(
        'Nomor WhatsApp sudah terdaftar. Silakan masuk.',
      );
    }

    await prefs.setString('account_name', cleanName);
    await prefs.setString('account_phone', cleanPhone);
    await prefs.setString('account_password', cleanPassword);

    await login(cleanPhone, cleanPassword);
  }

  // =========================
  // LOGIN
  // =========================

  Future<void> login(
    String p,
    String pass,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final cleanPhone = p.trim();
    final cleanPassword = pass.trim();

    if (cleanPhone.isEmpty || cleanPassword.isEmpty) {
      throw Exception(
        'Nomor WhatsApp dan password wajib diisi.',
      );
    }

    final savedPhone = prefs.getString('account_phone');
    final savedPassword = prefs.getString('account_password');
    final savedName = prefs.getString('account_name');

    if (savedPhone == null || savedPassword == null) {
      throw Exception(
        'Akun belum terdaftar. Silakan daftar terlebih dahulu.',
      );
    }

    if (cleanPhone != savedPhone) {
      throw Exception('Nomor WhatsApp tidak ditemukan.');
    }

    if (cleanPassword != savedPassword) {
      throw Exception('Password salah.');
    }

    userName = savedName ?? 'Pecinta Kuliner';
    phone = savedPhone;

    token = 'local-token-$savedPhone';

    // Simpan data sesi beserta timestamp login untuk durasi 30 hari
    await prefs.setString('token', token!);
    await prefs.setString('name', userName);
    await prefs.setString('phone', phone);
    await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);

    notifyListeners();
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('login_timestamp');

    token = null;
    userName = '';
    phone = '';

    cart.clear();
    ticket = null;
    tab = 0;

    notifyListeners();
  }

  // =========================
  // LOAD MENU
  // =========================

  Future<void> loadMenu() async {
    loading = true;
    error = null;

    notifyListeners();

    try {
      menu = await ApiService.getMenu();
    } catch (_) {
      menu = const [
        MenuItem(
          id: 'puthu-01',
          name: 'Puthu',
          category: 'pusaka',
          description:
              'Puthu beras pandan suji dengan gula aren cair dan kelapa gurih.',
          image: 'assets/images/puthu_bambu.png',
          price: 18000,
          stock: 120,
          rating: 4.9,
        ),
        MenuItem(
          id: 'klepon-02',
          name: 'Klepon',
          category: 'paling_laris',
          description:
              'Ketan hijau kenyal dengan isian gula aren cair.',
          image: 'assets/images/klepon_pandan.png',
          price: 18000,
          stock: 95,
          rating: 4.9,
        ),
        MenuItem(
          id: 'cenil-03',
          name: 'Cenil',
          category: 'pusaka',
          description:
              'Cenil warna-warni dengan juruh gula aren dan kelapa.',
          image: 'assets/images/cenil_pelangi.png',
          price: 18000,
          stock: 80,
          rating: 4.8,
        ),
        MenuItem(
          id: 'lupis-04',
          name: 'Lupis',
          category: 'pusaka',
          description:
              'Ketan legit dengan kelapa parut dan juruh aren.',
          image: 'assets/images/lupis_ketan.png',
          price: 18000,
          stock: 65,
          rating: 4.9,
        ),
        MenuItem(
          id: 'paket-campur-05',
          name: 'Paket Campur',
          category: 'paket_campur',
          description:
              'Puthu, klepon, cenil dan lupis dalam satu paket.',
          image: 'assets/images/paket_tampah.png',
          price: 20000,
          stock: 150,
          rating: 5.0,
        ),
        MenuItem(
          id: 'besek-hampers-06',
          name: 'Box Besek Bambu Hampers',
          category: 'besek',
          description:
              'Hampers tradisional dengan paket campur dan juruh aren.',
          image: 'assets/images/paket_tampah.png',
          price: 45000,
          stock: 40,
          rating: 5.0,
        ),
      ];
    }

    loading = false;

    notifyListeners();
  }

  // =========================
  // CART
  // =========================

  void add(MenuItem item) {
    final index = cart.indexWhere(
      (x) => x.item.id == item.id,
    );

    if (index >= 0) {
      cart[index].quantity++;
    } else {
      cart.add(
        CartItem(item: item),
      );
    }

    notifyListeners();
  }

  void remove(MenuItem item) {
    final index = cart.indexWhere(
      (x) => x.item.id == item.id,
    );

    if (index < 0) return;

    if (cart[index].quantity > 1) {
      cart[index].quantity--;
    } else {
      cart.removeAt(index);
    }

    notifyListeners();
  }

  // =========================
  // ORDER
  // =========================

  Future<void> submitOrder({
    required String pickupTime,
    required String pickupDate,
    String notes = '',
  }) async {
    final result = await ApiService.createOrder(
      name: userName,
      phone: phone,
      pickupTime: pickupTime,
      pickupDate: pickupDate,
      items: cart
          .map(
            (e) => {
              'menu_id': e.item.id,
              'nama': e.item.name,
              'quantity': e.quantity,
              'harga': e.item.price,
              'catatan': e.notes,
            },
          )
          .toList(),
      total: totalPrice,
      notes: notes,
    );

    ticket = result['data'] as Map<String, dynamic>?;

    cart.clear();
    tab = 3;

    notifyListeners();
  }
}