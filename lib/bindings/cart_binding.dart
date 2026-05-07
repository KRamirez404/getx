// ─── bindings/cart_binding.dart ──────────────────────────────
// Binding de la ruta /cart.
// CartController solo existe mientras el usuario está en /cart.

import 'package:get/get.dart';
import '../controllers/cart_controller.dart';

class CartBinding extends Bindings {
  @override
  void dependencies() {
    // CartController: se instancia al entrar a /cart.
    // GetX lo elimina al salir → libera memoria automáticamente.
    Get.lazyPut<CartController>(
      () => CartController(),
      fenix: true, // permite recrearlo si el usuario regresa
    );
  }
}
