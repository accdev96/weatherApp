import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _controller = TextEditingController();
  String _city = '';
  List<Map<String, dynamic>> _forecast = [];
  List<Map<String, dynamic>> _hourlyForecast = [];

  String _error = '';
  LatLng _cityLatLng = LatLng(
    0.0,
    0.0,
  ); // Coordenadas predeterminadas (lat, lng)
  int _selectedIndex = 0; // Para controlar el índice del BottomNavigationBar

  bool _showTempLayer = true;
  bool _showPrecipitationLayer = true;

  Map<String, double> maxTemperaturesPerDay = {};
  Map<String, double> minTemperaturesPerDay = {};

  // Métodos para obtener el pronóstico por horas y por el día
  Future<void> _fetchWeather() async {
    final String apiKey = '1bacfbd7cde7607f9441c8e0c8d09a69'; // Clave API
    final String url =
        'https://api.openweathermap.org/data/2.5/forecast?q=$_city,ES&appid=$apiKey&units=metric&lang=es';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        Map<String, dynamic> dailyData = {};
        var dateFormat = DateFormat('dd/MM/yyyy');
        Map<String, String> weekDaysTranslation = {
          'Monday': 'Lunes',
          'Tuesday': 'Martes',
          'Wednesday': 'Miércoles',
          'Thursday': 'Jueves',
          'Friday': 'Viernes',
          'Saturday': 'Sábado',
          'Sunday': 'Domingo',
        };

        List<Map<String, dynamic>> hourlyForecast = [];
        Map<String, Map<String, dynamic>> groupedForecast = {};

        for (var entry in data['list']) {
          final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
            entry['dt'] * 1000,
          );
          final String date = dateFormat.format(dt);
          final String hour = DateFormat('HH:mm').format(dt);

          final double temp = (entry['main']['temp'] as num).toDouble();
          final double tempMin = (entry['main']['temp_min'] as num).toDouble();
          final double tempMax = (entry['main']['temp_max'] as num).toDouble();
          final double windSpeedKmh =
              (entry['wind']['speed'] as num).toDouble() * 3.6;
          final double pop =
              entry.containsKey('pop') ? (entry['pop'] as num) * 100 : 0.0;
          final int humidity = entry['main']['humidity'] as int;
          final String description = entry['weather'][0]['description'];
          final String icon = entry['weather'][0]['icon'];

          // Actualizar el pronóstico por día
          if (!groupedForecast.containsKey(date)) {
            groupedForecast[date] = {
              'date': date,
              'temp': temp,
              'temp_min': tempMin,
              'temp_max': tempMax,
              'pop': pop,
              'wind': windSpeedKmh,
              'description': description,
              'humidity': humidity,
              'icon': icon,
            };
          } else {
            groupedForecast[date]!['temp_min'] =
                tempMin < groupedForecast[date]!['temp_min']
                    ? tempMin
                    : groupedForecast[date]!['temp_min'];
            groupedForecast[date]!['temp_max'] =
                tempMax > groupedForecast[date]!['temp_max']
                    ? tempMax
                    : groupedForecast[date]!['temp_max'];
            groupedForecast[date]!['pop'] =
                pop > groupedForecast[date]!['pop']
                    ? pop
                    : groupedForecast[date]!['pop'];
          }

          // Pronóstico por horas
          hourlyForecast.add({
            'date': date,
            'hour': hour,
            'temp': temp,
            'temp_max': tempMax,
            'temp_min': tempMin,
            'pop': pop,
            'wind': windSpeedKmh,
            'humidity': humidity,
            'description': description,
            'icon': icon,
          });

          if (!dailyData.containsKey(date)) {
            String dayOfWeekEnglish = DateFormat('EEEE').format(dt);
            String dayOfWeekSpanish =
                weekDaysTranslation[dayOfWeekEnglish] ?? dayOfWeekEnglish;

            dailyData[date] = {
              'date': date,
              'dayOfWeek': dayOfWeekSpanish,
              'temp': temp,
              'temp_max':
                  maxTemperaturesPerDay.containsKey(date)
                      ? maxTemperaturesPerDay[date]
                      : null,
              'temp_min':
                  minTemperaturesPerDay.containsKey(date)
                      ? minTemperaturesPerDay[date]
                      : null,
              'pop': pop.toInt(),
              'wind': windSpeedKmh.toStringAsFixed(1),
              'humidity': humidity,
              'description': description,
              'rain':
                  entry['rain'] != null
                      ? (entry['rain']['3h'] as num).toDouble()
                      : 0.0,
              'icon': icon,
            };
          }
        }

        double lat = (data['city']['coord']['lat'] as num).toDouble();
        double lon = (data['city']['coord']['lon'] as num).toDouble();
        _cityLatLng = LatLng(lat, lon);

        setState(() {
          _forecast = List<Map<String, dynamic>>.from(dailyData.values);
          _hourlyForecast = hourlyForecast;
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
                final iconCode = forecast['icon'] ?? '';

                return Card(
                  child: ListTile(
                    leading: Icon(
                      _getWeatherIcon(iconCode),
                      size: 40,
                      color: Colors.blue,
                    ),
                    title: Text(
                      '${forecast['dayOfWeek']} - ${forecast['date']}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '☀️ Máx: ${forecast['temp_max']}°C  🌡️ Mín: ${forecast['temp_min']}°C',
                        ),
                        Text('🌧️ Prob. Lluvia: ${forecast['pop']}%'),
                        Text('💧 Humedad: ${forecast['humidity']}'),
                        Text('🌬️ Viento: ${forecast['wind']}Km/h'),
                        Text(
                          '📌 ${forecast['description'][0].toUpperCase()}${forecast['description'].substring(1)}',
                        ),
                      ],
                    ),
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
    return Column(
      children: <Widget>[
        if (_error.isNotEmpty)
          Text(_error, style: TextStyle(color: Colors.red, fontSize: 18)),
        if (_hourlyForecast.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _hourlyForecast.length,
              itemBuilder: (context, index) {
                final forecast = _hourlyForecast[index];

                return Card(
                  child: ListTile(
                    leading: Icon(
                      _getWeatherIcon(forecast['icon']),
                      size: 40,
                      color: Colors.blue,
                    ),
                    title: Text('${forecast['date']} - ${forecast['hour']}'),
                    subtitle: Text(forecast['description']),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Vista de información de hoy (A Implementar)
  Widget _buildTodayView() {
    return Center(
      child: Text("Información del día de hoy (Aún no implementado)"),
    );
  }

  // Vista del mapa
  Widget _buildMapView() {
    final initialLatLng = _cityLatLng ?? LatLng(40.4168, -3.7038);

    return FlutterMap(
      options: MapOptions(
        initialCenter: initialLatLng, // Coordenadas iniciales
        initialZoom: 10.0, // Zoom inicial
        maxZoom: 12.0, // Zoom máximo
        minZoom: 5.0, // Zoom mínimo
      ),
      children: [
        // 1. Mapa base (OpenStreetMap)
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.app',
        ),
        // 2. Capa de temperatura de OpenWeatherMap (solo si _showTempLayer es verdadero)
        if (_showTempLayer)
          TileLayer(
            urlTemplate:
                "https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=1bacfbd7cde7607f9441c8e0c8d09a69",
            userAgentPackageName: 'com.example.app',
          ),
        // 3. Capa de precipitaciones de OpenWeatherMap (solo si _showPrecipitationLayer es verdadero)
        if (_showPrecipitationLayer)
          TileLayer(
            urlTemplate:
                "https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=1bacfbd7cde7607f9441c8e0c8d09a69",
            userAgentPackageName: 'com.example.app',
          ),
        Positioned(
          top: 20,
          right: 10,
          child: FloatingActionButton(
            onPressed: _toggleLayer, // Cambiar capa al presionar
            mini: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showTempLayer ? Icons.remove : Icons.add,
                  size: 10,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Botón para alternar capas
  void _toggleLayer() {
    setState(() {
      _showTempLayer = !_showTempLayer;
      _showPrecipitationLayer = !_showPrecipitationLayer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        backgroundColor: Colors.blue,
        actions: [],
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
