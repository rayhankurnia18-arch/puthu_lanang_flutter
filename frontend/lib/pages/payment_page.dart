import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class PaymentPage extends StatefulWidget {
  final AppState state;
  final List<Map<String, dynamic>> cartItems;
  final int totalPrice;
  final String notes;

  const PaymentPage({
    super.key,
    required this.state,
    required this.cartItems,
    required this.totalPrice,
    required this.notes,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = 'QRIS';
  bool isProcessing = false;

  final List<Map<String, String>> paymentMethods = [
    {'id': 'QRIS', 'name': 'QRIS (GoPay, OVO, Dana, ShopeePay)', 'icon': 'qr_code_2'},
    {'id': 'BCA', 'name': 'Virtual Account BCA', 'icon': 'account_balance'},
    {'id': 'MANDIRI', 'name': 'Virtual Account Mandiri', 'icon': 'account_balance'},
    {'id': 'GOPAY', 'name': 'GoPay / GoPay Later', 'icon': 'account_balance_wallet'},
  ];

  Future<void> processPayment() async {
    setState(() {
      isProcessing = true;
    });

    try {
      // 1. Panggil backend untuk mendapatkan Snap Token & Redirect URL dari Midtrans
      final paymentResponse = await http.post(
        Uri.parse('http://localhost:3000/api/payment/create-charge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gross_amount': widget.totalPrice,
          'customer_name': widget.state.userName.isEmpty ? 'Pelanggan' : widget.state.userName,
          'customer_phone': widget.state.phone.isEmpty ? '088212383828' : widget.state.phone,
        }),
      );

      final paymentData = jsonDecode(paymentResponse.body);

      if (paymentResponse.statusCode != 200 || paymentData['redirect_url'] == null) {
        throw Exception(paymentData['message'] ?? 'Gagal membuat sesi pembayaran Midtrans.');
      }

      final String redirectUrl = paymentData['redirect_url'];

      // 2. Buka URL Snap Midtrans (yang memuat popup metode pembayaran lengkap seperti gambar)
      final Uri uri = Uri.parse(redirectUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Tidak dapat membuka jendela pembayaran Midtrans.');
      }

      // 3. Setelah simulasi pembayaran sukses, buat pesanan & e-tiket di database
      final userId = widget.state.userId;
      final token = widget.state.token;
      if (userId == null || token == null) {
        throw Exception('Silakan masuk terlebih dahulu.');
      }
      final now = DateTime.now();
      final todayIso =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final response = await ApiService.createOrder(
        userId: userId,
        token: token,
        pickupTime: '16:30 - 17:00',
        pickupDate: todayIso,
        items: widget.cartItems,
        total: widget.totalPrice,
        notes: '${widget.notes} [Midtrans Snap: $selectedMethod]',
      );

      widget.state.ticket = response['data'];
      await widget.state.recordOrderHistory(
        summaryItems: widget.cartItems
            .map((e) => '${e['quantity']}x ${e['nama']}')
            .join(', '),
        total: widget.totalPrice,
        pickupDate: 'Hari Ini',
        pickupTime: '16:30 - 17:00',
        notes: widget.notes,
        orderId: (response['data']?['id'] ?? response['data']?['qr_code_token'])?.toString(),
      );
      widget.state.cart.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran Sukses! E-Tiket diterbitkan.'),
          backgroundColor: green,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses pembayaran: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brown,
      appBar: AppBar(
        backgroundColor: brown2,
        title: const Text('Pembayaran Midtrans Snap', style: TextStyle(color: cream, fontSize: 16, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ringkasan Pembayaran
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brown2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL TAGIHAN MIDTRANS', style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        rupiah(widget.totalPrice),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: border),
                      const SizedBox(height: 8),
                      Text('${widget.cartItems.length} Item Puthu Lanang', style: const TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text('PILIH METODE PEMBAYARAN', style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 12),

                // Daftar Metode Pembayaran
                ...paymentMethods.map((method) {
                  bool isSelected = selectedMethod == method['id'];
                  return GestureDetector(
                    onTap: isProcessing ? null : () => setState(() => selectedMethod = method['id']!),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: brown2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? gold : border, width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? gold : muted,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              method['name']!,
                              style: TextStyle(
                                color: isSelected ? cream : muted,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 30),

                // Tombol Bayar Sekarang
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isProcessing ? 'Menyiapkan Midtrans Snap...' : 'Bayar Sekarang (${rupiah(widget.totalPrice)})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}