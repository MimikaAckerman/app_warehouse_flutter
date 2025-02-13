import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CarretilleroScreen extends StatefulWidget {
  @override
  _CarretilleroScreenState createState() => _CarretilleroScreenState();
}

class _CarretilleroScreenState extends State<CarretilleroScreen> {
  List<Map<String, dynamic>> _solicitudes = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchSolicitudes();
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
        _fetchSolicitudes();
      }
    });
  }

  Future<void> _fetchSolicitudes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse("https://api-psc-warehouse.azurewebsites.net/curso-products"),
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          setState(() {
            _solicitudes = [];
            _isLoading = false;
          });
          return;
        }

        final decodedData = jsonDecode(response.body);
        if (decodedData != null && decodedData is List) {
          setState(() {
            _solicitudes = decodedData
                .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _solicitudes = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = "Error en la respuesta del servidor: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error de conexión: $e";
        _isLoading = false;
      });
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
          solicitud['no'] ?? 'N/A',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Línea: ${solicitud['linea'] ?? 'N/A'}"),
            Text("Denominación: ${solicitud['denominacion'] ?? 'N/A'}"),
            Text("Materia Prima: ${solicitud['refpt'] ?? 'N/A'}"),
            Text("Estado: ${solicitud['status'] ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    if (_solicitudes.isEmpty) {
      return Center(
        child: Text(
          "No hay solicitudes en este momento.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _solicitudes.length,
      itemBuilder: (context, index) {
        return _buildSolicitudCard(_solicitudes[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Carretillero"),
      ),
      body: _buildBody(),
    );
  }
}
