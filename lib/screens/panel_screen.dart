import 'package:flutter/material.dart';

class PanelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Panel Principal"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Aquí puedes navegar a la pantalla de Operario
                Navigator.pushNamed(context, '/operario');
              },
              child: Text("Operario"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aquí puedes navegar a la pantalla de Carretillero
                Navigator.pushNamed(context, '/carretillero');
              },
              child: Text("Carretillero"),
            ),
          ],
        ),
      ),
    );
  }
}
