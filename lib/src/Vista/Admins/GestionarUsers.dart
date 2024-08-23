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
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Agregar/Editar Usuario',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: documentoController,
              label: 'Documento',
              icon: Icons.card_membership,
            ),
            _buildTextField(
              controller: estadoController,
              label: 'Estado',
              icon: Icons.toggle_on,
            ),
            _buildTextField(
              controller: nombreController,
              label: 'Nombre',
              icon: Icons.person,
            ),
            _buildTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock,
              obscureText: true,
            ),
            _buildTextField(
              controller: rolController,
              label: 'Rol',
              icon: Icons.admin_panel_settings,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10, // espacio horizontal entre botones
              runSpacing: 10, // espacio vertical entre botones
              children: [
                _buildButton('Limpiar Campos', Colors.grey, _limpiarCampos),
                _buildButton('Agregar', Colors.blueAccent, _addUser),
                _buildButton('Actualizar', Colors.orange,
                    () => _updateUser(documentoController.text)),
                _buildButton('Eliminar', Colors.red,
                    () => _deleteUser(documentoController.text)),
              ],
            ),
            const SizedBox(height: 40),
            const Divider(thickness: 2),
            const SizedBox(height: 20),
            const Text(
              'Lista de Usuarios',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: _firestore.collection('Users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        title: Text(user['Nombre'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user['Rol']),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(user['Nombre'][0],
                              style: TextStyle(color: Colors.white)),
                        ),
                        onTap: () {
                          _mostrarDatosUsuario(user);
                        },
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
