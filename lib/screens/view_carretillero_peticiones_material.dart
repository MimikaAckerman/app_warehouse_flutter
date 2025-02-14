import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ViewCarretilleroPeticionesMaterial extends StatefulWidget {
  @override
  _ViewCarretilleroPeticionesMaterialState createState() =>
      _ViewCarretilleroPeticionesMaterialState();
}

class _ViewCarretilleroPeticionesMaterialState
    extends State<ViewCarretilleroPeticionesMaterial> {
  List<Map<String, dynamic>> _solicitudes = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchSolicitudes();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (mounted) {
        fetchSolicitudes();
      }
    });
  }

  Future<void> fetchSolicitudes() async {
    try {
      final response = await http.get(
        Uri.parse("https://api-psc-warehouse.azurewebsites.net/curso-products"),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedData = jsonDecode(response.body);
          if (decodedData != null && decodedData is List) {
            setState(() {
              _solicitudes = decodedData
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      print("Error al obtener solicitudes: $e");
    }
  }

  Future<void> actualizarEstado(String id, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(
            "https://api-psc-warehouse.azurewebsites.net/curso-product/$id/status/$newStatus"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print("Estado actualizado correctamente");
        fetchSolicitudes(); // Actualizar la lista de solicitudes después de cambiar el estado
      } else {
        print("Error al actualizar el estado");
        print("Código de estado: ${response.statusCode}");
        print("Cuerpo de la respuesta: ${response.body}");
      }
    } catch (e) {
      print("Error en la solicitud de actualización: $e");
    }
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud) {
    String? selectedEstado = solicitud['status'];
    List<String> estadosDisponibles = [
      "PENDIENTE",
      "EN CURSO",
      "FINALIZADO",
      "SOLICITADO"
    ];

    if (selectedEstado == null ||
        !estadosDisponibles.contains(selectedEstado)) {
      selectedEstado = "PENDIENTE";
    }

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          solicitud['no'] ?? 'N/A',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Línea: ${solicitud['linea'] ?? 'N/A'}"),
            Text("Denominación: ${solicitud['denominacion'] ?? 'N/A'}"),
            Text("Materia Prima: ${solicitud['refpt'] ?? 'N/A'}"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Estado: "),
                DropdownButton<String>(
                  value: selectedEstado,
                  items: estadosDisponibles.map((String estado) {
                    return DropdownMenuItem<String>(
                      value: estado,
                      child: Text(estado),
                    );
                  }).toList(),
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      setState(() {
                        solicitud['status'] = newValue;
                      });
                      await actualizarEstado(
                          solicitud['id'].toString(), newValue);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peticiones de Material'),
      ),
      body: _solicitudes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _solicitudes.length,
              itemBuilder: (context, index) {
                return _buildSolicitudCard(_solicitudes[index]);
              },
            ),
    );
  }
}
