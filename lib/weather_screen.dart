import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_icons/weather_icons.dart' as Weather;
import 'package:weather_icons/weather_icons.dart';

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

  int _selectedIndex = 0; // Para controlar el índice del BottomNavigationBar

 final bool _showTempLayer =
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
        print("Datos recibidos: $data");

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
        return _buildTodayView(_forecast, _city);
      case 2: // Mapas
        return _buildMapView();
      default:
        return _buildForecastView();
    }
  }

  IconData _getWeatherIcon(String iconCode) {
    Map<String, IconData> iconMap = {
      '01d': Weather.WeatherIcons.day_sunny, // ☀️ Día soleado
      '01n': Weather.WeatherIcons.night_clear, // 🌙 Noche despejada
      '02d': Weather.WeatherIcons.day_cloudy, // 🌤️ Parcialmente nublado (día)
      '02n':
          Weather
              .WeatherIcons
              .night_alt_cloudy, // 🌥️ Parcialmente nublado (noche)
      '03d': Weather.WeatherIcons.cloud, // ☁️ Nublado
      '03n': Weather.WeatherIcons.cloud,
      '04d': Weather.WeatherIcons.cloudy, // ☁️☁️ Nublado denso
      '04n': Weather.WeatherIcons.cloudy,
      '09d': Weather.WeatherIcons.showers, // 🌦️ Lluvias ligeras
      '09n': Weather.WeatherIcons.showers,
      '10d': Weather.WeatherIcons.rain, // 🌧️ Lluvia
      '10n': Weather.WeatherIcons.rain,
      '11d': Weather.WeatherIcons.thunderstorm, // ⛈️ Tormenta
      '11n': Weather.WeatherIcons.thunderstorm,
      '13d': Weather.WeatherIcons.snow, // ❄️ Nieve
      '13n': Weather.WeatherIcons.snow,
      '50d': Weather.WeatherIcons.fog, // 🌫️ Niebla
      '50n': Weather.WeatherIcons.fog,
    };

    return iconMap[iconCode] ?? Icons.error;
  }

  Widget _buildForecastView() {
  return Container(
    color: Color(0xFFFef7FF), // 🎨 Fondo azul claro
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
                final iconCode = forecast['icon'] ?? ''; // Obtener el código del icono

                return GestureDetector(
                  onTap: () {
                    // Filtra los datos de previsión por horas
                    final hourlyData = _hourlyForecast
                        .where(
                          (entry) => entry['date'] == forecast['date'],
                        )
                        .toList();

                    // Navega a la nueva pantalla para mostrar la previsión por horas
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _buildForecastHours(
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
                      borderRadius: BorderRadius.circular(12), // Bordes redondeados
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Día y fecha
                          Text(
                            '${forecast['dayOfWeek']} ${forecast['date']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),

                          // Información de la temperatura máxima
                          Row(
                            children: [
                              Icon(
                                Icons.wb_sunny, // Icono para el día soleado
                                size: 20,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Máx: ${forecast['temp_max'].toStringAsFixed(0)}°C',
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.cloud, // Icono de nubes
                                size: 20,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Mín: ${forecast['temp_min'].toStringAsFixed(0)}°C',
                              ),
                            ],
                          ),

                          // Row con probabilidad de lluvia y temperatura actual
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.beach_access, // Icono de lluvia
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Lluvia: ${forecast['pop']}%'),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.thermostat_outlined, // Icono de termómetro
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Temp: ${forecast['temp'].toStringAsFixed(0)}°C',
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Información de la humedad y descripción
                          Row(
                            children: [
                              Icon(
                                Icons.water_drop, // Icono de humedad
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              SizedBox(width: 8),
                              Text('Humedad: ${forecast['humidity']}%'),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.description, // Icono de descripción
                                size: 20,
                                color: Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Descripción: ${forecast['description'][0].toUpperCase()}${forecast['description'].substring(1)}',
                              ),
                            ],
                          ),
                        ],
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
      title: Text(
        'Previsión por horas',
        style: GoogleFonts.raleway(fontWeight: FontWeight.bold), // Fuente moderna
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(30),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Fecha: $dayOfWeek, $date',
            style: GoogleFonts.raleway(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Gradiente azul moderno
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
                  elevation: 5, // Sombra más sutil
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Bordes más redondeados
                  ),
                  child: ListTile(
                    leading: Icon(
                      _getWeatherIcon(iconCode),
                      size: 30,
                      color: Colors.blueAccent, // Color azul para los íconos
                    ),
                    title: Text(
                      '🕒 Hora: $hour',
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.bold,
                        fontSize: 16, // Tamaño de fuente más grande
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.thermostat_outlined, // Icono de temperatura
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 5),
                            Text(
                              '${hourData['temp'].toStringAsFixed(0)}°C',
                              style: GoogleFonts.raleway(fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              WeatherIcons.rain, // Icono de lluvia
                              size: 20,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Prob. Lluvia: ${hourData['pop'].toStringAsFixed(0)}%',
                              style: GoogleFonts.raleway(fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop, // Icono de humedad
                              size: 20,
                              color: Colors.blueAccent,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Humedad: ${hourData['humidity']}%',
                              style: GoogleFonts.raleway(fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.air, // Icono de viento
                              size: 20,
                              color: Colors.green,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Viento: ${(hourData['wind'] * 3.6).toStringAsFixed(0)} Km/h',
                              style: GoogleFonts.raleway(fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on, // Icono de ubicación
                              size: 20,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 5),
                            Text(
                              '${hourData['description'][0].toUpperCase()}${hourData['description'].substring(1)}',
                              style: GoogleFonts.raleway(fontSize: 14),
                            ),
                          ],
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

  Widget _buildTodayView(List<Map<String, dynamic>> _forecast, String _city) {
    final today = DateTime.now();
    final todayDateString =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    final todayForecast =
        _forecast
            .where((forecast) => forecast['date'] == todayDateString)
            .toList();

    if (todayForecast.isEmpty || _city.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 100, color: Colors.grey.shade600),
            SizedBox(height: 10),
            Text(
              "Debe seleccionar una localización en la pantalla de 'Días'",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
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
          colors: [Color(0xFF4A90E2), Color(0xFF17375E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(height: 40),
          Icon(_getWeatherIcon(iconCode), size: 100, color: Colors.white),
          SizedBox(height: 8),
          Text(
            '${forecast['dayOfWeek']} ${forecast['date']}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '${_city[0].toUpperCase()}${_city.substring(1)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          Spacer(),
          Text(
            '${forecast['temp'].toStringAsFixed(0)}°C',
            style: GoogleFonts.montserrat(
              fontSize: 80,
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
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 400),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _infoRow(
                      WeatherIcons.thermometer,
                      'Máx',
                      '${forecast['temp_max'].toStringAsFixed(0)}°C',
                    ),
                    _infoRow(
                      WeatherIcons.snowflake_cold,
                      'Mín',
                      '${forecast['temp_min'].toStringAsFixed(0)}°C',
                    ),
                    _infoRow(
                      WeatherIcons.raindrops,
                      'Lluvia',
                      '${forecast['pop']}%',
                    ),
                    _infoRow(
                      WeatherIcons.humidity,
                      'Humedad',
                      '${forecast['humidity']}%',
                    ),
                    _infoRow(
                      WeatherIcons.strong_wind,
                      'Viento',
                      '${(forecast['wind'] * 3.6).toStringAsFixed(0)} Km/h',
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(label, style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 16)),
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
          children: <Widget>[
            const SizedBox(
              height: 40,
            ), // Empuja el buscador un poco hacia abajo
            Visibility(
              visible: _selectedIndex == 0,
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
                  ElevatedButton(
                    onPressed: () {
                      if (_city.isNotEmpty) {
                        _fetchWeather();
                      }
                    },
                    child: Text('Obtener pronóstico semanal'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(child: _getCurrentView()), // Mantiene la vista expandida
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
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
