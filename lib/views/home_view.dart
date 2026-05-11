// ─── views/home_view.dart ─────────────────────────────────────
// GetView<HomeController>: StatelessWidget con 'controller'
// disponible directamente como getter. No necesitas Get.find().

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';

// GetView<T>: auto-busca HomeController con Get.find() internamente
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // 'controller' ya disponible sin Get.find() adicional
    return Scaffold(
      appBar: AppBar(
        title: const Text('GetX Shop'),
        actions: [
          // Obx: reacciona al carrito (cartCount) solo este botón
          Obx(
            () => Badge(
              label: Text('${controller.cartCount}'), // reactivo
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: controller.goToCart, // navega a /cart
              ),
            ),
          ),

          // Botón de logout con confirmación
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.defaultDialog(
              title: 'Cerrar sesión',
              middleText: '¿Estás seguro que quieres salir?',
              onConfirm: () {
                Get.back();
                Get.find<AuthController>().logout();
              },
              textConfirm: 'Sí, salir',
              textCancel: 'Cancelar',
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // Campo de búsqueda: actualiza searchQuery (RxString)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              maxLength: 50, // Límite de caracteres para optimizar rendimiento
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
                counterText: '', // Oculta el contador (opcional)
              ),
              // onChanged: actualiza el observable → debounce activa _applyFilter
              onChanged: (v) => controller.searchQuery.value = v,
            ),
          ),

          // UI optimizada: separa el loading de la lista
          Expanded(
            child: Stack(
              children: [
                // Lista de productos (visible cuando NO está cargando)
                Obx(() => Visibility(
                  visible: !controller.isLoading.value,
                  child: controller.filtered.isEmpty
                      ? const Center(child: Text('Sin resultados'))
                      : ListView.builder(
                          itemCount: controller.filtered.length,
                          itemBuilder: (_, i) {
                            final product = controller.filtered[i];
                            final currentInCart = controller.cart[product.id] ?? 0;
                            final isMaxStock = currentInCart >= product.stock;
                            
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('\$${product.price.toStringAsFixed(0)}'),
                                  if (product.stock < 5 && product.stock > 0)
                                    Text(
                                      '⚠️ Solo quedan ${product.stock} unidades',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  if (currentInCart > 0)
                                    Text(
                                      'En carrito: $currentInCart / ${product.stock}',
                                      style: const TextStyle(
                                        fontSize: 12, 
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 🆕 Botón de decremento (si ya hay unidades en carrito)
                                  if (currentInCart > 0)
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: () {
                                        // Reducir cantidad o eliminar si llega a 0
                                        if (currentInCart == 1) {
                                          controller.cart.remove(product.id);
                                        } else {
                                          controller.cart[product.id] = currentInCart - 1;
                                        }
                                      },
                                    ),
                                  // Botón de agregar (deshabilitado si no hay stock)
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_shopping_cart,
                                      color: isMaxStock ? Colors.grey : null,
                                    ),
                                    onPressed: isMaxStock 
                                        ? null // Deshabilitar si ya no hay stock
                                        : () => controller.addToCart(product),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                )),
                
                // Indicador de carga (visible cuando está cargando)
                Obx(() => Visibility(
                  visible: controller.isLoading.value,
                  child: const Center(child: CircularProgressIndicator()),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}