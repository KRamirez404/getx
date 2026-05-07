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
      appBar: AppBar(title: const Text('Mi Carrito')),

      body: Column(
        children: [
          // ── Obx: lista de items (reactiva automáticamente) ──────
          // Cada vez que items cambia, solo este widget se reconstruye.
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.items.length, // reactivo
                itemBuilder: (_, i) {
                  final item = controller.items[i];
                  final product = item['product'];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('Cant: ${item["quantity"]}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      // removeAt: RxList notifica → Obx reconstruye lista
                      onPressed: () => controller.removeItem(i),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Obx: total reactivo ────────────────────────────────
          // total.value cambia via ever() cuando items cambia.
          Obx(
            () => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Total: \$${controller.total.value.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ── GetBuilder: patrón MANUAL para el mensaje de checkout ──
          // checkoutDone es bool normal (no .obs).
          // Solo se reconstruye cuando controller llama update().
          GetBuilder<CartController>(
            builder: (ctrl) => ctrl.checkoutDone
                ? const Text(
                    '✅ Pedido confirmado',
                    style: TextStyle(color: Colors.green),
                  )
                : const SizedBox.shrink(), // invisible si no confirmado
          ),

          // Botón de checkout: reactivo al estado de carga
          Obx(
            () => ElevatedButton(
              onPressed: controller.isCheckingOut.value
                  ? null // deshabilita durante el proceso
                  : controller.checkout, // lanza el checkout
              child: controller.isCheckingOut.value
                  ? const CircularProgressIndicator()
                  : const Text('Confirmar pedido'),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
