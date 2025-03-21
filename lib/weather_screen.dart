import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _controller = TextEditingController();
  String _city = '';
  List<Map<String, dynamic>> _forecast = [];
  String _error = '';
  LatLng _cityLatLng = LatLng(0.0, 0.0); // Coordenadas predeterminadas (lat, lng)

String _normalizeCityName(String city) {
  Map<String, String> replacements = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n'
  };
  city = city.toLowerCase(); // Convertimos a minúsculas para uniformidad
  replacements.forEach((key, value) {
    city = city.replaceAll(key, value);
  });
  return city;
}


  Future<void> _fetchWeather() async {
    final String apiKey = '1bacfbd7cde7607f9441c8e0c8d09a69'; // Sustituir con tu clave API
    final String cityNormalized = _normalizeCityName(_city);

final String url = 'https://api.openweathermap.org/data/2.5/forecast?q=$cityNormalized,ES&appid=$apiKey&units=metric&lang=es';
final response = await http.get(Uri.parse(url));
print(response.body);  // Ver la respuesta completa para detectar posibles errores


    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> dailyForecast = [];
        Map<String, dynamic> dailyData = {};

        var dateFormat = DateFormat('dd/MM/yyyy');

        for (var entry in data['list']) {
          final DateTime dt = DateTime.fromMillisecondsSinceEpoch(entry['dt'] * 1000);
          final date = dateFormat.format(dt);

          Map<String, String> weekDaysTranslation = {
            'Monday': 'Lunes',
            'Tuesday': 'Martes',
            'Wednesday': 'Miércoles',
            'Thursday': 'Jueves',
            'Friday': 'Viernes',
            'Saturday': 'Sábado',
            'Sunday': 'Domingo',
          };

          if (!dailyData.containsKey(date)) {
            String dayOfWeekEnglish = DateFormat('EEEE').format(dt);
            String dayOfWeekSpanish = weekDaysTranslation[dayOfWeekEnglish] ?? dayOfWeekEnglish;

            dailyData[date] = {
              'date': date,
              'dayOfWeek': dayOfWeekSpanish,
              'temp': entry['main']['temp'],
              'description': entry['weather'][0]['description'],
              'rain': entry['rain'] != null ? (entry['rain']['3h'] as num).toDouble() : 0.0,
              'icon': entry['weather'][0]['icon'],
            };
          }
        }

        dailyForecast = List<Map<String, dynamic>>.from(dailyData.values);

        double lat = data['city']['coord']['lat'];
        double lon = data['city']['coord']['lon'];
        _cityLatLng = LatLng(lat, lon);

        setState(() {
          _forecast = dailyForecast;
          _error = '';  
        });

      } else {
        setState(() {
          _error = 'Ciudad no encontrada';
          _forecast = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al obtener los datos del clima';
        _forecast = [];
      });
    }
  }

  IconData _getWeatherIcon(String iconCode) {
    Map<String, IconData> iconMap = {
      '01d': Icons.wb_sunny,
      '01n': Icons.nightlight_round,
      '02d': Icons.cloud,
      '02n': Icons.cloud,
      '03d': Icons.cloud,
      '03n': Icons.cloud,
      '04d': Icons.cloud_outlined,
      '04n': Icons.cloud_outlined,
      '09d': Icons.water_drop,
      '09n': Icons.water_drop,
      '10d': Icons.umbrella,
      '10n': Icons.umbrella,
      '11d': Icons.thunderstorm,
      '11n': Icons.thunderstorm,
      '13d': Icons.ac_unit,
      '13n': Icons.ac_unit,
      '50d': Icons.foggy,
      '50n': Icons.foggy,
    };

    return iconMap[iconCode] ?? Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Ingresa la ciudad',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _city = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_city.isNotEmpty) {
                  _fetchWeather();
                }
              },
              child: const Text('Obtener pronóstico semanal'),
            ),
            const SizedBox(height: 20),
            if (_error.isNotEmpty)
              Text(
                _error,
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            if (_forecast.isNotEmpty) 
              Expanded(
                child: ListView.builder(
                  itemCount: _forecast.length,
                  itemBuilder: (context, index) {
                    final forecast = _forecast[index];
                    final rain = forecast['rain'] ?? 0.0;
                    final iconCode = forecast['icon'] ?? '';

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _getWeatherIcon(iconCode),
                          size: 40,
                          color: Colors.blue,
                        ),
                        title: Text(forecast['date']),
                        subtitle: Text('${forecast['dayOfWeek']}'),
                        trailing: Text('${forecast['temp']}°C'),
                        onTap: rain > 0 ? () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Precipitaciones'),
                                content: Text(rain > 0
                                    ? 'Precipitaciones: $rain mm'
                                    : 'No hay precipitaciones'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              );
                            },
                          );
                        } : null,
                      ),
                    );
                  },
                ),
              ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _cityLatLng,
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: [],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _cityLatLng,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
