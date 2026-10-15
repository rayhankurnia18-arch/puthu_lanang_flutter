import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import 'orders_page.dart';

class TicketPage extends StatefulWidget {
  final AppState state;

  const TicketPage({super.key, required this.state});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  AppState get state => widget.state;
  bool _completing = false;

  // Konfirmasi -> PATCH status 'Selesai' di backend -> buka Riwayat Transaksi
  Future<void> _confirmComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: brown2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Pesanan Selesai',
          style: TextStyle(color: cream, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Pastikan pesanan sudah Anda terima dari kasir. Status pesanan akan diubah menjadi "Selesai".',
          style: TextStyle(color: muted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Selesai', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _completing = true);

    try {
      await state.completeOrder();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Pesanan ditandai selesai. Terima kasih!'), backgroundColor: green),
      );
      navigator.push(
        MaterialPageRoute(builder: (_) => OrdersPage(state: state)),
      );
    } on SessionExpiredException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = state.ticket;

    // KONDISI 1: Jika belum ada pesanan aktif (t == null)
    if (t == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: brown2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: gold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Ada Pesanan Aktif',
                style: TextStyle(
                  color: cream,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yuk, pesan menu Puthu Lanang favoritmu sekarang dan ambil tanpa mengantre!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // KONDISI 2: Jika sudah ada pesanan (t != null), tampilkan E-Tiket
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- HEADER ATAS ---
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('PL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Puthu Lanang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Mobile Smart Takeaway App', style: TextStyle(color: muted, fontSize: 9)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // --- KARTU UTAMA E-TIKET ---
        Container(
          decoration: BoxDecoration(
            color: brown2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              // --- STATUS BERHASIL ---
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: green.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_outline, color: green, size: 16),
                          SizedBox(width: 6),
                          Text('Pesanan Smart Takeaway Berhasil', style: TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'E-Tiket Pengambilan',
                      style: TextStyle(color: cream, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tunjukkan QR Code ini kepada kasir gerai Puthu Lanang',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // --- KOTAK HIJAU NOMOR ANTREAN & QR ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3822),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: green.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PUTHU LANANG MALANG • EST 1935',
                      style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['antrean'] != null ? 'ANTREAN-${t['antrean']}' : 'ANTREAN-79',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.local_fire_department, color: brown, size: 14),
                          SizedBox(width: 4),
                          Text('SEDANG DIKUKUS ♨', style: TextStyle(color: brown, fontSize: 10, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // QR Code Wrapper Putih
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: QrImageView(
                        data: t['qr_code_token']?.toString() ?? t['id']?.toString() ?? 'PL-2026-X99201',
                        size: 160,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TOKEN: ${t['qr_code_token']?.toString() ?? t['id']?.toString() ?? 'PL-2026-X99201'}',
                      style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- LOKASI GERAI ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, color: gold, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Pusat Celaket', style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 2),
                              Text('Jl. Jaksa Agung Suprapto No. 73, Samaan, Klojen, Malang', style: TextStyle(color: muted, fontSize: 10, height: 1.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: border),
                    const SizedBox(height: 12),

                    // --- SLOT PENGAMBILAN ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_outlined, color: green, size: 18),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Slot Pengambilan', style: TextStyle(color: muted, fontSize: 9)),
                                const SizedBox(height: 2),
                                Text(
                                  '${t['pickup_date'] ?? 'Hari Ini'} • ${t['pickup_time'] ?? '16:30 - 17:00'}',
                                  style: const TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: green.withValues(alpha: 0.5)),
                          ),
                          child: const Text('Prioritas Express', style: TextStyle(color: green, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: border),
                    const SizedBox(height: 12),

                    // --- RINCIAN MENU DIPESAN ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text('RINCIAN MENU DIPESAN:', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t['summary_items']?.toString() ?? '1x Puthu / Paket Pilihan', style: const TextStyle(color: cream, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(t['total_harga'] != null ? rupiah(int.tryParse('${t['total_harga']}') ?? 20000) : 'Rp 20.000', style: const TextStyle(color: cream, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: brown,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        'Catatan: ${t['notes']?.toString().isNotEmpty == true ? t['notes'] : 'Tanpa catatan'}',
                        style: const TextStyle(color: muted, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: border),
                    const SizedBox(height: 8),

                    // --- TOTAL PEMBAYARAN ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran:', style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          t['total_harga'] != null ? rupiah(int.tryParse('${t['total_harga']}') ?? 20000) : 'Rp 20.000',
                          style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- TOMBOL KONFIRMASI PESANAN SELESAI ---
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _completing ? null : _confirmComplete,
            icon: _completing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _completing ? 'Memproses...' : 'Selesaikan Pesanan',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: green.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tekan setelah pesanan Anda diterima dari kasir.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 10),
        ),

        const SizedBox(height: 16),

        // --- WIDGET AI SMART EXPIRY & FRESHNESS PREDICTOR ---
        _buildAiFreshnessCard(t),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAiFreshnessCard(Map<String, dynamic> t) {
    final bestBefore = _calculateBestBefore(t);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brown2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: green.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco_outlined, color: green, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Freshness & Quality Predictor',
                  style: TextStyle(
                    color: cream,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: green.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  '0% Pengawet Kimia',
                  style: TextStyle(color: green, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Banner Golden Hour
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brown,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waktu Santap Optimal (Golden Window):',
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sebelum $bestBefore (±4 Jam)',
                        style: const TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '100% Segar',
                    style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Peringatan Bahan Segar
          const Text(
            'CATATAN KESEGARAN BAHAN ALAMI:',
            style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Puthu Lanang menggunakan kelapa parut segar kukus & gula aren asli tanpa zat pengawet. Kualitas terbaik dinikmati selagi hangat.',
            style: TextStyle(color: muted, fontSize: 11, height: 1.4),
          ),

          const SizedBox(height: 12),
          const Divider(color: border),
          const SizedBox(height: 8),

          // Tips Penyimpanan AI
          const Text(
            'TIPS PENYIMPANAN CERDAS BERBASIS AI:',
            style: TextStyle(color: cream, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),

          _buildTipRow(
            Icons.restaurant,
            'Nikmati Hangat Segera',
            'Tekstur puthu dan letupan gula aren paling lembut dalam 4 jam setelah pengambilan.',
          ),
          const SizedBox(height: 6),
          _buildTipRow(
            Icons.kitchen,
            'Simpan di Kulkas (Chiller)',
            'Jika belum disantap, pisahkan juruh aren & kelapa, simpan tertutup rapat di kulkas tahan hingga 24 jam.',
          ),
          const SizedBox(height: 6),
          _buildTipRow(
            Icons.soup_kitchen,
            'Kukus Ulang 3 Menit',
            'Kukus kembali selama 2-3 menit sebelum disajikan agar kelapa dan adonan kembali pulen gurih.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: gold, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: cream, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 1),
              Text(desc, style: const TextStyle(color: muted, fontSize: 10, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateBestBefore(Map<String, dynamic> t) {
    try {
      final pickupTime = t['pickup_time']?.toString() ?? '17:00';
      final parts = pickupTime.split('-');
      final targetStr = (parts.length > 1 ? parts[1] : parts[0]).trim();
      final timeParts = targetStr.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        int expiryHour = (hour + 4) % 24;
        return '${expiryHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} WIB';
      }
    } catch (_) {}
    final now = DateTime.now().add(const Duration(hours: 4));
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
  }
}