import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VisualizarPeticionesOperarioScreen extends StatefulWidget {
  final String? selectedLinea;

  const VisualizarPeticionesOperarioScreen({Key? key, this.selectedLinea})
      : super(key: key);

  @override
  _VisualizarPeticionesOperarioScreenState createState() =>
      _VisualizarPeticionesOperarioScreenState();
}

class _VisualizarPeticionesOperarioScreenState
    extends State<VisualizarPeticionesOperarioScreen> {
  List<Map<String, dynamic>> _peticiones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPeticiones();
  }

  Future<void> _fetchPeticiones() async {
    try {
      final response = await http.get(
        Uri.parse("https://api-psc-warehouse.azurewebsites.net/curso-products"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawData = jsonDecode(response.body);
        setState(() {
          _peticiones = rawData
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) =>
                  widget.selectedLinea == null ||
                  item['linea']?.toString() == widget.selectedLinea)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Error al cargar las peticiones";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error de conexión";
        _isLoading = false;
      });
    }
  }

  Widget _buildPeticionCard(Map<String, dynamic> peticion) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          'Referencia: ${peticion['no'] ?? 'N/A'}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Línea: ${peticion['linea'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              'Estado: ${peticion['status'] ?? 'N/A'}',
              style: TextStyle(
                color: _getStatusColor(peticion['status']),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Denominación', peticion['denominacion']),
                _buildDetailRow('Materia Prima', peticion['refpt']),
                _buildDetailRow('Fecha', _formatDate(peticion['date'])),
                _buildDetailRow('ID', peticion['id']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'SOLICITADO':
        return Colors.orange;
      case 'COMPLETADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Visualizar Peticiones"),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchPeticiones();
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _fetchPeticiones();
                          },
                          child: Text("Reintentar"),
                        ),
                      ],
                    ),
                  )
                : _peticiones.isEmpty
                    ? Center(
                        child: Text(
                          "No hay peticiones${widget.selectedLinea != null ? ' para la línea ${widget.selectedLinea}' : ''}",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPeticiones,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _peticiones.length,
                          itemBuilder: (context, index) {
                            return _buildPeticionCard(_peticiones[index]);
                          },
                        ),
                      ),
      ),
    );
  }
}
