import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ListaPrestamosScreen extends StatefulWidget {
  final String userId;

  ListaPrestamosScreen({required this.userId});

  @override
  _ListaPrestamosScreenState createState() => _ListaPrestamosScreenState();
}

class _ListaPrestamosScreenState extends State<ListaPrestamosScreen> {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final TextEditingController _abonoController = TextEditingController();
  final TextEditingController _cuotaController = TextEditingController();
  final TextEditingController _pagoDeudaController = TextEditingController();

  Future<void> _abonar(
      String prestamoId, double abono, String cedulaCliente) async {
    try {
      // Referencia al documento del préstamo
      DocumentReference prestamoRef =
          _firebase.collection('Prestamos').doc(prestamoId);
      DocumentSnapshot prestamoDoc = await prestamoRef.get();

      if (prestamoDoc.exists) {
        final data = prestamoDoc.data() as Map<String, dynamic>;
        final saldoPendiente = (data['ValorTotal'] as num?)?.toDouble() ?? 0;
        final numCuotas = (data['Numero_Cuotas'] as num?)?.toDouble() ?? 0;

        final nuevoSaldoPendiente = saldoPendiente - abono;

        if (nuevoSaldoPendiente < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('El abono excede el saldo pendiente')),
          );
          return;
        }

        double nuevaCuotaAproximada = 0;
        if (numCuotas > 0) {
          nuevaCuotaAproximada = nuevoSaldoPendiente / numCuotas;
        }

        // Determinar el estado del préstamo
        final estado = nuevoSaldoPendiente <= 0 ? 'Inactivo' : 'Activo';

        // Actualizar el documento del préstamo
        await prestamoRef.update({
          'ValorTotal': nuevoSaldoPendiente,
          'Cuota_Aproximada': nuevaCuotaAproximada,
          'Estado': estado,
        });

        // Obtener el nombre del cliente
        final clienteData = await _buscarDatosCliente(cedulaCliente);
        final clienteNombre = clienteData?['Nombre'] ?? 'Nombre no disponible';

        // Guardar el abono en la colección 'Abonos'
        final abonosRef = FirebaseFirestore.instance.collection('Abonos').doc();
        DateTime fechaActual = DateTime.now();
        final DateFormat formatoFecha = DateFormat('dd/MM/yyyy');
        final String fechaFormateada = formatoFecha.format(fechaActual);

        await abonosRef.set({
          'PrestamoId': prestamoId,
          'Monto': abono,
          'Fecha': fechaFormateada,
          'CedulaCliente': cedulaCliente,
          'NombreCliente': clienteNombre,
        });

        // Guardar el movimiento en la colección 'Movimientos'
        final movimientosRef =
            FirebaseFirestore.instance.collection('Movimientos').doc();
        await movimientosRef.set({
          'PrestamoId': prestamoId,
          'TipoMovimiento': 'Abono',
          'Monto': abono,
          'Fecha': fechaFormateada,
          'CedulaCliente': cedulaCliente,
          'NombreCliente': clienteNombre,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abono registrado exitosamente')),
        );
      }
    } catch (e) {
      print("Error al registrar el abono: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el abono')),
      );
    }
  }

  Future<void> _pagarDeuda(String prestamoId, double monto) async {
    try {
      DocumentReference prestamoRef =
          _firebase.collection('Prestamos').doc(prestamoId);
      DocumentSnapshot prestamoDoc = await prestamoRef.get();

      if (prestamoDoc.exists) {
        final data = prestamoDoc.data() as Map<String, dynamic>;
        final saldoPendiente = (data['ValorTotal'] as num?)?.toDouble() ?? 0;
        final deudaPendiente =
            (data['Deuda_Pendiente'] as num?)?.toDouble() ?? 0;

        final nuevoSaldoPendiente = saldoPendiente - monto;
        var nuevaDeudaPendiente = deudaPendiente - monto;

        if (nuevoSaldoPendiente < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('El pago de deuda excede el saldo pendiente')),
          );
          return;
        }

        if (nuevaDeudaPendiente < 0) {
          nuevaDeudaPendiente = 0;
        }

        final estado = nuevoSaldoPendiente <= 0 ? 'Inactivo' : 'Activo';

        await prestamoRef.update({
          'ValorTotal': nuevoSaldoPendiente,
          'Deuda_Pendiente': nuevaDeudaPendiente,
          'Estado': estado,
        });

        // Guardar el movimiento en la colección 'Movimientos'
        final movimientosRef =
            FirebaseFirestore.instance.collection('Movimientos').doc();
        DateTime fechaActual = DateTime.now();
        final DateFormat formatoFecha = DateFormat('dd/MM/yyyy');
        final String fechaFormateada = formatoFecha.format(fechaActual);

        await movimientosRef.set({
          'PrestamoId': prestamoId,
          'TipoMovimiento': 'Pago de Deuda',
          'Monto': monto,
          'Fecha': fechaFormateada,
          'Estado': estado,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pago de deuda registrado exitosamente')),
        );
      }
    } catch (e) {
      print("Error al pagar deuda: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el pago de deuda')),
      );
    }
  }

  Future<double?> _mostrarDialogoPagoDeuda(BuildContext context) {
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ingresar Pago de Deuda'),
          content: TextField(
            controller: _pagoDeudaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto del pago',
              hintText: 'Ingrese el monto',
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final parsedValue = double.tryParse(value);
                if (parsedValue != null) {
                  _pagoDeudaController.text = parsedValue.toStringAsFixed(0);
                  _pagoDeudaController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _pagoDeudaController.text.length),
                  );
                } else {
                  _pagoDeudaController.text = '';
                }
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancelar
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final monto = double.tryParse(_pagoDeudaController.text);
                Navigator.of(context).pop(monto); // Pasar el monto
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pagarCuota(String prestamoId, double cuota) async {
    try {
      DocumentReference prestamoRef =
          _firebase.collection('Prestamos').doc(prestamoId);
      DocumentSnapshot prestamoDoc = await prestamoRef.get();

      if (prestamoDoc.exists) {
        final data = prestamoDoc.data() as Map<String, dynamic>;
        final cuotaAproximada =
            (data['Cuota_Aproximada'] as num?)?.toDouble() ?? 0;
        final deudaPendiente =
            (data['Deuda_Pendiente'] as num?)?.toDouble() ?? 0;
        final valorTotal = (data['ValorTotal'] as num?)?.toDouble() ?? 0;
        final numCuotas = (data['Numero_Cuotas'] as num?)?.toDouble() ?? 0;

        // Verificar si el pago excede el saldo pendiente
        if (cuota > valorTotal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('El pago de cuota excede el saldo pendiente')),
          );
          return;
        }

        // Calcular el nuevo saldo pendiente y la nueva deuda pendiente
        double nuevoSaldoPendiente = valorTotal - cuota;
        double nuevaDeudaPendiente = deudaPendiente;

        if (cuota < cuotaAproximada) {
          nuevaDeudaPendiente += cuotaAproximada - cuota;
        } else {
          nuevaDeudaPendiente -= cuota - cuotaAproximada;
        }

        if (nuevaDeudaPendiente < 0) {
          nuevaDeudaPendiente = 0;
        }

        // Calcular el nuevo estado
        final nuevasCuotasRestantes = numCuotas - 1;
        final estado = nuevoSaldoPendiente <= 0 ? 'Inactivo' : 'Activo';

        // Actualizar el documento del préstamo
        await prestamoRef.update({
          'ValorTotal': nuevoSaldoPendiente,
          'Numero_Cuotas': nuevasCuotasRestantes,
          'Estado': estado,
          'Deuda_Pendiente': nuevaDeudaPendiente,
        });

        // Guardar el movimiento en la colección 'Movimientos'
        final movimientosRef =
            FirebaseFirestore.instance.collection('Movimientos').doc();
        DateTime fechaActual = DateTime.now();
        final DateFormat formatoFecha = DateFormat('dd/MM/yyyy');
        final String fechaFormateada = formatoFecha.format(fechaActual);

        await movimientosRef.set({
          'PrestamoId': prestamoId,
          'TipoMovimiento': 'Pago de Cuota',
          'Monto': cuota,
          'Fecha': fechaFormateada,
          'Estado': estado,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pago de cuota registrado exitosamente')),
        );
      }
    } catch (e) {
      print("Error al pagar cuota: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el pago de cuota')),
      );
    }
  }

  Future<double?> _mostrarDialogoAbono(BuildContext context) {
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ingresar Abono'),
          content: TextField(
            controller: _abonoController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto del abono',
              hintText: 'Ingrese el monto',
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final parsedValue = double.tryParse(value);
                if (parsedValue != null) {
                  _abonoController.text = parsedValue.toStringAsFixed(0);
                  _abonoController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _abonoController.text.length),
                  );
                } else {
                  _abonoController.text = '';
                }
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancelar
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final abono = double.tryParse(_abonoController.text);
                Navigator.of(context).pop(abono); // Pasar el abono
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<double?> _mostrarDialogoCuota(BuildContext context) {
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ingresar Pago de Cuota'),
          content: TextField(
            controller: _cuotaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto de la cuota',
              hintText: 'Ingrese el monto',
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final parsedValue = double.tryParse(value);
                if (parsedValue != null) {
                  _cuotaController.text = parsedValue.toStringAsFixed(0);
                  _cuotaController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _cuotaController.text.length),
                  );
                } else {
                  _cuotaController.text = '';
                }
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancelar
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final cuota = double.tryParse(_cuotaController.text);
                Navigator.of(context).pop(cuota); // Pasar la cuota
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _buscarDatosCliente(
      String cedulaCliente) async {
    try {
      QuerySnapshot querySnapshot = await _firebase
          .collection('Clientes')
          .where('Cedula', isEqualTo: cedulaCliente)
          .limit(1) // Limitar a 1 para obtener solo el primer documento
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Préstamos'),
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
              final prestamoId = prestamos[index].id;
              final cedula = prestamo['Cedula']?.toString() ?? 'No disponible';
              final valorPrestamo =
                  (prestamo['Valor_Prestamo'] as num?)?.toStringAsFixed(0) ??
                      '0';
              final interes = (prestamo['Interes_Incrementado'] as num?)
                      ?.toStringAsFixed(0) ??
                  '0';
              final cuotaAproximada =
                  (prestamo['Cuota_Aproximada'] as num?)?.toStringAsFixed(0) ??
                      '0';
              final valorTotal =
                  (prestamo['ValorTotal'] as num?)?.toStringAsFixed(0) ?? '0';
              final saldoPendiente =
                  (prestamo['ValorTotal'] as num?)?.toDouble() ?? 0;
              final numCuotas =
                  (prestamo['Numero_Cuotas'] as num?)?.toDouble() ?? 0;
              final estado = prestamo['Estado'] ?? 'Activo';
              final deudaPendiente =
                  (prestamo['Deuda_Pendiente'] as num?)?.toDouble() ?? 0;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _buscarDatosCliente(cedula),
                builder: (context, clientSnapshot) {
                  if (clientSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        title: Text('Cédula: $cedula',
                            style: Theme.of(context).textTheme.titleLarge),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Valor Préstamo: \$${valorPrestamo}',
                                style: Theme.of(context).textTheme.bodyLarge),
                            SizedBox(height: 4.0),
                            Text('Interés: ${interes}%',
                                style: Theme.of(context).textTheme.bodyLarge),
                            SizedBox(height: 4.0),
                            Text('Cuota: \$${cuotaAproximada}',
                                style: Theme.of(context).textTheme.bodyLarge),
                            SizedBox(height: 8.0),
                            Text('Nombre: No disponible',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text('Trabajo: No disponible',
                                style: Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 8.0),
                            Text('Cuotas Pagadas: No disponible',
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text('Cuotas Restantes: No disponible',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Valor Total',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey)),
                            Text('\$${valorTotal}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }

                  final cliente = clientSnapshot.data;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.all(16.0),
                          title: Text('Cédula: $cedula',
                              style: Theme.of(context).textTheme.titleLarge),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Valor Préstamo: \$${valorPrestamo}',
                                  style: Theme.of(context).textTheme.bodyLarge),
                              SizedBox(height: 4.0),
                              Text('Interés: ${interes}%',
                                  style: Theme.of(context).textTheme.bodyLarge),
                              SizedBox(height: 4.0),
                              Text('Cuota: \$${cuotaAproximada}',
                                  style: Theme.of(context).textTheme.bodyLarge),
                              SizedBox(height: 8.0),
                              Text(
                                  'Nombre: ${cliente?['Nombre'] ?? 'No disponible'}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(
                                  'Trabajo: ${cliente?['Trabajo'] ?? 'No disponible'}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(
                                  'Cuotas Restantes: ${numCuotas.toStringAsFixed(0)}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Text(
                                  'Deuda Pendiente: \$${deudaPendiente.toStringAsFixed(0)}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Valor Total',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.grey)),
                              Text('\$${valorTotal}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (estado == 'Activo')
                          Wrap(
                            spacing: 8.0, // Espacio horizontal entre botones
                            runSpacing:
                                4.0, // Espacio vertical entre filas de botones
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  final abono =
                                      await _mostrarDialogoAbono(context);
                                  if (abono != null) {
                                    _abonar(prestamoId, abono, cedula);
                                  }
                                },
                                child: Text('Abonar'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final cuota =
                                      await _mostrarDialogoCuota(context);
                                  if (cuota != null) {
                                    _pagarCuota(prestamoId, cuota);
                                  }
                                },
                                child: Text('Pagar Cuota'),
                              ),
                              if (deudaPendiente > 0)
                                ElevatedButton(
                                  onPressed: () async {
                                    final monto =
                                        await _mostrarDialogoPagoDeuda(context);
                                    if (monto != null) {
                                      _pagarDeuda(prestamoId, monto);
                                    }
                                  },
                                  child: Text('Pagar Deuda'),
                                ),
                            ],
                          )
                      ],
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
