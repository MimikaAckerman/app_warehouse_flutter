import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PeticionMaterialOperarioScreen extends StatefulWidget {
  final Function(String?) onLineaSelected;

  const PeticionMaterialOperarioScreen({
    Key? key,
    required this.onLineaSelected,
  }) : super(key: key);

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

  String? _selectedLinea;
  String? _selectedDenominacion;
  String? _selectedReferenciaSolida;
  String? _selectedMateriaPrima;
  String? _selectedMateriaPrimaId;

  bool _isLoading = true;
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
      });
    } catch (e) {
      setState(() {
        _successMessage = "Error al enviar la petición";
      });
    }
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDropdown("Línea", _lineas, _selectedLinea, (value) {
                    setState(() {
                      _selectedLinea = value;
                      _selectedDenominacion = null;
                      _selectedReferenciaSolida = null;
                      _selectedMateriaPrima = null;
                      _selectedMateriaPrimaId = null;
                      _denominaciones = _data
                          .where((item) => item['linea'] == value)
                          .map((item) => item['denominacion'].toString())
                          .toSet()
                          .toList();
                    });
                    widget
                        .onLineaSelected(value); // Notificar el cambio de línea
                  }),
                  _buildDropdown(
                      "Denominación", _denominaciones, _selectedDenominacion,
                      (value) {
                    setState(() {
                      _selectedDenominacion = value;
                      _selectedReferenciaSolida = null;
                      _selectedMateriaPrima = null;
                      _selectedMateriaPrimaId = null;
                      _referenciasSolidas = _data
                          .where((item) =>
                              item['linea'] == _selectedLinea &&
                              item['denominacion'] == value)
                          .map((item) => item['no'].toString())
                          .toSet()
                          .toList();
                    });
                  }),
                  _buildDropdown("Referencia Sólida", _referenciasSolidas,
                      _selectedReferenciaSolida, (value) {
                    setState(() {
                      _selectedReferenciaSolida = value;
                      _selectedMateriaPrima = null;
                      _selectedMateriaPrimaId = null;
                      _materiasPrimas = _data
                          .where((item) =>
                              item['linea'] == _selectedLinea &&
                              item['denominacion'] == _selectedDenominacion &&
                              item['no'] == value)
                          .map((item) => item['refpt'].toString())
                          .toSet()
                          .toList();
                    });
                  }),
                  _buildDropdown(
                      "Materia Prima", _materiasPrimas, _selectedMateriaPrima,
                      (value) {
                    setState(() {
                      _selectedMateriaPrima = value;
                      _selectedMateriaPrimaId = _data.firstWhere(
                        (item) => item['refpt'] == value,
                        orElse: () => {},
                      )['id'];
                    });
                  }),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedMateriaPrimaId != null
                        ? _enviarSolicitud
                        : null,
                    child: Text("SOLICITAR"),
                  ),
                  if (_successMessage != null)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: _successMessage!.contains("Error")
                              ? Colors.red
                              : Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
