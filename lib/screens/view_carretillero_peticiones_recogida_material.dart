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
                  .where((item) => item['status_recogida'] != 'RECOGIDO')
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      print("Error al obtener solicitudes de recogida: $e");
    }
  }

  Future<void> actualizarEstadoRecogida(String id) async {
    try {
      final url =
          'https://api-psc-warehouse.azurewebsites.net/status-recogida/$id/status/RECOGIDO';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Estado de recogida actualizado a RECOGIDO');
        _fetchSolicitudesRecogida();
      } else {
        print('Error al actualizar el estado de recogida');
        print('Código de estado: ${response.statusCode}');
        print('Cuerpo de la respuesta: ${response.body}');
      }
    } catch (e) {
      print('Error en la solicitud de actualización: $e');
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
          solicitud['linea'] ?? 'N/A',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hora: ${solicitud['timeHour'] ?? 'N/A'}'),
            Text('Estado: ${solicitud['status_recogida'] ?? 'N/A'}'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: solicitud['status_recogida'] != 'RECOGIDO'
                  ? () => actualizarEstadoRecogida(
                      solicitud['id_status'].toString())
                  : null,
              child: Text('RECOGIDO'),
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
        title: Text('Solicitudes de Recogida'),
      ),
      body: _solicitudesRecogida.isEmpty
          ? Center(child: Text('No hay solicitudes de recogida pendientes'))
          : ListView.builder(
              itemCount: _solicitudesRecogida.length,
              itemBuilder: (context, index) {
                return _buildSolicitudCard(_solicitudesRecogida[index]);
              },
            ),
    );
  }
}
