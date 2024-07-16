import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContabilidadDiaria extends StatefulWidget {
  @override
  _ContabilidadDiariaState createState() => _ContabilidadDiariaState();
}

class _ContabilidadDiariaState extends State<ContabilidadDiaria> {
  double saldoTotal = 0.0;

  @override
  void initState() {
    super.initState();
    calcularSaldoTotal();
  }

  void calcularSaldoTotal() async {
    try {
      QuerySnapshot accionesSnapshot = await FirebaseFirestore.instance
          .collection('Acciones')
          .where('Fecha', isEqualTo: DateTime.now().toLocal().toString().split(' ')[0])
          .get();

      double totalIngresos = 0.0;
      double totalAbonos = 0.0;

      accionesSnapshot.docs.forEach((accionDoc) {
        var data = accionDoc.data() as Map<String, dynamic>;
        if (data['Tipo'] == 'Ingreso') {
          totalIngresos += data['Monto'];
        } else if (data['Tipo'] == 'Abono') {
          totalAbonos += data['Monto'];
        }
      });

      setState(() {
        saldoTotal = totalIngresos - totalAbonos;
      });
    } catch (e) {
      print("Error calculando el saldo total: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contabilidad Diaria'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Saldo Total del Día:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '\$ ${saldoTotal.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: saldoTotal >= 0 ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
