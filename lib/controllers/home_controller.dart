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
    
    // 🆕 MONITOREO AUTOMÁTICO: Cada vez que el carrito cambia,
    // verifica que ninguna cantidad exceda el stock disponible
    ever(cart, (_) => _validateCartAgainstStock());
  }

  // loadProducts: llama a la API y actualiza el estado reactivo
  Future<void> loadProducts() async {
    isLoading.value = true; // activa spinner
    try {
      products.value = await _api.getProducts(); // actualiza RxList
      filtered.value = products; // inicializa la lista filtrada
    } catch (e) {
      // Manejo de error: muestra mensaje y deja lista vacía
      Get.snackbar(
        'Error',
        'No se pudieron cargar los productos',
        snackPosition: SnackPosition.BOTTOM,
        //backgroundColor: Colors.red,
        //colorText: Colors.white,
      );
      products.value = [];
      filtered.value = [];
    } finally {
      isLoading.value = false; // desactiva spinner
    }
  }

  // _applyFilter: filtra products según searchQuery
  void _applyFilter() {
    final q = searchQuery.value.toLowerCase();
    // Si la query está vacía, muestra todos
    filtered.value = q.isEmpty
        ? products
        : products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  // 🆕 _validateCartAgainstStock: corrige automáticamente cantidades 
  // que excedan el stock disponible (útil si el stock cambia externamente)
  void _validateCartAgainstStock() {
    bool hasChanges = false;
    
    // Crear una copia para iterar mientras modificamos el original
    final cartCopy = Map<int, int>.from(cart);
    
    for (var entry in cartCopy.entries) {
      final productId = entry.key;
      final quantityInCart = entry.value;
      
      // Buscar el producto actualizado (con su stock actual)
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => Product(id: productId, name: '', price: 0, stock: 0),
      );
      
      // Si el producto ya no existe o su stock es 0, eliminar del carrito
      if (product.stock == 0) {
        cart.remove(productId);
        hasChanges = true;
        
        Get.snackbar(
          'Producto eliminado',
          '${product.name} ya no está disponible',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } 
      // Si la cantidad en carrito excede el stock, ajustar al stock máximo
      else if (quantityInCart > product.stock) {
        cart[productId] = product.stock;
        hasChanges = true;
        
        Get.snackbar(
          'Cantidad ajustada',
          '${product.name}: ahora ${product.stock} unidades (stock máximo)',
          snackPosition: SnackPosition.BOTTOM,
        //  backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        );
      }
    }
    
    // Si hubo cambios, forzar actualización de la UI
    if (hasChanges) {
      cart.refresh();
    }
  }

  // 🆕 addToCart CORREGIDO: agrega o incrementa un producto en el carrito 
  // respetando el stock disponible
  void addToCart(Product product) {
    // Obtener la cantidad actual en el carrito (0 si no existe)
    final currentQuantityInCart = cart[product.id] ?? 0;
    
    // Verificar si ya alcanzó el límite de stock
    if (currentQuantityInCart >= product.stock) {
      // Mostrar mensaje diferente según si hay algo de stock o no
      if (product.stock == 0) {
        Get.snackbar(
          'Sin stock',
          '${product.name} no tiene stock disponible',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Stock agotado',
          'No puedes agregar más ${product.name}. Stock disponible: ${product.stock}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }
    
    // Agregar una unidad (solo si hay stock disponible)
    cart[product.id] = currentQuantityInCart + 1;
    
     }

  // 🆕 addMultipleToCart: agrega múltiples unidades de una vez (útil para steppers)
  void addMultipleToCart(Product product, int quantity) {
    final currentQuantityInCart = cart[product.id] ?? 0;
    final availableStock = product.stock - currentQuantityInCart;
    
    // Validar que la cantidad solicitada no exceda el stock disponible
    if (quantity > availableStock) {
      Get.defaultDialog(
        title: 'Stock insuficiente',
        middleText: 'Solo puedes agregar $availableStock unidades más de ${product.name}',
        onConfirm: () {
          if (availableStock > 0) {
            cart[product.id] = currentQuantityInCart + availableStock;
          }
          Get.back();
        },
        textConfirm: 'Agregar $availableStock',
        textCancel: 'Cancelar',
      );
      return;
    }
    
    // Agregar la cantidad solicitada
    cart[product.id] = currentQuantityInCart + quantity;
  }

  // goToCart: navega a /cart por nombre de ruta
  void goToCart() => Get.toNamed(
    AppRoutes.cart,
    arguments: {'cart': cart, 'products': products},
  );

  // 🆕 resetCart: limpia el carrito (útil para logout)
  void resetCart() {
    cart.clear();
  }

  @override
  void onClose() {
    // Aquí cancela timers, streams o TextEditingControllers
    super.onClose(); // GetX llama esto al salir de la ruta
  }
}