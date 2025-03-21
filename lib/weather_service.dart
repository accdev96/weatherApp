import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String _apiKey = 'YOUR_API_KEY'; // Reemplaza con tu clave de API
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5/';

  // Obtener el clima actual y pronóstico para 5 días
  Future<Map<String, dynamic>> getWeather(String city) async {
    final url = Uri.parse(
        '$_baseUrl/weather?q=$city&appid=$_apiKey&units=metric&lang=es'); // Obtiene el clima actual

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener el clima');
    }
  }

  // Obtener el pronóstico de 5 días (cada 3 horas)
  Future<Map<String, dynamic>> getDailyForecast(String city) async {
    final url = Uri.parse(
        '$_baseUrl/forecast?q=$city&appid=$_apiKey&units=metric&lang=es'); // Pronóstico cada 3 horas

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener el pronóstico diario');
    }
  }
}
