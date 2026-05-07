// ─── routes.dart ─────────────────────────────────────────────
// Centraliza rutas y conecta cada una con su Binding.

import 'package:get/get.dart';
import 'bindings/home_binding.dart';
import 'bindings/cart_binding.dart';
import 'views/home_view.dart';
import 'views/cart_view.dart';
import 'views/login_view.dart';

// Constantes de rutas: evita strings sueltos en el código
abstract class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const cart = '/cart';
}

abstract class AppPages {
  // routes: lista de GetPage, cada una con page + binding
  static final routes = [
    // Ruta de login: sin binding (no necesita controllers complejos)
    GetPage(name: AppRoutes.login, page: () => const LoginView()),

    // Ruta home: GetX llama HomeBinding.dependencies()
    // ANTES de construir HomeView. Los controllers ya existen
    // cuando el widget hace Get.find().
    GetPage(
      name: AppRoutes.home,
      page: () => HomeView(),
      binding: HomeBinding(), // inyecta HomeController + AuthController
    ),

    // Ruta cart: GetX elimina CartController al salir de la ruta
    // (a menos que uses permanent: true)
    GetPage(
      name: AppRoutes.cart,
      page: () => CartView(),
      binding: CartBinding(), // inyecta CartController
    ),
  ];
}
