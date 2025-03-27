import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<String?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Los servicios de ubicación están deshabilitados.';
    }

    // Verifica los permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Los permisos de ubicación están denegados.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Los permisos de ubicación están denegados permanentemente.';
    }

    // Obtiene la ubicación actual
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // Usa la API de OpenWeatherMap para obtener el nombre de la ciudad
    final String apiKey = '1bacfbd7cde7607f9441c8e0c8d09a69';
    final String url = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&lang=es';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['name'];
      } else {
        return 'No se pudo obtener la ciudad actual.';
      }
    } catch (e) {
      print(e);
      return 'Error al obtener la ciudad actual.';
    }
  }
}