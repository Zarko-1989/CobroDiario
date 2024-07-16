import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionUsers extends StatefulWidget {
  @override
  _GestionUsersState createState() => _GestionUsersState();
}

class _GestionUsersState extends State<GestionUsers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController documentoController = TextEditingController();
  final TextEditingController estadoController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController rolController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Agregar/Editar Usuario',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: documentoController,
              decoration: const InputDecoration(labelText: 'Documento'),
            ),
            TextField(
              controller: estadoController,
              decoration: const InputDecoration(labelText: 'Estado'),
            ),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            TextField(
              controller: rolController,
              decoration: const InputDecoration(labelText: 'Rol'),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10, // espacio horizontal entre botones
              runSpacing: 10, // espacio vertical entre botones
              children: [
                ElevatedButton(
                  onPressed: () {
                    _limpiarCampos();
                  },
                  child: const Text('Limpiar Campos'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addUser();
                  },
                  child: const Text('Agregar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateUser(documentoController.text);
                  },
                  child: const Text('Actualizar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _deleteUser(documentoController.text);
                  },
                  child: const Text('Eliminar'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Lista de Usuarios',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: _firestore.collection('Users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                var users = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    return ListTile(
                      title: Text(user['Nombre']),
                      subtitle: Text(user['Rol']),
                      onTap: () {
                        _mostrarDatosUsuario(user);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addUser() async {
    try {
      await _firestore.collection('Users').doc(documentoController.text).set({
        'Documento': documentoController.text,
        'Estado': estadoController.text,
        'Nombre': nombreController.text,
        'Password': passwordController.text,
        'Rol': rolController.text,
      });
      _limpiarCampos();
    } catch (e) {
      print("Error adding user: $e");
    }
  }

  void _updateUser(String userId) async {
    try {
      await _firestore.collection('Users').doc(userId).update({
        'Documento': documentoController.text,
        'Estado': estadoController.text,
        'Nombre': nombreController.text,
        'Password': passwordController.text,
        'Rol': rolController.text,
      });
      _limpiarCampos();
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  void _deleteUser(String userId) async {
    try {
      await _firestore.collection('Users').doc(userId).delete();
      _limpiarCampos();
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  void _limpiarCampos() {
    documentoController.clear();
    estadoController.clear();
    nombreController.clear();
    passwordController.clear();
    rolController.clear();
  }

  void _mostrarDatosUsuario(DocumentSnapshot user) {
    documentoController.text = user['Documento'];
    estadoController.text = user['Estado'];
    nombreController.text = user['Nombre'];
    passwordController.text = user['Password'];
    rolController.text = user['Rol'];
  }
}
