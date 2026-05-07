// ─── controllers/cart_controller.dart ────────────────────────
// Controller del carrito. Mezcla GetBuilder (manual) para el
// resumen y Obx (reactivo) para el total. Muestra ambos patrones.

import 'package:get/get.dart';
import '../routes.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CartController extends GetxController {
  final _api = Get.find<ApiService>(); // servicio global ya inicializado

  // items: RxList de mapas {product, quantity}.
  // Obx en la UI se reconstruye al agregar/quitar items.
  var items = <Map<String, dynamic>>[].obs;

  // total: RxDouble reactivo → el widget del total se actualiza solo
  var total = 0.0.obs;

  // isCheckingOut: controla el estado del botón de pago
  var isCheckingOut = false.obs;

  // checkoutDone: estado NO reactivo para GetBuilder
  // (demostramos el patrón manual también)
  bool checkoutDone = false;

  @override
  void onInit() {
    super.onInit();

    // Lee los argumentos pasados desde HomeController.goToCart()
    // Get.arguments: Map con 'cart' (RxMap) y 'products' (RxList)
    final args = Get.arguments as Map<String, dynamic>;
    final cartMap = args['cart'] as Map<int, int>;
    final allProds = args['products'] as List<Product>;

    // Construye la lista de items del carrito a partir del mapa
    items.value = cartMap.entries
        .map(
          (e) => {
            'product': allProds.firstWhere((p) => p.id == e.key),
            'quantity': e.value,
          },
        )
        .toList();

    // ever: cada vez que items cambie, recalcula el total automáticamente
    ever(items, (_) => _recalcTotal());
    _recalcTotal(); // calcula el total inicial
  }

  // _recalcTotal: suma precio × cantidad de todos los items
  void _recalcTotal() {
    total.value = items.fold(0.0, (sum, item) {
      final p = item['product'] as Product;
      return sum + (p.price * (item['quantity'] as int));
    });
  }

  // removeItem: quita un item de la lista (RxList dispara reactividad)
  void removeItem(int index) => items.removeAt(index);

  // checkout: llama a la API y usa GetBuilder para el mensaje final
  Future<void> checkout() async {
    isCheckingOut.value = true;
    final success = await _api.checkout(items.map((i) => i).toList());
    isCheckingOut.value = false;

    if (success) {
      checkoutDone = true; // variable normal (no .obs)
      items.clear(); // limpia el carrito reactivamente
      update(); // dispara GetBuilder manualmente

      // Get.dialog: muestra diálogo sin BuildContext
      Get.defaultDialog(
        title: '¡Pedido listo!',
        middleText: 'Tu compra fue procesada con éxito.',
        onConfirm: () => Get.offAllNamed(AppRoutes.home),
        textConfirm: 'Volver al inicio',
      );
    }
  }
}
