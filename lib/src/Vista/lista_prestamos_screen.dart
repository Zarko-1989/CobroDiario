import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _abonar(String prestamoId, double abono) async {
    try {
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

        await prestamoRef.update({
          'ValorTotal': nuevoSaldoPendiente,
          'Cuota_Aproximada': nuevaCuotaAproximada,
          'Estado': estado, // Actualizar el estado del préstamo
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

  Future<void> _pagarCuota(String prestamoId, double cuota) async {
    try {
      DocumentReference prestamoRef =
          _firebase.collection('Prestamos').doc(prestamoId);
      DocumentSnapshot prestamoDoc = await prestamoRef.get();

      if (prestamoDoc.exists) {
        final data = prestamoDoc.data() as Map<String, dynamic>;
        final saldoPendiente = (data['ValorTotal'] as num?)?.toDouble() ?? 0;
        final numCuotas = (data['Numero_Cuotas'] as num?)?.toDouble() ?? 0;

        final nuevoSaldoPendiente = saldoPendiente - cuota;
        final nuevasCuotasRestantes = numCuotas - 1;

        if (nuevoSaldoPendiente < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('El pago de cuota excede el saldo pendiente')),
          );
          return;
        }

        if (nuevasCuotasRestantes < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('El número de cuotas no puede ser negativo')),
          );
          return;
        }

        // Determinar el estado del préstamo
        final estado = nuevoSaldoPendiente <= 0 ? 'Inactivo' : 'Activo';

        await prestamoRef.update({
          'ValorTotal': nuevoSaldoPendiente,
          'Numero_Cuotas': nuevasCuotasRestantes,
          'Estado': estado, // Actualizar el estado del préstamo
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
              final estado = prestamo['Estado'] ??
                  'Activo'; // Obtener el estado del préstamo

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
                        if (estado ==
                            'Activo') // Mostrar botones solo si el estado es Activo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  final abono =
                                      await _mostrarDialogoAbono(context);
                                  if (abono != null) {
                                    _abonar(prestamoId, abono);
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
                            ],
                          ),
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
