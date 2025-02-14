import 'package:flutter/material.dart';
import '../screens/panel_screen.dart';
import '../screens/operario_screen.dart';
import '../screens/main_carretillero_screen.dart';
import '../screens/main_operario_screen.dart';

// Definimos las rutas como constantes para evitar errores de escritura
class Routes {
  static const String panel = '/panel';
  static const String operario = '/operario';
  static const String carretillero = '/carretillero';
  static const String peticionMaterialOperario = '/peticion_material_operario';
}

Map<String, WidgetBuilder> getApplicationRoutes() {
  return {
    Routes.panel: (context) => PanelScreen(),
    Routes.operario: (context) => OperarioScreen(),
    Routes.carretillero: (context) => CarretilleroScreen(),
    Routes.peticionMaterialOperario: (context) => MainOperarioScreen(),
  };
}
