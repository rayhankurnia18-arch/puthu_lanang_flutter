import 'package:flutter/material.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class TakeawayPage extends StatefulWidget {
  final AppState state;
  const TakeawayPage({super.key, required this.state});

  @override
  State<TakeawayPage> createState() => _TakeawayPageState();
}

class _TakeawayPageState extends State<TakeawayPage> {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static const List<String> _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  String selectedOutlet = 'Gerai Pusat Celaket';
  late List<Map<String, String>> dateOptions;
  late String selectedDate;
  late String selectedIsoDate;
  String selectedTime = '16:30 - 17:00';
  
  final notesController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool busy = false;

  Map<String, dynamic>? queueEstimate;
  bool loadingQueue = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.state.userName;
    phoneController.text = widget.state.phone;

    final now = DateTime.now();
    dateOptions = List.generate(3, (index) {
      final date = now.add(Duration(days: index));
      final dayStr = date.day.toString().padLeft(2, '0');
      final monthStr = _months[date.month - 1];

      String title;
      if (index == 0) {
        title = 'Hari Ini';
      } else if (index == 1) {
        title = 'Besok';
      } else {
        title = _days[date.weekday - 1];
      }

      final label = '$title\n$dayStr $monthStr';
      final iso = '${date.year}-${date.month.toString().padLeft(2, '0')}-$dayStr';

      return {
        'label': label,
        'iso': iso,
      };
    });

    selectedDate = dateOptions.first['label']!;
    selectedIsoDate = dateOptions.first['iso']!;
    fetchQueueEstimate();
  }

  Future<void> fetchQueueEstimate() async {
    setState(() => loadingQueue = true);
    final res = await ApiService.getAiQueueEstimate(
      outlet: selectedOutlet,
      day: selectedDate,
      timeSlot: selectedTime,
    );
    if (mounted) {
      setState(() {
        queueEstimate = res;
        loadingQueue = false;
      });
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => busy = true);

    final customNotes = notesController.text.trim();
    final takerName = nameController.text.trim();
    final takerPhone = phoneController.text.trim();
    
    String formattedNotes = customNotes;
    if (takerName.isNotEmpty || takerPhone.isNotEmpty) {
      final taker = 'Pengambil: $takerName ($takerPhone)';
      formattedNotes = customNotes.isNotEmpty ? '$customNotes | $taker' : taker;
    }

    try {
      await widget.state.submitOrder(
        pickupTime: selectedTime,
        pickupDate: selectedIsoDate,
        notes: formattedNotes,
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
            onTap: () {
              setState(() => selectedOutlet = 'Gerai Pusat Celaket');
              fetchQueueEstimate();
            },
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
            onTap: () {
              setState(() => selectedOutlet = 'Cabang Dinoyo');
              fetchQueueEstimate();
            },
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
              for (int i = 0; i < dateOptions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _buildDateCard(dateOptions[i]['label']!, dateOptions[i]['iso']!),
              ],
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
              onTap: () {
                setState(() => selectedTime = timeSlot);
                fetchQueueEstimate();
              },
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

          // --- WIDGET AI SMART QUEUE ESTIMATOR ---
          _buildAiQueueCard(),

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

  Widget _buildDateCard(String label, String iso) {
    bool isSelected = selectedDate == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedDate = label;
            selectedIsoDate = iso;
          });
          fetchQueueEstimate();
        },
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

  Widget _buildAiQueueCard() {
    if (queueEstimate == null && !loadingQueue) return const SizedBox.shrink();

    final crowdLevel = queueEstimate?['crowd_level'] ?? 'Ramai Lancar';
    final estWait = queueEstimate?['estimated_wait'] ?? '~8 - 12 Mnt';
    final crowdColorStr = queueEstimate?['crowd_color'] ?? 'gold';
    final tips = queueEstimate?['tips'] ?? 'Pesanan Anda disiapkan hangat dan segar saat jam pengambilan.';
    final peakPercent = (queueEstimate?['peak_percentage'] as num?)?.toDouble() ?? 60.0;
    final confidence = queueEstimate?['confidence_score'] ?? '96% Akurasi Prediksi AI';

    Color statusColor = gold;
    if (crowdColorStr == 'green') statusColor = const Color(0xFF4CAF50);
    if (crowdColorStr == 'orange') statusColor = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brown2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome, color: statusColor, size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Smart Queue Estimator',
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
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  confidence,
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Waktu Tunggu:', style: TextStyle(color: muted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: gold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        estWait,
                        style: const TextStyle(
                          color: cream,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      crowdLevel,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tingkat Kepadatan Gerai', style: TextStyle(color: muted, fontSize: 10)),
                  Text('${peakPercent.toInt()}%', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: peakPercent / 100,
                  backgroundColor: brown,
                  color: statusColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brown,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: gold, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tips,
                    style: const TextStyle(color: muted, fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}