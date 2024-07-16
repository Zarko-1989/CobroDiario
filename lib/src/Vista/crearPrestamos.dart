import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrearPrestamosScreen extends StatefulWidget {
  @override
  _CrearPrestamosScreenState createState() => _CrearPrestamosScreenState();
}

class _CrearPrestamosScreenState extends State<CrearPrestamosScreen> {
  TextEditingController cedulaController = TextEditingController();
  TextEditingController valorController = TextEditingController();
  TextEditingController abonoCapitalController =
      TextEditingController(); // Nuevo controlador para el abono al capital
  String formaPago = 'Diaria';
  String tipoPago = 'Libre'; // Nueva variable para el tipo de pago
  final firebase = FirebaseFirestore.instance;

  bool clienteExiste = true; // Variable para controlar si el cliente existe

  @override
  void initState() {
    super.initState();
    // Agregar un listener al controlador de texto para escuchar cambios en la cédula
    cedulaController.addListener(() {
      verificarCliente();
    });
  }

  void verificarCliente() async {
    try {
      // Verificar si la cédula del cliente existe en la tabla Clientes
      QuerySnapshot cliente = await firebase
          .collection('Clientes')
          .where('Cedula', isEqualTo: cedulaController.text)
          .get();

      setState(() {
        clienteExiste = cliente.docs.isNotEmpty;
      });
    } catch (e) {
      print('Error al verificar cliente: $e');
    }
  }

  void registroPrestamo() async {
    if (!clienteExiste) {
      // Si el cliente no existe, mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El cliente no existe'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Salir de la función si el cliente no existe
    }

    try {
      // Calcular el valor de los intereses (20% del valor del préstamo)
      double valorPrestamo = double.parse(valorController.text);
      double valorIntereses = valorPrestamo * 0.20;
      double valor_Total = valorIntereses + valorPrestamo;
      double abonoCapital = tipoPago == 'Interes+Capital'
          ? double.parse(abonoCapitalController.text)
          : 0.0;

      // Generar un ID único para el préstamo
      String prestamoId = firebase.collection('Prestamos').doc().id;

      // Obtener el día de la semana actual (Lunes: 1, Martes: 2, ..., Domingo: 7)
      int diaSemana = DateTime.now().weekday;

      // Registrar el préstamo en Firestore con el ID generado y el día de la semana
      await firebase.collection('Prestamos').doc(prestamoId).set({
        "CedulaCliente":
            int.parse(cedulaController.text), // Convertir a numérico
        "ValorPrestamo": valorPrestamo, // Convertir a numérico
        "ValorIntereses": valorIntereses, // Valor de los intereses
        "FormaPago": formaPago,
        "TipoPago": tipoPago, // Guardar el tipo de pago
        "AbonoCapital": abonoCapital, // Guardar el abono al capital
        "DiaSemana": diaSemana, // Guardar el día de la semana
        "Fecha": DateTime.now(),
        "ValorTotal": valor_Total,
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Préstamo registrado satisfactoriamente'),
          duration: Duration(seconds: 2),
        ),
      );

      // Volver a HomeScreen después de 2 segundos
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      print('Error al registrar préstamo: $e');
      // Mostrar mensaje de error si falla el registro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar préstamo'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Préstamo'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: cedulaController,
              decoration: InputDecoration(labelText: 'Cédula del Cliente'),
              keyboardType:
                  TextInputType.number, // Tipo numérico para la cédula
            ),
            SizedBox(height: 20),
            // Mostrar el mensaje de error si el cliente no existe
            if (!clienteExiste)
              Text(
                'El cliente no existe',
                style: TextStyle(color: Colors.red),
              ),
            TextField(
              controller: valorController,
              decoration:
                  const InputDecoration(labelText: 'Valor del Préstamo'),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true), // Tipo numérico para el valor del préstamo
            ),
            const SizedBox(height: 20),
            const Text('Forma de Pago:'),
            DropdownButton<String>(
              value: formaPago,
              onChanged: (String? newValue) {
                setState(() {
                  formaPago = newValue!;
                });
              },
              items: <String>[
                'Diaria',
                '20 Dias',
                '24 Dias',
                'Semanal',
                'Quincenal',
                'Mensual'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Tipo de Pago:'),
            DropdownButton<String>(
              value: tipoPago,
              onChanged: (String? newValue) {
                setState(() {
                  tipoPago = newValue!;
                });
              },
              items: <String>['Libre', 'Interes+Capital']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            if (tipoPago == 'Interes+Capital')
              TextField(
                controller: abonoCapitalController,
                decoration:
                    const InputDecoration(labelText: 'Abono al Capital'),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true), // Tipo numérico para el abono al capital
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: registroPrestamo,
              child: const Text('Registrar Préstamo'),
            ),
          ],
        ),
      ),
    );
  }
}
