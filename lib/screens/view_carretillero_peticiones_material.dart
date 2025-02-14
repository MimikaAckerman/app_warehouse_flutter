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
                  .where((item) => item['status'] != 'FINALIZADO')
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
        if (newStatus == 'FINALIZADO') {
          setState(() {
            _solicitudes
                .removeWhere((solicitud) => solicitud['id'].toString() == id);
          });
        } else {
          fetchSolicitudes(); // Actualizar la lista de solicitudes después de cambiar el estado
        }
      } else {
        print("Error al actualizar el estado");
        print("Código de estado: ${response.statusCode}");
        print("Cuerpo de la respuesta: ${response.body}");
      }
    } catch (e) {
      print("Error en la solicitud de actualización: $e");
    }
  }

  Color _determineCardColor(Map<String, dynamic> solicitud) {
    // Check if createdAt exists and is a valid timestamp
    if (solicitud['createdAt'] != null) {
      DateTime createdAt = DateTime.parse(solicitud['createdAt']);
      Duration difference = DateTime.now().difference(createdAt);

      // If waiting time is more than 10 minutes, return red
      if (difference.inMinutes > 10) {
        return const Color.fromARGB(255, 236, 34, 34)!;
      }
      // If waiting time is more than 5 minutes, return orange
      if (difference.inMinutes > 5) {
        return const Color.fromARGB(255, 231, 96, 43)!;
      }
    }

    // Default to light grey if no conditions met
    return const Color.fromARGB(255, 129, 128, 128)!;
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud) {
    String? selectedEstado = solicitud['status'];
    List<String> estadosDisponibles = [
      "PENDIENTE",
      "EN CURSO",
      "FINALIZADO",
    ];

    if (selectedEstado == null ||
        !estadosDisponibles.contains(selectedEstado)) {
      selectedEstado = "PENDIENTE";
    }

    return Card(
      color:
          _determineCardColor(solicitud), // Dynamic color based on waiting time
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
            // Optional: display waiting time for debugging
            Text("Tiempo de espera: ${_calculateWaitingTime(solicitud)}"),
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

  String _calculateWaitingTime(Map<String, dynamic> solicitud) {
    if (solicitud['createdAt'] != null) {
      DateTime createdAt = DateTime.parse(solicitud['createdAt']);
      Duration difference = DateTime.now().difference(createdAt);

      if (difference.inMinutes > 0) {
        return "${difference.inMinutes} minutos";
      }
      return "${difference.inSeconds} segundos";
    }
    return "Tiempo desconocido";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peticiones de Material'),
      ),
      body: _solicitudes.isEmpty
          ? Center(child: Text('No hay solicitudes disponibles'))
          : ListView.builder(
              itemCount: _solicitudes.length,
              itemBuilder: (context, index) {
                return _buildSolicitudCard(_solicitudes[index]);
              },
            ),
    );
  }
}
