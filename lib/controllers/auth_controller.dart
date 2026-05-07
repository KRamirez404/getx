// ─── controllers/auth_controller.dart ────────────────────────
// GetxController de UI para Login. Coordina con AuthService.
// Demuestra: Rx, validación, feedback reactivo.

import 'package:get/get.dart';
import '../routes.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  // Obtiene el AuthService global (registrado en main)
  final _auth = Get.find<AuthService>();

  // Estado del formulario: Rx<String> para campos de texto
  var email = ''.obs;
  var password = ''.obs;

  // RxBool: controla visibilidad del password
  var obscurePass = true.obs;

  // RxBool: deshabilita el botón mientras se procesa
  var isLoading = false.obs;

  // RxString: mensaje de error (vacío = sin error)
  var errorMsg = ''.obs;

  // Getter reactivo: el botón de login solo se habilita si hay
  // email y password (Obx en la UI lo detecta automáticamente)
  bool get canSubmit => email.value.isNotEmpty && password.value.length >= 6;

  // togglePassword: invierte la visibilidad (reactivo)
  void togglePassword() => obscurePass.value = !obscurePass.value;

  // logout: delega en el AuthService compartido
  Future<void> logout() => _auth.logout();

  // login: valida y delega al AuthService
  Future<void> login() async {
    if (!canSubmit) return;

    errorMsg.value = ''; // limpia error previo
    isLoading.value = true; // activa spinner del botón

    try {
      // Delega la lógica real al servicio global
      await _auth.login(email.value, password.value);

      // offNamed: navega a /home y elimina /login del stack
      // (el usuario no puede volver atrás con el botón físico)
      Get.offNamed(AppRoutes.home);
    } catch (e) {
      // errorMsg.value = '...' dispara Obx en la UI automáticamente
      errorMsg.value = 'Credenciales incorrectas. Intenta de nuevo.';
    } finally {
      isLoading.value = false; // siempre desactiva el spinner
    }
  }
}
