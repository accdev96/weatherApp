import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Importar intl

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _controller = TextEditingController();
  String _city = '';
  List<Map<String, dynamic>> _forecast = [];
  String _error = '';

  Future<void> _fetchWeather() async {
    final String apiKey = '1bacfbd7cde7607f9441c8e0c8d09a69'; // Sustituir con tu clave API
    final String url = 'https://api.openweathermap.org/data/2.5/forecast?q=$_city&appid=$apiKey&units=metric&lang=es';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Filtramos el pronóstico para obtener solo un valor por día
        List<Map<String, dynamic>> dailyForecast = [];
        Map<String, dynamic> dailyData = {};

        // Crear un objeto DateFormat
        var dateFormat = DateFormat('dd/MM/yyyy'); // Definir el formato de fecha

        for (var entry in data['list']) {
          final DateTime dt = DateTime.fromMillisecondsSinceEpoch(entry['dt'] * 1000);
          final date = dateFormat.format(dt); // Formatear la fecha al formato dd/MM/yyyy
          
          // Mapa para traducir los días de la semana de inglés a español
Map<String, String> weekDaysTranslation = {
  'Monday': 'Lunes',
  'Tuesday': 'Martes',
  'Wednesday': 'Miércoles',
  'Thursday': 'Jueves',
  'Friday': 'Viernes',
  'Saturday': 'Sábado',
  'Sunday': 'Domingos',
};

// Comprobamos si no existe la fecha y agregamos los datos
if (!dailyData.containsKey(date)) {
  // Obtener el nombre del día de la semana en inglés
  String dayOfWeekEnglish = DateFormat('EEEE').format(dt);

  // Traducir el día de la semana al español
  String dayOfWeekSpanish = weekDaysTranslation[dayOfWeekEnglish] ?? dayOfWeekEnglish;

  dailyData[date] = {
    'date': date,  // Almacenar la fecha
    'dayOfWeek': dayOfWeekSpanish, // Día de la semana en español
    'temp': entry['main']['temp'], // Almacenar la temperatura
    'description': entry['weather'][0]['description'], // Almacenar la descripción del clima
    'rain': entry['rain'] != null ? (entry['rain']['3h'] as num).toDouble() : 0.0, // Convertir rain a double (precipitación)
    'icon': entry['weather'][0]['icon'], // Almacenar el ícono del clima
  };
}
        }

        dailyForecast = List<Map<String, dynamic>>.from(dailyData.values);

        setState(() {
          _forecast = dailyForecast;
          _error = '';  // Limpiar el error si la consulta es exitosa
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

  // Función para obtener el IconData correspondiente con un respaldo
  IconData _getWeatherIcon(String iconCode) {
    // Mapeo de iconos de OpenWeatherMap a Material Icons
    Map<String, IconData> iconMap = {
      '01d': Icons.wb_sunny,      // Soleado (día)
      '01n': Icons.nightlight_round,  // Soleado (noche)
      '02d': Icons.cloud,         // Nublado (día)
      '02n': Icons.cloud,         // Nublado (noche)
      '03d': Icons.cloud,         // Parcialmente nublado (día)
      '03n': Icons.cloud,         // Parcialmente nublado (noche)
      '04d': Icons.cloud_outlined, // Muy nublado (día)
      '04n': Icons.cloud_outlined, // Muy nublado (noche)
      '09d': Icons.water_drop,    // Lluvia ligera (día)
      '09n': Icons.water_drop,    // Lluvia ligera (noche)
      '10d': Icons.umbrella,      // Lluvia moderada (día)
      '10n': Icons.umbrella,      // Lluvia moderada (noche)
      '11d': Icons.thunderstorm,  // Tormenta (día)
      '11n': Icons.thunderstorm,  // Tormenta (noche)
      '13d': Icons.ac_unit,       // Nieve (día)
      '13n': Icons.ac_unit,       // Nieve (noche)
      '50d': Icons.foggy,         // Neblina (día)
      '50n': Icons.foggy,         // Neblina (noche)
    };

    // Retornar el IconData correspondiente o un ícono de error si no se encuentra en el mapeo
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
                    final rain = forecast['rain'] ?? 0.0; // Precipitación
                    final iconCode = forecast['icon'] ?? ''; // Obtener el código de icono

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _getWeatherIcon(iconCode), // Usamos la función para obtener el IconData
                          size: 40,
                          color: Colors.blue,
                        ),
                        title: Text(forecast['date']),
                        subtitle: Text('${forecast['dayOfWeek']}'), // Mostrar el día de la semana
                        trailing: Text('${forecast['temp']}°C'),
                        // Solo mostramos el botón para las precipitaciones si existe
                        onTap: rain > 0 ? () {
                          // Mostrar el valor de precipitación cuando el usuario presiona el item
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
                        } : null, // Si no hay precipitaciones, no se activa el botón
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
