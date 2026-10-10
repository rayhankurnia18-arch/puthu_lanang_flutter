import 'package:flutter/material.dart';
import '../main.dart';
import '../state/app_state.dart';

class TakeawayPage extends StatefulWidget {
  final AppState state;
  const TakeawayPage({super.key, required this.state});

  @override
  State<TakeawayPage> createState() => _TakeawayPageState();
}

class _TakeawayPageState extends State<TakeawayPage> {
  // State lengkap sesuai desain Figma
  String selectedOutlet = 'Gerai Pusat Celaket';
  String selectedDate = 'Hari Ini\n30 Sep';
  String selectedTime = '16:30 - 17:00';
  
  final notesController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool busy = false;

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      await widget.state.submitOrder(
        pickupTime: selectedTime,
        pickupDate: DateTime.now().toIso8601String().split('T').first,
        notes: '${notesController.text} | Pengambil: ${nameController.text} (${phoneController.text})',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brown,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Form Smart Takeaway', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Atur gerai & slot waktu pengambilan pesanan', style: TextStyle(fontSize: 12, color: muted)),
          ],
        ),
        backgroundColor: brown,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- 1. PILIHAN GERAI OUTLET ---
          const Text('📍 Pilihan Gerai Outlet', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          
          // Gerai Pusat Celaket
          GestureDetector(
            onTap: () => setState(() => selectedOutlet = 'Gerai Pusat Celaket'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brown2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selectedOutlet == 'Gerai Pusat Celaket' ? green : border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(selectedOutlet == 'Gerai Pusat Celaket' ? Icons.radio_button_checked : Icons.radio_button_off, color: selectedOutlet == 'Gerai Pusat Celaket' ? green : Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      const Text('Gerai Pusat Celaket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text('Celaket Online', style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 26, top: 4, bottom: 8),
                    child: Text('Jl. Jaksa Agung Suprapto No. 73, Samaan, Klojen, Malang', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 26),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF1E3A1E), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Buka • Ramai Lancar', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Estimasi Antrean: ~12 Mnt', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Cabang Dinoyo
          GestureDetector(
            onTap: () => setState(() => selectedOutlet = 'Cabang Dinoyo'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brown2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selectedOutlet == 'Cabang Dinoyo' ? green : border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(selectedOutlet == 'Cabang Dinoyo' ? Icons.radio_button_checked : Icons.radio_button_off, color: selectedOutlet == 'Cabang Dinoyo' ? green : Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      const Text('Cabang Dinoyo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 26, top: 4, bottom: 8),
                    child: Text('Jl. MT Haryono No. 195, Lowokwaru, Kota Malang', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 26),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF1E3A1E), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Buka • Antrean Pendek', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Estimasi Antrean: ~5 Mnt', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- 2. TANGGAL PENGAMBILAN ---
          const Text('📅 Tanggal Pengambilan', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDateCard('Hari Ini\n30 Sep'),
              const SizedBox(width: 8),
              _buildDateCard('Besok\n01 Okt'),
              const SizedBox(width: 8),
              _buildDateCard('Kamis\n02 Okt'),
            ],
          ),

          const SizedBox(height: 20),

          // --- 3. SLOT WAKTU PENGAMBILAN ---
          const Text('⏰ Slot Waktu Pengambilan', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              '16:00 - 16:30',
              '16:30 - 17:00',
              '17:00 - 17:30',
              '17:30 - 18:00',
              '18:00 - 18:30',
              '18:30 - 19:00',
            ].map((timeSlot) => GestureDetector(
              onTap: () => setState(() => selectedTime = timeSlot),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedTime == timeSlot ? green : brown2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selectedTime == timeSlot ? green : border),
                ),
                child: Text(
                  timeSlot,
                  style: TextStyle(
                    color: selectedTime == timeSlot ? Colors.white : Colors.grey[300],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            )).toList(),
          ),

          const SizedBox(height: 20),

          // --- 4. CATATAN KHUSUS PESANAN ---
          const Text('✏️ Catatan Khusus Pesanan', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          TextField(
            controller: notesController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Catatan tambahan untuk pesanan (opsional)',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: brown2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
            ),
          ),

          const SizedBox(height: 20),

          // --- 5. DATA PENGAMBIL PESANAN ---
          const Text('👤 Data Pengambil Pesanan', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Nama Pengambil',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: brown2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Nomor Telepon',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: brown2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
            ),
          ),

          const SizedBox(height: 24),

          // --- 6. TOTAL & TOMBOL BUAT TIKET ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran:', style: TextStyle(color: Colors.white, fontSize: 13)),
              Flexible(
                child: Text(
                  rupiah(widget.state.totalPrice),
                  style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: busy ? null : submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: Text(
                busy ? 'Memproses...' : 'Buat Tiket Smart Takeaway',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDateCard(String label) {
    bool isSelected = selectedDate == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedDate = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE69616) : brown2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFE69616) : border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}