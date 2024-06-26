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
              return _buildPrestamoCard(data, document.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildPrestamoCard(Map<String, dynamic> data, String prestamoId) {
    DateTime fecha = data['Fecha'].toDate();
    String formaPago = data['FormaPago'];
    double valorIntereses = data['ValorIntereses'].toDouble();
    List<dynamic> pagosList = data['Pagos'] ?? [];
    List<double> pagos = pagosList
        .map((pago) => pago is int ? pago.toDouble() : pago as double)
        .toList();
    double deuda = data['Deuda'] != null ? data['Deuda'].toDouble() : 0;
    double valorPrestamo = data['ValorPrestamo'].toDouble();

    int? diaSemana = data['DiaSemana'] as int?;
    String diaSemanaTexto = _getDiaSemanaText(diaSemana);

    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Cédula Cliente: ${data['CedulaCliente']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                Text('Forma de Pago: $formaPago'),
                Text('Valor Intereses: ${valorIntereses.toStringAsFixed(0)}'),
                Text('Valor Préstamo: ${valorPrestamo.toStringAsFixed(0)}'),
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
                  _mostrarDialogoIngresarCuotas(context, prestamoId, formaPago,
                      valorIntereses, pagos, deuda);
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
      double deudaExistente) {
    int cantidadCuotas = _getCantidadCuotas(formaPago);
    double valorCuota = valorIntereses / cantidadCuotas;

    TextEditingController pagoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ingresar Cuotas Pagadas'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text('Cuota: ${valorCuota.toStringAsFixed(0)}'),
                TextField(
                  controller: pagoController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Pago realizado'),
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
              onPressed: () {
                double pagoRealizado =
                    double.tryParse(pagoController.text) ?? 0;

                if (pagoRealizado > 0) {
                  List<double> nuevasCuotas = [pagoRealizado];
                  double nuevaDeuda =
                      _calcularDeuda(nuevasCuotas, valorCuota, deudaExistente);

                  FirebaseFirestore.instance
                      .collection('Prestamos')
                      .doc(prestamoId)
                      .update({
                    'Pagos': FieldValue.arrayUnion(nuevasCuotas),
                    'Deuda': nuevaDeuda,
                  });

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
