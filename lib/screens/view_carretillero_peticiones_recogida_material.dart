import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ViewCarretilleroPeticionesRecogidaMaterial extends StatefulWidget {
  @override
  _ViewCarretilleroPeticionesRecogidaMaterialState createState() =>
      _ViewCarretilleroPeticionesRecogidaMaterialState();
}

class _ViewCarretilleroPeticionesRecogidaMaterialState
    extends State<ViewCarretilleroPeticionesRecogidaMaterial> {
  List<Map<String, dynamic>> _solicitudesRecogida = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchSolicitudesRecogida();
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
        _fetchSolicitudesRecogida();
      }
    });
  }

  Future<void> _fetchSolicitudesRecogida() async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://api-psc-warehouse.azurewebsites.net/status-recogida"),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedData = jsonDecode(response.body);
          if (decodedData != null && decodedData is List) {
            setState(() {
              _solicitudesRecogida = decodedData
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      print("Error al obtener solicitudes de recogida: $e");
    }
  }

  Future<void> _marcarComoRecogido(String id) async {
    try {
      final response = await http.put(
        Uri.parse(
            "https://api-psc-warehouse.azurewebsites.net/status-recogida/$id/status/RECOGIDO"),
      );

      if (response.statusCode == 200) {
        _fetchSolicitudesRecogida();
      } else {
        print("Error al actualizar el estado a RECOGIDO");
      }
    } catch (e) {
      print("Error al actualizar la solicitud de recogida: $e");
    }
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          "Línea: ${solicitud['linea'] ?? 'N/A'}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estado Recogida: ${solicitud['status_recogida'] ?? 'N/A'}"),
            Text("Hora: ${solicitud['timeHour'] ?? 'N/A'}"),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _marcarComoRecogido(solicitud['id'].toString()),
          child: Text("RECOGIDO"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _solicitudesRecogida.length,
      itemBuilder: (context, index) {
        return _buildSolicitudCard(_solicitudesRecogida[index]);
      },
    );
  }
}
