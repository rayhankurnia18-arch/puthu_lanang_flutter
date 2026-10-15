import 'package:flutter/material.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../widgets/menu_card.dart';
import '../widgets/app_card.dart';
import 'takeaway_page.dart';
import 'auth_page.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class MenuPage extends StatefulWidget {
  final AppState state;

  const MenuPage({super.key, required this.state});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool isAiExpanded = false;
  bool loadingAi = false;
  final TextEditingController aiPromptController = TextEditingController();
  final GlobalKey<FormState> _aiFormKey = GlobalKey<FormState>();
  Map<String, dynamic>? aiRecommendation;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    aiPromptController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> requestRecommendation(
      {String? customPrompt, String? preference, int? budget}) async {
    setState(() => loadingAi = true);
    final res = await ApiService.getAiRecommendation(
      query: customPrompt ?? aiPromptController.text.trim(),
      preference: preference ?? '',
      budget: budget,
    );
    if (mounted) {
      setState(() {
        aiRecommendation = res;
        loadingAi = false;
        isAiExpanded = true;
      });
    }
  }

  void addRecommendedPackageToCart() {
    final items = aiRecommendation?['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return;

    int addedCount = 0;
    for (final it in items) {
      final String itemId = it['id']?.toString() ?? '';
      final String itemName =
          (it['nama'] ?? it['name'] ?? '').toString().toLowerCase();
      final int qty = int.tryParse('${it['qty']}') ?? 1;

      final match = widget.state.menu.cast<dynamic>().firstWhere(
            (m) =>
                m.id == itemId ||
                m.name.toString().toLowerCase().contains(itemName) ||
                itemName.contains(m.name.toString().toLowerCase()),
            orElse: () =>
                widget.state.menu.isNotEmpty ? widget.state.menu.first : null,
          );

      if (match != null) {
        for (int q = 0; q < qty; q++) {
          widget.state.add(match);
        }
        addedCount += qty;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✨ $addedCount porsi rekomendasi kami berhasil ditambahkan ke keranjang!'),
        backgroundColor: green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            const Text(
              'Menu Jajanan Tradisional',
              style: TextStyle(
                color: cream,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Resep asli 1935, dikukus dadakan dengan kelapa parut gurih.',
              style: TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(height: 14),

            // --- WIDGET INTERAKTIF AI PUTHU RECOMMENDER ---
            _buildAiRecommenderCard(),

            const SizedBox(height: 16),
            ...state.menu.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MenuCard(item: m, state: state),
              ),
            ),
          ],
        ),
        if (state.totalItems > 0)
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: AppCard(
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${state.totalItems} item • ${rupiah(state.totalPrice)}',
                      style: const TextStyle(
                        color: cream,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!state.loggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Silakan masuk atau daftar akun terlebih dahulu untuk melanjutkan pesanan.'),
                            backgroundColor: gold,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuthPage(
                              state: state,
                            ),
                          ),
                        );

                        if (!state.loggedIn || !context.mounted) return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TakeawayPage(
                            state: state,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Lanjut'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAiRecommenderCard() {
    return Container(
      decoration: BoxDecoration(
        color: brown2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => isAiExpanded = !isAiExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.auto_awesome, color: gold, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AI Puthu Recommender',
                          style: TextStyle(
                            color: cream,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bingung pilih? Biarkan kami racikkan paket terbaik',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isAiExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: gold,
                  ),
                ],
              ),
            ),
          ),

          // Konten Ekspansi
          if (isAiExpanded) ...[
            const Divider(color: border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PILIHAN CEPAT REKOMENDASI:',
                    style: TextStyle(
                        color: gold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),

                  // Quick chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                          '🎁 Hampers & Oleh-oleh',
                          () => requestRecommendation(
                              preference: 'hampers besek hadiah')),
                      _buildChip(
                          '🍯 Manis Legit Aren',
                          () => requestRecommendation(
                              preference: 'manis gula aren')),
                      _buildChip(
                          '👨‍👩‍👧 Porsi Rame-Rame',
                          () => requestRecommendation(
                              preference: 'keluarga rame-rame 4 orang')),
                      _buildChip(
                          '💰 Budget < 40rb',
                          () => requestRecommendation(
                              preference: 'hemat', budget: 40000)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Form Input Chat/Prompt (kosong diizinkan -> rekomendasi default)
                  Form(
                    key: _aiFormKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: aiPromptController,
                            style: const TextStyle(color: cream, fontSize: 13),
                            validator: (v) {
                              final text = v?.trim() ?? '';
                              if (text.isEmpty) return null;
                              if (!RegExp(r'[A-Za-z0-9]').hasMatch(text)) {
                                return 'Permintaan harus berisi huruf atau angka';
                              }
                              return Validators.optionalText(text,
                                  maxLength: 150, fieldName: 'Permintaan');
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              hintText:
                                  'Misal: "Camilan santai 2 orang budget 35rb"',
                              hintStyle: TextStyle(
                                  color: muted.withValues(alpha: 0.6),
                                  fontSize: 12),
                              filled: true,
                              fillColor: brown,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: border)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: gold)),
                              errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.redAccent)),
                              focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.redAccent)),
                              errorStyle: const TextStyle(
                                  color: Colors.redAccent, fontSize: 11),
                            ),
                            onFieldSubmitted: (val) {
                              if (val.trim().isNotEmpty &&
                                  (_aiFormKey.currentState?.validate() ?? false)) {
                                requestRecommendation(customPrompt: val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: loadingAi
                              ? null
                              : () {
                                  if (!(_aiFormKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  if (aiPromptController.text.trim().isNotEmpty) {
                                    requestRecommendation(
                                        customPrompt:
                                            aiPromptController.text.trim());
                                  } else {
                                    requestRecommendation(
                                        preference: 'campur favorit');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: brown,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: loadingAi
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: brown))
                              : const Icon(Icons.send_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),

                  // Loading Indicator
                  if (loadingAi) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: gold)),
                        SizedBox(width: 10),
                        Text('AI sedang meracik rekomendasi menu...',
                            style: TextStyle(color: gold, fontSize: 11)),
                      ],
                    ),
                  ],

                  // Hasil Rekomendasi AI
                  if (aiRecommendation != null && !loadingAi) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: brown,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: green.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  aiRecommendation!['ai_tag'] ??
                                      'Rekomendasi Terbaik',
                                  style: const TextStyle(
                                      color: green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                rupiah((aiRecommendation!['total_estimated']
                                            as num?)
                                        ?.toInt() ??
                                    0),
                                style: const TextStyle(
                                    color: gold,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            aiRecommendation!['recommendation_title'] ??
                                'Paket Pilihan AI',
                            style: const TextStyle(
                                color: cream,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            aiRecommendation!['reason'] ?? '',
                            style: const TextStyle(
                                color: muted, fontSize: 11, height: 1.3),
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: border),
                          const SizedBox(height: 6),

                          // Rincian Item Rekomendasi
                          ...((aiRecommendation!['items'] as List<dynamic>?) ??
                                  [])
                              .map((it) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: brown2,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('${it['qty']}x',
                                        style: const TextStyle(
                                            color: gold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(it['nama'] ?? it['name'] ?? '',
                                            style: const TextStyle(
                                                color: cream,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                        if (it['alasan'] != null)
                                          Text(it['alasan'],
                                              style: const TextStyle(
                                                  color: muted, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    rupiah(((it['harga'] as num?)?.toInt() ??
                                            0) *
                                        ((it['qty'] as num?)?.toInt() ?? 1)),
                                    style: const TextStyle(
                                        color: cream, fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: addRecommendedPackageToCart,
                              icon:
                                  const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('Tambah Semua ke Keranjang',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: brown,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: const TextStyle(color: cream, fontSize: 11),
        ),
      ),
    );
  }
}
