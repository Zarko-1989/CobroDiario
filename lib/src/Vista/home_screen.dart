import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagosdiarios/src/Vista/GestionarUser.dart';
import 'package:pagosdiarios/src/Vista/crearcliente.dart';
import 'package:pagosdiarios/src/Vista/crearPrestamos.dart';
import 'package:pagosdiarios/src/Vista/lista_prestamos2.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<bool> isAdmin;

  @override
  void initState() {
    super.initState();
    isAdmin = _checkAdminRole();
  }

  Future<bool> _checkAdminRole() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && userDoc.get('Rol') == 'admin') {
        return true;
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return false;
  }

  Widget buildIconButton(IconData icon, double size, Widget destination) {
    return IconButton(
      iconSize: size,
      icon: Icon(icon),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
        actions: [
          FutureBuilder<bool>(
            future: isAdmin,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData && snapshot.data == true) {
                return buildIconButton(
                    Icons.admin_panel_settings, 36, GestionUsers());
              } else {
                return SizedBox.shrink(); // No mostrar nada si no es admin
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildIconButton(Icons.person_add, 72, CrearCliente()),
            // buildIconButton(Icons.list, 72, PruebasPrestamosPage2()),
            buildIconButton(Icons.monetization_on, 72, CrearPrestamosScreen()),
            buildIconButton(Icons.list_alt_rounded, 72, PruebasPrestamosPage()),
            // Agregar otros iconos si es necesario
          ],
        ),
      ),
    );
  }
}
