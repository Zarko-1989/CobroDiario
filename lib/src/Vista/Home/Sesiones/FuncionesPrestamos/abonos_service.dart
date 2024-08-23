import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/FuncionesPrestamos/location_service.dart';

class AbonosService {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final LocationService _locationService =
      LocationService(); // Instancia del servicio de ubicación

  Future<void> abonar(
    BuildContext context,
    String prestamoId,
    double abono,
    String cedulaCliente,
  ) async {
    try {
      DocumentReference prestamoRef =
          _firebase.collection('Prestamos').doc(prestamoId);
      DocumentSnapshot prestamoDoc = await prestamoRef.get();

      if (prestamoDoc.exists) {
        final data = prestamoDoc.data() as Map<String, dynamic>;
        final saldoPendiente = (data['ValorTotal'] as num?)?.toDouble() ?? 0;
        final numCuotas = (data['Numero_Cuotas'] as num?)?.toDouble() ?? 0;
        final interesIncrementado =
            (data['Interes_Incrementado'] as num?)?.toDouble() ?? 0;
        final metodoPago = data['Metodo_Pago']
            as String?; // Método de pago, por ejemplo, 'Semanal' o 'Quincenal'

        final nuevoSaldoPendiente = saldoPendiente - abono;

        if (nuevoSaldoPendiente < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('El abono excede el saldo pendiente')),
          );
          return;
        }

        double nuevaCuotaAproximada = 0;
        if (numCuotas > 0) {
          // Ajustar el cálculo de Cuota_Aproximada según el Método_Pago
          if (metodoPago == 'Semanal') {
            nuevaCuotaAproximada =
                nuevoSaldoPendiente / 4; // 4 cuotas semanales
          } else if (metodoPago == 'Quincenal') {
            nuevaCuotaAproximada =
                nuevoSaldoPendiente / 2; // 2 cuotas quincenales
          } else {
            nuevaCuotaAproximada = nuevoSaldoPendiente /
                numCuotas; // Método de pago desconocido, usar el número de cuotas original
          }
        }

        final estado = nuevoSaldoPendiente <= 0 ? 'Inactivo' : 'Activo';

        // Calcular el nuevo ValorIntereses como un porcentaje del ValorTotal
        double nuevoValorIntereses =
            nuevoSaldoPendiente * (interesIncrementado / 100);

        await prestamoRef.update({
          'ValorTotal': nuevoSaldoPendiente,
          'Cuota_Aproximada': nuevaCuotaAproximada,
          'Estado': estado,
          'ValorIntereses': nuevoValorIntereses,
        });

        final clienteData = await _buscarDatosCliente(cedulaCliente);
        final clienteNombre = clienteData?['Nombre'] ?? 'Nombre no disponible';

        // Obtener la ubicación actual
        final position = await _locationService.getCurrentLocation();
        if (position != null) {
          final abonosRef =
              FirebaseFirestore.instance.collection('Abonos').doc();
          DateTime fechaActual = DateTime.now();
          final DateFormat formatoFecha = DateFormat('dd/MM/yyyy');
          final String fechaFormateada = formatoFecha.format(fechaActual);

          await abonosRef.set({
            'PrestamoId': prestamoId,
            'Monto': abono,
            'Fecha': fechaFormateada,
            'CedulaCliente': cedulaCliente,
            'NombreCliente': clienteNombre,
            'Ubicacion': GeoPoint(
              position.latitude ?? 0.0, // Asegúrate de que no sea nulo
              position.longitude ?? 0.0, // Asegúrate de que no sea nulo
            ),
            'Timestamp': FieldValue.serverTimestamp(),
          });

          final movimientosRef =
              FirebaseFirestore.instance.collection('Movimientos').doc();
          await movimientosRef.set({
            'PrestamoId': prestamoId,
            'TipoMovimiento': 'Abono',
            'Monto': abono,
            'Fecha': fechaFormateada,
            'CedulaCliente': cedulaCliente,
            'NombreCliente': clienteNombre,
            'Ubicacion': GeoPoint(
              position.latitude ?? 0.0, // Asegúrate de que no sea nulo
              position.longitude ?? 0.0, // Asegúrate de que no sea nulo
            ),
            'Timestamp': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Abono registrado exitosamente')),
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
      print("Error al registrar el abono: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el abono: ${e.toString()}')),
      );
    }
  }

  Future<Map<String, dynamic>?> _buscarDatosCliente(
      String cedulaCliente) async {
    try {
      QuerySnapshot querySnapshot = await _firebase
          .collection('Clientes')
          .where('Cedula', isEqualTo: cedulaCliente)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      print("Error al buscar datos del cliente: $e");
      return null;
    }
  }
}
