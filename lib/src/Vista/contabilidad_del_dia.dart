import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContabilidadDelDia extends StatefulWidget {
  @override
  _ContabilidadDelDiaState createState() => _ContabilidadDelDiaState();
}

class _ContabilidadDelDiaState extends State<ContabilidadDelDia> {
  late DateTime selectedDate = DateTime.now();
  late Future<List<Map<String, dynamic>>> registrosPagos;

  @override
  void initState() {
    super.initState();
    registrosPagos = obtenerRegistrosPagos(selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        registrosPagos = obtenerRegistrosPagos(selectedDate);
      });
    }
  }

  Future<List<Map<String, dynamic>>> obtenerRegistrosPagos(
      DateTime fecha) async {
    List<Map<String, dynamic>> pagos = [];

    try {
      Timestamp startTimestamp = Timestamp.fromDate(fecha);
      Timestamp endTimestamp = Timestamp.fromDate(fecha.add(Duration(days: 1)));

      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('RegistrosPagos')
              .where('Fecha', isGreaterThanOrEqualTo: startTimestamp)
              .where('Fecha', isLessThan: endTimestamp)
              .get();

      pagos = querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Error fetching payment records: $e");
    }

    return pagos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contabilidad del Día'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: registrosPagos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No hay registros de pagos para esta fecha'));
          } else {
            List<Map<String, dynamic>> data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> registro = data[index];
                String formattedDate = registro['Fecha']
                    .toDate()
                    .toString(); // Formatear fecha si es necesario
                return ListTile(
                  title: Text('Usuario: ${registro['UsuarioNombre']}'),
                  subtitle: Text(
                      'Monto: ${registro['Monto']} - Fecha: $formattedDate'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
