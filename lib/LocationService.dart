import 'package:geolocator/geolocator.dart';

class LocationService {
  // Método para obtener la ubicación actual del usuario
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    // Verifica si el permiso de ubicación está habilitado
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Se necesita permiso para acceder a la ubicación.');
      }
    }

    // Obtiene la ubicación actual
    return await Geolocator.getCurrentPosition();
  }
}
