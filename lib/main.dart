import 'package:flutter/material.dart';
import 'weather_screen.dart'; // Asegúrate de que este es el archivo donde tienes la clase WeatherScreen
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Cambia la pantalla inicial a SplashScreen
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    
    // Inicializamos el controlador de la animación
    _controller = AnimationController(
      duration: Duration(seconds: 2), // Duración de la animación
      vsync: this,
    )..repeat(); // Hace que la animación se repita indefinidamente

    // Simula tarea asíncrona, por ejemplo, cargar datos de la API
    _loadData();
  }

  // Simula tarea asíncrona, por ejemplo, cargar datos de la API
  Future<void> _loadData() async {
    await Future.delayed(Duration(seconds: 3)); // Espera 3 segundos (puedes cambiarlo)
    // Después de que termine la tarea, navega a la pantalla WeatherScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WeatherScreen()), // Navega a WeatherScreen
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Limpiar el controlador de animación
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Puedes personalizar el color de fondo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí mostramos la imagen de carga
            Image.asset(
              'assets/images/w3.jpg', // Ruta de tu imagen
              width: 300, // Tamaño de la imagen
              height: 300, // Tamaño de la imagen
            ),
            SizedBox(height: 20), // Espaciado entre la imagen y el ícono
            RotationTransition(
              turns: _controller, // Aplicar la rotación con el controlador
              child: Icon(
                Icons.wb_sunny, // Ícono de sol
                size: 50, // Tamaño del ícono
                color: Colors.yellow, // Color del ícono
              ),
            ),
            SizedBox(height: 20), // Espaciado entre el ícono y el texto
            Text(
              'El Tiempo', // Texto debajo del indicador
              style: GoogleFonts.raleway(
                fontSize: 24, // Tamaño de la fuente
                fontWeight: FontWeight.bold, // Negrita
                color: Colors.white, // Color del texto
              ),
            ),
          ],
        ),
      ),
    );
  }
}
