import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pagosdiarios/src/Vista/Home/Sesiones/FuncionesPrestamos/location_service.dart';

class PagosService {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final LocationService _locationService =
      LocationService(); // Instancia del servicio de ubicación

  Future<void> pagarCuota(
    BuildContext context,
    String prestamoId,
    double cuota,
  ) async {
    try {
      DocumentReference prestamoRef =
          _firebase.collection('Prestamos').doc(prestamoId);
      DocumentSnapshot prestamoDoc = await prestamoRef.get();

      if (prestamoDoc.exists) {
        final data = prestamoDoc.data() as Map<String, dynamic>;
        final cuotaAproximada =
            (data['Cuota_Aproximada'] as num?)?.toDouble() ?? 0;
        final deudaPendiente =
            (data['Deuda_Pendiente'] as num?)?.toDouble() ?? 0;
        final valorTotal = (data['ValorTotal'] as num?)?.toDouble() ?? 0;
        final numCuotas = (data['Numero_Cuotas'] as num?)?.toDouble() ?? 0;
        final tipoPago = data['Tipo_Pago'] as String?;
        final valorIntereses =
            (data['ValorIntereses'] as num?)?.toDouble() ?? 0;

        if (cuota > valorTotal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('El pago de cuota excede el saldo pendiente')),
          );
          return;
        }

        double nuevoSaldoPendiente = valorTotal - cuota;
        double nuevaDeudaPendiente = deudaPendiente;
        double nuevoValorIntereses = valorIntereses;

        if (tipoPago == 'Libre') {
          // Ajustar intereses
          nuevoValorIntereses = valorIntereses - cuota;
          if (nuevoValorIntereses < 0) {
            nuevoValorIntereses = 0;
          }
          final estado = nuevoSaldoPendiente <= 0 ? 'Inactivo' : 'Activo';

          if (numCuotas == 0) {
            // Recalcular ValorIntereses y Numero_Cuotas
            final tasaInteres = (data['Tasa_Interes'] as num?)?.toDouble() ?? 0;
            final nuevoValorIntereses = valorTotal * (tasaInteres / 100);

            int nuevasCuotas;
            if (data['Periodicidad'] == 'Semanal') {
              nuevasCuotas = (nuevoValorIntereses / (valorTotal / 4))
                  .ceil(); // 4 cuotas semanales
            } else if (data['Periodicidad'] == 'Quincenal') {
              nuevasCuotas = (nuevoValorIntereses / (valorTotal / 2))
                  .ceil(); // 2 cuotas quincenales
            } else {
              nuevasCuotas =
                  1; // Valor por defecto si la periodicidad no es válida
            }

            await prestamoRef.update({
              'ValorIntereses': nuevoValorIntereses,
              'Numero_Cuotas': nuevasCuotas,
              'Estado': estado,
            });
          } else {
            // Actualizar Deuda_Pendiente
            nuevaDeudaPendiente = deudaPendiente - cuota;
            if (nuevaDeudaPendiente < 0) {
              nuevaDeudaPendiente = 0;
            }

            final nuevasCuotasRestantes = numCuotas - 1;
            final estado = nuevoSaldoPendiente <= 0 ? 'Inactivo' : 'Activo';

            await prestamoRef.update({
              'ValorTotal': nuevoSaldoPendiente,
              'ValorIntereses': nuevoValorIntereses,
              'Estado': estado,
              'Deuda_Pendiente': nuevaDeudaPendiente,
              'Numero_Cuotas': nuevasCuotasRestantes,
            });
          }
        } else {
          if (cuota < cuotaAproximada) {
            // Si el pago es menor que la cuota aproximada, acumular la diferencia en Deuda_Pendiente
            nuevaDeudaPendiente += cuotaAproximada - cuota;
          } else {
            // Ajustar Deuda_Pendiente si el pago es mayor o igual a la cuota aproximada
            nuevaDeudaPendiente -= cuota - cuotaAproximada;
            if (nuevaDeudaPendiente < 0) {
              nuevaDeudaPendiente = 0;
            }
          }

          final nuevasCuotasRestantes = numCuotas - 1;
          final estado = nuevoSaldoPendiente <= 0 ? 'Inactivo' : 'Activo';

          await prestamoRef.update({
            'ValorTotal': nuevoSaldoPendiente,
            'Numero_Cuotas': nuevasCuotasRestantes,
            'Estado': estado,
            'Deuda_Pendiente': nuevaDeudaPendiente,
          });
        }

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
            'TipoMovimiento': 'Pago de Cuota',
            'Monto': cuota,
            'Fecha': fechaFormateada,
            'Estado': await prestamoRef
                .get()
                .then((doc) => (doc.data() as Map<String, dynamic>)['Estado']),
            'Ubicacion': GeoPoint(
              position.latitude ?? 0.0, // Asegúrate de que no sea nulo
              position.longitude ?? 0.0, // Asegúrate de que no sea nulo
            ),
            'Timestamp': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pago de cuota registrado exitosamente')),
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
      print("Error al pagar cuota: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error al registrar el pago de cuota: ${e.toString()}')),
      );
    }
  }
}
