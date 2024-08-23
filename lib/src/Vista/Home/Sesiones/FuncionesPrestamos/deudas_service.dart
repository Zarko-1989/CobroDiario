import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/FuncionesPrestamos/location_service.dart';

class DeudasService {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  Future<void> pagarDeuda(
    BuildContext context,
    String prestamoId,
    double monto,
  ) async {
    try {
      DocumentReference prestamoRef =
          _firebase.collection('Prestamos').doc(prestamoId);
      DocumentSnapshot prestamoDoc = await prestamoRef.get();

      if (prestamoDoc.exists) {
        final data = prestamoDoc.data() as Map<String, dynamic>;
        final saldoDeuda = (data['Deuda_Pendiente'] as num?)?.toDouble() ?? 0;

        if (monto > saldoDeuda) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('El monto del pago excede la deuda pendiente')),
          );
          return;
        }

        final nuevoSaldoDeuda = saldoDeuda - monto;
        final estado = nuevoSaldoDeuda <= 0 ? 'Inactivo' : 'Activo';

        // Actualizar el saldo y el estado del préstamo
        await prestamoRef.update({
          'Deuda_Pendiente': nuevoSaldoDeuda,
          'Estado': estado,
        });

        // Obtener la ubicación actual
        final position = await _locationService.getCurrentLocation();
        if (position != null) {
          final movimientosRef =
              FirebaseFirestore.instance.collection('Movimientos').doc();
          DateTime fechaActual = DateTime.now();
          final DateFormat formatoFecha = DateFormat('dd/MM/yyyy');
          final String fechaFormateada = formatoFecha.format(fechaActual);

          await movimientosRef.set({
            'PrestamoId': prestamoId,
            'TipoMovimiento': 'Pago de Deuda',
            'Monto': monto,
            'Fecha': fechaFormateada,
            'Estado': estado,
            'Ubicacion': GeoPoint(
              position.latitude ?? 0.0, // Asegúrate de que no sea nulo
              position.longitude ?? 0.0, // Asegúrate de que no sea nulo
            ),
            'Timestamp': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pago de deuda registrado exitosamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo obtener la ubicación.')),
          );
        }
      } else {
        print("El documento del préstamo no existe.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El préstamo no existe.')),
        );
      }
    } catch (e) {
      print("Error al pagar deuda: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error al registrar el pago de deuda: ${e.toString()}')),
      );
    }
  }
}
