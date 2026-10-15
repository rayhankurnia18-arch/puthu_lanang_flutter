import 'package:flutter/material.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../widgets/app_card.dart';

class StoryPage extends StatefulWidget {
  final AppState state;
  const StoryPage({super.key, required this.state});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  // 1. Tambahkan ScrollController
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController, // 2. Pasang controller ke ListView
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

        // --- SUB-HEADER ARSIP ---
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: brown2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: const Text('📜 ARSIP PUSAKA • SEJAK 1935', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 12),

        // --- JUDUL UTAMA CERITA ---
        const Text(
          'Menjaga Keharuman\nMalam Malang\nSelama Tiga Generasi',
          textAlign: TextAlign.center,
          style: TextStyle(color: cream, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2),
        ),

        const SizedBox(height: 12),

        const Text(
          'Dari sebuah gerobak sederhana di sudut Jalan Jaksa Agung Suprapto hingga menjadi warisan kuliner legendaris yang menghangatkan malam kota Malang.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12, height: 1.4),
        ),

        const SizedBox(height: 20),

        // --- 4 KOTAK STATISTIK ---
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildStatBox('1935', 'TAHUN BERDIRI'),
            _buildStatBox('3 Gen', 'PENGASUH RESEP'),
            _buildStatBox('100%', 'BAMBU ALAMI'),
            _buildStatBox('Celaket', 'KAWASAN LEGENDARIS'),
          ],
        ),

        const SizedBox(height: 20),

        // --- KARTU ARSIP FOTO GEROBAK ---
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('BATAS WAKTU & PERTAHANAN', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: brown, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Arsip Foto', style: TextStyle(color: muted, fontSize: 9)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Menyalakan Api Kecil di Tengah\nDinginnya Malam Malang', style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/api_kecil_malam_malang.png',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    width: double.infinity,
                    color: border,
                    child: const Center(child: Icon(Icons.image, color: muted, size: 40)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // --- ESTAFET RASA SELAMA 9 DEKADE ---
        const Text('ESTAFET RASA SELAMA 9 DEKADE', style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        const Text('Estafet Rasa Selama 9 Dekade', style: TextStyle(color: cream, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),

        // Timeline Item 1
        _buildTimelineItem(
          badgeText: '1935 - 1960',
          badgeLabel: 'Perintis',
          title: 'Generasi Pendiri',
          desc: 'Dimulai dari gerobak sederhana dengan berkeliling menjajakan puthu di sekitar Jalan Jaksa Agung Suprapto, memperkenalkan kelezatan kue puthu hangat kepada warga lokal.',
          color: green,
        ),
        const SizedBox(height: 12),

        // Timeline Item 2
        _buildTimelineItem(
          badgeText: '1960 - 1995',
          badgeLabel: 'Ekspansi Lokal',
          title: 'Generasi Pengepul & Menetap',
          desc: 'Mulai menetap di satu lokasi tetap di kawasan Celaket. Mempertahankan kualitas bahan baku di tengah derasnya zaman dan menjadi ikon kuliner malam Malang.',
          color: gold,
        ),
        const SizedBox(height: 12),

        // Timeline Item 3
        _buildTimelineItem(
          badgeText: '1995 - SEKARANG',
          badgeLabel: 'Modernisasi',
          title: 'Generasi Modernisasi',
          desc: 'Menggabungkan tradisi pengukusan bambu murni dengan sistem pelayanan digital (smart takeaway), serta pengemasan besek elegan tanpa menghilangkan rasa asli. Dikukus oleh keluarga Puthu Lanang.',
          color: green,
        ),

        const SizedBox(height: 20),

        // --- JEJAK VISUAL LINTAS ZAMAN ---
        const Text('JEJAK VISUAL LINTAS ZAMAN', style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        const Text('Jejak Visual Lintas Zaman', style: TextStyle(color: cream, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: brown, borderRadius: BorderRadius.circular(4)),
                child: const Text('Arsip 1935', style: TextStyle(color: muted, fontSize: 9)),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/gerobak_pertama_celaket.png',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    width: double.infinity,
                    color: border,
                    child: const Center(child: Icon(Icons.image, color: muted, size: 30)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Gerobak Pertama di Celaket', style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Tonggak berdirinya warung tetap sederhana yang mengawali tradisi Puthu Lanang di sudut Jalan Raya Celaket.', style: TextStyle(color: muted, fontSize: 11)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: brown, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Teknik Pusaka', style: TextStyle(color: green, fontSize: 9)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Pengukusan Bambu Alami', style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('Menggunakan bilah bambu pilihan untuk puthu.', style: TextStyle(color: muted, fontSize: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: brown, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Warisan Warga', style: TextStyle(color: gold, fontSize: 9)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Dedikasi Keluarga Turun-Temurun', style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('Dikukus dadakan, menjaga cita rasa.', style: TextStyle(color: muted, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // --- KUTIPAN KHUSUS ---
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: green.withValues(alpha: 0.5)),
          ),
          child: const Text(
            '🌿 "Rasa puthu yang enak itu dunianya nyaring, saat uap bambu menutup, aromanya memanggil dan kesadaran dan nostalgi airnya tidak pernah merusak di tenggorokan. Rasa itulah yang terus sejak sembilan dekade lalu."',
            style: TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
          ),
        ),

        const SizedBox(height: 20),

        // --- 100% BAHAN ALAMI & JAM OPERASIONAL ---
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_outlined, color: green, size: 18),
                  SizedBox(width: 8),
                  Text('100% Bahan Alami', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Diproses segar setiap hari tanpa pengawet atau pemanis buatan. Menggunakan gula aren organik pilihan dan kelapa parut murni.', style: TextStyle(color: muted, fontSize: 11, height: 1.4)),
              const SizedBox(height: 12),
              const Divider(color: border),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.access_time, color: gold, size: 14),
                  SizedBox(width: 6),
                  Text('Jam Operasional: 17:30 - 21:30 WIB', style: TextStyle(color: cream, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.location_on, color: gold, size: 14),
                  SizedBox(width: 6),
                  Text('Jl. Jaksa Agung Suprapto No. 73, Samaan, Klojen, Malang', style: TextStyle(color: muted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- TOMBOL NAVIGASI BAWAH ---
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // 3. Fungsionalitas tombol kembali ke atas
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('⬆️ Kembali ke Atas', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.state.setTab(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('🛒 Lihat Menu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: brown2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required String badgeText, required String badgeLabel, required String title, required String desc, required Color color}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(badgeText, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: brown, borderRadius: BorderRadius.circular(4)),
                child: Text(badgeLabel, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: cream, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: muted, fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }
}