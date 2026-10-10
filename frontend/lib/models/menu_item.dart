class MenuItem {
  final String id, name, category, description, image;
  final int price, stock;
  final double rating;

  const MenuItem({required this.id, required this.name, required this.category, required this.description, required this.image, required this.price, required this.stock, required this.rating});

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: '${json['id']}',
    name: '${json['nama'] ?? json['name'] ?? 'Menu'}',
    category: '${json['kategori'] ?? json['category'] ?? 'Tradisional'}',
    description: '${json['deskripsi'] ?? json['description'] ?? ''}',
    image: '${json['gambar'] ?? json['image'] ?? '/images/puthu_bambu.png'}',
    price: int.tryParse('${json['harga'] ?? json['price'] ?? 0}') ?? 0,
    stock: int.tryParse('${json['stok'] ?? json['stockRemaining'] ?? 0}') ?? 0,
    rating: double.tryParse('${json['rating'] ?? 4.9}') ?? 4.9,
  );
}
