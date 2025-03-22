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
  LatLng _cityLatLng = LatLng(
    0.0,
    0.0,
  ); // Coordenadas predeterminadas (lat, lng)
  int _selectedIndex = 0; // Para controlar el índice del BottomNavigationBar

  bool _showTempLayer =
      true; // Controla la visibilidad de la capa de temperatura

  // Métodos para obtener el pronóstico por horas y por el día
  Future<void> _fetchWeather() async {
    final String apiKey =
        '1bacfbd7cde7607f9441c8e0c8d09a69'; // Sustituir con tu clave API
    final String url =
        'https://api.openweathermap.org/data/2.5/forecast?q=$_city,ES&appid=$apiKey&units=metric&lang=es';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> dailyForecast = [];
        Map<String, dynamic> dailyData = {};

        var dateFormat = DateFormat('dd/MM/yyyy');

        for (var entry in data['list']) {
          final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
            entry['dt'] * 1000,
          );
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
            String dayOfWeekSpanish =
                weekDaysTranslation[dayOfWeekEnglish] ?? dayOfWeekEnglish;

            dailyData[date] = {
              'date': date,
              'dayOfWeek': dayOfWeekSpanish,
              'temp': entry['main']['temp'],
              'description': entry['weather'][0]['description'],
              'rain':
                  entry['rain'] != null
                      ? (entry['rain']['3h'] as num).toDouble()
                      : 0.0,
              'icon': entry['weather'][0]['icon'],
            };
          }
        }

        dailyForecast = List<Map<String, dynamic>>.from(dailyData.values);

        double lat =
            (data['city']['coord']['lat'] is int)
                ? (data['city']['coord']['lat'] as int).toDouble()
                : data['city']['coord']['lat'];

        double lon =
            (data['city']['coord']['lon'] is int)
                ? (data['city']['coord']['lon'] as int).toDouble()
                : data['city']['coord']['lon'];

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
      print(e);
      setState(() {
        _error = 'Error al obtener los datos del clima';
        _forecast = [];
      });
    }
  }

  // Método para navegar entre las vistas
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Método para obtener la vista según el índice seleccionado
  Widget _getCurrentView() {
    switch (_selectedIndex) {
      case 0: // Días
        return _buildForecastView();
      case 1: // Horas
        return _buildHourlyForecastView();
      case 2: // Inicio
        return _buildTodayView();
      case 3: // Mapas
        return _buildMapView();
      default:
        return _buildForecastView();
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

  // Construir vista de pronóstico diario
  Widget _buildForecastView() {
    return Column(
      children: <Widget>[
        if (_error.isNotEmpty)
          Text(_error, style: TextStyle(color: Colors.red, fontSize: 18)),
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
                    onTap:
                        rain > 0
                            ? () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Precipitaciones'),
                                    content: Text(
                                      rain > 0
                                          ? 'Precipitaciones: $rain mm'
                                          : 'No hay precipitaciones',
                                    ),
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
                            }
                            : null,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Vista de pronóstico por horas (a implementar)
  Widget _buildHourlyForecastView() {
    return Center(child: Text("Pronóstico por horas (Aún no implementado)"));
  }

  // Vista de información de hoy (A Implementar)
  Widget _buildTodayView() {
    return Center(
      child: Text("Información del día de hoy (Aún no implementado)"),
    );
  }

  // Vista del mapa
  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _cityLatLng, // Coordenadas de la ciudad
        initialZoom: 12.0, // Nivel de zoom inicial
        maxZoom: 10.0,
        minZoom: 5.0
      ),
      children: [
        if (_showTempLayer) // Mostrar capa de temperatura si está activa
          TileLayer(
            urlTemplate:
                "https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=1bacfbd7cde7607f9441c8e0c8d09a69", // URL de la capa de temperatura
            subdomains: [
              'a',
              'b',
              'c',
            ], // Subdominios para distribuir las solicitudes de tiles
          ),
        // Puedes agregar más capas aquí según lo que quieras mostrar
      ],
    );
  }

  // Botón para alternar capas
  void _toggleLayer() {
    setState(() {
      _showTempLayer = !_showTempLayer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(
              _showTempLayer ? Icons.remove : Icons.add,
              size: 30, // Ajustar el tamaño del icono
              color:
                  Colors
                      .white, // Asegurarse de que el color del icono sea visible
            ),
            onPressed: _toggleLayer, // Cambiar capa al presionar
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: _selectedIndex != 3, // Ocultar en Mapas
              child: Column(
                children: [
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
                  Visibility(
                    visible:
                        _selectedIndex == 0 ||
                        _selectedIndex == 1, // Mostrar solo en Días y Horas
                    child: ElevatedButton(
                      onPressed: () {
                        if (_city.isNotEmpty) {
                          _fetchWeather();
                        }
                      },
                      child: Text(
                        _selectedIndex == 1
                            ? 'Obtener pronóstico por horas'
                            : 'Obtener pronóstico semanal',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(child: _getCurrentView()), // Mostrar la vista actual
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue, // Color de fondo del menú
        selectedItemColor: Colors.white, // Color del icono y texto seleccionado
        unselectedItemColor: Colors.white70, // Color de iconos no seleccionados
        showUnselectedLabels:
            true, // Mostrar etiquetas en elementos no seleccionados
        type:
            BottomNavigationBarType
                .fixed, // Evita animaciones molestas en más de 3 ítems
        elevation: 10, // Agrega sombra al menú
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Días',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Horas'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapas'),
        ],
      ),
    );
  }
}
