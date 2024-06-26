import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReporteGastosPage extends StatefulWidget {
  final String userId;

  ReporteGastosPage({required this.userId});

  @override
  _ReporteGastosPageState createState() => _ReporteGastosPageState();
}

class _ReporteGastosPageState extends State<ReporteGastosPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  late Future<String> _userName;

  @override
  void initState() {
    super.initState();
    _userName = _getUserName();
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

  void _submitForm(String userName) {
    if (_formKey.currentState!.validate()) {
      final String concepto = _conceptoController.text;
      final double valor = double.parse(_valorController.text);
      final DateTime fecha = DateTime.now();

      FirebaseFirestore.instance.collection('Gastos').add({
        'UsuarioId': widget.userId,
        'UsuarioNombre': userName,
        'Concepto': concepto,
        'Valor': valor,
        'Fecha': fecha,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gasto registrado exitosamente')),
        );
        _conceptoController.clear();
        _valorController.clear();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar el gasto: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte de Gastos'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: FutureBuilder<String>(
          future: _userName,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _conceptoController,
                      decoration:
                          InputDecoration(labelText: 'Concepto del Gasto'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un concepto';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _valorController,
                      decoration: InputDecoration(labelText: 'Valor del Gasto'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un valor';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor ingrese un valor válido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Text('Fecha: ${DateFormat.yMd().format(DateTime.now())}'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _submitForm(snapshot.data!),
                      child: Text('Registrar Gasto'),
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                  child: Text('Error al cargar el nombre de usuario'));
            }
          },
        ),
      ),
    );
  }
}
