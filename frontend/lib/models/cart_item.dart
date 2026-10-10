import 'menu_item.dart';

class CartItem {
  final MenuItem item;
  int quantity;
  String notes;
  CartItem({required this.item, this.quantity = 1, this.notes = ''});
  int get subtotal => item.price * quantity;
}
