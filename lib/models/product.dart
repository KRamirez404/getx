// ─── models/product.dart ──────────────────────────────────────
// Modelo simple con campos finales. No necesita GetX aquí.
// La reactividad la maneja el controller con RxList<Product>.

class Product {
  final int id; // identificador único
  final String name; // nombre del producto
  final double price; // precio en pesos colombianos
  final int stock; // unidades disponibles (0 = sin stock)

  // Constructor con parámetros nombrados y requeridos
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  // copyWith: inmutabilidad — crea una copia modificando solo lo necesario
  Product copyWith({String? name, double? price, int? stock}) {
    return Product(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  // fromJson: para parsear respuesta de la API
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
    );
  }

  // toJson: para enviar al backend en el checkout
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'stock': stock,
  };
}
