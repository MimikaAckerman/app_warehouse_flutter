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
  Timer? _waitingTimeTimer;
  Map<String, DateTime> _solicitudTimestamps = {};

  @override
  void initState() {
    super.initState();
    fetchSolicitudes();
    _startAutoRefresh();
    _startWaitingTimeUpdate();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _waitingTimeTimer?.cancel();
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

  void _startWaitingTimeUpdate() {
    _waitingTimeTimer?.cancel();
    _waitingTimeTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update waiting times
        });
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
                  .map<Map<String, dynamic>>((item) {
                // Maintain existing timestamp or create new one
                String itemId = item['id'].toString();
                if (!_solicitudTimestamps.containsKey(itemId)) {
                  _solicitudTimestamps[itemId] = DateTime.now();
                }

                // Add the tracked timestamp to the item
                item['trackedCreatedAt'] =
                    _solicitudTimestamps[itemId]!.toIso8601String();

                return Map<String, dynamic>.from(item);
              }).toList();
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
            _solicitudTimestamps.remove(id);
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

  String _calculateWaitingTime(Map<String, dynamic> solicitud) {
    try {
      dynamic createdAtValue = solicitud['trackedCreatedAt'];

      if (createdAtValue != null) {
        DateTime createdAt = DateTime.parse(createdAtValue);
        Duration difference = DateTime.now().difference(createdAt);

        if (difference.inHours > 0) {
          return "${difference.inHours} horas";
        }
        if (difference.inMinutes > 0) {
          return "${difference.inMinutes} minutos";
        }
        return "${difference.inSeconds} segundos";
      }
    } catch (e) {
      print("Error calculando tiempo de espera: $e");
    }
    return "Tiempo desconocido";
  }

  Color _determineCardColor(Map<String, dynamic> solicitud) {
    if (solicitud['status'] == 'EN CURSO') {
      return const Color.fromARGB(255, 12, 163, 12);
    }

    try {
      dynamic createdAtValue = solicitud['trackedCreatedAt'];

      if (createdAtValue != null) {
        DateTime createdAt = DateTime.parse(createdAtValue);
        Duration difference = DateTime.now().difference(createdAt);

        print(
            'Tiempo transcurrido: ${difference.inMinutes} minutos'); // Debug print

        // If waiting time is more than 10 minutes, return red
        if (difference.inMinutes > 10) {
          return const Color.fromARGB(255, 243, 48, 48);
        }
        // If waiting time is more than 5 minutes, return orange
        if (difference.inMinutes > 5) {
          return const Color.fromARGB(255, 235, 100, 47);
        }
      }
    } catch (e) {
      print("Error determinando color de la tarjeta: $e");
    }

    // Default to light grey if no conditions met
    return const Color.fromARGB(255, 170, 168, 168)!;
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
