import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrearCliente extends StatefulWidget {
  @override
  _CrearClienteState createState() => _CrearClienteState();
}

class _CrearClienteState extends State<CrearCliente> {
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
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

  final TextEditingController referenciasFamiliares1Controller =
      TextEditingController();
  final TextEditingController numReferenciasFamiliares1Controller =
      TextEditingController();
  final TextEditingController referenciasFamiliares2Controller =
      TextEditingController();
  final TextEditingController numReferenciasFamiliares2Controller =
      TextEditingController();

  void _agregarCliente() async {
    try {
      await FirebaseFirestore.instance.collection('Clientes').add({
        'Cedula': cedulaController.text,
        'Nombre': nombreController.text,
        'Celular': celularController.text,
        'Trabajo': trabajoController.text,
        'Barrio': barrioController.text,
        'Ciudad': ciudadController.text,
        'NombreFiador': nombreFiadorController.text,
        'CelularFiador': celularFiadorController.text,
        'DireccionFiador': direccionFiadorController.text,
        'ReferenciasPersonales': referenciasPersonalesController.text,
        'ReferenciasFamiliares1': referenciasFamiliares1Controller.text,
        'NumReferenciasFamiliares1': numReferenciasFamiliares1Controller.text,
        'ReferenciasFamiliares2': referenciasFamiliares2Controller.text,
        'NumReferenciasFamiliares2': numReferenciasFamiliares2Controller.text,
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
    celularController.clear();
    trabajoController.clear();
    barrioController.clear();
    ciudadController.clear();
    nombreFiadorController.clear();
    celularFiadorController.clear();
    direccionFiadorController.clear();
    referenciasPersonalesController.clear();
    referenciasFamiliares1Controller.clear();
    numReferenciasFamiliares1Controller.clear();
    referenciasFamiliares2Controller.clear();
    numReferenciasFamiliares2Controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Cliente'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: cedulaController,
              label: 'Cédula',
              icon: Icons.credit_card,
            ),
            _buildTextField(
              controller: nombreController,
              label: 'Nombre Completo',
              icon: Icons.person,
            ),
            _buildTextField(
              controller: celularController,
              label: 'Celular',
              icon: Icons.phone,
            ),
            _buildTextField(
              controller: trabajoController,
              label: 'Lugar de Trabajo',
              icon: Icons.work,
            ),
            _buildTextField(
              controller: barrioController,
              label: 'Barrio',
              icon: Icons.location_city,
            ),
            _buildTextField(
              controller: ciudadController,
              label: 'Ciudad',
              icon: Icons.location_city,
            ),
            _buildTextField(
              controller: nombreFiadorController,
              label: 'Nombre Fiador',
              icon: Icons.person_add,
            ),
            _buildTextField(
              controller: celularFiadorController,
              label: 'Celular Fiador',
              icon: Icons.phone,
            ),
            _buildTextField(
              controller: direccionFiadorController,
              label: 'Dirección Fiador',
              icon: Icons.home,
            ),
            _buildTextField(
              controller: referenciasPersonalesController,
              label: 'Referencias Personales',
              icon: Icons.contact_mail,
              maxLines: 3,
            ),
            SizedBox(height: 20),
            _buildTextField(
              controller: referenciasFamiliares1Controller,
              label: 'Referencia Familiar 1',
              icon: Icons.person,
            ),
            _buildTextField(
              controller: numReferenciasFamiliares1Controller,
              label: 'Número de Teléfono 1',
              icon: Icons.phone,
            ),
            _buildTextField(
              controller: referenciasFamiliares2Controller,
              label: 'Referencia Familiar 2',
              icon: Icons.person,
            ),
            _buildTextField(
              controller: numReferenciasFamiliares2Controller,
              label: 'Número de Teléfono 2',
              icon: Icons.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _agregarCliente,
              child: Text('Agregar Cliente'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blueAccent,
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        maxLines: maxLines,
      ),
    );
  }
}
