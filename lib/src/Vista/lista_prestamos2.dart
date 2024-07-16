import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PruebasPrestamosPage extends StatefulWidget {
  @override
  _PruebasPrestamosPageState createState() => _PruebasPrestamosPageState();
}

class _PruebasPrestamosPageState extends State<PruebasPrestamosPage> {
  // Variable para almacenar el día de la semana seleccionado
  int? selectedDayOfWeek;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Préstamos'),
        actions: [
          // Dropdown para seleccionar día de la semana
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

              // Obtener la fecha y convertirla a DateTime
              DateTime fecha = data['Fecha'].toDate();

              // Aplicar filtro si hay un día de la semana seleccionado
              if (selectedDayOfWeek == null ||
                  fecha.weekday == selectedDayOfWeek) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: _buscarDatosCliente(data['CedulaCliente'].toString()),
                  builder: (BuildContext context,
                      AsyncSnapshot<Map<String, dynamic>> clienteSnapshot) {
                    if (clienteSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox
                          .shrink(); // Puedes mostrar un widget de carga aquí si es necesario
                    }
                    if (clienteSnapshot.hasError || !clienteSnapshot.hasData) {
                      return const SizedBox
                          .shrink(); // Manejar errores si es necesario
                    }
                    String nombreCliente = clienteSnapshot.data!['Nombre'];
                    String trabajoCliente =
                        clienteSnapshot.data!['Trabajo'] ?? '';

                    return _buildPrestamoCard(
                        data, document.id, nombreCliente, trabajoCliente);
                  },
                );
              } else {
                // Si no cumple la condición de filtro, retornar un contenedor vacío o null
                return Container();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildPrestamoCard(Map<String, dynamic> data, String prestamoId,
      String nombreCliente, String trabajoCliente) {
    DateTime fecha = data['Fecha'].toDate();
    String tipoPago = data['TipoPago'];
    String formaPago = data['FormaPago'];
    double valorIntereses = data['ValorIntereses'].toDouble();
    double abonoCapital = data['AbonoCapital'].toDouble();
    double valorTotal = data['ValorTotal'].toDouble();
    List<dynamic> pagosList = data['Pagos'] ?? [];
    List<double> pagos = pagosList
        .map((pago) => pago is int ? pago.toDouble() : pago as double)
        .toList();
    double deuda = data['Deuda'] != null ? data['Deuda'].toDouble() : 0;
    double valorPrestamo = data['ValorPrestamo'].toDouble();

    // Verificar si el préstamo está inactivo
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
                            prestamoId,
                            formaPago,
                            valorIntereses,
                            tipoPago,
                            abonoCapital,
                            valorTotal,
                            pagos,
                            deuda,
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
                              context, prestamoId, valorPrestamo);
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
    String tipoPago,
    double abonoCapital,
    double valorTotal,
    List<double> pagos,
    double deudaExistente,
  ) {
    double valorCuota = 0.0;

    // Calcular la cuota según el tipo de pago seleccionado
    if (tipoPago == 'Libre') {
      valorCuota = valorIntereses / _getCantidadCuotas(formaPago);
    } else if (tipoPago == 'Interes+Capital') {
      valorCuota =
          (valorIntereses / _getCantidadCuotas(formaPago)) + abonoCapital;
    }

    TextEditingController pagoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
                decoration: const InputDecoration(labelText: 'Pago realizado'),
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

                  // Realizar la resta del pago realizado del valor total si es 'Interes+Capital'
                  double nuevoValorTotal = valorTotal;
                  if (tipoPago == 'Interes+Capital') {
                    nuevoValorTotal -= pagoRealizado;
                  }

                  double nuevaDeuda =
                      _calcularDeuda(nuevasCuotas, valorCuota, deudaExistente);

                  // Actualizar Firestore con los nuevos pagos y la nueva deuda
                  List<double> nuevosPagos = List.from(pagos)
                    ..addAll(nuevasCuotas);

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
        return 0;
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: PruebasPrestamosPage(),
  ));
}
