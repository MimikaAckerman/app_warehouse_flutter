import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class VisualizarPeticionesOperarioScreen extends StatefulWidget {
  final String? lineaSeleccionada;

  const VisualizarPeticionesOperarioScreen({
    Key? key,
    required this.lineaSeleccionada,
  }) : super(key: key);

  @override
  _VisualizarPeticionesOperarioScreenState createState() =>
      _VisualizarPeticionesOperarioScreenState();
}

class _VisualizarPeticionesOperarioScreenState
    extends State<VisualizarPeticionesOperarioScreen> {
  List<Map<String, dynamic>> _peticiones = [];
  bool _isLoading = false;
  String? _error;
  StreamController<List<Map<String, dynamic>>>? _peticionesController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initPeticionesStream();
  }

  @override
  void didUpdateWidget(VisualizarPeticionesOperarioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lineaSeleccionada != widget.lineaSeleccionada) {
      _restartStream();
    }
  }

  void _initPeticionesStream() {
    _peticionesController = StreamController<List<Map<String, dynamic>>>();
    _peticionesController?.stream.listen((peticiones) {
      if (mounted) {
        setState(() {
          _peticiones = peticiones;
          _isLoading = false;
        });
      }
    });

    // Iniciar actualizaciones automáticas
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Cancelar el timer existente si hay uno
    _refreshTimer?.cancel();

    // Hacer la primera carga inmediatamente
    _fetchPeticiones();

    // Configurar actualizaciones automáticas cada 5 segundos
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted && widget.lineaSeleccionada != null) {
        _fetchPeticiones();
      }
    });
  }

  void _restartStream() {
    _peticionesController?.close();
    _refreshTimer?.cancel();
    _initPeticionesStream();
  }

  Future<void> _fetchPeticiones() async {
    if (widget.lineaSeleccionada == null || !mounted) return;

    try {
      final response = await http.get(
        Uri.parse("https://api-psc-warehouse.azurewebsites.net/curso-products"),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          _peticionesController?.add([]);
          return;
        }

        final dynamic decodedData = jsonDecode(response.body);

        if (decodedData == null || decodedData is! List) {
          _peticionesController?.add([]);
          return;
        }

        final List<dynamic> rawData = decodedData;

        final peticionesFiltradas = rawData
            .where((item) =>
                item['linea'] == widget.lineaSeleccionada &&
                item['status'] == "SOLICITADO")
            .toList();

        _peticionesController?.add(peticionesFiltradas
            .map((item) => Map<String, dynamic>.from(item))
            .toList());

        setState(() {
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Error en la respuesta del servidor';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = null;
        });
      }
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
          peticion['no'] ?? 'N/A',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ref: ${peticion['refpt'] ?? 'N/A'}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Estado: ${peticion['status'] ?? 'N/A'}',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ID', peticion['id']?.toString() ?? 'N/A'),
                _buildInfoRow(
                    'ID Curso', peticion['id_curso']?.toString() ?? 'N/A'),
                _buildInfoRow('Línea', peticion['linea']?.toString() ?? 'N/A'),
                _buildInfoRow('Denominación',
                    peticion['denominacion']?.toString() ?? 'N/A'),
                _buildInfoRow(
                    'Referencia PT', peticion['refpt']?.toString() ?? 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            color: Colors.grey[400],
            size: 60,
          ),
          SizedBox(height: 16),
          Text(
            widget.lineaSeleccionada == null
                ? 'Seleccione una línea para ver las peticiones'
                : 'No hay peticiones activas para esta línea',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Peticiones Activas ${widget.lineaSeleccionada != null ? "- Línea ${widget.lineaSeleccionada}" : ""}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _fetchPeticiones,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    : _peticiones.isEmpty
                        ? _buildEmptyWidget()
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _peticionesController?.close();
    super.dispose();
  }
}
