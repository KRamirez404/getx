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
  
  // 🆕 Flag para prevenir race conditions en checkout
  bool _isProcessing = false;

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
    
    // 🆕 Monitorear cambios en items para validar stock
    ever(items, (_) => _validateStockInCart());
  }

  // _recalcTotal: suma precio × cantidad de todos los items
  void _recalcTotal() {
    total.value = items.fold(0.0, (sum, item) {
      final p = item['product'] as Product;
      return sum + (p.price * (item['quantity'] as int));
    });
  }
  
  // 🆕 _validateStockInCart: verifica que ningún item exceda el stock
  void _validateStockInCart() {
    bool hasChanges = false;
    
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final product = item['product'] as Product;
      final quantity = item['quantity'] as int;
      
      if (quantity > product.stock) {
        // Ajustar al stock máximo disponible
        if (product.stock == 0) {
          // Si no hay stock, eliminar el item
          items.removeAt(i);
          i--; // Ajustar índice después de eliminar
          hasChanges = true;
          
          Get.snackbar(
            'Producto eliminado',
            '${product.name} ya no tiene stock disponible',
            snackPosition: SnackPosition.BOTTOM,
            //backgroundColor: Colors.red,
            //colorText: Colors.white,
          );
        } else {
          // Ajustar cantidad al stock máximo
          item['quantity'] = product.stock;
          items[i] = item;
          hasChanges = true;
          
          Get.snackbar(
            'Cantidad ajustada',
            '${product.name}: ajustado a ${product.stock} unidades (stock máximo)',
            snackPosition: SnackPosition.BOTTOM,
            //  backgroundColor: Colors.orange,
          );
        }
      }
    }
    
    if (hasChanges) {
      _recalcTotal(); // Recalcular total después de cambios
      items.refresh(); // Forzar actualización UI
    }
  }

  // removeItem: quita un item de la lista (RxList dispara reactividad)
  void removeItem(int index) => items.removeAt(index);
  
  // 🆕 updateQuantity: actualiza la cantidad de un producto específico
  void updateQuantity(int index, int newQuantity) {
    final item = items[index];
    final product = item['product'] as Product;
    
    // Validar que la nueva cantidad no exceda el stock
    if (newQuantity > product.stock) {
      Get.snackbar(
        'Stock limitado',
        'Solo puedes tener ${product.stock} unidades de ${product.name}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    // Validar cantidad mínima (no menor a 1)
    if (newQuantity < 1) {
      removeItem(index);
      return;
    }
    
    // Actualizar cantidad
    item['quantity'] = newQuantity;
    items[index] = item; // Trigger reactividad
    _recalcTotal();
  }

  // 🆕 checkout CORREGIDO: valida stock antes de procesar y previene race conditions
  Future<void> checkout() async {
    // Prevenir múltiples checkouts simultáneos
    if (_isProcessing) return;
    
    // Validar stock antes de proceder al checkout
    final hasStockIssues = _validateStockBeforeCheckout();
    if (hasStockIssues) {
      Get.snackbar(
        'Error en el pedido',
        'No se puede procesar: algunos productos exceden el stock disponible',
        snackPosition: SnackPosition.BOTTOM,
        //backgroundColor: Colors.red,
        //colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    
    // Verificar que el carrito no esté vacío
    if (items.isEmpty) {
      Get.snackbar(
        'Carrito vacío',
        'Agrega productos antes de confirmar el pedido',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    _isProcessing = true;
    isCheckingOut.value = true;
    
    try {
      // Preparar datos para el checkout (formato que espera la API)
      final checkoutItems = items.map((item) {
        final product = item['product'] as Product;
        return {
          'product_id': product.id,
          'name': product.name,
          'quantity': item['quantity'],
          'price': product.price,
          'subtotal': product.price * (item['quantity'] as int),
        };
      }).toList();
      
      final success = await _api.checkout(checkoutItems);
      
      if (success) {
        checkoutDone = true; // variable normal (no .obs)
        items.clear(); // limpia el carrito reactivamente
        update(); // dispara GetBuilder manualmente

        // Get.dialog: muestra diálogo sin BuildContext
        Get.defaultDialog(
          title: '¡Pedido listo!',
          middleText: 'Tu compra fue procesada con éxito.',
          barrierDismissible: false, // Evita cerrar tocando fuera
          onConfirm: () {
            Get.back(); // Cierra el diálogo primero
            Get.offAllNamed(AppRoutes.home); // Luego navega
          },
          textConfirm: 'Volver al inicio',
        );
      }
    } catch (e) {
      // Manejar error de checkout
      Get.snackbar(
        'Error',
        'No se pudo procesar el pedido. Intenta nuevamente.',
        snackPosition: SnackPosition.BOTTOM,
        //backgroundColor: Colors.red,
       // colorText: Colors.white,
      );
    } finally {
      _isProcessing = false;
      isCheckingOut.value = false;
    }
  }
  
  // 🆕 _validateStockBeforeCheckout: verifica stock antes de procesar el pago
  bool _validateStockBeforeCheckout() {
    bool hasError = false;
    
    for (var item in items) {
      final product = item['product'] as Product;
      final quantity = item['quantity'] as int;
      
      if (quantity > product.stock) {
        hasError = true;
        // Mostrar error específico por producto
        Get.snackbar(
          'Stock insuficiente',
          '${product.name}: solicitaste $quantity pero solo hay ${product.stock}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    }
    
    return hasError;
  }

  @override
  void onClose() {
    // Limpiar flags al cerrar
    _isProcessing = false;
    super.onClose();
  }
}