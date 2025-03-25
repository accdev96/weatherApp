import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<Map<String, dynamic>> _hourlyForecast = [];

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

          List<Map<String, dynamic>> hourlyForecast = [];
          Map<String, Map<String, dynamic>> groupedForecast = {};

          for (var entry in data['list']) {
            final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
              entry['dt'] * 1000,
            );
            final String date = DateFormat('dd/MM/yyyy').format(dt);
            final String hour = DateFormat('HH:mm').format(dt);

            final double temp =
                entry['main']['temp'] is num
                    ? (entry['main']['temp'] as num).toDouble()
                    : 0.0;

            final double temp_min =
                entry['main']['temp_min'] is num
                    ? (entry['main']['temp_min'] as num).toDouble()
                    : 0.0;

            final double temp_max =
                entry['main']['temp_max'] is num
                    ? (entry['main']['temp_max'] as num).toDouble()
                    : 0.0;

            final double pop =
                entry.containsKey('pop')
                    ? (entry['pop'] is num ? (entry['pop'] as num) * 100 : 0.0)
                    : 0.0;

            final int humidity =
                entry['main']['humidity'] is int
                    ? entry['main']['humidity'] as int
                    : 0;

            final String city =
                entry['city'] != null
                    ? entry['city']['name']
                    : 'Ciudad no disponible';

            final double wind =
                entry.containsKey('wind')
                    ? (entry['wind']['speed'] is num
                        ? (entry['wind']['speed'] as num) * 100
                        : 0.0)
                    : 0.0;

            final String description = entry['weather'][0]['description'];
            final String icon = entry['weather'][0]['icon'];

            // Agrupamos los datos del pronóstico por ciudad y fecha
            if (!groupedForecast.containsKey(city)) {
              groupedForecast[city] =
                  {}; // Inicializamos el mapa para la ciudad
            }

            if (!groupedForecast[city]!.containsKey(date)) {
              groupedForecast[city]![date] = {
                'date': date,
                'city': city,
                'temp': temp,
                'temp_min': temp_min,
                'temp_max': temp_max,
                'pop': pop,
                'humidity': humidity,
                'description': description,
                'icon': icon,
                'wind': wind,
              };
            } else {
              // Actualizamos las temperaturas máximas y mínimas para cada ciudad y fecha
              // Aseguramos que las temperaturas mínimas y máximas se actualicen correctamente
              groupedForecast[city]![date]!['temp_min'] =
                  (temp_min < groupedForecast[city]![date]!['temp_min'])
                      ? temp_min
                      : groupedForecast[city]![date]!['temp_min'];

              groupedForecast[city]![date]!['temp_max'] =
                  (temp_max > groupedForecast[city]![date]!['temp_max'])
                      ? temp_max
                      : groupedForecast[city]![date]!['temp_max'];

              // Actualizamos la probabilidad de precipitación si es mayor
              groupedForecast[city]![date]!['pop'] =
                  (pop > groupedForecast[city]![date]!['pop'])
                      ? pop
                      : groupedForecast[city]![date]!['pop'];
            }

            hourlyForecast.add({
              'city': city,
              'date': date,
              'hour': hour,
              'temp': entry['main']['temp'],
              'temp_max': entry['main']['temp_max'],
              'temp_min': entry['main']['temp_min'],
              'pop': pop,
              'humidity': entry['main']['humidity'],
              'description': entry['weather'][0]['description'],
              'icon': entry['weather'][0]['icon'],
              'wind': entry['wind']['speed'],
            });
          }

          // Convertimos los pronósticos diarios en una lista de mapas
          List<Map<String, dynamic>> dailyForecast = [];

          groupedForecast.forEach((city, cityForecasts) {
            cityForecasts.forEach((date, forecast) {
              print(date);
              dailyForecast.add(forecast);
            });
          });

          setState(() {
            _hourlyForecast = hourlyForecast;
          });

          if (!dailyData.containsKey(date)) {
            String dayOfWeekEnglish = DateFormat('EEEE').format(dt);
            String dayOfWeekSpanish =
                weekDaysTranslation[dayOfWeekEnglish] ?? dayOfWeekEnglish;
            final double pop =
                entry.containsKey('pop')
                    ? (entry['pop'] is num ? (entry['pop'] as num) * 100 : 0.0)
                    : 0.0;
            final int popInt =
                pop == pop.toInt() ? pop.toInt() : pop.toDouble().toInt();

            dailyData[date] = {
              'date': date,
              'dayOfWeek': dayOfWeekSpanish,
              'temp': entry['main']['temp'],
              'temp_max': entry['main']['temp_max'],
              'temp_min': entry['main']['temp_min'],
              'pop': popInt,
              'humidity': entry['main']['humidity'],
              'description': entry['weather'][0]['description'],
              'rain':
                  entry['rain'] != null
                      ? (entry['rain']['3h'] as num).toDouble()
                      : 0.0,
              'icon': entry['weather'][0]['icon'],
              'wind': entry['wind']['speed'],
            };
          } else {
            // Si ya existe la fecha, actualizamos las temperaturas
            String dayOfWeekEnglish = DateFormat('EEEE').format(dt);
            String dayOfWeekSpanish =
                weekDaysTranslation[dayOfWeekEnglish] ?? dayOfWeekEnglish;

            final double pop =
                entry.containsKey('pop')
                    ? (entry['pop'] is num ? (entry['pop'] as num) * 100 : 0.0)
                    : 0.0;

            final int popInt =
                pop == pop.toInt() ? pop.toInt() : pop.toDouble().toInt();

            final double newTempMax =
                entry['main']['temp_max'] is num
                    ? (entry['main']['temp_max'] as num).toDouble()
                    : 0.0;

            final double newTempMin =
                entry['main']['temp_min'] is num
                    ? (entry['main']['temp_min'] as num).toDouble()
                    : 0.0;

            final double newWind =
                entry['wind']['speed'] is num
                    ? (entry['wind']['speed'] as num).toDouble()
                    : 0.0;

            // Actualizamos las temperaturas máximas y mínimas si es necesario
            final double updatedTempMax =
                newTempMax > dailyData[date]['temp_max']
                    ? newTempMax
                    : dailyData[date]['temp_max'];

            final double updatedTempMin =
                newTempMin < dailyData[date]['temp_min']
                    ? newTempMin
                    : dailyData[date]['temp_min'];

            dailyData[date] = {
              'date': date,
              'dayOfWeek': dayOfWeekSpanish,
              'temp': entry['main']['temp'],
              'temp_max': updatedTempMax,
              'temp_min': updatedTempMin,
              'pop': popInt,
              'humidity': entry['main']['humidity'],
              'description': entry['weather'][0]['description'],
              'rain':
                  entry['rain'] != null
                      ? (entry['rain']['3h'] as num).toDouble()
                      : 0.0,
              'icon': entry['weather'][0]['icon'],
              'wind': entry['wind']['speed'],
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
      case 1: // Inicio
        return _buildTodayView();
      case 2: // Mapas
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
    return Container(
      color: Color.fromARGB(255, 104, 192, 255), // 🎨 Fondo azul claro
      padding: const EdgeInsets.all(16.0),
      child: Column(
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

                  return GestureDetector(
                    onTap: () {
                      // Filtra los datos de previsión por horas
                      final hourlyData =
                          _hourlyForecast
                              .where(
                                (entry) => entry['date'] == forecast['date'],
                              )
                              .toList();

                      // Navega a la nueva pantalla para mostrar la previsión por horas
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => _buildForecastHours(
                                context,
                                forecast['date'],
                                hourlyData,
                              ),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white, // Fondo blanco para el Card
                      elevation: 3, // Sombra para dar profundidad
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Bordes redondeados
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getWeatherIcon(iconCode),
                          size: 40,
                          color: Colors.blue,
                        ),
                        title: Text(
                          '${forecast['dayOfWeek']} ${forecast['date']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '☀️ Máx: ${forecast['temp_max'].toStringAsFixed(0)}°C',
                            ),
                            Text(
                              '🌡️ Mín: ${forecast['temp_min'].toStringAsFixed(0)}°C',
                            ),
                            Text('🌧️ Prob. Lluvia: ${forecast['pop']}%'),
                            Text('💧 Humedad: ${forecast['humidity']}%'),
                            Text(
                              '📌 ${forecast['description'][0].toUpperCase()}${forecast['description'].substring(1)}',
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${forecast['temp'].toStringAsFixed(0)}°C',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String getDayOfWeekInSpanish(String date) {
    // Convertir la fecha de la cadena a un objeto DateTime usando el formato correcto
    DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(date);

    // Obtener el día de la semana en inglés
    String dayOfWeek = DateFormat('EEEE').format(parsedDate);

    // Mapa de días de la semana en inglés a español
    Map<String, String> daysOfWeekInSpanish = {
      'Monday': 'Lunes',
      'Tuesday': 'Martes',
      'Wednesday': 'Miércoles',
      'Thursday': 'Jueves',
      'Friday': 'Viernes',
      'Saturday': 'Sábado',
      'Sunday': 'Domingo',
    };

    // Convertir el día de la semana a español usando el mapa
    return daysOfWeekInSpanish[dayOfWeek] ??
        dayOfWeek; // En caso de no encontrar el día, devuelve el original
  }

  Widget _buildForecastHours(
    BuildContext context,
    String date,
    List<Map<String, dynamic>> hourlyData,
  ) {
    // Convertir la fecha de la cadena a un objeto DateTime usando el formato correcto
    DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(date);
    // Obtener el día de la semana
    String dayOfWeek = getDayOfWeekInSpanish(date);

    return Scaffold(
      appBar: AppBar(
        title: Text('Previsión por horas'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Fecha: $dayOfWeek, $date',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: Container(
        color: Color.fromARGB(255, 56, 160, 235), // 🎨 Fondo azul claro
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: hourlyData.length,
                itemBuilder: (context, index) {
                  final hourData = hourlyData[index];
                  final iconCode = hourData['icon'] ?? '';
                  final hour = hourData['hour'];

                  return Card(
                    color: Colors.white, // Fondo blanco para el Card
                    elevation: 3, // Sombra para dar efecto de profundidad
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Bordes redondeados
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getWeatherIcon(iconCode),
                        size: 30,
                        color: Colors.blue,
                      ),
                      title: Text(
                        '🕒 Hora: $hour',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🌡️ Temp: ${hourData['temp'].toStringAsFixed(0)}°C',
                          ),
                          Text(
                            '🌧️ Prob. Lluvia: ${hourData['pop'].toStringAsFixed(0)}%',
                          ),
                          Text('💧 Humedad: ${hourData['humidity']}%'),
                          Text(
                            '💨 Viento: ${(hourData['wind'] * 3.6).toStringAsFixed(0)} Km/h',
                          ),
                          Text(
                            '📌 ${hourData['description'][0].toUpperCase()}${hourData['description'].substring(1)}',
                          ),
                        ],
                      ),
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

  Widget _buildTodayView() {
    final today = DateTime.now();
    final todayDateString =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    final cityActual = _city;

    final todayForecast =
        _forecast
            .where((forecast) => forecast['date'] == todayDateString)
            .toList();

    if (todayForecast.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "No forecast available for today",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final forecast = todayForecast[0];
    final iconCode = forecast['icon'] ?? '';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 84, 158, 223),
            Colors.blue.shade900,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: <Widget>[
          // Texto superior con icono
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Icon(_getWeatherIcon(iconCode), size: 80, color: Colors.white),
                Text(
                  '${forecast['dayOfWeek']} ${forecast['date']}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '📌 ${cityActual[0].toUpperCase()}${cityActual.substring(1)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          Spacer(), // Empuja la fecha y temperatura al centro
          // Fecha y temperatura en el centro
          Column(
            children: [
              SizedBox(height: 8),
              Text(
                '${forecast['temp'].toStringAsFixed(0)}°C',
                style: GoogleFonts.adamina(
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 5,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Spacer(), // Empuja el Card hacia abajo
          // Card en la parte inferior con detalles adicionales
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: Colors.black54,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '☀️ Máx: ${forecast['temp_max'].toStringAsFixed(0)}°C',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '🌡️ Mín: ${forecast['temp_min'].toStringAsFixed(0)}°C',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '🌧️ Prob. Lluvia: ${forecast['pop']}%',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '💧 Humedad: ${forecast['humidity']}%',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '💨 Viento: ${(forecast['wind'] * 3.6).toStringAsFixed(0)} Km/h',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(40.4168, -3.7038), // Coordenadas de la ciudad
        initialZoom: 5.0, // Nivel de zoom inicial
        maxZoom: 18.0, // Ajusta el zoom máximo
        minZoom: 5.0,
      ),
      children: [
        // Capa de mapa base (OpenStreetMap en este caso)
        TileLayer(
          urlTemplate:
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png", // URL de OpenStreetMap
          // Eliminamos los subdominios
        ),

        // Mostrar capa de temperatura si _showTempLayer es true
        if (_showTempLayer)
          TileLayer(
            urlTemplate:
                "https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=1bacfbd7cde7607f9441c8e0c8d09a69", // URL de la capa de temperatura
            subdomains: [
              'a',
              'b',
              'c',
            ], // Subdominios para distribuir las solicitudes de tiles (mantén esto solo si es necesario)
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: _selectedIndex == 0, // Ocultar en Mapas
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
                    visible: _selectedIndex == 0,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_city.isNotEmpty) {
                          _fetchWeather();
                        }
                      },
                      child: Text('Obtener pronóstico semanal'),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
        ],
      ),
    );
  }
}
