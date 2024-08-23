import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagosdiarios/src/Vista/Admins/GestionarRutas.dart';
import 'package:pagosdiarios/src/Vista/Admins/GestionarUsers.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/CrearCliente.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/CrearPrestamo.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/ListaPrestamos.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/Reportegastos.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<bool> isAdmin;
  late Future<String> userName;

  @override
  void initState() {
    super.initState();
    isAdmin = _checkAdminRole();
    userName = _getUserName();
  }

  Future<bool> _checkAdminRole() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      var data = userDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('Rol') && data['Rol'] == 'admin') {
        return true;
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return false;
  }

  Future<String> _getUserName() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      var data = userDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('Nombre')) {
        return data['Nombre'];
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
    return 'Usuario';
  }

  void _registrarAccion(String tipo, double monto) {
    try {
      FirebaseFirestore.instance.collection('Acciones').add({
        'Fecha': DateTime.now().toLocal().toString().split(' ')[0],
        'Tipo': tipo,
        'Monto': monto,
        'Usuario': widget.userId,
      });
    } catch (e) {
      print("Error registrando acción: $e");
    }
  }

  Widget buildIconButton(IconData icon, String label, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: 120,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48),
              SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildIconButtonWithUserId(
      IconData icon, String label, Widget Function(String) destinationBuilder) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => destinationBuilder(widget.userId)),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: 120,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48),
              SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: userName,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Home Screen');
            } else if (snapshot.hasData) {
              return Text('Bienvenido, ${snapshot.data}');
            } else {
              return Text('Home Screen');
            }
          },
        ),
        actions: [
          FutureBuilder<bool>(
            future: isAdmin,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData && snapshot.data == true) {
                return IconButton(
                  icon: Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GestionUsers()),
                    );
                  },
                );
              } else {
                return SizedBox.shrink(); // No mostrar nada si no es admin
              }
            },
          ),
          FutureBuilder<bool>(
            future: isAdmin,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData && snapshot.data == true) {
                return IconButton(
                  icon: Icon(Icons.directions),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RutasPage()),
                    );
                  },
                );
              } else {
                return SizedBox.shrink(); // No mostrar nada si no es admin
              }
            },
          ),
        ],
      ),
      body: Center(
        child: GridView.count(
          crossAxisCount: 2,
          padding: EdgeInsets.all(16.0),
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            buildIconButton(Icons.person_add, 'Crear Cliente', CrearCliente()),
            buildIconButton(Icons.free_cancellation_sharp, 'Lista de Prestamos',
                ListaPrestamosScreen()),
            buildIconButton(Icons.monetization_on, 'Crear Préstamo',
                CrearPrestamosScreen()),
            buildIconButtonWithUserId(
                Icons.report_problem_outlined,
                'Reporte de Gastos',
                (userId) => ReporteGastosPage(userId: widget.userId)),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomeScreen(userId: 'USER_ID_AQUI'),
  ));
}
