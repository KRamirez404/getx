// ─── services/auth_service.dart ──────────────────────────────
// GetxService: singleton permanente. No se elimina al cambiar ruta.
// Ideal para: sesión, token, preferencias globales.

import 'package:get/get.dart';
import 'package:getx/controllers/home_controller.dart';
import '../routes.dart';

// Extiende GetxService (no GetxController) → no se destruye nunca
class AuthService extends GetxService {
  // RxBool: observable de tipo bool con .obs
  var isLoggedIn = false.obs;

  // RxString: el token del usuario (vacío = no autenticado)
  var token = ''.obs;

  // RxMap: datos del usuario (nombre, email, rol, etc.)
  var userData = <String, dynamic>{}.obs;

  // init(): patrón async para GetxService.
  // Retorna this para usarlo con await Get.putAsync()
  Future<AuthService> init() async {
    // Simula lectura de SharedPreferences o secure storage
    final savedToken = await _loadToken();

    if (savedToken != null && savedToken.isNotEmpty) {
      token.value = savedToken; // actualiza el Rx
      isLoggedIn.value = true; // notifica a la UI
      userData['name'] = 'Carlos García';
    }

    return this; // retorna la instancia para putAsync
  }

  // login: actualiza estado reactivo → UI responde sola
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    token.value = 'jwt_token_abc123';
    isLoggedIn.value = true;
    userData.value = {'name': email.split('@').first, 'email': email};
    await _saveToken(token.value);
  }

  // 🆕 logout CORREGIDO: limpia estado, el carrito y redirige al login
  Future<void> logout() async {
    token.value = '';
    isLoggedIn.value = false;
    userData.clear();
    
    // 🆕 Limpiar el carrito al hacer logout
    // Verificar si HomeController está registrado antes de acceder
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      homeController.resetCart();
    }
    
    await _clearToken();
    // offAll: navega y limpia TODO el navigation stack
    Get.offAllNamed(AppRoutes.login);
  }

  // Helpers privados (en producción usarías shared_preferences)
  Future<String?> _loadToken() async => null;
  Future<void> _saveToken(String t) async {}
  Future<void> _clearToken() async {}
}