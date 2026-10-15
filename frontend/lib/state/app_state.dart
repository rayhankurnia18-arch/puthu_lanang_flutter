import 'dart:convert';

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
  int? userId; // ID akun di tabel `users` (kunci relasi pesanan)

  List<MenuItem> menu = const [];
  final List<CartItem> cart = [];
  Map<String, dynamic>? ticket;

  // Riwayat transaksi (terbaru di urutan pertama)
  List<Map<String, dynamic>> orderHistory = [];

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
    userId = prefs.getInt('user_id');

    // Sesi lama (sebelum riwayat diikat ke user_id) tidak punya user_id:
    // paksa masuk ulang agar pesanan terikat ke akun yang benar.
    if (token != null && userId == null) {
      await logout();
      return;
    }

    _loadHistory(prefs);

    notifyListeners();
  }

  // =========================
  // REGISTER
  // =========================

  Future<void> register(
    String name,
    String p,
    String pass, {
    required int userId,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = p.trim();
    final cleanPassword = pass.trim();

    if (cleanName.isEmpty || cleanPhone.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Lengkapi semua data terlebih dahulu.');
    }

    if (cleanPassword.length < 6) {
      throw Exception('Password minimal 6 karakter.');
    }

    // Register ke MySQL melalui backend (sudah dilakukan di verify-otp)
    // Langsung simpan sesi login ke SharedPreferences
    await _saveSession(
      userId: userId,
      name: cleanName,
      phone: cleanPhone,
      token: 'server-token-$cleanPhone',
    );
  }

  // =========================
  // LOGIN
  // =========================

  Future<void> login(
    String p,
    String pass,
  ) async {
    final cleanPhone = p.trim();
    final cleanPassword = pass.trim();

    if (cleanPhone.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Nomor WhatsApp dan password wajib diisi.');
    }

    // Login ke MySQL melalui backend
    final result = await ApiService.login(cleanPhone, cleanPassword);
    final data = result['data'] as Map<String, dynamic>;
    final id = int.tryParse('${data['id']}');
    if (id == null) throw Exception('Data akun dari server tidak valid.');

    await _saveSession(
      userId: id,
      name: data['nama'] as String? ?? 'Pecinta Kuliner',
      phone: cleanPhone,
      token: data['token'] as String? ?? 'server-token-$cleanPhone',
    );
  }

  // Helper: simpan sesi ke SharedPreferences & update state
  Future<void> _saveSession({
    required int userId,
    required String name,
    required String phone,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    this.userId = userId;
    this.token = token;
    userName = name;
    this.phone = phone;

    await prefs.setInt('user_id', userId);
    await prefs.setString('token', token);
    await prefs.setString('name', name);
    await prefs.setString('phone', phone);
    await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
    _loadHistory(prefs);

    notifyListeners();
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_id');
    await prefs.remove('token');
    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('login_timestamp');

    userId = null;
    token = null;
    userName = '';
    phone = '';
    orderHistory = [];

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
  // RIWAYAT TRANSAKSI
  // =========================

  // Cache lokal riwayat dipisah per user_id (bukan nomor telepon) sehingga
  // akun baru dengan nomor yang sama tidak mewarisi riwayat akun lama.
  String get _historyKey => 'order_history_u${userId ?? 0}';

  void _loadHistory(SharedPreferences prefs) {
    try {
      final raw = userId == null ? null : prefs.getString(_historyKey);
      orderHistory = raw == null
          ? []
          : (jsonDecode(raw) as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    } catch (_) {
      orderHistory = [];
    }
  }

  // Catat pesanan yang selesai ke daftar Riwayat Transaksi
  Future<void> recordOrderHistory({
    required String summaryItems,
    required int total,
    required String pickupDate,
    required String pickupTime,
    String notes = '',
    String? orderId,
  }) async {
    orderHistory.insert(0, {
      'id': orderId ?? 'PL-${DateTime.now().millisecondsSinceEpoch}',
      'created_at': DateTime.now().toIso8601String(),
      'summary_items': summaryItems,
      'total': total,
      'status': 'Sedang Dikukus',
      'outlet': 'Gerai Pusat Celaket',
      'pickup_date': pickupDate,
      'pickup_time': pickupTime,
      'notes': notes,
    });

    await _saveHistoryCache();
  }

  // Ambil riwayat pesanan dari database berdasarkan user_id lalu perbarui cache.
  // Melempar exception bila backend tidak terjangkau (UI memakai cache lama).
  // Bila server menolak sesi (akun sudah dihapus), otomatis logout.
  Future<void> loadOrderHistory() async {
    final id = userId;
    final tk = token;
    if (id == null || tk == null) return;

    try {
      orderHistory = await ApiService.getOrders(userId: id, token: tk);
    } on SessionExpiredException {
      await logout();
      rethrow;
    }
    await _saveHistoryCache();
    notifyListeners();
  }

  // Konfirmasi pesanan selesai: ubah status di database menjadi 'Selesai'.
  Future<void> completeOrder() async {
    final id = userId;
    final tk = token;
    final orderId = ticket?['id']?.toString();
    if (id == null || tk == null || orderId == null) {
      throw Exception('Tidak ada pesanan aktif untuk diselesaikan.');
    }

    try {
      await ApiService.completeOrder(orderId: orderId, userId: id, token: tk);
    } on SessionExpiredException {
      await logout();
      rethrow;
    }

    final index = orderHistory.indexWhere((o) => o['id']?.toString() == orderId);
    if (index >= 0) orderHistory[index]['status'] = 'Selesai';
    await _saveHistoryCache();

    ticket = null; // tiket sudah selesai, tidak lagi aktif
    notifyListeners();
  }

  Future<void> _saveHistoryCache() async {
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(orderHistory));
    } catch (_) {
      // Riwayat tetap tersedia di memori meskipun penyimpanan lokal gagal
    }
  }

  // =========================
  // ORDER
  // =========================

  Future<void> submitOrder({
    required String pickupTime,
    required String pickupDate,
    String notes = '',
    int discount = 0,
  }) async {
    final id = userId;
    final tk = token;
    if (id == null || tk == null) {
      throw Exception('Silakan masuk terlebih dahulu.');
    }

    final payTotal = (totalPrice - discount).clamp(0, totalPrice).toInt();
    final summaryItems = cart.map((e) => '${e.quantity}x ${e.item.name}').join(', ');
    final Map<String, dynamic> result;
    try {
      result = await ApiService.createOrder(
        userId: id,
        token: tk,
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
        total: payTotal,
        notes: notes,
      );
    } on SessionExpiredException {
      await logout();
      rethrow;
    }

    final data = (result['data'] as Map<String, dynamic>?) ?? {};
    ticket = {
      ...data,
      'notes': (data['notes'] != null && data['notes'].toString().isNotEmpty)
          ? data['notes']
          : notes,
      'pickup_time': data['pickup_time'] ?? pickupTime,
      'pickup_date': data['pickup_date'] ?? pickupDate,
      'summary_items': data['summary_items'] ?? (summaryItems.isNotEmpty ? summaryItems : '1x Puthu / Paket Pilihan'),
    };

    // Simpan otomatis ke Riwayat Transaksi (sebelum keranjang dikosongkan)
    await recordOrderHistory(
      summaryItems: ticket!['summary_items'].toString(),
      total: payTotal,
      pickupDate: ticket!['pickup_date'].toString(),
      pickupTime: ticket!['pickup_time'].toString(),
      notes: ticket!['notes']?.toString() ?? '',
      orderId: (data['id'] ?? data['qr_code_token'])?.toString(),
    );

    cart.clear();
    tab = 3;

    notifyListeners();
  }
}