import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_icons/weather_icons.dart' as Weather;
import 'package:weather_icons/weather_icons.dart';

class WeatherScreen extends StatefulWidget {
  final String city;
  WeatherScreen({required this.city});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _controller = TextEditingController();
  String _city = '';
  List<Map<String, dynamic>> _forecast = [];
  List<Map<String, dynamic>> _hourlyForecast = [];
  bool _showPrecipitationLayer = true;
  bool _showTemperatureLayer = true;
  bool _showWindLayer = true;
  bool _showCloudsLayer = true;
  String _error = '';
  int _selectedIndex = 0;
  final bool _showTempLayer = true;

  @override
  void initState() {
    super.initState();
    _city = widget.city;
    _fetchWeather();
    _selectedIndex = 1;
  }

  Future<void> _fetchWeather() async {
    final String apiKey = '1bacfbd7cde7607f9441c8e0c8d09a69';
    final String url =
        'https://api.openweathermap.org/data/2.5/forecast?q=$_city,ES&appid=$apiKey&units=metric&lang=es';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Datos recibidos: $data");

        List<Map<String, dynamic>> dailyForecast = [];
        Map<String, dynamic> dailyData = {};
        Map<String, Map<String, dynamic>> groupedForecast = {};
        List<Map<String, dynamic>> hourlyForecast = [];

        var dateFormat = DateFormat('dd/MM/yyyy');
        var weekDaysTranslation = {
          'Monday': 'Lunes',
          'Tuesday': 'Martes',
          'Wednesday': 'Miércoles',
          'Thursday': 'Jueves',
          'Friday': 'Viernes',
          'Saturday': 'Sábado',
          'Sunday': 'Domingo',
        };

        for (var entry in data['list']) {
          final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
            entry['dt'] * 1000,
          );
          final date = dateFormat.format(dt);
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
          final String description = entry['weather'][0]['description'];
          final String icon = entry['weather'][0]['icon'];
          final double wind =
              entry.containsKey('wind')
                  ? (entry['wind']['speed'] is num
                      ? (entry['wind']['speed'] as num).toDouble()
                      : 0.0)
                  : 0.0;
          hourlyForecast.add({
            'date': date,
            'hour': hour,
            'temp': temp,
            'temp_max': temp_max,
            'temp_min': temp_min,
            'pop': pop,
            'humidity': humidity,
            'description': description,
            'icon': icon,
            'wind': wind,
          });

          if (!groupedForecast.containsKey(date)) {
            groupedForecast[date] = {
              'date': date,
              'dayOfWeek':
                  weekDaysTranslation[DateFormat('EEEE').format(dt)] ??
                  DateFormat('EEEE').format(dt),
              'temp': temp,
              'temp_max': temp_max,
              'temp_min': temp_min,
              'pop': pop,
              'humidity': humidity,
              'description': description,
              'icon': icon,
              'wind': wind,
            };
          } else {
            groupedForecast[date]!['temp_min'] =
                (temp_min < groupedForecast[date]!['temp_min'])
                    ? temp_min
                    : groupedForecast[date]!['temp_min'];
            groupedForecast[date]!['temp_max'] =
                (temp_max > groupedForecast[date]!['temp_max'])
                    ? temp_max
                    : groupedForecast[date]!['temp_max'];
            groupedForecast[date]!['pop'] =
                (pop > groupedForecast[date]!['pop'])
                    ? pop
                    : groupedForecast[date]!['pop'];
          }
        }

        dailyForecast = List<Map<String, dynamic>>.from(groupedForecast.values);

        setState(() {
          _forecast = dailyForecast;
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _buildForecastView();
      case 1:
        return _buildTodayView(_forecast, _city);
      case 2:
        return _buildMapView();
      default:
        return _buildForecastView();
    }
  }

  IconData _getWeatherIcon(String iconCode) {
    Map<String, IconData> iconMap = {
      '01d': Weather.WeatherIcons.day_sunny,
      '01n': Weather.WeatherIcons.night_clear,
      '02d': Weather.WeatherIcons.day_cloudy,
      '02n': Weather.WeatherIcons.night_alt_cloudy,
      '03d': Weather.WeatherIcons.cloud,
      '03n': Weather.WeatherIcons.cloud,
      '04d': Weather.WeatherIcons.cloudy,
      '04n': Weather.WeatherIcons.cloudy,
      '09d': Weather.WeatherIcons.showers,
      '09n': Weather.WeatherIcons.showers,
      '10d': Weather.WeatherIcons.rain,
      '10n': Weather.WeatherIcons.rain,
      '11d': Weather.WeatherIcons.thunderstorm,
      '11n': Weather.WeatherIcons.thunderstorm,
      '13d': Weather.WeatherIcons.snow,
      '13n': Weather.WeatherIcons.snow,
      '50d': Weather.WeatherIcons.fog,
      '50n': Weather.WeatherIcons.fog,
    };

    return iconMap[iconCode] ?? Icons.error;
  }

 Widget _buildForecastView() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final screenHeight = constraints.maxHeight;

      return Container(
        color: Colors.blue,
        padding: EdgeInsets.all(screenWidth * 0.04), // Padding dinámico
        child: Column(
          children: <Widget>[
            if (_error.isNotEmpty)
              Text(
                _error,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: screenWidth * 0.045, // Texto responsivo
                ),
              ),
            if (_forecast.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _forecast.length,
                  itemBuilder: (context, index) {
                    final forecast = _forecast[index];
                    final iconCode = forecast['icon'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        final hourlyData = _hourlyForecast
                            .where((entry) => entry['date'] == forecast['date'])
                            .toList();
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
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03), // Bordes dinámicos
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.04), // Padding dinámico
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${forecast['dayOfWeek']} ${forecast['date']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.045, // Texto responsivo
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01), // Espaciado dinámico
                              Row(
                                children: [
                                  Icon(
                                    Icons.wb_sunny,
                                    size: screenWidth * 0.05, // Icono responsivo
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                  Text(
                                    'Temp. Máx: ${forecast['temp_max'].toStringAsFixed(0)}°C',
                                    style: TextStyle(fontSize: screenWidth * 0.04), // Texto responsivo
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.thermostat,
                                    size: screenWidth * 0.05, // Icono responsivo
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                  Text(
                                    'Temp. Mín: ${forecast['temp_min'].toStringAsFixed(0)}°C',
                                    style: TextStyle(fontSize: screenWidth * 0.04), // Texto responsivo
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.beach_access,
                                        size: screenWidth * 0.05, // Icono responsivo
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                      Text(
                                        'Lluvia: ${forecast['pop'].toStringAsFixed(0)}%',
                                        style: TextStyle(fontSize: screenWidth * 0.04), // Texto responsivo
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.thermostat_outlined,
                                        size: screenWidth * 0.05, // Icono responsivo
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                      Text(
                                        'Temp: ${forecast['temp'].toStringAsFixed(0)}°C',
                                        style: TextStyle(fontSize: screenWidth * 0.04), // Texto responsivo
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.water_drop,
                                    size: screenWidth * 0.05, // Icono responsivo
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                  Text(
                                    'Humedad: ${forecast['humidity']}%',
                                    style: TextStyle(fontSize: screenWidth * 0.04), // Texto responsivo
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    size: screenWidth * 0.05, // Icono responsivo
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                  Text(
                                    'Descripción: ${forecast['description'][0].toUpperCase()}${forecast['description'].substring(1)}',
                                    style: TextStyle(fontSize: screenWidth * 0.04), // Texto responsivo
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
    },
  );
}

  String getDayOfWeekInSpanish(String date) {
    DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(date);
    String dayOfWeek = DateFormat('EEEE').format(parsedDate);
    Map<String, String> daysOfWeekInSpanish = {
      'Monday': 'Lunes',
      'Tuesday': 'Martes',
      'Wednesday': 'Miércoles',
      'Thursday': 'Jueves',
      'Friday': 'Viernes',
      'Saturday': 'Sábado',
      'Sunday': 'Domingo',
    };
    return daysOfWeekInSpanish[dayOfWeek] ?? dayOfWeek;
  }

Widget _buildForecastHours(
  BuildContext context,
  String date,
  List<Map<String, dynamic>> hourlyData,
) {
  DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(date);
  String dayOfWeek = getDayOfWeekInSpanish(date);

  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Previsión por horas',
        style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
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
    body: LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.all(screenWidth * 0.04), // Padding dinámico
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
                      color: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.04), // Bordes dinámicos
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getWeatherIcon(iconCode),
                          size: screenWidth * 0.08, // Icono responsivo
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          '🕒 Hora: $hour',
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.045, // Texto responsivo
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.thermostat_outlined,
                                  size: screenWidth * 0.05, // Icono responsivo
                                  color: Colors.red,
                                ),
                                SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                Text(
                                  '${hourData['temp'].toStringAsFixed(0)}°C',
                                  style: GoogleFonts.raleway(fontSize: screenWidth * 0.04), // Texto responsivo
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  WeatherIcons.rain,
                                  size: screenWidth * 0.05, // Icono responsivo
                                  color: Colors.blue,
                                ),
                                SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                Text(
                                  'Prob. Lluvia: ${hourData['pop'].toStringAsFixed(0)}%',
                                  style: GoogleFonts.raleway(fontSize: screenWidth * 0.04), // Texto responsivo
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  size: screenWidth * 0.05, // Icono responsivo
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                Text(
                                  'Humedad: ${hourData['humidity']}%',
                                  style: GoogleFonts.raleway(fontSize: screenWidth * 0.04), // Texto responsivo
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.air,
                                  size: screenWidth * 0.05, // Icono responsivo
                                  color: Colors.green,
                                ),
                                SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                Text(
                                  'Viento: ${(hourData['wind'] * 3.6).toStringAsFixed(0)} Km/h',
                                  style: GoogleFonts.raleway(fontSize: screenWidth * 0.04), // Texto responsivo
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: screenWidth * 0.05, // Icono responsivo
                                  color: Colors.orange,
                                ),
                                SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                                Text(
                                  '${hourData['description'][0].toUpperCase()}${hourData['description'].substring(1)}',
                                  style: GoogleFonts.raleway(fontSize: screenWidth * 0.04), // Texto responsivo
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
        );
      },
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

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
              SizedBox(height: screenHeight * 0.05), // Espaciado dinámico
              Icon(
                _getWeatherIcon(iconCode),
                size: screenWidth * 0.25, // Icono responsivo
                color: Colors.white,
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                '${forecast['dayOfWeek']} ',
                style: TextStyle(
                  fontSize: screenWidth * 0.06, // Texto responsivo
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${forecast['date']}',
                style: TextStyle(
                  fontSize: screenWidth * 0.05, // Texto responsivo
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_city[0].toUpperCase()}${_city.substring(1)}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.07, // Texto responsivo
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02), // Espaciado dinámico
                  Icon(
                    Icons.location_pin,
                    color: Colors.white,
                    size: screenWidth * 0.07, // Icono responsivo
                  ),
                ],
              ),
              Spacer(),
              Text(
                '${forecast['temp'].toStringAsFixed(0)}°C',
                style: GoogleFonts.montserrat(
                  fontSize: screenWidth * 0.2, // Texto responsivo
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
                padding: EdgeInsets.all(screenWidth * 0.04), // Padding dinámico
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
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
                    padding: EdgeInsets.all(
                      screenWidth * 0.05,
                    ), // Padding dinámico
                    child: Column(
                      children: [
                        _infoRow(
                          WeatherIcons.thermometer,
                          'Máx',
                          '${forecast['temp_max'].toStringAsFixed(0)}°C',
                          screenWidth,
                        ),
                        _infoRow(
                          WeatherIcons.snowflake_cold,
                          'Mín',
                          '${forecast['temp_min'].toStringAsFixed(0)}°C',
                          screenWidth,
                        ),
                        _infoRow(
                          WeatherIcons.raindrops,
                          'Lluvia',
                          '${forecast['pop'].toStringAsFixed(0)}%',
                          screenWidth,
                        ),
                        _infoRow(
                          WeatherIcons.humidity,
                          'Humedad',
                          '${forecast['humidity']}%',
                          screenWidth,
                        ),
                        _infoRow(
                          WeatherIcons.strong_wind,
                          'Viento',
                          '${(forecast['wind']).toStringAsFixed(0)} Km/h',
                          screenWidth,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    double screenWidth,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: screenWidth * 0.02,
      ), // Padding dinámico
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: screenWidth * 0.05,
              ), // Icono responsivo
              SizedBox(width: screenWidth * 0.03), // Espaciado dinámico
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                ), // Texto responsivo
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
            ), // Texto responsivo
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final String apiKey =
        '1bacfbd7cde7607f9441c8e0c8d09a69'; // Define la API key aquí

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return Container(
          width: screenWidth,
          height: screenHeight,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                40.4168,
                -3.7038,
              ), // Coordenadas de la ciudad
              initialZoom: 5.0, // Nivel de zoom inicial
              maxZoom: 18.0, // Ajusta el zoom máximo
              minZoom: 5.0,
            ),
            children: [
              // Capa de mapa base (OpenStreetMap en este caso)
              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png", // URL de OpenStreetMap
              ),

              // Mostrar capa de precipitación
              if (_showPrecipitationLayer)
                TileLayer(
                  urlTemplate:
                      "https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=$apiKey", // URL de la capa de precipitación
                ),

              // Mostrar capa de temperatura
              if (_showTemperatureLayer)
                TileLayer(
                  urlTemplate:
                      "https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=$apiKey", // URL de la capa de temperatura
                ),

              // Mostrar capa de viento
              if (_showWindLayer)
                TileLayer(
                  urlTemplate:
                      "https://tile.openweathermap.org/map/wind_new/{z}/{x}/{y}.png?appid=$apiKey", // URL de la capa de viento
                ),

              // Mostrar capa de nubes
              if (_showCloudsLayer)
                TileLayer(
                  urlTemplate:
                      "https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=$apiKey", // URL de la capa de nubes
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // Padding dinámico
        child: Column(
          children: <Widget>[
            SizedBox(
              height: screenHeight * 0.05, // Espaciado dinámico
            ),
            Visibility(
              visible: _selectedIndex == 0,
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Ingresa la ciudad',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ), // Padding dinámico dentro del TextField
                    ),
                    onChanged: (value) {
                      setState(() {
                        _city = value;
                      });
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02), // Espaciado dinámico
                  ElevatedButton(
                    onPressed: () {
                      if (_city.isNotEmpty) {
                        _fetchWeather();
                      }
                    },
                    child: Text(
                      'Obtener pronóstico semanal',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                      ), // Texto responsivo
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // Espaciado dinámico
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
      floatingActionButton:
          _selectedIndex == 2
              ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showPrecipitationLayer = !_showPrecipitationLayer;
                      });
                    },
                    child: Icon(Icons.grain),
                    tooltip: 'Mostrar/Ocultar Precipitaciones',
                  ),
                  SizedBox(height: screenHeight * 0.02), // Espaciado dinámico
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showTemperatureLayer = !_showTemperatureLayer;
                      });
                    },
                    child: Icon(Icons.thermostat),
                    tooltip: 'Mostrar/Ocultar Temperatura',
                  ),
                  SizedBox(height: screenHeight * 0.02), // Espaciado dinámico
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showWindLayer = !_showWindLayer;
                      });
                    },
                    child: Icon(Icons.air),
                    tooltip: 'Mostrar/Ocultar Viento',
                  ),
                  SizedBox(height: screenHeight * 0.02), // Espaciado dinámico
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showCloudsLayer = !_showCloudsLayer;
                      });
                    },
                    child: Icon(Icons.cloud),
                    tooltip: 'Mostrar/Ocultar Nubes',
                  ),
                ],
              )
              : null,
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _error = 'Los servicios de ubicación están deshabilitados.';
      });
      return;
    }

    // Verifica los permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Los permisos de ubicación están denegados.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _error = 'Los permisos de ubicación están denegados permanentemente.';
      });
      return;
    }

    // Obtiene la ubicación actual
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Usa la API de OpenWeatherMap para obtener el nombre de la ciudad
    final String apiKey = '1bacfbd7cde7607f9441c8e0c8d09a69';
    final String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&lang=es';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _city = data['name'];
          _fetchWeather();
        });
      } else {
        setState(() {
          _error = 'No se pudo obtener la ciudad actual.';
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        _error = 'Error al obtener la ciudad actual.';
      });
    }
  }
}
