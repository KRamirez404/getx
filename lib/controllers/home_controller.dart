// ─── controllers/home_controller.dart ────────────────────────
// GetxController: lógica de negocio de la pantalla Home.
// Maneja: lista de productos, búsqueda, filtros, carrito.

import 'package:get/get.dart';
import '../routes.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  // Get.find: obtiene ApiService ya registrado en main().
  // No necesita parámetros porque GetxService es singleton.
  final _api = Get.find<ApiService>();

  // RxList: lista reactiva de productos. Obx se reconstruye
  // automáticamente cuando se agregan/quitan/modifican items.
  var products = <Product>[].obs;

  // RxList filtrada: solo los productos que coinciden con la búsqueda
  var filtered = <Product>[].obs;

  // RxBool: true mientras espera respuesta de la API
  var isLoading = false.obs;

  // RxString: texto actual del campo de búsqueda
  var searchQuery = ''.obs;

  // RxMap: conteo de items en el carrito {productId: cantidad}
  var cart = <int, int>{}.obs;

  // Getter no reactivo: calcula el total del carrito en tiempo real
  int get cartCount => cart.values.fold(0, (a, b) => a + b);

  @override
  void onInit() {
    super.onInit(); // SIEMPRE llama super primero
    loadProducts(); // carga datos al inicializar el controller

    // debounce: espera 400ms sin cambios antes de filtrar.
    // Evita filtrar en cada tecla presionada → mejor performance.
    debounce(
      searchQuery,
      (_) => _applyFilter(),
      time: const Duration(milliseconds: 400),
    );
  }

  // loadProducts: llama a la API y actualiza el estado reactivo
  Future<void> loadProducts() async {
    isLoading.value = true; // activa spinner
    products.value = await _api.getProducts(); // actualiza RxList
    filtered.value = products; // inicializa la lista filtrada
    isLoading.value = false; // desactiva spinner
  }

  // _applyFilter: filtra products según searchQuery
  void _applyFilter() {
    final q = searchQuery.value.toLowerCase();
    // Si la query está vacía, muestra todos
    filtered.value = q.isEmpty
        ? products
        : products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  // addToCart: agrega o incrementa un producto en el carrito (RxMap)
  void addToCart(Product product) {
    if (product.stock == 0) {
      // Get.snackbar: muestra notificación SIN necesitar BuildContext
      Get.snackbar('Sin stock', '${product.name} no tiene stock');
      return;
    }
    // RxMap: la asignación directa dispara reactividad
    cart[product.id] = (cart[product.id] ?? 0) + 1;
  }

  // goToCart: navega a /cart por nombre de ruta
  void goToCart() => Get.toNamed(
    AppRoutes.cart,
    arguments: {'cart': cart, 'products': products},
  );

  @override
  void onClose() {
    // Aquí cancela timers, streams o TextEditingControllers
    super.onClose(); // GetX llama esto al salir de la ruta
  }
}
