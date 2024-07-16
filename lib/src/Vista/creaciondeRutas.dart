import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RutasPage extends StatefulWidget {
  @override
  _RutasPageState createState() => _RutasPageState();
}

class _RutasPageState extends State<RutasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Gestion de Rutas'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Agregar/Editar Ruta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codigoController,
                decoration: InputDecoration(labelText: 'Codigo Ruta'),
              ),
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre De Ruta'),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _limpiarCampos();
                    },
                    child: const Text('Limpiar Campos'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _addRutas();
                    },
                    child: const Text('Agregar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _updateRutas(codigoController.text);
                    },
                    child: const Text('Actualizar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _deleteRutas(codigoController.text);
                    },
                    child: const Text('Eliminar'),
                  )
                ],
              ),
            ],
          ),
        ));
  }

  void _updateRutas(String rutasId) async {
    try {
      await _firestore.collection('Rutas').doc(rutasId).update({
        'Codigo': codigoController.text,
      });
      _limpiarCampos();
    } catch (e) {
      print("Error actualizando Ruta: $e");
    }
  }

  void _deleteRutas(String rutasId) async {
    try {
      await _firestore.collection('Rutas').doc(rutasId).delete();
      _limpiarCampos();
    } catch (e) {
      print("Error al eliminar Ruta $e");
    }
  }

  void _addRutas() async {
    try {
      await _firestore.collection('Rutas').doc(codigoController.text).set({
        'Codigo': codigoController.text,
      });
      _limpiarCampos();
    } catch (e) {
      print("Error agregar ruta: $e");
    }
  }

  void _limpiarCampos() {
    codigoController.clear();
    nombreController.clear();
  }
}
