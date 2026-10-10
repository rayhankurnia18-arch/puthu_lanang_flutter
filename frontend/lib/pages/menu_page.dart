import 'package:flutter/material.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../widgets/menu_card.dart';
import '../widgets/app_card.dart';
import 'payment_page.dart';

class MenuPage extends StatefulWidget {
  final AppState state;

  const MenuPage({super.key, required this.state});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
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
              'Menu Jajanan Traditional',
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
                    onPressed: () {
                      final cartItemsList = state.cart.map((cartItem) {
                        return {
                          'id': cartItem.item.id,
                          'nama': cartItem.item.name,
                          'harga': cartItem.item.price,
                          'qty': cartItem.quantity,
                        };
                      }).toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            state: state,
                            cartItems: cartItemsList,
                            totalPrice: state.totalPrice,
                            notes: 'Tanpa catatan',
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
}