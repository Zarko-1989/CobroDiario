import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/FuncionesPrestamos/abonos_service.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/FuncionesPrestamos/deudas_service.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/FuncionesPrestamos/pagos_service.dart';

class ListaPrestamosScreen extends StatefulWidget {
  @override
  _ListaPrestamosScreenState createState() => _ListaPrestamosScreenState();
}

class _ListaPrestamosScreenState extends State<ListaPrestamosScreen> {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _buscarDatosCliente(
      String cedulaCliente) async {
    try {
      QuerySnapshot querySnapshot = await _firebase
          .collection('Clientes')
          .where('Cedula', isEqualTo: cedulaCliente)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      print("Error al buscar datos del cliente: $e");
      return null;
    }
  }

  Future<double?> _mostrarDialogoAbono(BuildContext context) async {
    final TextEditingController _controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Abonar'),
          content: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto a abonar',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            ElevatedButton(
              child: Text('Abonar'),
              onPressed: () {
                final amount = double.tryParse(_controller.text);
                Navigator.of(context)
                    .pop(amount); // Pasa el valor al resultado del diálogo
              },
            ),
          ],
        );
      },
    );
  }

  Future<double?> _mostrarDialogoPagoDeuda(BuildContext context) async {
    final TextEditingController _controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pagar Deuda'),
          content: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto a pagar',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            ElevatedButton(
              child: Text('Pagar'),
              onPressed: () {
                final amount = double.tryParse(_controller.text);
                Navigator.of(context)
                    .pop(amount); // Pasa el valor al resultado del diálogo
              },
            ),
          ],
        );
      },
    );
  }

  Future<double?> _mostrarDialogoCuota(BuildContext context) async {
    final TextEditingController _controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pagar Cuota'),
          content: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto de la cuota',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            ElevatedButton(
              child: Text('Pagar'),
              onPressed: () {
                final amount = double.tryParse(_controller.text);
                Navigator.of(context)
                    .pop(amount); // Pasa el valor al resultado del diálogo
              },
            ),
          ],
        );
      },
    );
  }

  void _abonar(String prestamoId, double abono, String cedulaCliente) {
    AbonosService().abonar(context, prestamoId, abono, cedulaCliente);
  }

  void _pagarDeuda(String prestamoId, double monto) {
    DeudasService().pagarDeuda(context, prestamoId, monto);
  }

  void _pagarCuota(String prestamoId, double cuota) {
    PagosService().pagarCuota(context, prestamoId, cuota);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Préstamos'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebase.collection('Prestamos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay préstamos disponibles.'));
          }

          final prestamos = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: prestamos.length,
            itemBuilder: (context, index) {
              final prestamo = prestamos[index].data() as Map<String, dynamic>;
              final cedula = prestamo['Cedula']?.toString() ?? 'No disponible';
              final prestamoId = prestamos[index].id;
              final valorPrestamo =
                  (prestamo['Valor_Prestamo'] as num?)?.toStringAsFixed(0) ??
                      '0.00';
              final interes = (prestamo['Interes_Incrementado'] as num?)
                      ?.toStringAsFixed(0) ??
                  '0.00';
              final cuotaAproximada =
                  (prestamo['Cuota_Aproximada'] as num?)?.toStringAsFixed(0) ??
                      '0.00';
              final valorTotal =
                  (prestamo['ValorTotal'] as num?)?.toStringAsFixed(0) ??
                      '0.00';
              final saldoPendiente =
                  (prestamo['ValorTotal'] as num?)?.toDouble() ?? 0;
              final numCuotas =
                  (prestamo['Numero_Cuotas'] as num?)?.toDouble() ?? 0;
              final estado = prestamo['Estado'] ?? 'Activo';
              final deudaPendiente =
                  (prestamo['Deuda_Pendiente'] as num?)?.toDouble() ?? 0;
              final valorIntereses =
                  (prestamo['ValorIntereses'] as num?)?.toDouble() ?? 0;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _buscarDatosCliente(cedula),
                builder: (context, clientSnapshot) {
                  final clienteData = clientSnapshot.data;
                  final nombreCliente = clienteData?['Nombre'] ?? 'Desconocido';
                  final trabajoCliente =
                      clienteData?['Trabajo'] ?? 'No disponible';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 6.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente: $nombreCliente',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.teal)),
                          SizedBox(height: 8.0),
                          Text('Cédula: $cedula'),
                          Text('Trabajo: $trabajoCliente'),
                          SizedBox(height: 8.0),
                          Text('Valor Préstamo: \$${valorPrestamo}',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                          Text('Interés: \$${interes}',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                          Text('Cuota Aproximada: \$${cuotaAproximada}',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                          Text('Valor Total: \$${valorTotal}',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 8.0),
                          Text(
                              'Saldo Pendiente: \$${saldoPendiente.toStringAsFixed(0)}'),
                          Text(
                              'Número de Cuotas: ${numCuotas.toStringAsFixed(0)}'),
                          Text('Estado: $estado',
                              style: TextStyle(
                                  color: estado == 'Activo'
                                      ? Colors.blue
                                      : Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              'Deuda Pendiente: \$${deudaPendiente.toStringAsFixed(0)}'),
                          Text(
                              'Valor Intereses: \$${valorIntereses.toStringAsFixed(0)}'),
                          SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final abono =
                                      await _mostrarDialogoAbono(context);
                                  if (abono != null) {
                                    _abonar(prestamoId, abono, cedula);
                                  }
                                },
                                icon: Icon(Icons.add),
                                label: Text('Abonar'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                              ),
                              if (deudaPendiente >
                                  0) // Aquí se añade la condición
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final montoDeuda =
                                        await _mostrarDialogoPagoDeuda(context);
                                    if (montoDeuda != null) {
                                      _pagarDeuda(prestamoId, montoDeuda);
                                    }
                                  },
                                  icon: Icon(Icons.payment),
                                  label: Text('Pagar Deuda'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final cuota =
                                      await _mostrarDialogoCuota(context);
                                  if (cuota != null) {
                                    _pagarCuota(prestamoId, cuota);
                                  }
                                },
                                icon: Icon(Icons.attach_money),
                                label: Text('Pagar Cuota'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
