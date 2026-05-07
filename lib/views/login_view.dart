// ─── views/login_view.dart ────────────────────────────────────
// LoginView: GetX<T> (reactivo + acceso al controller en builder)
// Muestra: validación reactiva, toggle password, error handling.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

// LoginView NO usa GetView porque AuthController se registra
// aquí mismo con Get.put (no viene de un Binding previo)
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get.put: registra e instancia AuthController inmediatamente.
    // Si ya existe (raro en login), retorna la instancia existente.
    final ctrl = Get.put(AuthController());

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('GetX Shop', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 32),

            // Email: onChanged actualiza el RxString (no reconstruye nada)
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              onChanged: (v) => ctrl.email.value = v,
            ),
            const SizedBox(height: 16),

            // GetX<T>: reactivo + acceso al controller en builder.
            // Solo reconstruye el TextField cuando obscurePass cambia.
            GetX<AuthController>(
              builder: (c) => TextField(
                obscureText: c.obscurePass.value, // reactivo
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      c.obscurePass.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: c.togglePassword, // invierte obscurePass
                  ),
                ),
                onChanged: (v) => c.password.value = v,
              ),
            ),
            const SizedBox(height: 8),

            // Mensaje de error: solo visible si errorMsg no está vacío
            Obx(
              () => ctrl.errorMsg.value.isNotEmpty
                  ? Text(
                      ctrl.errorMsg.value,
                      style: const TextStyle(color: Colors.red),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Botón: reactivo a isLoading y canSubmit
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // null deshabilita el botón; canSubmit valida email + password
                  onPressed: (ctrl.isLoading.value || !ctrl.canSubmit)
                      ? null
                      : ctrl.login,
                  child: ctrl.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text('Iniciar sesión'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
