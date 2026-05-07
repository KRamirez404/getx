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

          // AuthController: obtenemos el segundo controller con find
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: Get.find<AuthController>()
                .logout, // llama logout en el servicio
          ),
        ],
      ),

      body: Column(
        children: [
          // Campo de búsqueda: actualiza searchQuery (RxString)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
              ),
              // onChanged: actualiza el observable → debounce activa _applyFilter
              onChanged: (v) => controller.searchQuery.value = v,
            ),
          ),

          // Obx: escucha isLoading y filtered simultáneamente
          Expanded(
            child: Obx(() {
              // Si está cargando: muestra spinner
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              // Si no hay resultados: mensaje vacío
              if (controller.filtered.isEmpty) {
                return const Center(child: Text('Sin resultados'));
              }
              // Lista reactiva: se reconstruye al cambiar filtered
              return ListView.builder(
                itemCount: controller.filtered.length, // reactivo
                itemBuilder: (_, i) {
                  final product = controller.filtered[i];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('\$${product.price}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      // addToCart: actualiza RxMap cart → cartCount cambia → Badge se reconstruye
                      onPressed: () => controller.addToCart(product),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
