import 'package:flutter/material.dart';
import '../main.dart';
import '../models/menu_item.dart';
import '../state/app_state.dart';
import 'app_card.dart';

class MenuCard extends StatelessWidget {
  final MenuItem item;
  final AppState state;

  const MenuCard({
    super.key,
    required this.item,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final q = state.cart
        .where((x) => x.item.id == item.id)
        .fold(0, (s, x) => s + x.quantity);

    return AppCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              item.image,
              width: 92,
              height: 92,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 92,
                  height: 92,
                  color: brown,
                  child: const Icon(
                    Icons.image_not_supported,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: cream,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      '★ ${item.rating}',
                      style: const TextStyle(
                        color: gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rupiah(item.price),
                        style: const TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    if (q == 0)
                      ElevatedButton.icon(
                        onPressed: () => state.add(item),
                        icon: const Icon(
                          Icons.add,
                          size: 15,
                        ),
                        label: const Text('Tambah'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          minimumSize: Size.zero,
                        ),
                      )
                    else
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => state.remove(item),
                            icon: const Icon(
                              Icons.remove,
                              size: 16,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: brown,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            child: Text(
                              '$q',
                              style: const TextStyle(
                                color: gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: () => state.add(item),
                            icon: const Icon(
                              Icons.add,
                              size: 16,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: green,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}