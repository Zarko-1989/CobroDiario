import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    home: PruebasPrestamosPage(userId: 'USER_ID_AQUI'),
  ));
}

class PruebasPrestamosPage extends StatefulWidget {
  final String userId;
  PruebasPrestamosPage({required this.userId});
  @override
  _PruebasPrestamosPageState createState() => _PruebasPrestamosPageState();
}

class _PruebasPrestamosPageState extends State<PruebasPrestamosPage> {
  int? selectedDayOfWeek;
  late Future<String> _userName;

  @override
  void initState() {
    super.initState();
    _userName = _getUserName(); // Inicialización de _userName en initState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Préstamos'),
        actions: [
          DropdownButton<int>(
            value: selectedDayOfWeek,
            onChanged: (value) {
              setState(() {
                selectedDayOfWeek = value;
              });
            },
            items: [
              DropdownMenuItem(
                value: null,
                child: const Text('Todos'),
              ),
              DropdownMenuItem(
                value: DateTime.monday,
                child: const Text('Lunes'),
              ),
              DropdownMenuItem(
                value: DateTime.tuesday,
                child: const Text('Martes'),
              ),
              DropdownMenuItem(
                value: DateTime.wednesday,
                child: const Text('Miércoles'),
              ),
              DropdownMenuItem(
                value: DateTime.thursday,
                child: const Text('Jueves'),
              ),
              DropdownMenuItem(
                value: DateTime.friday,
                child: const Text('Viernes'),
              ),
              DropdownMenuItem(
                value: DateTime.saturday,
                child: const Text('Sábado'),
              ),
              DropdownMenuItem(
                value: DateTime.sunday,
                child: const Text('Domingo'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Prestamos').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay préstamos disponibles'),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;

              DateTime fecha = data['Fecha'].toDate();

              if (selectedDayOfWeek == null ||
                  fecha.weekday == selectedDayOfWeek) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: _buscarDatosCliente(data['CedulaCliente'].toString()),
                  builder: (BuildContext context,
                      AsyncSnapshot<Map<String, dynamic>> clienteSnapshot) {
                    if (clienteSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (clienteSnapshot.hasError || !clienteSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    String nombreCliente = clienteSnapshot.data!['Nombre'];
                    String trabajoCliente =
                        clienteSnapshot.data!['Trabajo'] ?? '';

                    return _buildPrestamoCard(
                      document,
                      data,
                      nombreCliente,
                      trabajoCliente,
                    );
                  },
                );
              } else {
                return Container();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildPrestamoCard(
    DocumentSnapshot document,
    Map<String, dynamic> data,
    String nombreCliente,
    String trabajoCliente,
  ) {
    DateTime fecha = data['Fecha'].toDate();
    String tipoPago = data['TipoPago'];
    String formaPago = data['FormaPago'];
    double valorIntereses = data['ValorIntereses'].toDouble();
    double valorTotal = data['ValorTotal'].toDouble();
    List<dynamic> pagosList = data['Pagos'] ?? [];
    List<double> pagos = pagosList
        .map((pago) => pago is int ? pago.toDouble() : pago as double)
        .toList();
    double deuda = data['Deuda'] != null ? data['Deuda'].toDouble() : 0;
    double valorPrestamo = data['ValorPrestamo'].toDouble();
    double valorCuota = calcularValorCuota(data);

    bool estaInactivo = valorTotal == 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nombre Cliente: $nombreCliente',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Trabajo: $trabajoCliente',
            ),
            const SizedBox(height: 8),
            Text(
              'Cédula Cliente: ${data['CedulaCliente']}',
            ),
            const SizedBox(height: 8),
            Text('Valor Cuota: ${valorCuota.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text('Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}'),
            Text('Forma de Pago: $formaPago'),
            const SizedBox(height: 8),
            Text('Valor Préstamo: ${valorPrestamo.toStringAsFixed(0)}'),
            Text('Valor Intereses: ${valorIntereses.toStringAsFixed(0)}'),
            if (deuda > 0) Text('Deuda: ${deuda.toStringAsFixed(0)}'),
            if (estaInactivo)
              Text('Estado: Inactivo', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            const Text('Pagos realizados:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (pagos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: pagos.asMap().entries.map((entry) {
                  final numeroCuota = entry.key + 1;
                  final pago = entry.value;
                  return Text('Cuota $numeroCuota: ${pago.toStringAsFixed(0)}');
                }).toList(),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: estaInactivo
                      ? null
                      : () {
                          _mostrarDialogoIngresarCuotas(
                            context,
                            document.id,
                            data['FormaPago'],
                            valorIntereses,
                            data['TipoPago'],
                            valorTotal,
                            pagos,
                            data['Deuda'] != null
                                ? data['Deuda'].toDouble()
                                : 0,
                            widget
                                .userId, // Pasa el userId actual como parámetro
                          );
                        },
                  child: const Text('Ingresar Cuotas'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: estaInactivo
                      ? null
                      : () {
                          _mostrarDialogoAbonos(
                            context,
                            document.id,
                            valorPrestamo,
                          );
                        },
                  child: const Text('Abonos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _buscarDatosCliente(String cedulaCliente) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('Clientes')
        .where('Cedula', isEqualTo: cedulaCliente)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data() as Map<String, dynamic>;
    } else {
      return {}; // Manejar el caso donde no se encuentra el cliente
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: abonoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Valor del Abono'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                double abono = double.tryParse(abonoController.text) ?? 0;
                if (abono > 0) {
                  double nuevoValorPrestamo = valorPrestamo - abono;
                  double nuevoValorIntereses = nuevoValorPrestamo * 0.2;

                  if (nuevoValorPrestamo <= 0) {
                    nuevoValorPrestamo = 0;
                    nuevoValorIntereses = 0;
                    FirebaseFirestore.instance
                        .collection('Prestamos')
                        .doc(prestamoId)
                        .update({
                      'ValorPrestamo': nuevoValorPrestamo,
                      'ValorIntereses': nuevoValorIntereses,
                      'Estado': 'Inactivo',
                    });
                  } else {
                    FirebaseFirestore.instance
                        .collection('Prestamos')
                        .doc(prestamoId)
                        .update({
                      'ValorPrestamo': nuevoValorPrestamo,
                      'ValorIntereses': nuevoValorIntereses,
                    });
                  }
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

  double calcularValorCuota(Map<String, dynamic> data) {
    double valorIntereses = data['ValorIntereses'].toDouble();
    double valorPrestamo = data['ValorPrestamo'].toDouble();
    String tipoPago = data['TipoPago'];
    String formaPago = data['FormaPago'];

    double valorCuota = 0.0;

    if (tipoPago == 'Libre') {
      valorCuota = valorIntereses / _getCantidadCuotas(formaPago);
    } else if (tipoPago == 'Interes+Capital') {
      valorCuota = (valorIntereses / _getCantidadCuotas(formaPago));
    }

    return valorCuota;
  }

  void _mostrarDialogoIngresarCuotas(
    BuildContext context,
    String prestamoId,
    String formaPago,
    double valorIntereses,
    String tipoPago,
    double valorTotal,
    List<double> pagos,
    double deudaExistente,
    String userId, // Recibe el userId como parámetro
  ) {
    double valorCuota = 0.0;

    if (tipoPago == 'Libre') {
      valorCuota = valorIntereses / _getCantidadCuotas(formaPago);
    } else if (tipoPago == 'Interes+Capital') {
      valorCuota = (valorIntereses / _getCantidadCuotas(formaPago));
    }

    TextEditingController pagoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<String>(
          future: _userName, // Obtener el nombre de usuario
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: const Text('Ingresar Cuotas Pagadas'),
                content: const CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return AlertDialog(
                title: const Text('Ingresar Cuotas Pagadas'),
                content: const Text('Error obteniendo el nombre de usuario'),
              );
            }

            String userName = snapshot.data!;

            return AlertDialog(
              title: const Text('Ingresar Cuotas Pagadas'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Cuota: ${valorCuota.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pagoController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Pago realizado'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    double pagoRealizado =
                        double.tryParse(pagoController.text) ?? 0;

                    if (pagoRealizado > 0) {
                      List<double> nuevasCuotas = [pagoRealizado];

                      Map<String, dynamic> registroPago = {
                        'UsuarioId': userId,
                        'UsuarioNombre': userName,
                        'Fecha': Timestamp.now(),
                        'Monto': pagoRealizado,
                        'Hora': DateFormat('HH:mm:ss').format(DateTime.now()),
                      };

                      double nuevoValorTotal = valorTotal;
                      if (tipoPago == 'Interes+Capital') {
                        nuevoValorTotal -= pagoRealizado;
                      }

                      double nuevaDeuda = _calcularDeuda(
                          nuevasCuotas, valorCuota, deudaExistente);

                      List<double> nuevosPagos = List.from(pagos)
                        ..addAll(nuevasCuotas);

                      // Actualizar datos del préstamo
                      if (nuevoValorTotal <= 0) {
                        nuevoValorTotal = 0;
                        FirebaseFirestore.instance
                            .collection('Prestamos')
                            .doc(prestamoId)
                            .update({
                          'Pagos': nuevosPagos,
                          'Deuda': nuevaDeuda,
                          'ValorTotal': nuevoValorTotal,
                          'Estado': 'Inactivo',
                        });
                      } else {
                        FirebaseFirestore.instance
                            .collection('Prestamos')
                            .doc(prestamoId)
                            .update({
                          'Pagos': nuevosPagos,
                          'Deuda': nuevaDeuda,
                          'ValorTotal': nuevoValorTotal,
                        });
                      }

                      // Registrar el pago en la colección RegistrosPagos
                      FirebaseFirestore.instance
                          .collection('RegistrosPagos')
                          .add(registroPago);

                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _getUserName() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      var data = userDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('Nombre')) {
        return data['Nombre'];
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
    return 'Usuario';
  }

  double _calcularDeuda(
      List<double> cuotas, double valorCuota, double deudaExistente) {
    double deudaAcumulada = deudaExistente;

    for (double pago in cuotas) {
      if (pago < valorCuota) {
        deudaAcumulada += valorCuota - pago;
      } else if (pago > valorCuota) {
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
      case 'Diaria':
        return 30;
      case '20 Dias':
        return 20;
      case '24 Dias':
        return 24;
      case 'Semanal':
        return 4;
      case 'Quincenal':
        return 2;
      case 'Mensual':
        return 1;
      default:
        return 1;
    }
  }
}
