import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PeticionMaterialOperarioScreen extends StatefulWidget {
  @override
  _PeticionMaterialOperarioScreenState createState() =>
      _PeticionMaterialOperarioScreenState();
}

class _PeticionMaterialOperarioScreenState
    extends State<PeticionMaterialOperarioScreen> {
  List<Map<String, dynamic>> _data = [];
  List<String> _lineas = [];
  List<String> _denominaciones = [];
  List<String> _referenciasSolidas = [];
  List<String> _materiasPrimas = [];
  List<dynamic> _solicitudes = [];

  String? _selectedLinea;
  String? _selectedDenominacion;
  String? _selectedReferenciaSolida;
  String? _selectedMateriaPrima;
  String? _selectedMateriaPrimaId;

  bool _isLoading = true;
  bool _isLoadingSolicitudes = false;
  String? _errorSolicitudes;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(
        Uri.parse("https://api-psc-warehouse.azurewebsites.net/lrefs"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawData = jsonDecode(response.body);

        Set<String> lineasUnicas = {};
        for (var item in rawData) {
          if (item.containsKey('linea') && item['linea'] != null) {
            lineasUnicas.add(item['linea'].toString());
          }
        }

        setState(() {
          _data =
              rawData.map((item) => Map<String, dynamic>.from(item)).toList();
          _lineas = lineasUnicas.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSolicitudes() async {
    if (_selectedLinea == null) return;

    setState(() {
      _isLoadingSolicitudes = true;
      _errorSolicitudes = null;
    });

    try {
      final response = await http.get(
        Uri.parse("https://api-psc-warehouse.azurewebsites.net/curso-products"),
      );

      if (response.statusCode == 200) {
        List<dynamic> solicitudes = jsonDecode(response.body);

        List<dynamic> solicitudesFiltradas = solicitudes
            .where((solicitud) => solicitud["linea"] == _selectedLinea)
            .toList();

        setState(() {
          _solicitudes = solicitudesFiltradas;
          _isLoadingSolicitudes = false;
        });
      } else {
        setState(() {
          _errorSolicitudes = "Error al cargar las solicitudes";
          _isLoadingSolicitudes = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorSolicitudes = "Error de conexión con el servidor";
        _isLoadingSolicitudes = false;
      });
    }
  }

  Future<void> _enviarSolicitud() async {
    if (_selectedMateriaPrimaId == null) return;

    String productId = _selectedMateriaPrimaId!;
    String url =
        "https://api-psc-warehouse.azurewebsites.net/product/$productId/status/SOLICITADO";

    try {
      await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({}),
      );

      setState(() {
        _successMessage = "Solicitado correctamente";
      });

      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _successMessage = null;
        });
        _fetchSolicitudes(); // Actualizar solicitudes después de enviar una nueva
      });
    } catch (e) {
      setState(() {
        _successMessage = "Error al enviar la petición";
      });
    }
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      isExpanded: true,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis, softWrap: false),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
          border: OutlineInputBorder(), hintText: "Seleccione $label"),
    );
  }

  Widget _buildSolicitudesSection() {
    return _isLoadingSolicitudes
        ? Center(child: CircularProgressIndicator())
        : _errorSolicitudes != null
            ? Center(
                child: Text(
                  _errorSolicitudes!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
            : _solicitudes.isEmpty
                ? Center(
                    child: Text("No hay solicitudes para esta línea."),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _solicitudes.length,
                    itemBuilder: (context, index) {
                      final solicitud = _solicitudes[index];

                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                              "Materia Prima: ${solicitud["materia_prima"]}"),
                          subtitle: Text("Estado: ${solicitud["estado"]}"),
                          trailing: Text(
                            solicitud["fecha"],
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Petición de Material - Operario")),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown("Seleccione una línea", _lineas, _selectedLinea,
                  (value) {
                setState(() {
                  _selectedLinea = value;
                  _fetchSolicitudes(); // Cargar solicitudes de la línea seleccionada
                });
              }),
              _buildDropdown("Seleccione una denominación", _denominaciones,
                  _selectedDenominacion, (value) {
                setState(() {
                  _selectedDenominacion = value;
                });
              }),
              _buildDropdown("Referencia Sólida (No)", _referenciasSolidas,
                  _selectedReferenciaSolida, (value) {
                setState(() {
                  _selectedReferenciaSolida = value;
                });
              }),
              _buildDropdown(
                  "Materia Prima", _materiasPrimas, _selectedMateriaPrima,
                  (value) {
                setState(() {
                  _selectedMateriaPrima = value;
                });
              }),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _selectedMateriaPrimaId != null ? _enviarSolicitud : null,
                child: Text("SOLICITAR"),
              ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ),
              SizedBox(height: 20),
              Text("Solicitudes realizadas:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildSolicitudesSection(),
            ],
          ),
        ),
      ),
    );
  }
}
