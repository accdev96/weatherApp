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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(), // Cambia la pantalla inicial a SplashScreen
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2), // Duración de la animación
      vsync: this,
    )..repeat();

    _loadData();
    
  }

  Future<void> _loadData() async {
    await Future.delayed(
      Duration(seconds: 3),
    ); 
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherScreen(),
      ), 
    );
  }

  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, 

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/w3.jpg',
              width:
                  MediaQuery.of(context).size.width *
                  0.6, 
              height:
                  MediaQuery.of(context).size.height *
                  0.3, 
            ),
            SizedBox(height: 20), 
            RotationTransition(
              turns: _controller, 
              child: Icon(
                Icons.wb_sunny, 
                size: 50, 
                color: Colors.yellow, 
              ),
            ),
            SizedBox(height: 20), 
            Text(
              'Pronóstico del Clima', 
              style: GoogleFonts.raleway(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Obtén el clima actualizado para tu ubicación.',
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
