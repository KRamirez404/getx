// ─── main.dart ───────────────────────────────────────────────
// Punto de entrada. Inicializa servicios globales antes de runApp.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'routes.dart';

// async main: necesario para await antes de runApp
void main() async {
  // Asegura que Flutter esté inicializado antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  // GetxService: registra ApiService como singleton permanente.
  // putAsync espera la Future antes de continuar.
  await Get.putAsync<ApiService>(() async {
    final service = ApiService();
    await service.init(); // inicialización async (Dio, headers, etc.)
    return service; // retorna instancia lista
  });

  // AuthService: otro GetxService permanente.
  // Carga el token guardado en SharedPreferences.
  await Get.putAsync<AuthService>(() async => await AuthService().init());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GetMaterialApp reemplaza MaterialApp.
    // Inyecta el Navigator de GetX → habilita Get.to, Get.back,
    // snackbars y dialogs sin BuildContext.
    return GetMaterialApp(
      title: 'GetX Shop',
      debugShowCheckedModeBanner: false,

      // defaultTransition: animación global entre rutas
      defaultTransition: Transition.fadeIn,

      // initialRoute: primera pantalla según estado de auth
      initialRoute: Get.find<AuthService>().isLoggedIn.value
          ? AppRoutes.home
          : AppRoutes.login,

      // getPages: todas las rutas con sus bindings declarados
      getPages: AppPages.routes,
    );
  }
}
