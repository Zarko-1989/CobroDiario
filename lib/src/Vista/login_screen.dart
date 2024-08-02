import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagosdiarios/src/Vista/home_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  TextEditingController user = TextEditingController();
  TextEditingController pass = TextEditingController();

  validarDatos() async {
    try {
      CollectionReference ref = FirebaseFirestore.instance.collection('Users');
      QuerySnapshot usuario = await ref.get();

      if (usuario.docs.isNotEmpty) {
        for (var cursor in usuario.docs) {
          if (cursor.get('Nombre') == user.text) {
            print('Usuario Encontrado');
            print('Nombre: ${cursor.get('Nombre')}');
            print('Documento: ${cursor.get('Documento')}');
            print('Rol: ${cursor.get('Rol')}');
            if (cursor.get('Documento') == pass.text) {
              print('************** ACCESO ACEPTADO **************');
              print(' Estado -> ' + cursor.get('Estado'));
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(userId: cursor.id),
                ),
              );
            }
          }
        }
      } else {
        print('No hay documento en la coleccion');
      }
    } catch (e) {
      print('Error... ' + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingresar Login'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: TextField(
                controller: user,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelText: 'Usuario',
                  hintText: 'Digite su usuario',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: pass,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelText: 'Contraseña',
                  hintText: 'Digite su contraseña',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 50, right: 10),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    print('Ingresando...');
                    validarDatos();
                  },
                  child: const Text('Ingresar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
