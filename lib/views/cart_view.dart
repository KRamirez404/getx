// ─── views/cart_view.dart ─────────────────────────────────────
// CartView: muestra Obx (reactivo) Y GetBuilder (manual) juntos.
// Propósito: demostrar cuándo usar cada patrón en la misma pantalla.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';

class CartView extends GetView<CartController> {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        actions: [
          // 🆕 Botón para vaciar el carrito
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              Get.defaultDialog(
                title: 'Vaciar carrito',
                middleText: '¿Eliminar todos los productos?',
                onConfirm: () {
                  controller.items.clear();
                  Get.back();
                },
                textConfirm: 'Sí, vaciar',
                textCancel: 'Cancelar',
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Obx: lista de items (reactiva automáticamente) ──────
          // Cada vez que items cambia, solo este widget se reconstruye.
          Expanded(
            child: Obx(
              () => controller.items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Tu carrito está vacío'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.items.length, // reactivo
                      itemBuilder: (_, i) {
                        final item = controller.items[i];
                        final product = item['product'];
                        final quantity = item['quantity'] as int;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(product.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Precio: \$${product.price.toStringAsFixed(0)}'),
                                Text(
                                  'Subtotal: \$${(product.price * quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                // 🆕 Mostrar advertencia si está cerca del stock
                                if (quantity == product.stock && product.stock > 0)
                                  const Text(
                                    '⚠️ Máximo stock alcanzado',
                                    style: TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Botón disminuir cantidad
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 20),
                                  onPressed: quantity > 1
                                      ? () => controller.updateQuantity(i, quantity - 1)
                                      : () => controller.removeItem(i),
                                ),
                                // Cantidad actual
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '$quantity',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Botón aumentar cantidad (con verificación de stock)
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: quantity < product.stock
                                      ? () => controller.updateQuantity(i, quantity + 1)
                                      : null, // Deshabilitar si llega al stock máximo
                                ),
                                // Botón eliminar
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => controller.removeItem(i),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // ── Divider ───────────────────────────────────────────
          const Divider(height: 1),

          // ── Obx: total reactivo ────────────────────────────────
          // total.value cambia via ever() cuando items cambia.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => Text(
                    '\$${controller.total.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── GetBuilder: patrón MANUAL para el mensaje de checkout ──
          // checkoutDone es bool normal (no .obs).
          // Solo se reconstruye cuando controller llama update().
          GetBuilder<CartController>(
            builder: (ctrl) => ctrl.checkoutDone
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '✅ Pedido confirmado',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  )
                : const SizedBox.shrink(), // invisible si no confirmado
          ),

          // Botón de checkout: reactivo al estado de carga
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: (controller.isCheckingOut.value || controller.items.isEmpty)
                      ? null // deshabilita durante el proceso o si está vacío
                      : controller.checkout, // lanza el checkout
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: controller.isCheckingOut.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar pedido'),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}