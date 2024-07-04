import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PruebasPrestamosPage extends StatefulWidget {
  @override
  _PruebasPrestamosPageState createState() => _PruebasPrestamosPageState();
}

class _PruebasPrestamosPageState extends State<PruebasPrestamosPage> {
  int _selectedFilter =
      1; // 1: Todos los préstamos, 2: Préstamos del día actual
  late DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Préstamos'),
        backgroundColor: Colors.blue,
        actions: [
          DropdownButton<int>(
            value: _selectedFilter,
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
            },
            items: [
              DropdownMenuItem(
                value: 1,
                child: Text('Todos los préstamos'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text('Préstamos de Hoy'),
              ),
            ],
          ),
          if (_selectedFilter == 2)
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                _selectDate(context);
              },
            ),
        ],
      ),
      body: StreamBuilder(
        stream: _selectedFilter == 1
            ? FirebaseFirestore.instance.collection('Prestamos').snapshots()
            : FirebaseFirestore.instance
                .collection('Prestamos')
                .where('DiaSemana', isEqualTo: _selectedDate.weekday)
                .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No hay préstamos disponibles',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return FutureBuilder(
                future: _getClienteInfo(data['CedulaCliente']
                    .toString()), // Convert CedulaCliente to String
                builder: (BuildContext context,
                    AsyncSnapshot<Map<String, String>> clienteSnapshot) {
                  if (clienteSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (clienteSnapshot.hasError || !clienteSnapshot.hasData) {
                    return Center(
                      child: Text(
                        'Error al cargar la información del cliente',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    );
                  }
                  Map<String, String> clienteInfo = clienteSnapshot.data!;
                  String nombreCliente = clienteInfo['Nombre'] ?? 'Desconocido';
                  String trabajoCliente =
                      clienteInfo['Trabajo'] ?? 'Desconocido';
                  return _buildPrestamoCard(
                      data, document.id, nombreCliente, trabajoCliente);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, String>> _getClienteInfo(String cedulaCliente) async {
    try {
      var clienteSnapshot = await FirebaseFirestore.instance
          .collection('Clientes')
          .where('Cedula', isEqualTo: cedulaCliente)
          .limit(1)
          .get();
      if (clienteSnapshot.docs.isNotEmpty) {
        var clienteData = clienteSnapshot.docs.first.data();
        return {
          'Nombre': clienteData['Nombre'] as String,
          'Trabajo': clienteData['Trabajo'] as String,
        };
      }
    } catch (e) {
      print('Error al obtener la información del cliente: $e');
    }
    return {};
  }

  Widget _buildPrestamoCard(Map<String, dynamic> data, String prestamoId,
      String nombreCliente, String trabajoCliente) {
    DateTime fecha = data['Fecha'].toDate();
    String formaPago = data['FormaPago'];
    double valorIntereses = data['ValorIntereses'].toDouble();
    List<dynamic> pagosList = data['Pagos'] ?? [];
    List<double> pagos = pagosList
        .map((pago) => pago is int ? pago.toDouble() : pago as double)
        .toList();
    double deuda = data['Deuda'] != null ? data['Deuda'].toDouble() : 0;
    double valorPrestamo = data['ValorPrestamo'].toDouble();
    double abonoCapital =
        data['AbonoCapital'] != null ? data['AbonoCapital'].toDouble() : 0;

    int? diaSemana = data['DiaSemana'] as int?;
    String diaSemanaTexto = _getDiaSemanaText(diaSemana);

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Cliente: $nombreCliente (Cédula: ${data['CedulaCliente']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trabajo: $trabajoCliente'),
                SizedBox(height: 8),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                Text('Forma de Pago: $formaPago'),
                Text('Valor Intereses: ${valorIntereses.toStringAsFixed(0)}'),
                Text('Valor Préstamo: ${valorPrestamo.toStringAsFixed(0)}'),
                Text('Abono Capital: ${abonoCapital.toStringAsFixed(0)}'),
                if (deuda > 0) Text('Deuda: ${deuda.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                const Text('Pagos realizados:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (pagos.isNotEmpty)
                  ...pagos.asMap().entries.map(
                    (entry) {
                      final numeroCuota = entry.key + 1;
                      final pago = entry.value;
                      return Text(
                          'Cuota $numeroCuota: ${pago.toStringAsFixed(0)}');
                    },
                  ),
                if (diaSemana != null)
                  Text('Día de la semana: $diaSemanaTexto'),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  _mostrarDialogoIngresarCuotas(
                      context,
                      prestamoId,
                      formaPago,
                      valorIntereses,
                      pagos,
                      deuda,
                      data['TipoPago'],
                      data['ValorTotal'],
                      abonoCapital);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Ingresar Cuotas',
                    style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _mostrarDialogoAbonos(context, prestamoId, valorPrestamo);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Abonos', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  String _getDiaSemanaText(int? diaSemana) {
    if (diaSemana != null) {
      switch (diaSemana) {
        case 1:
          return 'Lunes';
        case 2:
          return 'Martes';
        case 3:
          return 'Miércoles';
        case 4:
          return 'Jueves';
        case 5:
          return 'Viernes';
        case 6:
          return 'Sábado';
        case 7:
          return 'Domingo';
        default:
          return 'Desconocido';
      }
    } else {
      return 'Desconocido';
    }
  }

  void _mostrarDialogoAbonos(
      BuildContext context, String prestamoId, double valorPrestamo) {
    TextEditingController abonoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ingresar Abono'),
          content: TextField(
            controller: abonoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor del Abono'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                double abono = double.tryParse(abonoController.text) ?? 0;
                if (abono > 0) {
                  double nuevoValorPrestamo = valorPrestamo - abono;
                  double nuevoValorIntereses = nuevoValorPrestamo * 0.2;

                  FirebaseFirestore.instance
                      .collection('Prestamos')
                      .doc(prestamoId)
                      .update({
                    'ValorPrestamo': nuevoValorPrestamo,
                    'ValorIntereses': nuevoValorIntereses,
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoIngresarCuotas(
      BuildContext context,
      String prestamoId,
      String formaPago,
      double valorIntereses,
      List<double> pagos,
      double deudaExistente,
      String tipoPago,
      double valorTotal,
      double abonoCapitalFromDB) {
    int cantidadCuotas = _getCantidadCuotas(formaPago);
    double cuotaBase = valorIntereses / cantidadCuotas;

    TextEditingController pagoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ingresar Cuotas Pagadas'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: pagoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Valor del Abono Capital'),
                ),
                if (tipoPago == 'Interes+Capital')
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: pagoController,
                    builder: (context, value, child) {
                      double abonoCapital = double.tryParse(value.text) ?? 0;
                      double cuotaTotal = cuotaBase + abonoCapital;
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                            'Cuota Total: ${cuotaTotal.toStringAsFixed(2)}'),
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                double abonoCapitalEntered =
                    double.tryParse(pagoController.text) ?? 0;
                double cuotaTotal =
                    cuotaBase + abonoCapitalFromDB + abonoCapitalEntered;

                if (cuotaTotal > 0) {
                  List<double> nuevasCuotas = [...pagos, cuotaTotal];
                  double nuevaDeuda =
                      _calcularDeuda(nuevasCuotas, cuotaBase, deudaExistente);
                  double nuevoValorTotal = valorTotal - cuotaTotal;

                  Map<String, dynamic> updateData = {
                    'Pagos': FieldValue.arrayUnion([cuotaTotal]),
                    'Deuda': nuevaDeuda,
                    'ValorTotal': nuevoValorTotal,
                  };

                  if (nuevoValorTotal <= 0) {
                    updateData['inactivo'] = true;
                    updateData['ValorTotal'] =
                        0; // Asegurarse de que ValorTotal no sea menor a 0
                  }

                  // Actualizar en Firestore
                  await FirebaseFirestore.instance
                      .collection('Prestamos')
                      .doc(prestamoId)
                      .update(updateData);

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  double _calcularDeuda(
      List<double> cuotas, double valorCuota, double deudaExistente) {
    double deudaAcumulada = deudaExistente;

    for (double pago in cuotas) {
      if (pago < valorCuota) {
        deudaAcumulada += valorCuota - pago;
      } else {
        deudaAcumulada -= (pago - valorCuota);
      }

      if (deudaAcumulada < 0) {
        deudaAcumulada = 0;
      }
    }

    return deudaAcumulada;
  }

  int _getCantidadCuotas(String formaPago) {
    switch (formaPago) {
      case 'Diario':
        return 30;
      case 'Semanal':
        return 4;
      case 'Quincenal':
        return 2;
      case 'Mensual':
        return 1;
      default:
        return 0;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void main() {
    runApp(MaterialApp(
      home: PruebasPrestamosPage(),
    ));
  }
}
