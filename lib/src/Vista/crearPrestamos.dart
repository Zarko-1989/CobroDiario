import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrearPrestamosScreen extends StatefulWidget {
  @override
  _CrearPrestamosScreenState createState() => _CrearPrestamosScreenState();
}

class _CrearPrestamosScreenState extends State<CrearPrestamosScreen> {
  TextEditingController cedulaController = TextEditingController();
  TextEditingController valorController = TextEditingController();
  String formaPago = 'Diaria';
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

      // Generar un ID único para el préstamo
      String prestamoId = firebase.collection('Prestamos').doc().id;

      // Registrar el préstamo en Firestore con el ID generado
      await firebase.collection('Prestamos').doc(prestamoId).set({
        "CedulaCliente":
            int.parse(cedulaController.text), // Convertir a numérico
        "ValorPrestamo": valorPrestamo, // Convertir a numérico
        "ValorIntereses": valorIntereses, // Valor de los intereses
        "FormaPago": formaPago,
        "Fecha": DateTime.now(),
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
              decoration: InputDecoration(labelText: 'Valor del Préstamo'),
              keyboardType: TextInputType.numberWithOptions(
                  decimal: true), // Tipo numérico para el valor del préstamo
            ),
            SizedBox(height: 20),
            Text('Forma de Pago:'),
            DropdownButton<String>(
              value: formaPago,
              onChanged: (String? newValue) {
                setState(() {
                  formaPago = newValue!;
                });
              },
              items: <String>['Diaria', 'Semanal', 'Quincenal', 'Mensual']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: registroPrestamo,
              child: Text('Registrar Préstamo'),
            ),
          ],
        ),
      ),
    );
  }
}
