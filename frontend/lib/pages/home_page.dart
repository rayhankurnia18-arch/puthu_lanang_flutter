import 'package:flutter/material.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../widgets/app_card.dart';

class HomePage extends StatefulWidget {
  final AppState state;

  const HomePage({super.key, required this.state});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final popular = widget.state.menu.take(4).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Kartu Profil & Indikator Antrean
        AppCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.state.userName.isEmpty ? 'P' : widget.state.userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Puthu Lanang',
                      style: TextStyle(
                        color: cream,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Mobile Smart Takeaway App',
                      style: TextStyle(
                        color: muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gerai Celaket: Antrean ~12 Mnt',
                      style: TextStyle(
                        color: green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: brown,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: muted,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Banner Utama Cita Rasa Pusaka
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [brown2, green.withValues(alpha: .28), brown2],
            ),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Chip(
                label: Text('EST. 1935 MALANG'),
                backgroundColor: gold,
                labelStyle: TextStyle(
                  color: brown,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cita Rasa Pusaka\nSejak 1935',
                style: TextStyle(
                  color: cream,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dikukus dadakan dalam tabung bambu swang murni dengan harum pandan suji dan gula aren melaka.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Tombol Pesan Takeaway -> Berpindah ke Tab Menu (Index 1)
                  ElevatedButton(
                    onPressed: () {
                      widget.state.setTab(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Pesan Takeaway'),
                        SizedBox(width: 6),
                        Text('→', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Tombol Baca Cerita -> Berpindah ke Tab Cerita (Index 2)
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.state.setTab(2);
                    },
                    icon: const Icon(Icons.menu_book, size: 16),
                    label: const Text('Baca Cerita'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cream,
                      side: const BorderSide(color: border),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Kartu Lokasi Gerai (Aman dari Overflow)
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Gerai Asli Celaket',
                      style: TextStyle(
                        color: cream,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Jl. Jaksa Agung Suprapto No. 73',
                      style: TextStyle(color: muted, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '17:30 - 21:30',
                style: TextStyle(
                  color: green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Judul Bagian Menu Populer & Tombol Lihat Semua
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '✨ Pilihan Menu Populer',
              style: TextStyle(
                color: cream,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            
            // Tombol Lihat Semua -> Berpindah ke Tab Menu (Index 1)
            GestureDetector(
              onTap: () {
                widget.state.setTab(1);
              },
              child: const Text(
                'Lihat Semua →',
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid Menu Populer dengan Rating & Tombol Tambah
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: popular.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (c, i) {
            final m = popular[i];
            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Image.asset(
                          m.image,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 100,
                            color: border,
                            child: const Center(
                              child: Icon(Icons.image_not_supported, color: muted),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: gold, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                '${m.rating}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            color: cream,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rupiah(m.price),
                          style: const TextStyle(
                            color: gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                widget.state.add(m);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '+ Tambah',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        ],
      ),
    );
  }
}