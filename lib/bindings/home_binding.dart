// ─── bindings/home_binding.dart ──────────────────────────────
// Binding: declara qué controllers necesita la ruta /home.
// GetX llama dependencies() ANTES de construir HomeView.
// Los controllers se eliminan automáticamente al salir de la ruta.

import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';

// Extiende Bindings → obliga a implementar dependencies()
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // lazyPut: registra la fábrica pero NO crea la instancia todavía.
    // HomeController se crea al primer Get.find<HomeController>().
    // fenix: true → si fue eliminado, se recrea al volver a la ruta.
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

    // AuthController: controller de UI para el estado de login en HomeView.
    // (AuthService ya existe como servicio global, este controller
    //  maneja la lógica específica de la pantalla Home)
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
