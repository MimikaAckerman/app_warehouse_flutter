import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OperarioScreen extends StatefulWidget {
  @override
  _OperarioScreenState createState() => _OperarioScreenState();
}

class _OperarioScreenState extends State<OperarioScreen> {
  final TextEditingController _codigoController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _validarCodigo() async {
    String codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      setState(() {
        _errorMessage = "Por favor, ingrese su código de trabajador";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            "https://api-psc-warehouse.azurewebsites.net/verify_user/$codigo"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey("user_id")) {
          // Si el código es válido, registrar el inicio del trabajo
          await _registrarInicioTrabajo(codigo);
        } else {
          setState(() {
            _errorMessage = "Código de trabajador no válido";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error en la validación del código";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error de conexión con el servidor";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registrarInicioTrabajo(String codigo) async {
    try {
      final response = await http.post(
        Uri.parse(
            "https://api-psc-warehouse.azurewebsites.net/insertInicioTrabajo"),
        headers: {"Content-Type": "application/json"},
        body:
            jsonEncode({"codOpe": codigo}), // ✅ Se corrige el nombre del campo
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["message"] == "Registro insertado correctamente") {
          // ✅ Si el registro es exitoso, redirigir a la pantalla de peticiones
          Navigator.pushReplacementNamed(
              context, '/peticion_material_operario');
        } else {
          setState(() {
            _errorMessage = "Error al registrar el inicio de trabajo";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error al registrar el inicio de trabajo";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error de conexión con el servidor";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Operario")),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Ingrese su código de trabajador:",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _codigoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Código de trabajador",
                errorText: _errorMessage,
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _validarCodigo,
                    child: Text("Ingresar"),
                  ),
          ],
        ),
      ),
    );
  }
}
