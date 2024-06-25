import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    title: 'Pruebas de Préstamos',
    home: PruebasPrestamosPage(),
  ));
}

class PruebasPrestamosPage extends StatelessWidget {
  // Función para abonar al préstamo
  Future<void> abonarPrestamo(BuildContext context, String documentId) async {
    TextEditingController abonoController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Abonar al Capital'),
          content: TextField(
            controller: abonoController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Ingrese el monto a abonar'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Abonar'),
              onPressed: () async {
                // Obtener el valor ingresado por el usuario
                int abono = int.tryParse(abonoController.text) ?? 0;
                if (abono > 0) {
                  // Realizar la actualización en Firestore
                  await FirebaseFirestore.instance
                      .collection('Prestamos')
                      .doc(documentId)
                      .update({
                    'Abonos': FieldValue.arrayUnion(
                        [abono]), // Agregar abono al vector de abonos
                    'ValorPrestamo': FieldValue.increment(
                        -abono), // Restar abono a ValorPrestamo
                    'ValorIntereses': FieldValue.increment(
                        -abono * 0.2), // Recalcular ValorIntereses
                  });

                  Navigator.of(context).pop(); // Cerrar el AlertDialog
                } else {
                  // Mostrar mensaje de error si el valor ingresado es inválido
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ingrese un valor válido para abonar'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Función para pagar una cuota del préstamo
  Future<void> pagarCuota(
      BuildContext context, String documentId, double valorCuota) async {
    TextEditingController cuotaPagadaController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pagar Cuota'),
          content: TextField(
            controller: cuotaPagadaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Ingrese el monto a pagar'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Pagar'),
              onPressed: () async {
                // Obtener el valor ingresado por el usuario
                double montoPagado =
                    double.tryParse(cuotaPagadaController.text) ?? 0;
                if (montoPagado > 0) {
                  // Calcular cuántas cuotas se van a pagar (en este caso se paga una cuota)
                  int cantidadCuotas = 1;

                  // Calcular el monto total a pagar (valor de la cuota a pagar)
                  double montoTotal = valorCuota;

                  // Verificar si el monto pagado no supera el monto total a pagar
                  if (montoPagado <= montoTotal) {
                    // Realizar la actualización en Firestore
                    await FirebaseFirestore.instance
                        .collection('Prestamos')
                        .doc(documentId)
                        .update({
                      'CuotasPagadas': FieldValue.increment(
                          1), // Incrementar el contador de cuotas pagadas
                      'ValorPrestamo': FieldValue.increment(
                          -montoPagado), // Restar el monto pagado al préstamo
                      'ValorIntereses': FieldValue.increment(
                          -montoPagado * 0.2), // Ajustar los intereses
                    });

                    Navigator.of(context).pop(); // Cerrar el AlertDialog
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'El monto pagado no puede ser mayor al monto total a pagar'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Ingrese un valor válido para pagar la cuota'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pruebas de Préstamos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Prestamos').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar los datos: ${snapshot.error}'));
          } else if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay datos disponibles'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (BuildContext context, int index) {
                var prestamo = snapshot.data!.docs[index];
                var fecha = (prestamo['Fecha'] as Timestamp).toDate();
                var formattedFecha = DateFormat('dd/MM/yyyy').format(fecha);

                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(
                        'Cédula del Cliente: ${prestamo['CedulaCliente']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: $formattedFecha'),
                        Text('Forma de Pago: ${prestamo['FormaPago']}'),
                        Text(
                            'Valor de Intereses: ${prestamo['ValorIntereses']}'),
                        Text(
                            'Valor del Préstamo: ${prestamo['ValorPrestamo']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Llamar a la función para abonar al préstamo
                            abonarPrestamo(context, prestamo.id);
                          },
                          child: Text('Abonar'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Llamar a la función para pagar una cuota del préstamo
                            pagarCuota(
                                context, prestamo.id, prestamo['ValorCuota']);
                          },
                          child: Text('Pagar Cuota'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
