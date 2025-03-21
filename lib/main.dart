import 'package:flutter/material.dart';
import 'weather_screen.dart'; // Asegúrate de que este es el archivo donde tienes la clase WeatherScreen

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherScreen(),  // Establece WeatherScreen como la pantalla principal
    );
  }
}
