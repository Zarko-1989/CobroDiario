import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagosdiarios/src/Vista/Home/home_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  TextEditingController user = TextEditingController();
  TextEditingController pass = TextEditingController();
  String errorMessage = '';

  Future<void> validarDatos() async {
    setState(() {
      errorMessage = ''; // Limpia cualquier mensaje de error anterior
    });

    try {
      CollectionReference ref = FirebaseFirestore.instance.collection('Users');
      QuerySnapshot usuario = await ref.get();

      bool usuarioEncontrado = false;

      for (var cursor in usuario.docs) {
        if (cursor.get('Nombre') == user.text) {
          usuarioEncontrado = true;
          if (cursor.get('Documento') == pass.text) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeScreen(userId: cursor.id)),
            );
            return;
          } else {
            setState(() {
              errorMessage = 'Contraseña incorrecta';
            });
            return;
          }
        }
      }

      if (!usuarioEncontrado) {
        setState(() {
          errorMessage = 'Usuario no encontrado';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error... ' + e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Iniciar Sesión'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/login_icon.png'), // Cambia esto por tu imagen
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(60),
                  color: Colors.blueAccent,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Bienvenido de nuevo!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: user,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Usuario',
                hintText: 'Ingrese su usuario',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Contraseña',
                hintText: 'Ingrese su contraseña',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                validarDatos();
              },
              child: Text('Ingresar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
