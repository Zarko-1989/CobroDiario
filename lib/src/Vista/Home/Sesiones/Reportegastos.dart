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
      final double montoNegativo = -valor; // Convertir el valor a negativo
      final DateTime fecha = DateTime.now();
      final String fechaFormateada = DateFormat('dd/MM/yyyy').format(fecha);

      // Guardar en la colección "Gastos"
      FirebaseFirestore.instance.collection('Gastos').add({
        'UsuarioId': widget.userId,
        'UsuarioNombre': userName,
        'TipoMovimiento': concepto,
        'Monto': montoNegativo, // Guardar el monto como negativo
        'Fecha': fechaFormateada, // Guardar la fecha en formato DD/MM/YYYY
      }).then((_) {
        // También guardar en la colección "Movimientos"
        return FirebaseFirestore.instance.collection('Movimientos').add({
          'UsuarioId': widget.userId,
          'UsuarioNombre': userName,
          'TipoMovimiento': concepto,
          'Monto': montoNegativo, // Guardar el monto como negativo
          'Fecha': fechaFormateada, // Guardar la fecha en formato DD/MM/YYYY
        });
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
        backgroundColor: Colors.blueAccent,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Registro de Gastos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _conceptoController,
                      decoration: InputDecoration(
                        labelText: 'Concepto del Gasto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.description, color: Colors.blueAccent),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un concepto';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _valorController,
                      decoration: InputDecoration(
                        labelText: 'Valor del Gasto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.money_off, color: Colors.blueAccent),
                      ),
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
                    Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _submitForm(snapshot.data!),
                      child: Text('Registrar Gasto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: Text(
                  'Error al cargar el nombre de usuario',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
