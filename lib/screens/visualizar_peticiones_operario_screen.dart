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
  // Peticiones de curso-products (SOLICITADO)
  List<Map<String, dynamic>> _peticiones = [];

  // Peticiones de status-recogida (PENDIENTE / RECOGIDO)
  List<Map<String, dynamic>> _recogidaPeticiones = [];

  bool _isLoading = false;
  String? _error;

  // Para refresco automático
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void didUpdateWidget(VisualizarPeticionesOperarioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lineaSeleccionada != widget.lineaSeleccionada) {
      // Cuando cambia la línea, volvemos a refrescar
      _fetchPeticiones();
      _fetchRecogidaPeticiones();
    }
  }

  void _startAutoRefresh() {
    // Cancelar timer previo si existía
    _refreshTimer?.cancel();

    // Cargar de inmediato
    _fetchPeticiones();
    _fetchRecogidaPeticiones();

    // Refrescar cada 5s
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (mounted && widget.lineaSeleccionada != null) {
        _fetchPeticiones();
        _fetchRecogidaPeticiones();
      }
    });
  }

  // =============================
  // ========== CURSO-PRODUCTS ===
  // =============================
  Future<void> _fetchPeticiones() async {
    if (widget.lineaSeleccionada == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse("https://api-psc-warehouse.azurewebsites.net/curso-products"),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          setState(() {
            _peticiones = [];
            _isLoading = false;
          });
          return;
        }

        final decodedData = jsonDecode(response.body);

        if (decodedData == null || decodedData is! List) {
          setState(() {
            _peticiones = [];
            _isLoading = false;
          });
          return;
        }

        final List<dynamic> rawData = decodedData;

        // Filtrar: línea = líneaSeleccionada && status = SOLICITADO
        final peticionesFiltradas = rawData
            .where((item) =>
                item['linea'] == widget.lineaSeleccionada &&
                item['status'] == "SOLICITADO")
            .toList();

        setState(() {
          _peticiones = peticionesFiltradas
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error en la respuesta del servidor (curso-products)';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error de conexión con el servidor (curso-products)';
          _isLoading = false;
        });
      }
    }
  }

  // =============================
  // ========== STATUS-RECOGIDA ==
  // =============================
  Future<void> _fetchRecogidaPeticiones() async {
    if (widget.lineaSeleccionada == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            "https://api-psc-warehouse.azurewebsites.net/status-recogida"),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          setState(() {
            _recogidaPeticiones = [];
          });
          return;
        }

        final decodedData = jsonDecode(response.body);

        if (decodedData == null || decodedData is! List) {
          setState(() {
            _recogidaPeticiones = [];
          });
          return;
        }

        // Filtrar las solicitudes de recogida por la línea
        final List<dynamic> rawRecogida = decodedData;
        final recogidasFiltradas = rawRecogida
            .where((item) => item['linea'] == widget.lineaSeleccionada)
            .toList();

        setState(() {
          _recogidaPeticiones = recogidasFiltradas
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error al obtener solicitudes de recogida: $e");
    }
  }

  // =============================

  Future<void> _cambiarEstadoAFinalizado(String productId) async {
    try {
      final response = await http.put(
        Uri.parse(
            "https://api-psc-warehouse.azurewebsites.net/curso-product/$productId/status/FINALIZADO"),
      );

      if (response.statusCode == 200) {
        // Actualizar la lista de peticiones
        await _fetchPeticiones();
      } else {
        print('Error al cambiar el estado a FINALIZADO');
      }
    } catch (e) {
      print('Error de conexión al cambiar el estado a FINALIZADO');
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
                _buildInfoRow('Línea', peticion['linea']?.toString() ?? 'N/A'),
                _buildInfoRow('Denominación',
                    peticion['denominacion']?.toString() ?? 'N/A'),
                _buildInfoRow(
                    'Referencia PT', peticion['refpt']?.toString() ?? 'N/A'),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 16, bottom: 16),
              child: ElevatedButton(
                onPressed: () {
                  _cambiarEstadoAFinalizado(peticion['id'].toString());
                },
                child: Text('Recibido'),
              ),
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

  Widget _buildEmptyWidget(String texto) {
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
            texto,
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

  // Sección de peticiones del curso-products
  Widget _buildPeticionesSection() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(color: Colors.red),
        ),
      );
    } else if (_peticiones.isEmpty) {
      return _buildEmptyWidget(
        widget.lineaSeleccionada == null
            ? 'Seleccione una línea para ver las peticiones'
            : 'No hay peticiones activas (SOLICITADO) para esta línea',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPeticiones,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _peticiones.length,
        itemBuilder: (context, index) {
          return _buildPeticionCard(_peticiones[index]);
        },
      ),
    );
  }

  // Sección de solicitudes de recogida
  Widget _buildRecogidaSection() {
    if (_recogidaPeticiones.isEmpty && widget.lineaSeleccionada != null) {
      return _buildEmptyWidget(
          'No hay solicitudes de recogida para la línea ${widget.lineaSeleccionada}');
    }

    // Muestra la lista de recogida
    return ListView.builder(
      padding: EdgeInsets.all(16),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _recogidaPeticiones.length,
      itemBuilder: (context, index) {
        final recogida = _recogidaPeticiones[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              'Línea: ${recogida['linea'] ?? ''}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Estado Recogida: ${recogida['status_recogida'] ?? ''}\nHora: ${recogida['timeHour'] ?? ''}',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitudes Activas: ${widget.lineaSeleccionada ?? ""}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    _fetchPeticiones();
                    _fetchRecogidaPeticiones();
                  },
                ),
              ],
            ),
          ),
          // Lista de peticiones (curso-products)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Sección de Peticiones (estado SOLICITADO)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Peticiones (SOLICITADO)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                  _buildPeticionesSection(),

                  // Sección de Recogidas
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Solicitudes de Recogida',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                  _buildRecogidaSection(),
                ],
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
    super.dispose();
  }
}
