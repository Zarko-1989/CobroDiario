import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrearCliente extends StatefulWidget {
  @override
  _CrearClienteState createState() => _CrearClienteState();
}

class _CrearClienteState extends State<CrearCliente> {
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController celularController = TextEditingController();
  final TextEditingController trabajoController = TextEditingController();
  final TextEditingController barrioController = TextEditingController();
  final TextEditingController ciudadController = TextEditingController();
  final TextEditingController nombreFiadorController = TextEditingController();
  final TextEditingController celularFiadorController = TextEditingController();
  final TextEditingController direccionFiadorController =
      TextEditingController();
  final TextEditingController referenciasPersonalesController =
      TextEditingController();

  void _agregarCliente() async {
    try {
      await FirebaseFirestore.instance.collection('Clientes').add({
        'Cedula': cedulaController.text,
        'Nombre': nombreController.text,
        'Apellido': apellidoController.text,
        'Celular': celularController.text,
        'Trabajo': trabajoController.text,
        'Barrio': barrioController.text,
        'Ciudad': ciudadController.text,
        'NombreFiador': nombreFiadorController.text,
        'CelularFiador': celularFiadorController.text,
        'DireccionFiador': direccionFiadorController.text,
        'ReferenciasPersonales': referenciasPersonalesController.text,
      });
      _limpiarCampos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente agregado correctamente'),
        ),
      );
    } catch (e) {
      print("Error adding client: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar cliente'),
        ),
      );
    }
  }

  void _limpiarCampos() {
    cedulaController.clear();
    nombreController.clear();
    apellidoController.clear();
    celularController.clear();
    trabajoController.clear();
    barrioController.clear();
    ciudadController.clear();
    nombreFiadorController.clear();
    celularFiadorController.clear();
    direccionFiadorController.clear();
    referenciasPersonalesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Cliente'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: cedulaController,
              decoration: InputDecoration(labelText: 'Cédula'),
            ),
            TextField(
              controller: nombreController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: apellidoController,
              decoration: InputDecoration(labelText: 'Apellido'),
            ),
            TextField(
              controller: celularController,
              decoration: InputDecoration(labelText: 'Celular'),
            ),
            TextField(
              controller: trabajoController,
              decoration: InputDecoration(labelText: 'Lugar de Trabajo'),
            ),
            TextField(
              controller: barrioController,
              decoration: InputDecoration(labelText: 'Barrio'),
            ),
            TextField(
              controller: ciudadController,
              decoration: InputDecoration(labelText: 'Ciudad'),
            ),
            TextField(
              controller: nombreFiadorController,
              decoration: InputDecoration(labelText: 'Nombre Fiador'),
            ),
            TextField(
              controller: celularFiadorController,
              decoration: InputDecoration(labelText: 'Celular Fiador'),
            ),
            TextField(
              controller: direccionFiadorController,
              decoration: InputDecoration(labelText: 'Dirección Fiador'),
            ),
            TextField(
              controller: referenciasPersonalesController,
              decoration: const InputDecoration(labelText: 'Referencias Personales'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _agregarCliente,
              child: Text('Agregar Cliente'),
            ),
          ],
        ),
      ),
    );
  }
}
