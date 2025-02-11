import 'package:flutter/material.dart';
import '../screens/panel_screen.dart';
import '../screens/operario_screen.dart';
import '../screens/carretillero_screen.dart';
import '../screens/peticion_material_operario_screen.dart';

Map<String, WidgetBuilder> getApplicationRoutes() {
  return {
    '/panel': (context) => PanelScreen(),
    '/operario': (context) => OperarioScreen(),
    '/carretillero': (context) => CarretilleroScreen(),
    '/peticion_material_operario': (context) =>
        PeticionMaterialOperarioScreen(),
  };
}
