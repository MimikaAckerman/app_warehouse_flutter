import 'package:flutter/material.dart';
import 'view_carretillero_peticiones_material.dart';
import 'view_carretillero_peticiones_recogida_material.dart';

class CarretilleroScreen extends StatefulWidget {
  @override
  _CarretilleroScreenState createState() => _CarretilleroScreenState();
}

class _CarretilleroScreenState extends State<CarretilleroScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Carretillero"),
      ),
      body: Column(
        children: [
          Expanded(child: ViewCarretilleroPeticionesMaterial()),
          Divider(),
          Expanded(child: ViewCarretilleroPeticionesRecogidaMaterial()),
        ],
      ),
    );
  }
}
