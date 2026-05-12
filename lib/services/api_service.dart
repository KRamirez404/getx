// GetxService para llamadas HTTP. Permanente en memoria.
// Todos los controllers lo obtienen con Get.find<ApiService>().

import 'package:get/get.dart';
import '../models/product.dart';

class ApiService extends GetxService {
  // init: configura headers, interceptores, base URL, etc.
  Future<ApiService> init() async {
    
    await Future.delayed(const Duration(milliseconds: 100));
    return this;
  }

  // getProducts: retorna lista de productos desde la API
  Future<List<Product>> getProducts() async {
    try {
      // Simular tiempo de carga
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Datos simulados 
      return [
        Product(id: 1, name: 'Camiseta Negra',  price: 49900, stock: 10),
        Product(id: 2, name: 'Jeans Slim',       price: 129900, stock: 5),
        Product(id: 3, name: 'Zapatillas Run',   price: 249900, stock: 3),
        Product(id: 4, name: 'Gorra Vintage',    price: 39900, stock: 2),
      ];
    } catch (e) {
      throw Exception('Error al cargar productos: $e');
    }
  }

  // checkout ahora recibe un formato específico
  Future<bool> checkout(List<Map<String, dynamic>> items) async {
    try {
      // Simular envío a API
      await Future.delayed(const Duration(seconds: 1));
      
      
      print('Checkout procesado: ${items.length} productos');
      return true;
    } catch (e) {
      print('Error en checkout: $e');
      return false;
    }
  }
}