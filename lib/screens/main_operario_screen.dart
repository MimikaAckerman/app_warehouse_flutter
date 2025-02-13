import 'package:flutter/material.dart';
import 'peticion_material_operario_screen.dart';
import 'visualizar_peticiones_operario_screen.dart';

class MainOperarioScreen extends StatefulWidget {
  const MainOperarioScreen({super.key});

  @override
  _MainOperarioScreenState createState() => _MainOperarioScreenState();
}

class _MainOperarioScreenState extends State<MainOperarioScreen> {
  String? _selectedLinea;

  void _updateSelectedLinea(String? linea) {
    setState(() {
      _selectedLinea = linea;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sistema de Peticiones - Operario'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Panel superior - Formulario de petición
          Expanded(
            flex: 1,
            child: PeticionMaterialOperarioScreen(
              onLineaSelected: _updateSelectedLinea,
            ),
          ),
          // Separador horizontal
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),
          // Panel inferior - Lista de peticiones
          Expanded(
            flex: 1,
            child: VisualizarPeticionesOperarioScreen(
              lineaSeleccionada: _selectedLinea,
            ),
          ),
        ],
      ),
    );
  }
}
