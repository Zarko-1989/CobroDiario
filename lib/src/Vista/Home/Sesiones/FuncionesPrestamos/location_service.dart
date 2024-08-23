import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  Future<LocationData?> getCurrentLocation() async {
    try {
      // Verificar permisos de ubicación
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        // Solicitar permisos si no están concedidos
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Permisos de ubicación no concedidos.');
          return null;
        }
      }

      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        // Solicitar que el usuario habilite el servicio de ubicación
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('Servicio de ubicación no habilitado.');
          return null;
        }
      }

      // Obtener la ubicación actual
      return await _location.getLocation();
    } catch (e) {
      print('Error al obtener la ubicación: ${e.toString()}');
      return null;
    }
  }
}
